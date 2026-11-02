// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get statusReady => 'Pronto para a ação';

  @override
  String get statusCancelling => 'Cancelando...';

  @override
  String get statusFilesLoaded =>
      'Arquivos carregados da galeria. Procurando para quem enviá-los!';

  @override
  String get statusSearching => 'Procurando dispositivos Flash...';

  @override
  String statusSearchError(Object error) {
    return 'Erro ao buscar: $error';
  }

  @override
  String statusWaitingFiles(String ip) {
    return 'Aguardando arquivos...\nSeu IP é: $ip';
  }

  @override
  String statusReceivingFrom(String sender) {
    return 'Recebendo de $sender...';
  }

  @override
  String get statusSavedToDownloads => 'Salvo em Downloads/Flash!';

  @override
  String statusSaveFailed(Object error) {
    return 'Recebido, mas não foi possível salvar: $error';
  }

  @override
  String get statusTransferError => 'Erro na transferência';

  @override
  String get statusWebActive =>
      'Modo Web ativo 🌐\nPeça para o outro aparelho abrir o navegador';

  @override
  String statusWebDownloading(String file) {
    return 'O outro aparelho está baixando $file...';
  }

  @override
  String get statusDownloadDone => 'Download concluído!';

  @override
  String statusWebReceiving(String file) {
    return 'Recebendo $file pela web...';
  }

  @override
  String get statusWebSaved => 'Arquivo salvo em Downloads/Flash!';

  @override
  String get statusWebReceiveError => 'Erro ao receber o arquivo';

  @override
  String statusWebError(Object error) {
    return 'Erro ao abrir o Modo Web: $error';
  }

  @override
  String get statusPreparingSend => 'Preparando o envio...';

  @override
  String get statusTransfersDone => 'Transferências concluídas!';

  @override
  String get preparingFiles => 'Preparando arquivos…';

  @override
  String get retryTooltip => 'Tentar de novo';

  @override
  String get statusFileReadyWeb =>
      'Arquivo pronto. O outro aparelho já pode baixá-lo.';

  @override
  String get helpTooltip => 'Como funciona?';

  @override
  String get settingsTooltip => 'Configurações de salvamento';

  @override
  String get copyTooltip => 'Copiar link';

  @override
  String get nameFieldLabel => 'Seu nome (aparece na rede)';

  @override
  String get btnBeReceiver => 'SER RECEPTOR';

  @override
  String get btnSearchDevices => 'BUSCAR APARELHOS';

  @override
  String get btnWebMode => 'MODO WEB (PARA IPHONE / PC)';

  @override
  String get btnStopReceiver => 'Parar receptor';

  @override
  String get btnGoBack => 'Voltar';

  @override
  String get btnCloseWebServer => 'Fechar servidor web';

  @override
  String get btnSelectFileShare => 'Selecionar arquivo para compartilhar';

  @override
  String get btnChangeFile => 'Trocar arquivo';

  @override
  String get settingsTitle => 'Configurações do Flash';

  @override
  String get settingsSaveLabel => 'Os arquivos que você recebe são salvos em:';

  @override
  String get settingsSaveValue => 'Downloads / Flash';

  @override
  String get settingsSaveHint =>
      'Você pode abri-los pelo app Arquivos ou na seção Downloads do seu telefone. Não é preciso a permissão de \"acesso a todos os arquivos\".';

  @override
  String get understood => 'Entendi';

  @override
  String get onboardingTitle => 'Como o Flash funciona?';

  @override
  String get onboardingIntro =>
      'Transfira arquivos entre aparelhos na mesma rede Wi-Fi, sem internet nem nuvem. Escolha um modo:';

  @override
  String get onboardingReceiverTitle => 'Ser receptor';

  @override
  String get onboardingReceiverDesc =>
      'No aparelho que vai RECEBER. Ele fica aguardando; o recebido é salvo em Downloads/Flash.';

  @override
  String get onboardingSenderTitle => 'Buscar aparelhos';

  @override
  String get onboardingSenderDesc =>
      'No aparelho que vai ENVIAR (Android). Toque no receptor que aparecer e escolha os arquivos.';

  @override
  String get onboardingWebTitle => 'Modo Web (iPhone / PC)';

  @override
  String get onboardingWebDesc =>
      'Cria uma página local: o outro aparelho abre o endereço (ou escaneia o QR) no navegador para enviar ou baixar.';

  @override
  String get onboardingTip =>
      'Dica: os dois aparelhos devem estar na mesma rede Wi-Fi.';

  @override
  String get onboardingGotIt => 'Entendi!';

  @override
  String get webEnterInBrowser => 'No navegador do outro aparelho, digite:';

  @override
  String get webScanQr => 'ou escaneie este código com a câmera:';

  @override
  String get webDownloadQuestion =>
      'Quer que o outro aparelho baixe um arquivo seu?';

  @override
  String webSharing(String file) {
    return 'Compartilhando: $file';
  }

  @override
  String get addressCopied => 'Endereço copiado';

  @override
  String get deviceDefaultName => 'Aparelho Flash';

  @override
  String deviceSubtitle(String ip) {
    return 'IP: $ip · Toque para enviar';
  }

  @override
  String get searchingWifi => 'Procurando na sua rede Wi-Fi...';

  @override
  String get deviceNotAppearing => 'O aparelho não aparece?';

  @override
  String get enterReceiverIp => 'Digite o IP do receptor';

  @override
  String get statsCompleted => 'Concluído';

  @override
  String statsRemaining(String eta) {
    return 'faltam $eta';
  }

  @override
  String get someone => 'alguém';

  @override
  String get statusIntegrityFailed =>
      'O arquivo chegou corrompido (a verificação falhou). Não foi salvo.';

  @override
  String get settingsChooseFolder => 'Escolher pasta (cartão SD)';

  @override
  String get saveLocationChanged => 'Local de salvamento atualizado';

  @override
  String get settingsUseDefault => 'Usar Downloads/Flash';

  @override
  String get settingsThemeLabel => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get webHtmlSubtitle => 'Transferência direta Android ↔ iPhone';

  @override
  String get webHtmlDownloadHeading => 'Arquivo disponível para baixar:';

  @override
  String get webHtmlDownloadButton => 'TOQUE PARA BAIXAR';

  @override
  String get webHtmlNoFile =>
      '(O outro aparelho não está compartilhando nenhum arquivo para baixar)';

  @override
  String get webHtmlSendHeading =>
      'Enviar para o outro aparelho (você pode escolher vários)';

  @override
  String get webHtmlSendButton => 'ENVIAR ARQUIVOS';

  @override
  String get webHtmlKeepScreen =>
      'Por favor, mantenha a tela ligada enquanto eles sobem.';

  @override
  String get webHtmlSelectAlert => 'Selecione pelo menos um arquivo primeiro';

  @override
  String get webHtmlUploading => 'Enviando';

  @override
  String get webHtmlDone => 'Concluído!';

  @override
  String get webHtmlFilesOk => 'arquivos enviados com sucesso';

  @override
  String get galleryTooltip => 'Galeria';

  @override
  String get galleryTitle => 'Galeria do Flash';

  @override
  String get galleryEmpty =>
      'Ainda não há transferências.\nO que você receber ou enviar aparecerá aqui.';

  @override
  String get galleryFilterAll => 'Tudo';

  @override
  String get galleryFilterReceived => 'Recebidos';

  @override
  String get galleryFilterSent => 'Enviados';

  @override
  String get galleryNoFolder => 'Sem pasta';

  @override
  String get galleryReceived => 'Recebido';

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
    return '$count arquivos';
  }

  @override
  String get galleryShareFolder => 'Compartilhar pasta';

  @override
  String get galleryInfoSize => 'Tamanho';

  @override
  String get galleryInfoType => 'Tipo';

  @override
  String get galleryInfoDate => 'Data';

  @override
  String get galleryInfoDirection => 'Direção';

  @override
  String get galleryInfoPeer => 'Aparelho';

  @override
  String get galleryInfoFolder => 'Pasta';

  @override
  String get galleryInfoLocation => 'Localização';

  @override
  String get galleryActionShare => 'Compartilhar';

  @override
  String get galleryActionOpen => 'Abrir';

  @override
  String get galleryActionRemove => 'Remover do histórico';

  @override
  String get galleryRemovedMsg => 'Removido do histórico';

  @override
  String galleryShareError(String error) {
    return 'Não foi possível compartilhar: $error';
  }

  @override
  String galleryOpenError(String error) {
    return 'Não foi possível abrir: $error';
  }

  @override
  String get folderDialogTitle => 'Nome da transferência';

  @override
  String get folderDialogDesc =>
      'Será criada uma pasta com este nome para organizar os arquivos nos dois aparelhos. Deixe em branco para não agrupar.';

  @override
  String get folderDialogHint => 'Ex.: Fotos da viagem';

  @override
  String get folderDialogSkip => 'Sem pasta';

  @override
  String get folderDialogOk => 'Continuar';

  @override
  String get webFolderLabel => 'Pasta para o que você receber (opcional)';

  @override
  String gallerySelectedCount(int count) {
    return '$count selecionados';
  }

  @override
  String get galleryShareAsDoc => 'Compartilhar como documento';

  @override
  String get gallerySelect => 'Selecionar';

  @override
  String get galleryRenameFolder => 'Renomear pasta';

  @override
  String get galleryDeleteSelected => 'Excluir';

  @override
  String galleryDeleteConfirm(int count) {
    return 'Remover $count do histórico?';
  }

  @override
  String galleryFolderCreated(String date) {
    return 'Criada em $date';
  }

  @override
  String get updatesTitle => 'Atualizações';

  @override
  String get updatesCheck => 'Buscar atualizações';

  @override
  String get updatesChecking => 'Buscando atualizações…';

  @override
  String get updatesUpToDate => 'Você já está na última versão';

  @override
  String get updatesError => 'Não foi possível buscar atualizações';

  @override
  String updatesAvailable(String version) {
    return 'Nova versão: $version';
  }

  @override
  String get updatesDownload => 'Baixar e instalar';

  @override
  String updatesDownloading(String pct) {
    return 'Baixando… $pct%';
  }

  @override
  String get updatesLater => 'Agora não';

  @override
  String get updaterNotConfigured => 'O atualizador ainda não está configurado';
}
