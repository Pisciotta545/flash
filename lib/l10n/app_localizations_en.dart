// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get statusReady => 'Ready to go';

  @override
  String get statusCancelling => 'Cancelling...';

  @override
  String get statusFilesLoaded =>
      'Files loaded from the gallery. Looking for someone to send them to!';

  @override
  String get statusSearching => 'Searching for Flash devices...';

  @override
  String statusSearchError(Object error) {
    return 'Search error: $error';
  }

  @override
  String statusWaitingFiles(String ip) {
    return 'Waiting for files...\nYour IP is: $ip';
  }

  @override
  String statusReceivingFrom(String sender) {
    return 'Receiving from $sender...';
  }

  @override
  String get statusSavedToDownloads => 'Saved to Downloads/Flash!';

  @override
  String statusSaveFailed(Object error) {
    return 'Received, but could not be saved: $error';
  }

  @override
  String get statusTransferError => 'Transfer error';

  @override
  String get statusWebActive =>
      'Web Mode active 🌐\nHave the other device open its web browser';

  @override
  String statusWebDownloading(String file) {
    return 'The other device is downloading $file...';
  }

  @override
  String get statusDownloadDone => 'Download finished!';

  @override
  String statusWebReceiving(String file) {
    return 'Receiving $file from the web...';
  }

  @override
  String get statusWebSaved => 'File saved to Downloads/Flash!';

  @override
  String get statusWebReceiveError => 'Error receiving the file';

  @override
  String statusWebError(Object error) {
    return 'Error starting Web Mode: $error';
  }

  @override
  String get statusPreparingSend => 'Preparing to send...';

  @override
  String get statusTransfersDone => 'Transfers finished!';

  @override
  String get preparingFiles => 'Preparing files…';

  @override
  String get retryTooltip => 'Retry';

  @override
  String get statusFileReadyWeb =>
      'File ready. The other device can download it now.';

  @override
  String get helpTooltip => 'How does it work?';

  @override
  String get settingsTooltip => 'Save settings';

  @override
  String get copyTooltip => 'Copy link';

  @override
  String get nameFieldLabel => 'Your name (shown on the network)';

  @override
  String get btnBeReceiver => 'BE RECEIVER';

  @override
  String get btnSearchDevices => 'FIND DEVICES';

  @override
  String get btnWebMode => 'WEB MODE (FOR IPHONE / PC)';

  @override
  String get btnStopReceiver => 'Stop receiver';

  @override
  String get btnGoBack => 'Go back';

  @override
  String get btnCloseWebServer => 'Close web server';

  @override
  String get btnSelectFileShare => 'Select a file to share';

  @override
  String get btnChangeFile => 'Change file';

  @override
  String get settingsTitle => 'Flash settings';

  @override
  String get settingsSaveLabel => 'The files you receive are saved in:';

  @override
  String get settingsSaveValue => 'Downloads / Flash';

  @override
  String get settingsSaveHint =>
      'You can open them from the Files app or the Downloads section of your phone. No \"all files access\" permission is needed.';

  @override
  String get understood => 'Got it';

  @override
  String get onboardingTitle => 'How does Flash work?';

  @override
  String get onboardingIntro =>
      'Transfer files between devices on the same Wi-Fi network, with no internet or cloud. Pick a mode:';

  @override
  String get onboardingReceiverTitle => 'Be receiver';

  @override
  String get onboardingReceiverDesc =>
      'On the device that will RECEIVE. It waits; received files are saved to Downloads/Flash.';

  @override
  String get onboardingSenderTitle => 'Find devices';

  @override
  String get onboardingSenderDesc =>
      'On the device that will SEND (Android). Tap the receiver that appears and choose the files.';

  @override
  String get onboardingWebTitle => 'Web Mode (iPhone / PC)';

  @override
  String get onboardingWebDesc =>
      'Starts a local page: the other device opens the address (or scans the QR) in its browser to send or download.';

  @override
  String get onboardingTip =>
      'Tip: both devices must be on the same Wi-Fi network.';

  @override
  String get onboardingGotIt => 'Got it!';

  @override
  String get webEnterInBrowser => 'In the other device\'s browser, type:';

  @override
  String get webScanQr => 'or scan this code with the camera:';

  @override
  String get webDownloadQuestion =>
      'Want the other device to download a file of yours?';

  @override
  String webSharing(String file) {
    return 'Sharing: $file';
  }

  @override
  String get addressCopied => 'Address copied';

  @override
  String get deviceDefaultName => 'Flash device';

  @override
  String deviceSubtitle(String ip) {
    return 'IP: $ip · Tap to send';
  }

  @override
  String get searchingWifi => 'Searching your Wi-Fi network...';

  @override
  String get deviceNotAppearing => 'Device not showing up?';

  @override
  String get enterReceiverIp => 'Type the receiver\'s IP';

  @override
  String get statsCompleted => 'Completed';

  @override
  String statsRemaining(String eta) {
    return '$eta left';
  }

  @override
  String get someone => 'someone';

  @override
  String get statusIntegrityFailed =>
      'The file arrived corrupted (integrity check failed). It was not saved.';

  @override
  String get settingsChooseFolder => 'Choose folder (SD card)';

  @override
  String get saveLocationChanged => 'Save location updated';

  @override
  String get settingsUseDefault => 'Use Downloads/Flash';

  @override
  String get settingsThemeLabel => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get webHtmlSubtitle => 'Direct transfer Android ↔ iPhone';

  @override
  String get webHtmlDownloadHeading => 'File available to download:';

  @override
  String get webHtmlDownloadButton => 'TAP TO DOWNLOAD';

  @override
  String get webHtmlNoFile =>
      '(The other device is not sharing any file to download)';

  @override
  String get webHtmlSendHeading =>
      'Send to the other device (you can pick several)';

  @override
  String get webHtmlSendButton => 'SEND FILES';

  @override
  String get webHtmlKeepScreen =>
      'Please keep the screen on while they upload.';

  @override
  String get webHtmlSelectAlert => 'Select at least one file first';

  @override
  String get webHtmlUploading => 'Uploading';

  @override
  String get webHtmlDone => 'Finished!';

  @override
  String get webHtmlFilesOk => 'files uploaded successfully';

  @override
  String get galleryTooltip => 'Gallery';

  @override
  String get galleryTitle => 'Flash Gallery';

  @override
  String get galleryEmpty =>
      'No transfers yet.\nWhat you receive or send will show up here.';

  @override
  String get galleryFilterAll => 'All';

  @override
  String get galleryFilterReceived => 'Received';

  @override
  String get galleryFilterSent => 'Sent';

  @override
  String get galleryNoFolder => 'No folder';

  @override
  String get galleryReceived => 'Received';

  @override
  String get gallerySent => 'Sent';

  @override
  String galleryFrom(String peer) {
    return 'From $peer';
  }

  @override
  String galleryTo(String peer) {
    return 'To $peer';
  }

  @override
  String galleryItemsCount(int count) {
    return '$count files';
  }

  @override
  String get galleryShareFolder => 'Share folder';

  @override
  String get galleryInfoSize => 'Size';

  @override
  String get galleryInfoType => 'Type';

  @override
  String get galleryInfoDate => 'Date';

  @override
  String get galleryInfoDirection => 'Direction';

  @override
  String get galleryInfoPeer => 'Device';

  @override
  String get galleryInfoFolder => 'Folder';

  @override
  String get galleryInfoLocation => 'Location';

  @override
  String get galleryActionShare => 'Share';

  @override
  String get galleryActionOpen => 'Open';

  @override
  String get galleryActionRemove => 'Remove from history';

  @override
  String get galleryRemovedMsg => 'Removed from history';

  @override
  String galleryShareError(String error) {
    return 'Couldn\'t share: $error';
  }

  @override
  String galleryOpenError(String error) {
    return 'Couldn\'t open: $error';
  }

  @override
  String get folderDialogTitle => 'Transfer name';

  @override
  String get folderDialogDesc =>
      'A folder with this name will be created to organize the files on both devices. Leave it empty to not group them.';

  @override
  String get folderDialogHint => 'e.g. Trip photos';

  @override
  String get folderDialogSkip => 'No folder';

  @override
  String get folderDialogOk => 'Continue';

  @override
  String get webFolderLabel => 'Folder for what you receive (optional)';

  @override
  String gallerySelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get galleryShareAsDoc => 'Share as document';

  @override
  String get gallerySelect => 'Select';

  @override
  String get galleryRenameFolder => 'Rename folder';

  @override
  String get galleryDeleteSelected => 'Delete';

  @override
  String galleryDeleteConfirm(int count) {
    return 'Remove $count from history?';
  }

  @override
  String galleryFolderCreated(String date) {
    return 'Created on $date';
  }

  @override
  String get updatesTitle => 'Updates';

  @override
  String get updatesCheck => 'Check for updates';

  @override
  String get updatesChecking => 'Checking for updates…';

  @override
  String get updatesUpToDate => 'You\'re on the latest version';

  @override
  String get updatesError => 'Couldn\'t check for updates';

  @override
  String updatesAvailable(String version) {
    return 'New version: $version';
  }

  @override
  String get updatesDownload => 'Download and install';

  @override
  String updatesDownloading(String pct) {
    return 'Downloading… $pct%';
  }

  @override
  String get updatesLater => 'Not now';

  @override
  String get updaterNotConfigured => 'The updater isn\'t configured yet';
}
