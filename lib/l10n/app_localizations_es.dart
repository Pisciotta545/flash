// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get statusReady => 'Listo para la acción';

  @override
  String get statusCancelling => 'Cancelando...';

  @override
  String get statusFilesLoaded =>
      'Archivos cargados de la galería. ¡Buscando a quién enviarlos!';

  @override
  String get statusSearching => 'Buscando dispositivos Flash...';

  @override
  String statusSearchError(Object error) {
    return 'Error al buscar: $error';
  }

  @override
  String statusWaitingFiles(String ip) {
    return 'Esperando archivos...\nTu IP es: $ip';
  }

  @override
  String statusReceivingFrom(String sender) {
    return 'Recibiendo de $sender...';
  }

  @override
  String get statusSavedToDownloads => '¡Guardado en Descargas/Flash!';

  @override
  String statusSaveFailed(Object error) {
    return 'Recibido, pero no se pudo guardar: $error';
  }

  @override
  String get statusTransferError => 'Error en la transferencia';

  @override
  String get statusWebActive =>
      'Modo Web activo 🌐\nQue el otro equipo abra el navegador web';

  @override
  String statusWebDownloading(String file) {
    return 'El otro equipo está descargando $file...';
  }

  @override
  String get statusDownloadDone => '¡Descarga finalizada!';

  @override
  String statusWebReceiving(String file) {
    return 'Recibiendo $file desde la web...';
  }

  @override
  String get statusWebSaved => '¡Archivo guardado en Descargas/Flash!';

  @override
  String get statusWebReceiveError => 'Error al recibir el archivo';

  @override
  String statusWebError(Object error) {
    return 'Error al abrir el Modo Web: $error';
  }

  @override
  String get statusPreparingSend => 'Preparando envío...';

  @override
  String get statusTransfersDone => '¡Transferencias finalizadas!';

  @override
  String get preparingFiles => 'Preparando archivos…';

  @override
  String get retryTooltip => 'Reintentar';

  @override
  String get statusFileReadyWeb =>
      'Archivo listo. El otro equipo ya puede descargarlo.';

  @override
  String get helpTooltip => '¿Cómo funciona?';

  @override
  String get settingsTooltip => 'Ajustes de guardado';

  @override
  String get copyTooltip => 'Copiar enlace';

  @override
  String get nameFieldLabel => 'Tu nombre (aparecerá en la red)';

  @override
  String get btnBeReceiver => 'SER RECEPTOR';

  @override
  String get btnSearchDevices => 'BUSCAR EQUIPOS';

  @override
  String get btnWebMode => 'MODO WEB (PARA IPHONE / PC)';

  @override
  String get btnStopReceiver => 'Detener receptor';

  @override
  String get btnGoBack => 'Volver atrás';

  @override
  String get btnCloseWebServer => 'Cerrar servidor web';

  @override
  String get btnSelectFileShare => 'Seleccionar archivo a compartir';

  @override
  String get btnChangeFile => 'Cambiar archivo';

  @override
  String get settingsTitle => 'Ajustes de Flash';

  @override
  String get settingsSaveLabel => 'Los archivos que recibas se guardan en:';

  @override
  String get settingsSaveValue => 'Descargas / Flash';

  @override
  String get settingsSaveHint =>
      'Podés abrirlos desde la app Archivos o desde la sección Descargas de tu teléfono. No hace falta darle permiso de \"acceso a todos los archivos\".';

  @override
  String get understood => 'Entendido';

  @override
  String get onboardingTitle => '¿Cómo funciona Flash?';

  @override
  String get onboardingIntro =>
      'Transferí archivos entre equipos de la misma red Wi-Fi, sin internet ni nube. Elegí un modo:';

  @override
  String get onboardingReceiverTitle => 'Ser receptor';

  @override
  String get onboardingReceiverDesc =>
      'En el equipo que va a RECIBIR. Queda esperando; lo recibido se guarda en Descargas/Flash.';

  @override
  String get onboardingSenderTitle => 'Buscar equipos';

  @override
  String get onboardingSenderDesc =>
      'En el equipo que va a ENVIAR (Android). Tocá el receptor que aparezca y elegí los archivos.';

  @override
  String get onboardingWebTitle => 'Modo Web (iPhone / PC)';

  @override
  String get onboardingWebDesc =>
      'Levanta una página local: el otro equipo abre la dirección (o escanea el QR) en su navegador para enviar o descargar.';

  @override
  String get onboardingTip =>
      'Consejo: ambos equipos deben estar en la misma red Wi-Fi.';

  @override
  String get onboardingGotIt => '¡Entendido!';

  @override
  String get webEnterInBrowser => 'En el navegador del otro equipo escribí:';

  @override
  String get webScanQr => 'o escaneá este código con la cámara:';

  @override
  String get webDownloadQuestion =>
      '¿Querés que el otro equipo descargue un archivo tuyo?';

  @override
  String webSharing(String file) {
    return 'Compartiendo: $file';
  }

  @override
  String get addressCopied => 'Dirección copiada';

  @override
  String get deviceDefaultName => 'Dispositivo Flash';

  @override
  String deviceSubtitle(String ip) {
    return 'IP: $ip · Tocá para enviar';
  }

  @override
  String get searchingWifi => 'Buscando en tu red Wi-Fi...';

  @override
  String get deviceNotAppearing => '¿No aparece el dispositivo?';

  @override
  String get enterReceiverIp => 'Escribí la IP del receptor';

  @override
  String get statsCompleted => 'Completado';

  @override
  String statsRemaining(String eta) {
    return 'faltan $eta';
  }

  @override
  String get someone => 'alguien';

  @override
  String get statusIntegrityFailed =>
      'El archivo llegó dañado (falló la verificación). No se guardó.';

  @override
  String get settingsChooseFolder => 'Elegir carpeta (tarjeta SD)';

  @override
  String get saveLocationChanged => 'Ubicación de guardado actualizada';

  @override
  String get settingsUseDefault => 'Usar Descargas/Flash';

  @override
  String get settingsThemeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get webHtmlSubtitle => 'Transferencia directa Android ↔ iPhone';

  @override
  String get webHtmlDownloadHeading => 'Archivo disponible para descargar:';

  @override
  String get webHtmlDownloadButton => 'TOCAR PARA DESCARGAR';

  @override
  String get webHtmlNoFile =>
      '(El otro equipo no está compartiendo ningún archivo para descargar)';

  @override
  String get webHtmlSendHeading =>
      'Enviar al otro equipo (podés elegir varios)';

  @override
  String get webHtmlSendButton => 'ENVIAR ARCHIVOS';

  @override
  String get webHtmlKeepScreen =>
      'Por favor, mantené la pantalla encendida mientras suben.';

  @override
  String get webHtmlSelectAlert => 'Seleccioná al menos un archivo primero';

  @override
  String get webHtmlUploading => 'Subiendo';

  @override
  String get webHtmlDone => '¡Finalizado!';

  @override
  String get webHtmlFilesOk => 'archivos subidos con éxito';

  @override
  String get galleryTooltip => 'Galería';

  @override
  String get galleryTitle => 'Galería de Flash';

  @override
  String get galleryEmpty =>
      'Todavía no hay transferencias.\nLo que recibas o envíes aparecerá acá.';

  @override
  String get galleryFilterAll => 'Todo';

  @override
  String get galleryFilterReceived => 'Recibidos';

  @override
  String get galleryFilterSent => 'Enviados';

  @override
  String get galleryNoFolder => 'Sin carpeta';

  @override
  String get galleryReceived => 'Recibido';

  @override
  String get gallerySent => 'Enviado';

  @override
  String galleryFrom(String peer) {
    return 'De $peer';
  }

  @override
  String galleryTo(String peer) {
    return 'Para $peer';
  }

  @override
  String galleryItemsCount(int count) {
    return '$count archivos';
  }

  @override
  String get galleryShareFolder => 'Compartir carpeta';

  @override
  String get galleryInfoSize => 'Tamaño';

  @override
  String get galleryInfoType => 'Tipo';

  @override
  String get galleryInfoDate => 'Fecha';

  @override
  String get galleryInfoDirection => 'Dirección';

  @override
  String get galleryInfoPeer => 'Equipo';

  @override
  String get galleryInfoFolder => 'Carpeta';

  @override
  String get galleryInfoLocation => 'Ubicación';

  @override
  String get galleryActionShare => 'Compartir';

  @override
  String get galleryActionOpen => 'Abrir';

  @override
  String get galleryActionRemove => 'Quitar del historial';

  @override
  String get galleryRemovedMsg => 'Quitado del historial';

  @override
  String galleryShareError(String error) {
    return 'No se pudo compartir: $error';
  }

  @override
  String galleryOpenError(String error) {
    return 'No se pudo abrir: $error';
  }

  @override
  String get folderDialogTitle => 'Nombre de la transferencia';

  @override
  String get folderDialogDesc =>
      'Se creará una carpeta con este nombre para ordenar los archivos en ambos equipos. Dejalo vacío para no agrupar.';

  @override
  String get folderDialogHint => 'Ej.: Fotos del viaje';

  @override
  String get folderDialogSkip => 'Sin carpeta';

  @override
  String get folderDialogOk => 'Continuar';

  @override
  String get webFolderLabel => 'Carpeta para lo que recibas (opcional)';

  @override
  String gallerySelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get galleryShareAsDoc => 'Compartir como documento';

  @override
  String get gallerySelect => 'Seleccionar';

  @override
  String get galleryRenameFolder => 'Renombrar carpeta';

  @override
  String get galleryDeleteSelected => 'Eliminar';

  @override
  String galleryDeleteConfirm(int count) {
    return '¿Quitar $count del historial?';
  }

  @override
  String galleryFolderCreated(String date) {
    return 'Creada el $date';
  }

  @override
  String get updatesTitle => 'Actualizaciones';

  @override
  String get updatesCheck => 'Buscar actualizaciones';

  @override
  String get updatesChecking => 'Buscando actualizaciones…';

  @override
  String get updatesUpToDate => 'Ya tenés la última versión';

  @override
  String get updatesError => 'No se pudo buscar actualizaciones';

  @override
  String updatesAvailable(String version) {
    return 'Nueva versión: $version';
  }

  @override
  String get updatesDownload => 'Descargar e instalar';

  @override
  String updatesDownloading(String pct) {
    return 'Descargando… $pct%';
  }

  @override
  String get updatesLater => 'Ahora no';

  @override
  String get updaterNotConfigured =>
      'El actualizador todavía no está configurado';
}
