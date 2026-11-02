import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @statusReady.
  ///
  /// In es, this message translates to:
  /// **'Listo para la acción'**
  String get statusReady;

  /// No description provided for @statusCancelling.
  ///
  /// In es, this message translates to:
  /// **'Cancelando...'**
  String get statusCancelling;

  /// No description provided for @statusFilesLoaded.
  ///
  /// In es, this message translates to:
  /// **'Archivos cargados de la galería. ¡Buscando a quién enviarlos!'**
  String get statusFilesLoaded;

  /// No description provided for @statusSearching.
  ///
  /// In es, this message translates to:
  /// **'Buscando dispositivos Flash...'**
  String get statusSearching;

  /// No description provided for @statusSearchError.
  ///
  /// In es, this message translates to:
  /// **'Error al buscar: {error}'**
  String statusSearchError(Object error);

  /// No description provided for @statusWaitingFiles.
  ///
  /// In es, this message translates to:
  /// **'Esperando archivos...\nTu IP es: {ip}'**
  String statusWaitingFiles(String ip);

  /// No description provided for @statusReceivingFrom.
  ///
  /// In es, this message translates to:
  /// **'Recibiendo de {sender}...'**
  String statusReceivingFrom(String sender);

  /// No description provided for @statusSavedToDownloads.
  ///
  /// In es, this message translates to:
  /// **'¡Guardado en Descargas/Flash!'**
  String get statusSavedToDownloads;

  /// No description provided for @statusSaveFailed.
  ///
  /// In es, this message translates to:
  /// **'Recibido, pero no se pudo guardar: {error}'**
  String statusSaveFailed(Object error);

  /// No description provided for @statusTransferError.
  ///
  /// In es, this message translates to:
  /// **'Error en la transferencia'**
  String get statusTransferError;

  /// No description provided for @statusWebActive.
  ///
  /// In es, this message translates to:
  /// **'Modo Web activo 🌐\nQue el otro equipo abra el navegador web'**
  String get statusWebActive;

  /// No description provided for @statusWebDownloading.
  ///
  /// In es, this message translates to:
  /// **'El otro equipo está descargando {file}...'**
  String statusWebDownloading(String file);

  /// No description provided for @statusDownloadDone.
  ///
  /// In es, this message translates to:
  /// **'¡Descarga finalizada!'**
  String get statusDownloadDone;

  /// No description provided for @statusWebReceiving.
  ///
  /// In es, this message translates to:
  /// **'Recibiendo {file} desde la web...'**
  String statusWebReceiving(String file);

  /// No description provided for @statusWebSaved.
  ///
  /// In es, this message translates to:
  /// **'¡Archivo guardado en Descargas/Flash!'**
  String get statusWebSaved;

  /// No description provided for @statusWebReceiveError.
  ///
  /// In es, this message translates to:
  /// **'Error al recibir el archivo'**
  String get statusWebReceiveError;

  /// No description provided for @statusWebError.
  ///
  /// In es, this message translates to:
  /// **'Error al abrir el Modo Web: {error}'**
  String statusWebError(Object error);

  /// No description provided for @statusPreparingSend.
  ///
  /// In es, this message translates to:
  /// **'Preparando envío...'**
  String get statusPreparingSend;

  /// No description provided for @statusTransfersDone.
  ///
  /// In es, this message translates to:
  /// **'¡Transferencias finalizadas!'**
  String get statusTransfersDone;

  /// No description provided for @preparingFiles.
  ///
  /// In es, this message translates to:
  /// **'Preparando archivos…'**
  String get preparingFiles;

  /// No description provided for @retryTooltip.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retryTooltip;

  /// No description provided for @statusFileReadyWeb.
  ///
  /// In es, this message translates to:
  /// **'Archivo listo. El otro equipo ya puede descargarlo.'**
  String get statusFileReadyWeb;

  /// No description provided for @helpTooltip.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona?'**
  String get helpTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de guardado'**
  String get settingsTooltip;

  /// No description provided for @copyTooltip.
  ///
  /// In es, this message translates to:
  /// **'Copiar enlace'**
  String get copyTooltip;

  /// No description provided for @nameFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Tu nombre (aparecerá en la red)'**
  String get nameFieldLabel;

  /// No description provided for @btnBeReceiver.
  ///
  /// In es, this message translates to:
  /// **'SER RECEPTOR'**
  String get btnBeReceiver;

  /// No description provided for @btnSearchDevices.
  ///
  /// In es, this message translates to:
  /// **'BUSCAR EQUIPOS'**
  String get btnSearchDevices;

  /// No description provided for @btnWebMode.
  ///
  /// In es, this message translates to:
  /// **'MODO WEB (PARA IPHONE / PC)'**
  String get btnWebMode;

  /// No description provided for @btnStopReceiver.
  ///
  /// In es, this message translates to:
  /// **'Detener receptor'**
  String get btnStopReceiver;

  /// No description provided for @btnGoBack.
  ///
  /// In es, this message translates to:
  /// **'Volver atrás'**
  String get btnGoBack;

  /// No description provided for @btnCloseWebServer.
  ///
  /// In es, this message translates to:
  /// **'Cerrar servidor web'**
  String get btnCloseWebServer;

  /// No description provided for @btnSelectFileShare.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar archivo a compartir'**
  String get btnSelectFileShare;

  /// No description provided for @btnChangeFile.
  ///
  /// In es, this message translates to:
  /// **'Cambiar archivo'**
  String get btnChangeFile;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes de Flash'**
  String get settingsTitle;

  /// No description provided for @settingsSaveLabel.
  ///
  /// In es, this message translates to:
  /// **'Los archivos que recibas se guardan en:'**
  String get settingsSaveLabel;

  /// No description provided for @settingsSaveValue.
  ///
  /// In es, this message translates to:
  /// **'Descargas / Flash'**
  String get settingsSaveValue;

  /// No description provided for @settingsSaveHint.
  ///
  /// In es, this message translates to:
  /// **'Podés abrirlos desde la app Archivos o desde la sección Descargas de tu teléfono. No hace falta darle permiso de \"acceso a todos los archivos\".'**
  String get settingsSaveHint;

  /// No description provided for @understood.
  ///
  /// In es, this message translates to:
  /// **'Entendido'**
  String get understood;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo funciona Flash?'**
  String get onboardingTitle;

  /// No description provided for @onboardingIntro.
  ///
  /// In es, this message translates to:
  /// **'Transferí archivos entre equipos de la misma red Wi-Fi, sin internet ni nube. Elegí un modo:'**
  String get onboardingIntro;

  /// No description provided for @onboardingReceiverTitle.
  ///
  /// In es, this message translates to:
  /// **'Ser receptor'**
  String get onboardingReceiverTitle;

  /// No description provided for @onboardingReceiverDesc.
  ///
  /// In es, this message translates to:
  /// **'En el equipo que va a RECIBIR. Queda esperando; lo recibido se guarda en Descargas/Flash.'**
  String get onboardingReceiverDesc;

  /// No description provided for @onboardingSenderTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar equipos'**
  String get onboardingSenderTitle;

  /// No description provided for @onboardingSenderDesc.
  ///
  /// In es, this message translates to:
  /// **'En el equipo que va a ENVIAR (Android). Tocá el receptor que aparezca y elegí los archivos.'**
  String get onboardingSenderDesc;

  /// No description provided for @onboardingWebTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo Web (iPhone / PC)'**
  String get onboardingWebTitle;

  /// No description provided for @onboardingWebDesc.
  ///
  /// In es, this message translates to:
  /// **'Levanta una página local: el otro equipo abre la dirección (o escanea el QR) en su navegador para enviar o descargar.'**
  String get onboardingWebDesc;

  /// No description provided for @onboardingTip.
  ///
  /// In es, this message translates to:
  /// **'Consejo: ambos equipos deben estar en la misma red Wi-Fi.'**
  String get onboardingTip;

  /// No description provided for @onboardingGotIt.
  ///
  /// In es, this message translates to:
  /// **'¡Entendido!'**
  String get onboardingGotIt;

  /// No description provided for @webEnterInBrowser.
  ///
  /// In es, this message translates to:
  /// **'En el navegador del otro equipo escribí:'**
  String get webEnterInBrowser;

  /// No description provided for @webScanQr.
  ///
  /// In es, this message translates to:
  /// **'o escaneá este código con la cámara:'**
  String get webScanQr;

  /// No description provided for @webDownloadQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Querés que el otro equipo descargue un archivo tuyo?'**
  String get webDownloadQuestion;

  /// No description provided for @webSharing.
  ///
  /// In es, this message translates to:
  /// **'Compartiendo: {file}'**
  String webSharing(String file);

  /// No description provided for @addressCopied.
  ///
  /// In es, this message translates to:
  /// **'Dirección copiada'**
  String get addressCopied;

  /// No description provided for @deviceDefaultName.
  ///
  /// In es, this message translates to:
  /// **'Dispositivo Flash'**
  String get deviceDefaultName;

  /// No description provided for @deviceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'IP: {ip} · Tocá para enviar'**
  String deviceSubtitle(String ip);

  /// No description provided for @searchingWifi.
  ///
  /// In es, this message translates to:
  /// **'Buscando en tu red Wi-Fi...'**
  String get searchingWifi;

  /// No description provided for @deviceNotAppearing.
  ///
  /// In es, this message translates to:
  /// **'¿No aparece el dispositivo?'**
  String get deviceNotAppearing;

  /// No description provided for @enterReceiverIp.
  ///
  /// In es, this message translates to:
  /// **'Escribí la IP del receptor'**
  String get enterReceiverIp;

  /// No description provided for @statsCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get statsCompleted;

  /// No description provided for @statsRemaining.
  ///
  /// In es, this message translates to:
  /// **'faltan {eta}'**
  String statsRemaining(String eta);

  /// No description provided for @someone.
  ///
  /// In es, this message translates to:
  /// **'alguien'**
  String get someone;

  /// No description provided for @statusIntegrityFailed.
  ///
  /// In es, this message translates to:
  /// **'El archivo llegó dañado (falló la verificación). No se guardó.'**
  String get statusIntegrityFailed;

  /// No description provided for @settingsChooseFolder.
  ///
  /// In es, this message translates to:
  /// **'Elegir carpeta (tarjeta SD)'**
  String get settingsChooseFolder;

  /// No description provided for @saveLocationChanged.
  ///
  /// In es, this message translates to:
  /// **'Ubicación de guardado actualizada'**
  String get saveLocationChanged;

  /// No description provided for @settingsUseDefault.
  ///
  /// In es, this message translates to:
  /// **'Usar Descargas/Flash'**
  String get settingsUseDefault;

  /// No description provided for @settingsThemeLabel.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsThemeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @webHtmlSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Transferencia directa Android ↔ iPhone'**
  String get webHtmlSubtitle;

  /// No description provided for @webHtmlDownloadHeading.
  ///
  /// In es, this message translates to:
  /// **'Archivo disponible para descargar:'**
  String get webHtmlDownloadHeading;

  /// No description provided for @webHtmlDownloadButton.
  ///
  /// In es, this message translates to:
  /// **'TOCAR PARA DESCARGAR'**
  String get webHtmlDownloadButton;

  /// No description provided for @webHtmlNoFile.
  ///
  /// In es, this message translates to:
  /// **'(El otro equipo no está compartiendo ningún archivo para descargar)'**
  String get webHtmlNoFile;

  /// No description provided for @webHtmlSendHeading.
  ///
  /// In es, this message translates to:
  /// **'Enviar al otro equipo (podés elegir varios)'**
  String get webHtmlSendHeading;

  /// No description provided for @webHtmlSendButton.
  ///
  /// In es, this message translates to:
  /// **'ENVIAR ARCHIVOS'**
  String get webHtmlSendButton;

  /// No description provided for @webHtmlKeepScreen.
  ///
  /// In es, this message translates to:
  /// **'Por favor, mantené la pantalla encendida mientras suben.'**
  String get webHtmlKeepScreen;

  /// No description provided for @webHtmlSelectAlert.
  ///
  /// In es, this message translates to:
  /// **'Seleccioná al menos un archivo primero'**
  String get webHtmlSelectAlert;

  /// No description provided for @webHtmlUploading.
  ///
  /// In es, this message translates to:
  /// **'Subiendo'**
  String get webHtmlUploading;

  /// No description provided for @webHtmlDone.
  ///
  /// In es, this message translates to:
  /// **'¡Finalizado!'**
  String get webHtmlDone;

  /// No description provided for @webHtmlFilesOk.
  ///
  /// In es, this message translates to:
  /// **'archivos subidos con éxito'**
  String get webHtmlFilesOk;

  /// No description provided for @galleryTooltip.
  ///
  /// In es, this message translates to:
  /// **'Galería'**
  String get galleryTooltip;

  /// No description provided for @galleryTitle.
  ///
  /// In es, this message translates to:
  /// **'Galería de Flash'**
  String get galleryTitle;

  /// No description provided for @galleryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay transferencias.\nLo que recibas o envíes aparecerá acá.'**
  String get galleryEmpty;

  /// No description provided for @galleryFilterAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get galleryFilterAll;

  /// No description provided for @galleryFilterReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibidos'**
  String get galleryFilterReceived;

  /// No description provided for @galleryFilterSent.
  ///
  /// In es, this message translates to:
  /// **'Enviados'**
  String get galleryFilterSent;

  /// No description provided for @galleryNoFolder.
  ///
  /// In es, this message translates to:
  /// **'Sin carpeta'**
  String get galleryNoFolder;

  /// No description provided for @galleryReceived.
  ///
  /// In es, this message translates to:
  /// **'Recibido'**
  String get galleryReceived;

  /// No description provided for @gallerySent.
  ///
  /// In es, this message translates to:
  /// **'Enviado'**
  String get gallerySent;

  /// No description provided for @galleryFrom.
  ///
  /// In es, this message translates to:
  /// **'De {peer}'**
  String galleryFrom(String peer);

  /// No description provided for @galleryTo.
  ///
  /// In es, this message translates to:
  /// **'Para {peer}'**
  String galleryTo(String peer);

  /// No description provided for @galleryItemsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} archivos'**
  String galleryItemsCount(int count);

  /// No description provided for @galleryShareFolder.
  ///
  /// In es, this message translates to:
  /// **'Compartir carpeta'**
  String get galleryShareFolder;

  /// No description provided for @galleryInfoSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño'**
  String get galleryInfoSize;

  /// No description provided for @galleryInfoType.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get galleryInfoType;

  /// No description provided for @galleryInfoDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get galleryInfoDate;

  /// No description provided for @galleryInfoDirection.
  ///
  /// In es, this message translates to:
  /// **'Dirección'**
  String get galleryInfoDirection;

  /// No description provided for @galleryInfoPeer.
  ///
  /// In es, this message translates to:
  /// **'Equipo'**
  String get galleryInfoPeer;

  /// No description provided for @galleryInfoFolder.
  ///
  /// In es, this message translates to:
  /// **'Carpeta'**
  String get galleryInfoFolder;

  /// No description provided for @galleryInfoLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get galleryInfoLocation;

  /// No description provided for @galleryActionShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get galleryActionShare;

  /// No description provided for @galleryActionOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get galleryActionOpen;

  /// No description provided for @galleryActionRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar del historial'**
  String get galleryActionRemove;

  /// No description provided for @galleryRemovedMsg.
  ///
  /// In es, this message translates to:
  /// **'Quitado del historial'**
  String get galleryRemovedMsg;

  /// No description provided for @galleryShareError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo compartir: {error}'**
  String galleryShareError(String error);

  /// No description provided for @galleryOpenError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir: {error}'**
  String galleryOpenError(String error);

  /// No description provided for @folderDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la transferencia'**
  String get folderDialogTitle;

  /// No description provided for @folderDialogDesc.
  ///
  /// In es, this message translates to:
  /// **'Se creará una carpeta con este nombre para ordenar los archivos en ambos equipos. Dejalo vacío para no agrupar.'**
  String get folderDialogDesc;

  /// No description provided for @folderDialogHint.
  ///
  /// In es, this message translates to:
  /// **'Ej.: Fotos del viaje'**
  String get folderDialogHint;

  /// No description provided for @folderDialogSkip.
  ///
  /// In es, this message translates to:
  /// **'Sin carpeta'**
  String get folderDialogSkip;

  /// No description provided for @folderDialogOk.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get folderDialogOk;

  /// No description provided for @webFolderLabel.
  ///
  /// In es, this message translates to:
  /// **'Carpeta para lo que recibas (opcional)'**
  String get webFolderLabel;

  /// No description provided for @gallerySelectedCount.
  ///
  /// In es, this message translates to:
  /// **'{count} seleccionados'**
  String gallerySelectedCount(int count);

  /// No description provided for @galleryShareAsDoc.
  ///
  /// In es, this message translates to:
  /// **'Compartir como documento'**
  String get galleryShareAsDoc;

  /// No description provided for @gallerySelect.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar'**
  String get gallerySelect;

  /// No description provided for @galleryRenameFolder.
  ///
  /// In es, this message translates to:
  /// **'Renombrar carpeta'**
  String get galleryRenameFolder;

  /// No description provided for @galleryDeleteSelected.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get galleryDeleteSelected;

  /// No description provided for @galleryDeleteConfirm.
  ///
  /// In es, this message translates to:
  /// **'¿Quitar {count} del historial?'**
  String galleryDeleteConfirm(int count);

  /// No description provided for @galleryFolderCreated.
  ///
  /// In es, this message translates to:
  /// **'Creada el {date}'**
  String galleryFolderCreated(String date);

  /// No description provided for @updatesTitle.
  ///
  /// In es, this message translates to:
  /// **'Actualizaciones'**
  String get updatesTitle;

  /// No description provided for @updatesCheck.
  ///
  /// In es, this message translates to:
  /// **'Buscar actualizaciones'**
  String get updatesCheck;

  /// No description provided for @updatesChecking.
  ///
  /// In es, this message translates to:
  /// **'Buscando actualizaciones…'**
  String get updatesChecking;

  /// No description provided for @updatesUpToDate.
  ///
  /// In es, this message translates to:
  /// **'Ya tenés la última versión'**
  String get updatesUpToDate;

  /// No description provided for @updatesError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo buscar actualizaciones'**
  String get updatesError;

  /// No description provided for @updatesAvailable.
  ///
  /// In es, this message translates to:
  /// **'Nueva versión: {version}'**
  String updatesAvailable(String version);

  /// No description provided for @updatesDownload.
  ///
  /// In es, this message translates to:
  /// **'Descargar e instalar'**
  String get updatesDownload;

  /// No description provided for @updatesDownloading.
  ///
  /// In es, this message translates to:
  /// **'Descargando… {pct}%'**
  String updatesDownloading(String pct);

  /// No description provided for @updatesLater.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get updatesLater;

  /// No description provided for @updaterNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'El actualizador todavía no está configurado'**
  String get updaterNotConfigured;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
