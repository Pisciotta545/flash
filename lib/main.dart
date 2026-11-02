import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nsd/nsd.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'gallery.dart';
import 'updater.dart';

void main() => runApp(const FlashApp());

/// U5: modo de tema elegido por el usuario (sistema / claro / oscuro). Se carga
/// desde shared_preferences al iniciar y MaterialApp se reconstruye al cambiarlo.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

ThemeMode themeModeFromString(String s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode m) {
  switch (m) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

/// Tema Material 3 con la marca amarilla de Flash, derivado para claro u oscuro.
ThemeData flashTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.yellow,
      brightness: brightness,
    ),
  );
}

class FlashApp extends StatelessWidget {
  const FlashApp({super.key});
  @override
  Widget build(BuildContext context) {
    // U5: la UI se adapta al tema; el modo lo decide el usuario (por defecto, el
    // del sistema). I1: el idioma sigue la configuración del teléfono y cae a
    // español si no hay traducción.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Transferencias Flash',
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: flashTheme(Brightness.light),
          darkTheme: flashTheme(Brightness.dark),
          themeMode: mode,
          home: const FlashHomePage(),
        );
      },
    );
  }
}

/// Foto del progreso de una transferencia en un instante dado.
/// Se emite con throttling para no repintar la UI en cada chunk (ver V1).
class TransferStats {
  final double progress; // 0.0 .. 1.0
  final int bytes; // bytes transferidos hasta ahora
  final int total; // tamaño total esperado
  final double bytesPerSec; // velocidad promedio
  final Duration eta; // tiempo restante estimado
  const TransferStats({
    this.progress = 0.0,
    this.bytes = 0,
    this.total = 0,
    this.bytesPerSec = 0.0,
    this.eta = Duration.zero,
  });
}

class TransferTask {
  String name;
  String path;
  int size;
  String status;

  // El progreso de alta frecuencia viaja por este notifier: solo se repinta la
  // barra de esa tarea, no toda la pantalla (V1). Las métricas (MB/s, ETA) son
  // parte del mismo paquete (U1).
  final ValueNotifier<TransferStats> stats;

  // Estado interno del medidor (throttling + velocidad promedio).
  final Stopwatch _sw = Stopwatch();
  int _bytes = 0;
  int _lastEmitMs = -1000; // fuerza una primera emisión temprana

  double progress; // última fracción conocida (para lecturas puntuales)

  TransferTask({
    required this.name,
    required this.path,
    required this.size,
    this.status = 'waiting',
  }) : progress = 0.0,
       stats = ValueNotifier(TransferStats(total: size));

  /// Suma bytes transferidos. Emite un nuevo [TransferStats] como mucho cada
  /// ~120 ms (o cuando [force] es true), evitando el cuello de botella de
  /// llamar a setState por cada bloque.
  void addBytes(int n, {bool force = false}) {
    if (!_sw.isRunning) _sw.start();
    _bytes += n;
    final nowMs = _sw.elapsedMilliseconds;
    if (!force && nowMs - _lastEmitMs < 120) return;

    final speed = nowMs > 0 ? _bytes * 1000 / nowMs : 0.0;
    progress = size > 0 ? (_bytes / size).clamp(0.0, 1.0) : (force ? 1.0 : 0.0);
    final remaining = size > _bytes ? size - _bytes : 0;
    final eta = speed > 0
        ? Duration(seconds: (remaining / speed).round())
        : Duration.zero;
    stats.value = TransferStats(
      progress: progress,
      bytes: _bytes,
      total: size,
      bytesPerSec: speed,
      eta: eta,
    );
    _lastEmitMs = nowMs;
  }

  /// Reinicia los contadores para volver a intentar la transferencia desde cero
  /// (sin esto, un reintento arrastraría los bytes del intento fallido y la barra
  /// mostraría más del 100 %).
  void reset() {
    _sw.reset();
    _bytes = 0;
    _lastEmitMs = -1000;
    progress = 0.0;
    stats.value = TransferStats(total: size);
  }

  void complete() {
    _sw.stop();
    progress = 1.0;
    status = 'done';
    final shown = size > 0 ? size : _bytes;
    stats.value = TransferStats(
      progress: 1.0,
      bytes: shown,
      total: shown,
      bytesPerSec: 0.0,
      eta: Duration.zero,
    );
  }

  void disposeStats() => stats.dispose();
}

/// Devuelve solo el nombre base de un archivo, descartando rutas y `..` para
/// impedir *path traversal* al construir la ruta de guardado (ver S1).
String safeFileName(String raw) {
  // Quedarse con el último segmento tras cualquier separador.
  var name = raw.replaceAll('\\', '/').split('/').last.trim();
  // Quitar restos de recorrido y caracteres problemáticos.
  name = name.replaceAll('..', '').replaceAll(RegExp(r'[\x00-\x1f]'), '');
  if (name.isEmpty || name == '.' || name == '..') {
    name = 'archivo_${DateTime.now().millisecondsSinceEpoch}.dat';
  }
  return name;
}

/// G4: normaliza el nombre de carpeta de una transferencia para que sea seguro
/// como nombre de directorio (sin separadores, `..` ni caracteres de control) y
/// con un largo acotado. "" significa "sin carpeta".
String sanitizeFolderName(String raw) {
  var n = raw
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '')
      .replaceAll('..', '')
      .trim();
  if (n.length > 60) n = n.substring(0, 60).trim();
  return n;
}

String humanSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  double v = bytes / 1024;
  int i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

String humanSpeed(double bytesPerSec) {
  if (bytesPerSec <= 0) return '';
  return '${humanSize(bytesPerSec.round())}/s';
}

String humanEta(Duration d) {
  if (d <= Duration.zero) return '';
  final s = d.inSeconds;
  if (s < 60) return '${s}s';
  final m = s ~/ 60;
  final r = s % 60;
  if (m < 60) return '${m}m ${r}s';
  final h = m ~/ 60;
  return '${h}h ${m % 60}m';
}

/// R1: CRC32 (IEEE) incremental en Dart puro, sin dependencias. Sirve para
/// verificar que el archivo llegó íntegro (detecta corrupción en la transferencia).
/// El emisor lo precalcula y lo manda en la cabecera; el receptor lo recalcula
/// sobre los bytes que escribe y compara antes de dar la transferencia por buena.
class Crc32 {
  static final List<int> _table = _buildTable();

  static List<int> _buildTable() {
    final table = List<int>.filled(256, 0);
    for (int n = 0; n < 256; n++) {
      int c = n;
      for (int k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
      }
      table[n] = c;
    }
    return table;
  }

  int _crc = 0xFFFFFFFF;

  void update(List<int> bytes) {
    int c = _crc;
    for (final b in bytes) {
      c = _table[(c ^ b) & 0xFF] ^ (c >> 8);
    }
    _crc = c;
  }

  /// Valor final del CRC32 (entero sin signo de 32 bits).
  int get value => (_crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

/// Calcula el CRC32 de un archivo leyéndolo en streaming (una sola pasada).
Future<int> crc32OfFile(File file) async {
  final crc = Crc32();
  await for (final chunk in file.openRead()) {
    crc.update(chunk);
  }
  return crc.value;
}

class FlashHomePage extends StatefulWidget {
  const FlashHomePage({super.key});
  @override
  State<FlashHomePage> createState() => _FlashHomePageState();
}

class _FlashHomePageState extends State<FlashHomePage> {
  List<TransferTask> tasks = [];
  // Vacío = mostrar el mensaje "listo" traducido (ver _buildStatusHeader).
  String statusMessage = "";

  Registration? registration;
  Discovery? discovery;
  ServerSocket? serverSocket;
  HttpServer? webServer;
  StreamSubscription? _intentDataStreamSubscription;

  List<Service> foundDevices = [];
  bool isReceptor = false;
  bool isScanning = false;
  bool isWebMode = false;
  String myIp = "";

  // Muestra un overlay "Preparando archivos…" mientras el selector copia lo
  // elegido a caché: así la app no parece "tildada" al elegir de la galería.
  bool _isPreparingFiles = false;

  // Último receptor al que se envió, para poder reintentar una tarea que falle.
  String? _lastTargetHost;
  String? _lastTargetName; // nombre legible del receptor (para la galería)
  int _lastTargetPort = 4000;

  // G4: nombre de carpeta elegido para el envío actual ("" = sin carpeta). Viaja
  // en la cabecera para que el receptor agrupe los archivos en Flash/<carpeta>/.
  String _transferFolder = "";

  // G4: carpeta donde agrupar lo que llegue por Modo Web ("" = sin carpeta).
  final TextEditingController webFolderController = TextEditingController();

  // Reintentos automáticos por archivo antes de marcar la tarea en error.
  static const int _maxSendAttempts = 3;
  // Optimización de envío: leer en bloques grandes (256 KB) en vez de los ~64 KB
  // de openRead() → menos iteraciones y menos llamadas al socket, más throughput.
  static const int _sendBlockSize = 256 * 1024;

  // G3: carpeta de caché donde se escriben los archivos entrantes antes de
  // moverlos a Descargas/Flash vía MediaStore. No se usan rutas absolutas.
  String? _tempDirPath;

  // Canal nativo que guarda en Descargas/Flash sin MANAGE_EXTERNAL_STORAGE.
  static const MethodChannel _storageChannel = MethodChannel(
    'com.velocidad.flash/storage',
  );

  File? webSharedFile;
  final TextEditingController ipController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  // I1: atajo a las cadenas traducidas (según el idioma del teléfono).
  AppLocalizations get _t => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    requestPermissions();
    loadSettings();
    setupShareIntent();
    _tempDir(); // pre-calienta la carpeta de caché
    GalleryStore.instance.load(); // G4: precarga el índice de la galería
    _refreshSaveLabel(); // destino de guardado (Descargas/Flash o carpeta elegida)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      // G5: comprobación silenciosa de actualizaciones al abrir (solo avisa si
      // hay una versión nueva disponible).
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Updater.checkForUpdates(context, silent: true);
      });
    });
  }

  /// Carpeta de caché de la app (sin permisos) para los archivos entrantes.
  Future<String> _tempDir() async {
    _tempDirPath ??= (await getTemporaryDirectory()).path;
    return _tempDirPath!;
  }

  /// Mueve [tempPath] al destino configurado mediante el canal nativo: la carpeta
  /// elegida por el usuario (SAF, p. ej. la tarjeta SD) o, por defecto, Descargas/Flash
  /// (MediaStore en Android 10+, copia directa en Android ≤9). Si se indica
  /// [subFolder], los archivos se agrupan en `Flash/<subFolder>/` (G4).
  /// Devuelve { uri, path }: `uri` para abrir/compartir, `path` legible para la
  /// galería. Lanza si el guardado falla, para que el llamador marque el error.
  Future<Map<String, dynamic>?> _saveIncoming(
    String tempPath,
    String fileName, {
    String subFolder = "",
  }) {
    return _storageChannel.invokeMapMethod<String, dynamic>('saveIncoming', {
      'tempPath': tempPath,
      'fileName': fileName,
      'subFolder': subFolder,
    });
  }

  /// G4: identificador único para una entrada de la galería.
  String _newId(String name) =>
      '${DateTime.now().microsecondsSinceEpoch}_${name.hashCode}';

  /// G4: registra en la galería un archivo recibido. [res] es el mapa que devolvió
  /// el guardado nativo ({ uri, path }).
  Future<void> _recordReceived(
    String name,
    int size,
    String folder,
    String peer,
    Map<String, dynamic>? res,
  ) async {
    await GalleryStore.instance.add(
      GalleryEntry(
        id: _newId(name),
        name: name,
        size: size,
        mime: mimeFromName(name),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        direction: 'received',
        peer: peer,
        folder: folder,
        location: (res?['path'] as String?) ?? '',
        uri: (res?['uri'] as String?) ?? '',
      ),
    );
  }

  /// G4: registra en la galería un archivo que se envió (historial). El archivo
  /// original sigue siendo del usuario; se guarda su ruta para poder compartirlo.
  Future<void> _recordSent(TransferTask task) async {
    await GalleryStore.instance.add(
      GalleryEntry(
        id: _newId(task.name),
        name: task.name,
        size: task.size,
        mime: mimeFromName(task.name),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        direction: 'sent',
        peer: (_lastTargetName ?? _lastTargetHost ?? '').trim(),
        folder: _transferFolder,
        location: task.path,
        uri: task.path,
      ),
    );
  }

  /// G4: pide (opcionalmente) un nombre para la transferencia, que se convertirá
  /// en una carpeta en ambos equipos. Devuelve "" si no se quiere agrupar.
  Future<String> _askFolderName() async {
    final ctrl = TextEditingController(text: _transferFolder);
    final scheme = Theme.of(context).colorScheme;
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.create_new_folder, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(_t.folderDialogTitle)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t.folderDialogDesc,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.pop(c, v.trim()),
              decoration: InputDecoration(
                hintText: _t.folderDialogHint,
                prefixIcon: const Icon(Icons.folder),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, ''),
            child: Text(_t.folderDialogSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: Text(_t.folderDialogOk),
          ),
        ],
      ),
    );
    return sanitizeFolderName(result ?? '');
  }

  // Destino de guardado. "" = destino por defecto (Descargas/Flash); si no, es la
  // etiqueta legible de la carpeta elegida (p. ej. "Tarjeta SD/Flash").
  String _saveLabel = "";

  /// Consulta al lado nativo la etiqueta del destino actual de guardado.
  Future<void> _refreshSaveLabel() async {
    try {
      final label = await _storageChannel.invokeMethod<String>('getSaveLabel');
      if (mounted) setState(() => _saveLabel = label ?? "");
    } catch (_) {
      // Si falla, se asume el destino por defecto.
    }
  }

  /// Abre el selector del sistema para elegir una carpeta destino (incluida la
  /// tarjeta de memoria). Devuelve true si el usuario eligió una carpeta.
  Future<bool> _pickSaveFolder() async {
    try {
      final label = await _storageChannel.invokeMethod<String>(
        'pickSaveFolder',
      );
      if (label == null) return false; // cancelado
      if (mounted) setState(() => _saveLabel = label);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Vuelve a guardar en Descargas/Flash (destino por defecto).
  Future<void> _useDefaultFolder() async {
    try {
      final label = await _storageChannel.invokeMethod<String>(
        'useDefaultFolder',
      );
      if (mounted) setState(() => _saveLabel = label ?? "");
    } catch (_) {}
  }

  /// U2: mantiene la pantalla encendida mientras hay una transferencia activa.
  Future<void> _setWakelock(bool on) async {
    try {
      await WakelockPlus.toggle(enable: on);
    } catch (_) {
      // En plataformas sin soporte simplemente se ignora.
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    webFolderController.dispose();
    _setWakelock(false); // U2
    super.dispose();
  }

  // --- CONFIGURAR EL MENÚ COMPARTIR (CORREGIDO) ---
  void setupShareIntent() {
    // Escuchador con .instance para versiones nuevas del paquete
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
          handleSharedFiles(value);
        }, onError: (err) {});

    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      handleSharedFiles(value);
    });
  }

  Future<void> handleSharedFiles(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    setState(() => _isPreparingFiles = true); // overlay: no queda "tildada"
    try {
      // length() async en vez de lengthSync(): no bloquea el hilo de UI mientras
      // se calcula el tamaño de cada archivo compartido.
      final newTasks = <TransferTask>[];
      for (final f in files) {
        int size = 0;
        try {
          size = await File(f.path).length();
        } catch (_) {}
        newTasks.add(
          TransferTask(name: f.path.split('/').last, path: f.path, size: size),
        );
      }
      if (!mounted) return;
      setState(() {
        tasks = newTasks;
        statusMessage = _t.statusFilesLoaded;
      });
    } finally {
      if (mounted) setState(() => _isPreparingFiles = false);
    }
    startScanning();
  }

  // --- AJUSTES Y MEMORIA ---
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // U5: aplicar el modo de tema guardado.
    themeModeNotifier.value = themeModeFromString(
      prefs.getString('themeMode') ?? 'system',
    );
    setState(() {
      nameController.text = prefs.getString('userName') ?? "Usuario Flash";
    });
  }

  /// U5: cambia el modo de tema y lo persiste.
  Future<void> _setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeModeToString(mode));
  }

  Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
  }

  Future<void> requestPermissions() async {
    // G3: ya no se pide MANAGE_EXTERNAL_STORAGE. En Android 10+ guardar en
    // Descargas no requiere permiso; Permission.storage solo aplica a versiones
    // viejas. La ubicación la necesita el descubrimiento mDNS.
    await [Permission.storage, Permission.location].request();
  }

  Future<void> getLocalIp() async {
    try {
      String? fallbackIp;
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            if (interface.name.toLowerCase().contains('wlan')) {
              setState(() => myIp = addr.address);
              return;
            }
            fallbackIp ??= addr.address;
          }
        }
      }
      setState(() => myIp = fallbackIp ?? "No detectada");
    } catch (e) {
      setState(() => myIp = "No detectada");
    }
  }

  Future<void> resetState() async {
    setState(() => statusMessage = _t.statusCancelling);
    _setWakelock(false); // U2: liberar pantalla al salir de un modo activo
    try {
      if (registration != null) await unregister(registration!);
      if (discovery != null) await stopDiscovery(discovery!);
      serverSocket?.close();
      await webServer?.close();
    } catch (_) {
      // Cierre best-effort: si algo ya estaba cerrado, no es un error.
    }

    setState(() {
      isReceptor = false;
      isScanning = false;
      isWebMode = false;
      webSharedFile = null;
      foundDevices.clear();
      tasks.clear();
      statusMessage = _t.statusReady;
    });
  }

  Future<void> showSettingsMenu() async {
    await _refreshSaveLabel(); // refrescar el destino actual antes de mostrarlo
    if (!mounted) return;
    final scheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDialog) {
          final isCustom = _saveLabel.isNotEmpty;
          final destination = isCustom ? _saveLabel : _t.settingsSaveValue;
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.settings, color: scheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(_t.settingsTitle)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Destino de guardado (incluye tarjeta SD) ---
                  Row(
                    children: [
                      Icon(Icons.download_done, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t.settingsSaveLabel,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Recuadro del destino actual. Si el usuario eligió una carpeta
                  // propia (p. ej. la tarjeta SD) queda resaltado y con un tilde,
                  // para que se note que la ubicación cambió correctamente.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isCustom
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isCustom
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: isCustom ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCustom ? Icons.sd_card : Icons.folder,
                          color: isCustom
                              ? scheme.onPrimaryContainer
                              : scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            destination,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCustom
                                  ? scheme.onPrimaryContainer
                                  : null,
                            ),
                          ),
                        ),
                        if (isCustom)
                          Icon(
                            Icons.check_circle,
                            color: scheme.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.sd_card, size: 18),
                        label: Text(_t.settingsChooseFolder),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await _pickSaveFolder();
                          if (ok) {
                            setDialog(() {});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_t.saveLocationChanged),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                      ),
                      if (isCustom)
                        TextButton.icon(
                          icon: const Icon(Icons.restore, size: 18),
                          label: Text(_t.settingsUseDefault),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            await _useDefaultFolder();
                            setDialog(() {});
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(_t.saveLocationChanged),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t.settingsSaveHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Divider(height: 28),
                  // --- Tema (U5) ---
                  Row(
                    children: [
                      Icon(Icons.brightness_6, color: scheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        _t.settingsThemeLabel,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: const Icon(Icons.brightness_auto, size: 18),
                        label: Text(_t.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: const Icon(Icons.light_mode, size: 18),
                        label: Text(_t.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: const Icon(Icons.dark_mode, size: 18),
                        label: Text(_t.themeDark),
                      ),
                    ],
                    selected: {themeModeNotifier.value},
                    onSelectionChanged: (sel) async {
                      await _setThemeMode(sel.first);
                      setDialog(() {});
                    },
                  ),
                  const Divider(height: 28),
                  // --- Actualizaciones (G5) ---
                  Row(
                    children: [
                      Icon(Icons.system_update, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _t.updatesTitle,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(_t.updatesCheck),
                    onPressed: () {
                      Navigator.pop(context);
                      Updater.checkForUpdates(context);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t.understood),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================
  // 🧭 ONBOARDING / AYUDA (U4)
  // ==========================================

  /// Muestra la ayuda automáticamente la primera vez que se abre la app.
  Future<void> _maybeShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seenOnboarding') ?? false) return;
    await prefs.setBool('seenOnboarding', true);
    if (mounted) showOnboarding();
  }

  Widget _helpItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showOnboarding() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Text("⚡", style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(child: Text(_t.onboardingTitle)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t.onboardingIntro, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              _helpItem(
                Icons.download,
                _t.onboardingReceiverTitle,
                _t.onboardingReceiverDesc,
              ),
              _helpItem(
                Icons.send,
                _t.onboardingSenderTitle,
                _t.onboardingSenderDesc,
              ),
              _helpItem(
                Icons.language,
                _t.onboardingWebTitle,
                _t.onboardingWebDesc,
              ),
              const SizedBox(height: 4),
              Text(
                _t.onboardingTip,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_t.onboardingGotIt),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🌐 MODO WEB (PARA IPHONES Y PC)
  // ==========================================
  Future<void> startWebMode() async {
    await getLocalIp();
    _setWakelock(true); // U2
    setState(() {
      isWebMode = true;
      tasks.clear();
    });

    try {
      webServer = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      setState(() => statusMessage = _t.statusWebActive);

      webServer!.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add(
          'Access-Control-Allow-Methods',
          'POST, GET, OPTIONS',
        );
        request.response.headers.add(
          'Access-Control-Allow-Headers',
          'Origin, X-Requested-With, Content-Type, Accept',
        );

        if (request.method == 'OPTIONS') {
          request.response
            ..statusCode = HttpStatus.ok
            ..close();
          return;
        }

        if (request.method == 'GET' && request.uri.path == '/') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(_getHtmlPage())
            ..close();
        } else if (request.method == 'GET' && request.uri.path == '/download') {
          if (webSharedFile != null && await webSharedFile!.exists()) {
            String fileName = webSharedFile!.path.split('/').last;
            request.response.headers.contentType = ContentType.binary;
            request.response.headers.add(
              'Content-Disposition',
              'attachment; filename="$fileName"',
            );

            setState(() => statusMessage = _t.statusWebDownloading(fileName));
            await request.response.addStream(webSharedFile!.openRead());
            await request.response.close();
            setState(() => statusMessage = _t.statusDownloadDone);
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..write('Archivo no encontrado')
              ..close();
          }
        } else if (request.method == 'POST' && request.uri.path == '/upload') {
          String fileName = safeFileName(
            Uri.decodeComponent(
              request.uri.queryParameters['name'] ?? 'archivo_web.dat',
            ),
          );
          int totalSize = request.headers.contentLength;

          // G3: se escribe a un temporal de caché y luego se mueve a Descargas.
          final tmpDir = await _tempDir();
          String tempPath =
              '$tmpDir/${DateTime.now().microsecondsSinceEpoch}_$fileName';

          TransferTask webTask = TransferTask(
            name: fileName,
            path: tempPath,
            size: totalSize > 0 ? totalSize : 100,
            status: 'receiving',
          );
          setState(() {
            statusMessage = _t.statusWebReceiving(fileName);
            tasks.insert(0, webTask);
          });

          IOSink sink = File(tempPath).openWrite();

          try {
            await for (var chunk in request) {
              sink.add(chunk);
              webTask.addBytes(chunk.length); // progreso con throttle (V1/U1)
            }
            await sink.close();
            final webFolder = sanitizeFolderName(webFolderController.text);
            final res = await _saveIncoming(
              tempPath,
              fileName,
              subFolder: webFolder,
            ); // G3: al destino configurado

            request.response
              ..statusCode = HttpStatus.ok
              ..write('OK')
              ..close();
            webTask.complete();
            // G4: registrar en la galería lo recibido por Modo Web.
            await _recordReceived(
              fileName,
              totalSize > 0 ? totalSize : webTask.size,
              webFolder,
              'Web',
              res,
            );
            setState(() {
              statusMessage = _t.statusWebSaved;
            });
          } catch (e) {
            await sink.close();
            setState(() {
              webTask.status = 'error';
              statusMessage = _t.statusWebReceiveError;
            });
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..close();
          }
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      });
    } catch (e) {
      setState(() => statusMessage = _t.statusWebError(e));
    }
  }

  Future<void> selectFileForWeb() async {
    setState(() => _isPreparingFiles = true); // overlay mientras copia a caché
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles();
    } finally {
      if (mounted) setState(() => _isPreparingFiles = false);
    }
    if (result != null) {
      setState(() {
        webSharedFile = File(result!.files.single.path!);
        statusMessage = _t.statusFileReadyWeb;
      });
    }
  }

  String _getHtmlPage() {
    // I1: la página servida al navegador del otro equipo se traduce según el
    // idioma del teléfono que hace de servidor.
    final lang = Localizations.localeOf(context).languageCode;
    String downloadSection = webSharedFile != null
        ? '''
        <div style="margin-top: 30px; padding: 20px; border: 2px dashed yellow; border-radius:10px;">
          <h3 style="margin-top:0;">📥 ${_t.webHtmlDownloadHeading}</h3>
          <p style="font-size: 18px; word-break: break-all;"><b>${webSharedFile!.path.split('/').last}</b></p>
          <br>
          <a href="/download" style="background:yellow; color:black; padding:15px 30px; text-decoration:none; font-weight:bold; border-radius:5px; display:inline-block; font-size:16px;">${_t.webHtmlDownloadButton}</a>
        </div>
      '''
        : '<p style="color:gray; font-style:italic;">${_t.webHtmlNoFile}</p>';

    return '''
    <!DOCTYPE html>
    <html lang="$lang">
    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Flash Web</title></head>
    <body style="background:#1e1e1e; color:#fff; font-family:sans-serif; text-align:center; padding:20px; margin:0;">
      <h1 style="color:yellow; font-size:40px; margin-bottom: 10px;">⚡ FLASH</h1>
      <p style="color:#aaa; margin-top:0;">${_t.webHtmlSubtitle}</p>
      $downloadSection
      <div style="margin-top: 40px; padding: 20px; background:#2a2a2a; border-radius:10px;">
        <h3 style="margin-top:0;">🚀 ${_t.webHtmlSendHeading}</h3>
        <input type="file" id="filePicker" multiple style="margin-bottom:20px; width:100%; color:white;">
        <br>
        <button id="btnSend" onclick="sendFiles()" style="background:#4CAF50; color:white; padding:15px 30px; border:none; font-weight:bold; border-radius:5px; width:100%; font-size:16px;">${_t.webHtmlSendButton}</button>
        <h4 id="status" style="color:yellow; margin-top:20px; word-break: break-all;"></h4>
        <p style="color:gray; font-size:12px;">${_t.webHtmlKeepScreen}</p>
      </div>
      <script>
        async function sendFiles() {
          const input = document.getElementById('filePicker');
          if (!input.files.length) return alert("${_t.webHtmlSelectAlert}");
          const statusLabel = document.getElementById('status');
          const btn = document.getElementById('btnSend');
          btn.disabled = true; btn.style.opacity = '0.5';
          let successCount = 0; let total = input.files.length;

          for(let i = 0; i < total; i++) {
            const file = input.files[i];
            statusLabel.innerText = `${_t.webHtmlUploading} (\${i+1}/\${total}): \${file.name}...`;
            try {
              const response = await fetch('/upload?name=' + encodeURIComponent(file.name), { method: 'POST', body: file });
              if(response.ok) successCount++;
            } catch (e) { console.error(e); }
          }

          statusLabel.innerText = `${_t.webHtmlDone} \${successCount}/\${total} ${_t.webHtmlFilesOk}. ✅`;
          input.value = ''; btn.disabled = false; btn.style.opacity = '1.0';
        }
      </script>
    </body>
    </html>
    ''';
  }

  // ==========================================
  // FUNCIONES DE FLASH NATIVO (ANDROID A ANDROID)
  // ==========================================
  Future<void> startReceptor() async {
    setState(() {
      isReceptor = true;
      tasks.clear();
    });
    _setWakelock(true); // U2
    await getLocalIp();

    String myName = nameController.text.trim().isEmpty
        ? "Usuario Flash"
        : nameController.text.trim();
    await saveName(myName);

    try {
      registration = await register(
        Service(name: myName, type: '_flash._tcp', port: 4000),
      );
    } catch (e) {
      debugPrint("Error mDNS: $e");
    }

    await _tempDir(); // G3: asegurar la carpeta de caché antes de recibir
    serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 4000);
    setState(() => statusMessage = _t.statusWaitingFiles(myIp));

    serverSocket!.listen((socket) {
      socket.setOption(
        SocketOption.tcpNoDelay,
        true,
      ); // V2: sin demora de Nagle
      List<int> buffer = [];
      bool headerParsed = false;
      bool finalized = false;
      int expectedSize = 0;
      int bytesReceived = 0;
      int?
      expectedCrc; // R1: CRC32 que anunció el emisor (null = sin verificación)
      final Crc32 crc = Crc32(); // R1: CRC32 calculado sobre lo recibido
      IOSink? fileSink;
      TransferTask? currentTask;
      String savedFilePath = "";
      String currentFolder = ""; // G4: carpeta pedida por el emisor
      String currentSender = _t.someone; // G4: nombre del emisor (para la galería)

      socket.listen(
        (List<int> data) {
          if (!headerParsed) {
            buffer.addAll(data);
            int newlineIndex = buffer.indexOf(10);

            if (newlineIndex != -1) {
              // P1: cabecera JSON en una línea (los nombres con '|' o caracteres
              // raros ya no rompen el parseo).
              String senderName = _t.someone;
              String fileName;
              try {
                final header = utf8.decode(buffer.sublist(0, newlineIndex));
                final map = jsonDecode(header) as Map<String, dynamic>;
                senderName =
                    (map['sender'] as String?)?.trim().isNotEmpty == true
                    ? map['sender'] as String
                    : _t.someone;
                fileName = safeFileName(
                  map['name'] as String? ?? 'archivo.dat',
                );
                expectedSize = (map['size'] as num?)?.toInt() ?? 0;
                expectedCrc = (map['crc32'] as num?)?.toInt(); // R1 (opcional)
                currentSender = senderName; // G4
                currentFolder = sanitizeFolderName(
                  map['folder'] as String? ?? '',
                ); // G4
              } catch (_) {
                // Cabecera inválida: abortar esta conexión sin romper el receptor.
                socket.destroy();
                return;
              }

              // G3: se recibe a un temporal de caché; al terminar se mueve a
              // Descargas/Flash vía el canal nativo.
              final tmpDir = _tempDirPath ?? Directory.systemTemp.path;
              savedFilePath =
                  '$tmpDir/${DateTime.now().microsecondsSinceEpoch}_$fileName';

              currentTask = TransferTask(
                name: fileName,
                path: savedFilePath,
                size: expectedSize,
                status: 'receiving',
              );
              setState(() {
                tasks.insert(0, currentTask!);
                statusMessage = _t.statusReceivingFrom(senderName);
              });

              fileSink = File(savedFilePath).openWrite();

              List<int> fileData = buffer.sublist(newlineIndex + 1);
              fileSink!.add(fileData);
              crc.update(fileData); // R1
              bytesReceived += fileData.length;
              headerParsed = true;
              currentTask!.addBytes(
                fileData.length,
              ); // V1: progreso con throttle
            }
          } else {
            fileSink!.add(data);
            crc.update(data); // R1
            bytesReceived += data.length;
            currentTask?.addBytes(data.length); // V1: progreso con throttle
          }

          if (headerParsed && bytesReceived >= expectedSize && !finalized) {
            finalized = true;
            socket.close();
            final task = currentTask;
            final sink = fileSink;
            final tmpPath = savedFilePath;
            final fname = task?.name ?? 'archivo.dat';
            // Cierre + traslado a Descargas en segundo plano (sin bloquear el
            // socket). Los bytes ya están en disco; acá solo se mueve el archivo.
            final crcExpected = expectedCrc;
            final crcActual = crc.value;
            final folder = currentFolder; // G4
            final sender = currentSender; // G4
            final fsize = task?.size ?? expectedSize; // G4
            () async {
              try {
                await sink?.close();
                // R1: si el emisor anunció un CRC y no coincide, el archivo llegó
                // corrupto: no se guarda y la tarea queda en error.
                if (crcExpected != null && crcExpected != crcActual) {
                  try {
                    await File(tmpPath).delete();
                  } catch (_) {}
                  task?.status = 'error';
                  if (mounted) {
                    setState(() => statusMessage = _t.statusIntegrityFailed);
                  }
                  return;
                }
                final res = await _saveIncoming(
                  tmpPath,
                  fname,
                  subFolder: folder,
                ); // G3: al destino configurado
                task?.complete();
                // G4: registrar en la galería lo recibido.
                await _recordReceived(fname, fsize, folder, sender, res);
                if (mounted) {
                  setState(() => statusMessage = _t.statusSavedToDownloads);
                }
              } catch (e) {
                task?.status = 'error';
                if (mounted) {
                  setState(() => statusMessage = _t.statusSaveFailed(e));
                }
              }
            }();
          }
        },
        onError: (e) {
          if (finalized) return;
          finalized = true;
          fileSink?.close();
          socket.close();
          if (currentTask != null) {
            setState(() {
              currentTask!.status = 'error';
              statusMessage = _t.statusTransferError;
            });
          }
        },
        onDone: () {
          if (!finalized) fileSink?.close();
        },
      );
    });
  }

  Future<void> startScanning() async {
    setState(() {
      isScanning = true;
      statusMessage = _t.statusSearching;
    });

    await saveName(nameController.text.trim());

    try {
      discovery = await startDiscovery('_flash._tcp');
      discovery!.addListener(
        () => setState(() => foundDevices = discovery!.services),
      );
    } catch (e) {
      setState(() => statusMessage = _t.statusSearchError(e));
    }
  }

  Future<void> triggerSend(
    String targetHost,
    int targetPort, {
    String? peerName,
  }) async {
    // Recordar el destino para poder reintentar una tarea que falle (botón de
    // reintento en la lista) y mostrarlo en la galería.
    _lastTargetHost = targetHost;
    _lastTargetName = (peerName != null && peerName.trim().isNotEmpty)
        ? peerName.trim()
        : targetHost;
    _lastTargetPort = targetPort;

    bool hasPending = tasks.any(
      (t) => t.status == 'waiting' || t.status == 'error',
    );

    if (!hasPending) {
      setState(() => _isPreparingFiles = true); // overlay: no queda "tildada"
      FilePickerResult? result;
      try {
        result = await FilePicker.platform.pickFiles(allowMultiple: true);
      } finally {
        if (mounted) setState(() => _isPreparingFiles = false);
      }
      if (result == null) return;
      final picked = result.files;
      setState(() {
        tasks = picked
            .map((f) => TransferTask(name: f.name, path: f.path!, size: f.size))
            .toList();
        statusMessage = _t.statusPreparingSend;
      });
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // G4: pedir un nombre opcional para la transferencia. Ese nombre crea una
    // carpeta en el receptor y agrupa el envío en la galería de ambos equipos.
    if (!mounted) return;
    _transferFolder = await _askFolderName();

    _setWakelock(true); // U2: pantalla encendida mientras se envía
    try {
      for (var task in tasks) {
        if (task.status == 'done') continue;
        await _sendTaskWithRetries(task, targetHost, targetPort);
      }
      setState(() => statusMessage = _t.statusTransfersDone);
    } finally {
      _setWakelock(false); // U2: liberar al terminar el envío
    }
  }

  /// Reintenta manualmente una tarea que quedó en error, reenviándola al último
  /// receptor usado. Lo dispara el botón de reintento de la lista.
  Future<void> _retryTask(TransferTask task) async {
    final host = _lastTargetHost;
    if (host == null) return; // sin destino conocido no hay a dónde reintentar
    _setWakelock(true);
    try {
      await _sendTaskWithRetries(task, host, _lastTargetPort);
      if (mounted) setState(() => statusMessage = _t.statusTransfersDone);
    } finally {
      _setWakelock(false);
    }
  }

  /// Envía una tarea reintentando automáticamente hasta [_maxSendAttempts] veces
  /// antes de darla por fallida. Devuelve true si se envió con éxito.
  Future<bool> _sendTaskWithRetries(
    TransferTask task,
    String host,
    int port,
  ) async {
    for (int attempt = 1; attempt <= _maxSendAttempts; attempt++) {
      try {
        // Reinicia contadores en cada intento (incluye el manual sobre una tarea
        // que ya venía en error) para que la barra arranque de cero.
        task.reset();
        if (attempt > 1) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
        if (mounted) setState(() => task.status = 'sending');
        await _sendTaskOnce(task, host, port);
        task.complete();
        await _recordSent(task); // G4: historial de enviados
        if (mounted) setState(() {});
        return true;
      } catch (_) {
        // Sigue reintentando mientras queden intentos.
      }
    }
    if (mounted) setState(() => task.status = 'error');
    return false;
  }

  /// Un intento de envío de un archivo a [host]:[port].
  Future<void> _sendTaskOnce(TransferTask task, String host, int port) async {
    final senderName = nameController.text.trim().isEmpty
        ? "Usuario Flash"
        : nameController.text.trim();

    final socket = await Socket.connect(host, port);
    try {
      socket.setOption(SocketOption.tcpNoDelay, true); // V2
      final file = File(task.path);

      // R1: CRC32 del archivo (una pasada) para que el receptor verifique la
      // integridad al terminar.
      final crc = await crc32OfFile(file);

      // P1: cabecera JSON en una línea, terminada en '\n'.
      final header =
          '${jsonEncode({'sender': senderName, 'name': task.name, 'size': task.size, 'crc32': crc, 'folder': _transferFolder})}\n';
      socket.add(utf8.encode(header));

      // Optimización: leer en bloques grandes (256 KB) en vez de los ~64 KB de
      // openRead() → menos iteraciones y menos llamadas al socket.
      final raf = await file.open();
      try {
        while (true) {
          final chunk = await raf.read(_sendBlockSize);
          if (chunk.isEmpty) break;
          socket.add(chunk);
          task.addBytes(chunk.length); // V1: progreso con throttle
        }
      } finally {
        await raf.close();
      }

      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 100));
    } finally {
      await socket.close();
    }
  }

  // ==========================================
  // INTERFAZ GRÁFICA
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⚡ FLASH',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: _t.galleryTooltip,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GalleryPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: _t.helpTooltip,
            onPressed: showOnboarding,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: _t.settingsTooltip,
            onPressed: showSettingsMenu,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildStatusHeader(),

              if (!isReceptor && !isScanning && !isWebMode) ...[
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: nameController,
                    onChanged: (val) => saveName(val),
                    decoration: InputDecoration(
                      labelText: _t.nameFieldLabel,
                      prefixIcon: Icon(Icons.person, color: scheme.primary),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                _buildModeSelection(),
              ],

              if (isReceptor) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: resetState,
                  icon: const Icon(Icons.cancel),
                  label: Text(_t.btnStopReceiver),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (isScanning) ...[
                if (foundDevices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      _t.searchingWifi,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                _buildDeviceList(),
                _buildManualIpFallback(),
                ElevatedButton.icon(
                  onPressed: resetState,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(_t.btnGoBack),
                ),
              ],

              if (isWebMode) ...[
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    border: Border.all(color: scheme.primary),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _t.webEnterInBrowser,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "http://$myIp:8080",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: scheme.onSurfaceVariant,
                            ),
                            tooltip: _t.copyTooltip,
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: "http://$myIp:8080"),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_t.addressCopied),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      // U3: QR para escanear desde el iPhone/PC sin tipear la IP.
                      if (myIp.isNotEmpty && myIp != "No detectada") ...[
                        const SizedBox(height: 16),
                        Text(
                          _t.webScanQr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: QrImageView(
                            data: "http://$myIp:8080",
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // G4: carpeta opcional donde agrupar lo que llegue por web.
                      TextField(
                        controller: webFolderController,
                        decoration: InputDecoration(
                          labelText: _t.webFolderLabel,
                          prefixIcon: const Icon(Icons.create_new_folder),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(),
                      Text(
                        _t.webDownloadQuestion,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: selectFileForWeb,
                        icon: const Icon(
                          Icons.file_upload,
                          color: Colors.black,
                        ),
                        label: Text(
                          webSharedFile == null
                              ? _t.btnSelectFileShare
                              : _t.btnChangeFile,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      if (webSharedFile != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _t.webSharing(webSharedFile!.path.split('/').last),
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: resetState,
                  icon: const Icon(Icons.cancel),
                  label: Text(_t.btnCloseWebServer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              Expanded(child: _buildTaskList()),
            ],
          ),
          if (_isPreparingFiles) _buildPreparingOverlay(),
        ],
      ),
    );
  }

  /// Capa translúcida con spinner que se muestra mientras el selector de archivos
  /// copia lo elegido a caché. Evita que la app se vea "tildada" y bloquea toques
  /// accidentales durante ese momento.
  Widget _buildPreparingOverlay() {
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black54,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _t.preparingFiles,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: scheme.primaryContainer,
      child: Text(
        statusMessage.isEmpty ? _t.statusReady : statusMessage,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: startReceptor,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(_t.btnBeReceiver),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: startScanning,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  child: Text(_t.btnSearchDevices),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: startWebMode,
              icon: const Icon(Icons.language),
              label: Text(_t.btnWebMode),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.blueGrey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    final accent = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ...foundDevices.map((d) {
          String deviceName = (d.name != null && d.name!.isNotEmpty)
              ? d.name!
              : _t.deviceDefaultName;
          return ListTile(
            leading: Icon(Icons.phonelink_ring, color: accent),
            title: Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_t.deviceSubtitle(d.host ?? "?")),
            onTap: () =>
                triggerSend(d.host!, d.port ?? 4000, peerName: deviceName),
            trailing: Icon(Icons.send, color: accent),
          );
        }),
      ],
    );
  }

  Widget _buildManualIpFallback() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              _t.deviceNotAppearing,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipController,
                    decoration: InputDecoration(
                      hintText: _t.enterReceiverIp,
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (ipController.text.isNotEmpty) {
                      triggerSend(ipController.text.trim(), 4000);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text(task.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: ValueListenableBuilder<TransferStats>(
            // V1: solo se repinta esta barra cuando el medidor emite (con
            // throttle), no toda la pantalla.
            valueListenable: task.stats,
            builder: (context, s, _) {
              final done = task.status == 'done';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: s.progress,
                    color: scheme.primary,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statsLine(task, s, done),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            },
          ),
          trailing:
              (task.status == 'error' &&
                  _lastTargetHost != null &&
                  !isReceptor &&
                  !isWebMode)
              // Solo en contexto de envío: reintentar reenvía al último receptor.
              // En recepción/Modo Web el error es entrante y no hay a dónde reintentar.
              ? IconButton(
                  icon: const Icon(Icons.refresh),
                  color: Colors.amber.shade700,
                  tooltip: _t.retryTooltip,
                  onPressed: () => _retryTask(task),
                )
              : Icon(
                  _getStatusIcon(task.status),
                  color: _getStatusColor(task.status),
                ),
        );
      },
    );
  }

  // U1: arma la línea de detalle (porcentaje • tamaños • velocidad • ETA).
  String _statsLine(TransferTask task, TransferStats s, bool done) {
    final total = task.size > 0 ? task.size : s.total;
    if (done) {
      return "${_t.statsCompleted} • ${humanSize(total)}";
    }
    if (task.status == 'error') return _t.statusTransferError;

    final pct = "${(s.progress * 100).toStringAsFixed(1)}%";
    final parts = <String>[pct];
    if (total > 0) parts.add("${humanSize(s.bytes)} / ${humanSize(total)}");
    final spd = humanSpeed(s.bytesPerSec);
    if (spd.isNotEmpty) parts.add(spd);
    final eta = humanEta(s.eta);
    if (eta.isNotEmpty) parts.add(_t.statsRemaining(eta));
    return parts.join(" • ");
  }

  IconData _getStatusIcon(String s) {
    if (s == 'done') return Icons.check_circle;
    if (s == 'error') return Icons.error;
    return Icons.sync;
  }

  Color _getStatusColor(String s) {
    if (s == 'done') return Colors.green;
    if (s == 'error') return Colors.red;
    // En curso: ámbar, legible tanto en tema claro como oscuro.
    return Colors.amber.shade700;
  }
}
