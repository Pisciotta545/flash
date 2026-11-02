import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';

/// G5: auto-actualizador basado en GitHub Releases.
///
/// Configurá acá tu repositorio (usuario/repositorio). La app consulta la última
/// *release* publicada, compara la versión con la instalada y, si hay una más
/// nueva, descarga el APK adjunto y abre el instalador del sistema.
///
/// Cómo publicar una actualización:
///   1. Subí la versión en pubspec.yaml (p. ej. 1.1.0+2) y compilá el APK.
///   2. En GitHub → Releases → "Draft a new release".
///   3. Tag = la versión (p. ej. v1.1.0). Adjuntá el APK (Flash-v1.1.0.apk).
///   4. Publicá. La app lo detecta solo.
const String kUpdateRepo = 'Pisciotta545/flash';

class _Release {
  final String tag; // versión (p. ej. "v1.1.0")
  final String apkUrl; // URL de descarga del APK
  final String notes; // cuerpo de la release
  const _Release(this.tag, this.apkUrl, this.notes);
}

class Updater {
  static const MethodChannel _ch = MethodChannel('com.velocidad.flash/storage');

  static bool get _configured =>
      !kUpdateRepo.contains('TU_USUARIO') && kUpdateRepo.contains('/');

  /// Punto de entrada. [silent] = no avisar si ya está al día o si falla (para
  /// la comprobación automática al abrir la app).
  static Future<void> checkForUpdates(
    BuildContext context, {
    bool silent = false,
  }) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!_configured) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(content: Text(t.updaterNotConfigured)));
      }
      return;
    }

    if (!silent) {
      messenger.showSnackBar(SnackBar(content: Text(t.updatesChecking)));
    }

    _Release? rel;
    String current = '';
    try {
      final info = await PackageInfo.fromPlatform();
      current = info.version;
      rel = await _fetchLatest();
    } catch (_) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(content: Text(t.updatesError)));
      }
      return;
    }

    if (rel == null || _cmp(rel.tag, current) <= 0) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(content: Text(t.updatesUpToDate)));
      }
      return;
    }

    if (!context.mounted) return;
    _showUpdateDialog(context, rel);
  }

  static Future<_Release?> _fetchLatest() async {
    final uri = Uri.parse('https://api.github.com/repos/$kUpdateRepo/releases/latest');
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'FlashApp');
      req.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      final resp = await req.close();
      if (resp.statusCode != 200) return null;
      final body = await resp.transform(utf8.decoder).join();
      final map = jsonDecode(body) as Map<String, dynamic>;
      final tag = (map['tag_name'] as String?)?.trim() ?? '';
      final notes = (map['body'] as String?)?.trim() ?? '';
      final assets = (map['assets'] as List<dynamic>? ?? []);
      String apkUrl = '';
      for (final a in assets) {
        final m = a as Map<String, dynamic>;
        final name = (m['name'] as String?) ?? '';
        if (name.toLowerCase().endsWith('.apk')) {
          apkUrl = (m['browser_download_url'] as String?) ?? '';
          break;
        }
      }
      if (tag.isEmpty || apkUrl.isEmpty) return null;
      return _Release(tag, apkUrl, notes);
    } finally {
      client.close();
    }
  }

  /// Compara dos versiones "1.2.3" (ignora una 'v' inicial). >0 si a es mayor.
  static int _cmp(String a, String b) {
    List<int> parts(String s) => s
        .replaceAll(RegExp(r'^[vV]'), '')
        .split(RegExp(r'[.+-]'))
        .map((x) => int.tryParse(x) ?? 0)
        .toList();
    final pa = parts(a), pb = parts(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (int i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x - y;
    }
    return 0;
  }

  static void _showUpdateDialog(BuildContext context, _Release rel) {
    final t = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update),
            const SizedBox(width: 10),
            Expanded(child: Text(t.updatesAvailable(rel.tag))),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(rel.notes.isEmpty ? '' : rel.notes),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t.updatesLater),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: Text(t.updatesDownload),
            onPressed: () {
              Navigator.pop(c);
              _downloadAndInstall(context, rel);
            },
          ),
        ],
      ),
    );
  }

  static Future<void> _downloadAndInstall(
    BuildContext context,
    _Release rel,
  ) async {
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final progress = ValueNotifier<double>(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: progress,
              builder: (c, p, _) => Column(
                children: [
                  LinearProgressIndicator(value: p > 0 ? p : null),
                  const SizedBox(height: 12),
                  Text(t.updatesDownloading((p * 100).toStringAsFixed(0))),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Flash-update.apk');
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(rel.apkUrl));
      req.headers.set(HttpHeaders.userAgentHeader, 'FlashApp');
      final resp = await req.close();
      final total = resp.contentLength;
      final sink = file.openWrite();
      int received = 0;
      await for (final chunk in resp) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) progress.value = received / total;
      }
      await sink.close();
      client.close();

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      await _ch.invokeMethod('installApk', {'path': file.path});
    } catch (_) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text(t.updatesError)));
    } finally {
      progress.dispose();
    }
  }
}
