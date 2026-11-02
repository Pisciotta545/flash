import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';

/// G4 (galería): canal nativo compartido con el guardado. Acá se usa para
/// compartir y abrir archivos desde la galería.
const MethodChannel _galleryChannel = MethodChannel('com.velocidad.flash/storage');

/// Normaliza un nombre de carpeta (sin separadores, `..` ni control, largo acotado).
String sanitizeFolder(String raw) {
  var n = raw
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '')
      .replaceAll('..', '')
      .trim();
  if (n.length > 60) n = n.substring(0, 60).trim();
  return n;
}

/// Una entrada del historial/galería de Flash: un archivo que la app recibió o
/// envió. Se persiste como JSON en el almacenamiento interno de la app.
class GalleryEntry {
  final String id;
  final String name;
  final int size;
  final String mime;
  final int timestamp; // epoch ms
  final String direction; // 'received' | 'sent'
  final String peer; // de quién (recibido) o a quién (enviado)
  final String folder; // nombre de la transferencia ("" = sin carpeta)
  final String location; // ubicación legible
  final String uri; // content:// o ruta para abrir/compartir

  const GalleryEntry({
    required this.id,
    required this.name,
    required this.size,
    required this.mime,
    required this.timestamp,
    required this.direction,
    required this.peer,
    required this.folder,
    required this.location,
    required this.uri,
  });

  bool get isReceived => direction == 'received';

  GalleryEntry copyWith({String? folder}) => GalleryEntry(
    id: id,
    name: name,
    size: size,
    mime: mime,
    timestamp: timestamp,
    direction: direction,
    peer: peer,
    folder: folder ?? this.folder,
    location: location,
    uri: uri,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'mime': mime,
    'timestamp': timestamp,
    'direction': direction,
    'peer': peer,
    'folder': folder,
    'location': location,
    'uri': uri,
  };

  static GalleryEntry fromJson(Map<String, dynamic> j) => GalleryEntry(
    id: j['id'] as String? ?? '',
    name: j['name'] as String? ?? '',
    size: (j['size'] as num?)?.toInt() ?? 0,
    mime: j['mime'] as String? ?? 'application/octet-stream',
    timestamp: (j['timestamp'] as num?)?.toInt() ?? 0,
    direction: j['direction'] as String? ?? 'received',
    peer: j['peer'] as String? ?? '',
    folder: j['folder'] as String? ?? '',
    location: j['location'] as String? ?? '',
    uri: j['uri'] as String? ?? '',
  );
}

/// Índice persistente de la galería. Singleton con escrituras serializadas para
/// que las llamadas desde los callbacks de sockets no se pisen entre sí.
class GalleryStore {
  GalleryStore._();
  static final GalleryStore instance = GalleryStore._();

  /// Se incrementa en cada cambio para que la UI se reconstruya.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  List<GalleryEntry> _entries = [];
  bool _loaded = false;
  File? _file;
  Future<void> _writeChain = Future.value();

  Future<File> _indexFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/flash_gallery.json');
    return _file!;
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final f = await _indexFile();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final list = jsonDecode(raw) as List<dynamic>;
        _entries = list
            .map((e) => GalleryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      _entries = [];
    }
    _loaded = true;
  }

  List<GalleryEntry> get entries => List.unmodifiable(_entries);

  GalleryEntry? byId(String id) {
    for (final e in _entries) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Fecha de creación de una carpeta = timestamp del archivo más antiguo que
  /// contiene (cuando se usó ese nombre por primera vez). null si está vacía.
  int? folderCreatedAt(String folder) {
    int? min;
    for (final e in _entries) {
      if (e.folder == folder) {
        if (min == null || e.timestamp < min) min = e.timestamp;
      }
    }
    return min;
  }

  Future<void> _persist() async {
    _writeChain = _writeChain.then((_) async {
      try {
        final f = await _indexFile();
        await f.writeAsString(jsonEncode(_entries.map((e) => e.toJson()).toList()));
      } catch (_) {}
    });
    return _writeChain;
  }

  Future<void> add(GalleryEntry entry) async {
    await load();
    _entries.insert(0, entry);
    revision.value++;
    await _persist();
  }

  Future<void> remove(String id) async {
    await load();
    _entries.removeWhere((e) => e.id == id);
    revision.value++;
    await _persist();
  }

  Future<void> removeMany(Set<String> ids) async {
    await load();
    _entries.removeWhere((e) => ids.contains(e.id));
    revision.value++;
    await _persist();
  }

  /// Renombra una carpeta en todas sus entradas (se refleja también en la
  /// galería local; el nombre nuevo no cambia dónde ya están guardados los
  /// archivos en el disco, solo cómo se agrupan acá).
  Future<void> renameFolder(String oldName, String newName) async {
    await load();
    final clean = sanitizeFolder(newName);
    for (int i = 0; i < _entries.length; i++) {
      if (_entries[i].folder == oldName) {
        _entries[i] = _entries[i].copyWith(folder: clean);
      }
    }
    revision.value++;
    await _persist();
  }

  /// Comparte uno o varios archivos. [asDocument] fuerza el envío sin comprimir
  /// (útil para mandar calidad original por WhatsApp).
  Future<void> share(List<GalleryEntry> items, {bool asDocument = false}) async {
    if (items.isEmpty) return;
    final mime = items.length == 1 ? items.first.mime : '*/*';
    await _galleryChannel.invokeMethod('shareFiles', {
      'uris': items.map((e) => e.uri).toList(),
      // Nombre real (con extensión) de cada archivo: MediaStore a veces no la
      // devuelve, y sin extensión CapCut no lo reconoce y WhatsApp lo nombra .bin.
      'names': items.map((e) => e.name).toList(),
      'mime': mime,
      'asDocument': asDocument,
    });
  }

  Future<void> open(GalleryEntry item) async {
    await _galleryChannel.invokeMethod('openFile', {
      'uri': item.uri,
      'mime': item.mime,
    });
  }
}

/// Deriva un tipo MIME aproximado a partir de la extensión del nombre.
String mimeFromName(String name) {
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return 'application/octet-stream';
  final ext = name.substring(dot + 1).toLowerCase();
  const map = {
    'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
    'gif': 'image/gif', 'webp': 'image/webp', 'bmp': 'image/bmp',
    'heic': 'image/heic', 'svg': 'image/svg+xml',
    'mp4': 'video/mp4', 'mkv': 'video/x-matroska', 'mov': 'video/quicktime',
    'avi': 'video/x-msvideo', '3gp': 'video/3gpp', 'webm': 'video/webm',
    'mp3': 'audio/mpeg', 'wav': 'audio/wav', 'ogg': 'audio/ogg',
    'm4a': 'audio/mp4', 'flac': 'audio/flac', 'aac': 'audio/aac',
    'pdf': 'application/pdf', 'txt': 'text/plain', 'csv': 'text/csv',
    'doc': 'application/msword',
    'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'zip': 'application/zip', 'rar': 'application/vnd.rar',
    '7z': 'application/x-7z-compressed', 'apk': 'application/vnd.android.package-archive',
  };
  return map[ext] ?? 'application/octet-stream';
}

IconData iconForMime(String mime) {
  if (mime.startsWith('image/')) return Icons.image;
  if (mime.startsWith('video/')) return Icons.videocam;
  if (mime.startsWith('audio/')) return Icons.audiotrack;
  if (mime == 'application/pdf') return Icons.picture_as_pdf;
  if (mime.startsWith('text/')) return Icons.description;
  if (mime.contains('zip') || mime.contains('rar') || mime.contains('7z') ||
      mime.contains('compressed')) {
    return Icons.folder_zip;
  }
  if (mime.contains('android.package')) return Icons.android;
  return Icons.insert_drive_file;
}

String _humanSizeLocal(int bytes) {
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

String _formatDate(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// Pantalla de la galería.
class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

enum _Filter { all, received, sent }

class _GalleryPageState extends State<GalleryPage> {
  _Filter _filter = _Filter.all;
  final Set<String> _selected = {}; // ids seleccionados
  final Set<String> _collapsed = {}; // carpetas plegadas

  bool get _selecting => _selected.isNotEmpty;

  @override
  void initState() {
    super.initState();
    GalleryStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  AppLocalizations get _t => AppLocalizations.of(context);

  List<GalleryEntry> get _visible {
    final all = GalleryStore.instance.entries;
    switch (_filter) {
      case _Filter.received:
        return all.where((e) => e.isReceived).toList();
      case _Filter.sent:
        return all.where((e) => !e.isReceived).toList();
      case _Filter.all:
        return all;
    }
  }

  Map<String, List<GalleryEntry>> get _grouped {
    final map = <String, List<GalleryEntry>>{};
    for (final e in _visible) {
      map.putIfAbsent(e.folder, () => []).add(e);
    }
    return map;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
    });
  }

  void _clearSelection() => setState(() => _selected.clear());

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting ? _selectionAppBar() : _normalAppBar(),
        body: ValueListenableBuilder<int>(
          valueListenable: GalleryStore.instance.revision,
          builder: (context, _, _) {
            final groups = _grouped;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<_Filter>(
                    segments: [
                      ButtonSegment(value: _Filter.all, label: Text(_t.galleryFilterAll)),
                      ButtonSegment(
                          value: _Filter.received, label: Text(_t.galleryFilterReceived)),
                      ButtonSegment(value: _Filter.sent, label: Text(_t.galleryFilterSent)),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                ),
                Expanded(
                  child: groups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.photo_library_outlined,
                                    size: 64, color: scheme.outline),
                                const SizedBox(height: 16),
                                Text(
                                  _t.galleryEmpty,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          children: [
                            for (final entry in groups.entries)
                              _buildFolderSection(entry.key, entry.value),
                            const SizedBox(height: 24),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _normalAppBar() => AppBar(
        title: Text(_t.galleryTitle),
        centerTitle: true,
      );

  AppBar _selectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text(_t.gallerySelectedCount(_selected.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: _t.galleryActionShare,
          onPressed: () => _shareSelected(asDocument: false),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: _t.galleryDeleteSelected,
          onPressed: _deleteSelected,
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'doc') _shareSelected(asDocument: true);
          },
          itemBuilder: (c) => [
            PopupMenuItem(value: 'doc', child: Text(_t.galleryShareAsDoc)),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderSection(String folder, List<GalleryEntry> items) {
    final scheme = Theme.of(context).colorScheme;
    final title = folder.isEmpty ? _t.galleryNoFolder : folder;
    final collapsed = _collapsed.contains(folder);
    final createdAt =
        folder.isEmpty ? null : GalleryStore.instance.folderCreatedAt(folder);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            if (!_collapsed.remove(folder)) _collapsed.add(folder);
          }),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
            child: Row(
              children: [
                Icon(collapsed ? Icons.chevron_right : Icons.expand_more,
                    color: scheme.onSurfaceVariant),
                const SizedBox(width: 2),
                Icon(folder.isEmpty ? Icons.inbox : Icons.folder, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (createdAt != null)
                        Text(
                          _t.galleryFolderCreated(_formatDate(createdAt)),
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                Text(
                  _t.galleryItemsCount(items.length),
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'share') _share(items);
                    if (v == 'doc') _share(items, asDocument: true);
                    if (v == 'rename' && folder.isNotEmpty) _renameFolder(folder);
                    if (v == 'select') _selectFolder(items);
                  },
                  itemBuilder: (c) => [
                    PopupMenuItem(value: 'share', child: Text(_t.galleryShareFolder)),
                    PopupMenuItem(value: 'doc', child: Text(_t.galleryShareAsDoc)),
                    PopupMenuItem(value: 'select', child: Text(_t.gallerySelect)),
                    if (folder.isNotEmpty)
                      PopupMenuItem(value: 'rename', child: Text(_t.galleryRenameFolder)),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!collapsed) ...items.map(_buildTile),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildTile(GalleryEntry e) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected.contains(e.id);
    return ListTile(
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.4),
      leading: _selecting
          ? Checkbox(
              value: selected,
              onChanged: (_) => _toggleSelect(e.id),
            )
          : CircleAvatar(
              backgroundColor: scheme.surfaceContainerHighest,
              child: Icon(iconForMime(e.mime), color: scheme.primary),
            ),
      title: Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_humanSizeLocal(e.size)} • ${_formatDate(e.timestamp)}\n'
        '${e.isReceived ? _t.galleryFrom(e.peer) : _t.galleryTo(e.peer)}',
        maxLines: 2,
      ),
      isThreeLine: true,
      trailing: _selecting
          ? null
          : Icon(
              e.isReceived ? Icons.south_west : Icons.north_east,
              color: e.isReceived ? Colors.green : scheme.primary,
              size: 18,
            ),
      onTap: () => _selecting ? _toggleSelect(e.id) : _showDetail(e),
      onLongPress: () => _toggleSelect(e.id),
    );
  }

  void _selectFolder(List<GalleryEntry> items) {
    setState(() => _selected.addAll(items.map((e) => e.id)));
  }

  Future<void> _renameFolder(String folder) async {
    final ctrl = TextEditingController(text: folder);
    final result = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(_t.galleryRenameFolder),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: _t.folderDialogHint,
            prefixIcon: const Icon(Icons.folder),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(c, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(_t.understood)),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: Text(_t.folderDialogOk),
          ),
        ],
      ),
    );
    if (result == null) return;
    final clean = sanitizeFolder(result);
    if (clean.isEmpty || clean == folder) return;
    await GalleryStore.instance.renameFolder(folder, clean);
  }

  void _showDetail(GalleryEntry e) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(iconForMime(e.mime), color: scheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _info(_t.galleryInfoSize, _humanSizeLocal(e.size)),
                  _info(_t.galleryInfoType, e.mime),
                  _info(_t.galleryInfoDate, _formatDate(e.timestamp)),
                  _info(
                    _t.galleryInfoDirection,
                    e.isReceived ? _t.galleryReceived : _t.gallerySent,
                  ),
                  _info(_t.galleryInfoPeer, e.peer.isEmpty ? '—' : e.peer),
                  _info(_t.galleryInfoFolder,
                      e.folder.isEmpty ? _t.galleryNoFolder : e.folder),
                  _info(_t.galleryInfoLocation, e.location.isEmpty ? e.uri : e.location),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.share),
                          label: Text(_t.galleryActionShare),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _share([e]);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: Text(_t.galleryActionOpen),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _open(e);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.description_outlined),
                    label: Text(_t.galleryShareAsDoc),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _share([e], asDocument: true);
                    },
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      _t.galleryActionRemove,
                      style: const TextStyle(color: Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      GalleryStore.instance.remove(e.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_t.galleryRemovedMsg)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _info(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  List<GalleryEntry> _selectedEntries() {
    final out = <GalleryEntry>[];
    for (final id in _selected) {
      final e = GalleryStore.instance.byId(id);
      if (e != null) out.add(e);
    }
    return out;
  }

  Future<void> _shareSelected({required bool asDocument}) async {
    final items = _selectedEntries();
    await _share(items, asDocument: asDocument);
  }

  Future<void> _deleteSelected() async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = Set<String>.from(_selected);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(_t.galleryDeleteConfirm(ids.length)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(_t.understood)),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(_t.galleryDeleteSelected),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await GalleryStore.instance.removeMany(ids);
    _clearSelection();
    messenger.showSnackBar(SnackBar(content: Text(_t.galleryRemovedMsg)));
  }

  Future<void> _share(List<GalleryEntry> items, {bool asDocument = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await GalleryStore.instance.share(items, asDocument: asDocument);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(_t.galleryShareError(e.toString()))),
      );
    }
  }

  Future<void> _open(GalleryEntry e) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await GalleryStore.instance.open(e);
    } catch (err) {
      messenger.showSnackBar(
        SnackBar(content: Text(_t.galleryOpenError(err.toString()))),
      );
    }
  }
}
