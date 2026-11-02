package com.velocidad.flash

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

/// G3 + tarjeta SD + carpetas con nombre: guarda los archivos recibidos sin
/// necesitar MANAGE_EXTERNAL_STORAGE. Por defecto van a Descargas/Flash
/// (MediaStore en Android 10+, copia directa en Android 9 y anteriores). El usuario
/// también puede elegir una carpeta propia (por ejemplo en la tarjeta de memoria)
/// mediante el Storage Access Framework (ACTION_OPEN_DOCUMENT_TREE).
///
/// G4 (galería): cada transferencia puede traer un nombre de carpeta (subFolder);
/// los archivos se agrupan en Descargas/Flash/<subFolder>/. saveIncoming devuelve
/// un mapa { uri, path } para que Flutter pueda indexar el archivo en la galería:
/// `uri` sirve para abrir/compartir, `path` es la ubicación legible para mostrar.
///
/// G4 (compartir/abrir): shareFiles y openFile disparan los selectores del sistema
/// (ACTION_SEND / ACTION_VIEW) sobre content:// (MediaStore o SAF) o sobre rutas de
/// archivo (vía FileProvider).
///
/// Los bytes NO viajan por el canal: Flutter escribe a un archivo temporal en caché
/// y acá solo se mueve/copia esa ruta, así que la velocidad no se resiente.
class MainActivity : FlutterActivity() {
    private val channelName = "com.velocidad.flash/storage"
    private val prefsName = "flash_storage"
    private val keyTreeUri = "save_tree_uri"
    private val reqPickFolder = 7001

    // MethodChannel.Result en espera del resultado del selector de carpeta.
    private var pendingPickResult: MethodChannel.Result? = null

    private fun prefs() = applicationContext.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveIncoming" -> {
                        val tempPath = call.argument<String>("tempPath")
                        val fileName = call.argument<String>("fileName")
                        // G4: carpeta opcional donde agrupar el archivo recibido.
                        val subFolder = call.argument<String>("subFolder")
                        if (tempPath == null || fileName == null) {
                            result.error("ARGS", "tempPath y fileName son obligatorios", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveIncoming(tempPath, fileName, subFolder))
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }
                    // G4: comparte uno o varios archivos (content:// o rutas) con el
                    // selector del sistema (ACTION_SEND / ACTION_SEND_MULTIPLE).
                    "shareFiles" -> {
                        val uris = call.argument<List<String>>("uris")
                        val mime = call.argument<String>("mime") ?: "*/*"
                        // G4: "como documento" fuerza un MIME genérico para que apps
                        // como WhatsApp lo envíen como archivo (sin comprimir).
                        val asDocument = call.argument<Boolean>("asDocument") ?: false
                        if (uris == null || uris.isEmpty()) {
                            result.error("ARGS", "uris es obligatorio", null)
                            return@setMethodCallHandler
                        }
                        // Copiar a caché puede tardar (archivos grandes): en un hilo
                        // aparte para no bloquear la UI. startActivity y result van en
                        // el hilo principal.
                        Thread {
                            try {
                                val intent = buildShareIntent(uris, mime, asDocument)
                                runOnUiThread {
                                    startActivity(intent)
                                    result.success(true)
                                }
                            } catch (e: Exception) {
                                runOnUiThread { result.error("SHARE_FAILED", e.message, null) }
                            }
                        }.start()
                    }
                    // G5 (auto-actualizador): abre el instalador del sistema sobre el
                    // APK descargado. Requiere el permiso REQUEST_INSTALL_PACKAGES.
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("ARGS", "path es obligatorio", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("INSTALL_FAILED", e.message, null)
                        }
                    }
                    // G4: abre un archivo con la app correspondiente (ACTION_VIEW).
                    "openFile" -> {
                        val uriStr = call.argument<String>("uri")
                        val mime = call.argument<String>("mime") ?: "*/*"
                        if (uriStr == null) {
                            result.error("ARGS", "uri es obligatorio", null)
                            return@setMethodCallHandler
                        }
                        try {
                            openFile(uriStr, mime)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("OPEN_FAILED", e.message, null)
                        }
                    }
                    // Lanza el selector de carpeta del sistema (incluye la tarjeta SD).
                    // Resuelve con la etiqueta de la carpeta elegida, o null si se canceló.
                    "pickSaveFolder" -> {
                        if (pendingPickResult != null) {
                            result.error("BUSY", "Ya hay un selector de carpeta abierto", null)
                            return@setMethodCallHandler
                        }
                        pendingPickResult = result
                        try {
                            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                                addFlags(
                                    Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
                                )
                            }
                            startActivityForResult(intent, reqPickFolder)
                        } catch (e: Exception) {
                            pendingPickResult = null
                            result.error("PICK_FAILED", e.message, null)
                        }
                    }
                    // Etiqueta legible del destino actual (para mostrar en Ajustes).
                    "getSaveLabel" -> result.success(currentSaveLabel())
                    // Vuelve al destino por defecto (Descargas/Flash) y suelta el permiso.
                    "useDefaultFolder" -> {
                        releaseSavedTree()
                        result.success(currentSaveLabel())
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != reqPickFolder) return
        val pending = pendingPickResult
        pendingPickResult = null
        val uri = data?.data
        if (resultCode == Activity.RESULT_OK && uri != null) {
            try {
                val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                contentResolver.takePersistableUriPermission(uri, flags)
                prefs().edit().putString(keyTreeUri, uri.toString()).apply()
                pending?.success(currentSaveLabel())
            } catch (e: Exception) {
                pending?.error("PERSIST_FAILED", e.message, null)
            }
        } else {
            // Cancelado por el usuario.
            pending?.success(null)
        }
    }

    /// Guarda en la carpeta elegida (SAF) si hay una configurada y válida; si no,
    /// cae al destino por defecto Descargas/Flash. Devuelve { uri, path }.
    private fun saveIncoming(tempPath: String, fileName: String, subFolder: String?): Map<String, String> {
        val sub = subFolder?.trim().orEmpty()
        val treeUri = savedTreeUri()
        if (treeUri != null) {
            return saveToTree(treeUri, tempPath, fileName, sub)
        }
        return saveToDownloads(tempPath, fileName, sub)
    }

    /// Guarda mediante el Storage Access Framework en la carpeta elegida por el
    /// usuario, creando (si hace falta) la subcarpeta [sub].
    private fun saveToTree(treeUri: Uri, tempPath: String, fileName: String, sub: String): Map<String, String> {
        val resolver = applicationContext.contentResolver
        val rootDocId = DocumentsContract.getTreeDocumentId(treeUri)
        var parent = DocumentsContract.buildDocumentUriUsingTree(treeUri, rootDocId)
        if (sub.isNotEmpty()) {
            parent = findOrCreateChildDir(treeUri, parent, sub)
        }
        val mime = mimeOf(fileName)
        val dest = DocumentsContract.createDocument(resolver, parent, mime, fileName)
            ?: throw IllegalStateException("No se pudo crear el archivo en la carpeta elegida")
        resolver.openOutputStream(dest)?.use { out ->
            FileInputStream(File(tempPath)).use { input -> input.copyTo(out, 1 shl 16) }
        } ?: throw IllegalStateException("No se pudo abrir el destino")
        File(tempPath).delete()
        val base = currentSaveLabel().ifEmpty { "Carpeta elegida" }
        val path = if (sub.isEmpty()) "$base/$fileName" else "$base/$sub/$fileName"
        return mapOf("uri" to dest.toString(), "path" to path)
    }

    /// Busca una subcarpeta con nombre [name] dentro de [parent]; si no existe, la crea.
    private fun findOrCreateChildDir(treeUri: Uri, parent: Uri, name: String): Uri {
        val resolver = applicationContext.contentResolver
        val parentDocId = DocumentsContract.getDocumentId(parent)
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(treeUri, parentDocId)
        try {
            resolver.query(
                childrenUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_MIME_TYPE
                ),
                null, null, null
            )?.use { c ->
                while (c.moveToNext()) {
                    val id = c.getString(0)
                    val dn = c.getString(1)
                    val mt = c.getString(2)
                    if (dn == name && mt == DocumentsContract.Document.MIME_TYPE_DIR) {
                        return DocumentsContract.buildDocumentUriUsingTree(treeUri, id)
                    }
                }
            }
        } catch (_: Exception) {
            // Si la consulta falla, intentamos crear igual.
        }
        return DocumentsContract.createDocument(
            resolver, parent, DocumentsContract.Document.MIME_TYPE_DIR, name
        ) ?: throw IllegalStateException("No se pudo crear la carpeta \"$name\"")
    }

    private fun saveToDownloads(tempPath: String, fileName: String, sub: String): Map<String, String> {
        val src = File(tempPath)
        val relative = if (sub.isEmpty()) "Flash" else "Flash/$sub"
        val displayBase = if (sub.isEmpty()) "Descargas/Flash" else "Descargas/Flash/$sub"
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ (API 29+): MediaStore.Downloads, sin permisos.
            val resolver = applicationContext.contentResolver
            val collection =
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/" + relative
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("No se pudo crear la entrada en Descargas")
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(src).use { input -> input.copyTo(out, 1 shl 16) }
            } ?: throw IllegalStateException("No se pudo abrir el destino")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            src.delete()
            return mapOf("uri" to uri.toString(), "path" to "$displayBase/$fileName")
        } else {
            // Android 9 y anteriores: ruta pública directa (WRITE_EXTERNAL_STORAGE).
            val downloads =
                Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val dir = File(downloads, relative).apply { mkdirs() }
            val dest = File(dir, fileName)
            src.copyTo(dest, overwrite = true)
            src.delete()
            return mapOf("uri" to dest.absolutePath, "path" to "$displayBase/$fileName")
        }
    }

    /// Convierte una cadena guardada (content:// o ruta de archivo) en un Uri
    /// compartible. Para rutas de archivo usa FileProvider.
    private fun toShareableUri(s: String): Uri {
        if (s.startsWith("content://")) return Uri.parse(s)
        val authority = "${applicationContext.packageName}.fileprovider"
        return FileProvider.getUriForFile(this, authority, File(s))
    }

    /// Construye el Intent de compartir. Cada archivo se materializa en la caché
    /// (con su nombre/extensión real) y se expone vía FileProvider. Así:
    ///  - Modo normal: el FileProvider reporta el MIME real (por la extensión) →
    ///    CapCut y otros editores reconocen el archivo.
    ///  - Modo documento: se usa un FileProvider propio (DocFileProvider) que
    ///    reporta "application/octet-stream" → WhatsApp lo envía como documento,
    ///    sin comprimir.
    private fun buildShareIntent(uris: List<String>, mime: String, asDocument: Boolean): Intent {
        val authority = if (asDocument) {
            "${applicationContext.packageName}.docprovider"
        } else {
            "${applicationContext.packageName}.fileprovider"
        }

        val resolved = ArrayList<Uri>()
        for (s in uris) {
            try {
                val file = materializeForShare(s) ?: continue
                resolved.add(FileProvider.getUriForFile(this, authority, file))
            } catch (_: Exception) {
                // Ignorar el que no se pueda preparar.
            }
        }
        if (resolved.isEmpty()) throw IllegalStateException("No hay archivos disponibles para compartir")

        val type = if (asDocument) "application/octet-stream" else mime

        val intent = if (resolved.size == 1) {
            Intent(Intent.ACTION_SEND).apply {
                this.type = type
                putExtra(Intent.EXTRA_STREAM, resolved[0])
            }
        } else {
            Intent(Intent.ACTION_SEND_MULTIPLE).apply {
                this.type = type
                putParcelableArrayListExtra(Intent.EXTRA_STREAM, resolved)
            }
        }
        intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        val chooser = Intent.createChooser(intent, "Compartir con…")
        chooser.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        return chooser
    }

    /// Devuelve un File (en caché) listo para compartir vía FileProvider.
    ///  - content:// (MediaStore/SAF): se copia a caché con su nombre real.
    ///  - ruta de archivo: se usa tal cual (si existe).
    private fun materializeForShare(s: String): File? {
        if (!s.startsWith("content://")) {
            val f = File(s)
            return if (f.exists()) f else null
        }
        val uri = Uri.parse(s)
        val name = queryDisplayName(uri) ?: "archivo_${System.currentTimeMillis()}"
        val dir = File(cacheDir, "share_cache").apply { mkdirs() }
        val safe = name.replace('/', '_').replace('\\', '_')
        val out = File(dir, safe)
        applicationContext.contentResolver.openInputStream(uri)?.use { input ->
            java.io.FileOutputStream(out).use { output -> input.copyTo(output, 1 shl 16) }
        } ?: return null
        return out
    }

    /// Nombre visible (con extensión) de un content:// vía OpenableColumns.
    private fun queryDisplayName(uri: Uri): String? {
        return try {
            applicationContext.contentResolver.query(
                uri, arrayOf(android.provider.OpenableColumns.DISPLAY_NAME), null, null, null
            )?.use { c ->
                if (c.moveToFirst()) {
                    val idx = c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (idx >= 0) c.getString(idx)?.takeIf { it.isNotEmpty() } else null
                } else null
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) throw IllegalStateException("El APK descargado no existe")
        val authority = "${applicationContext.packageName}.fileprovider"
        val uri = FileProvider.getUriForFile(this, authority, file)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openFile(uriStr: String, mime: String) {
        if (!uriStr.startsWith("content://") && !File(uriStr).exists()) {
            throw IllegalStateException("El archivo ya no existe")
        }
        val uri = toShareableUri(uriStr)
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mime)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(intent, "Abrir con…"))
    }

    /// URI de la carpeta elegida, solo si todavía tenemos permiso persistido sobre ella.
    private fun savedTreeUri(): Uri? {
        val str = prefs().getString(keyTreeUri, null) ?: return null
        val uri = Uri.parse(str)
        val held = contentResolver.persistedUriPermissions.any {
            it.uri == uri && it.isWritePermission
        }
        if (!held) {
            // El permiso se perdió (revocado, SD extraída, etc.): volver al destino por defecto.
            prefs().edit().remove(keyTreeUri).apply()
            return null
        }
        return uri
    }

    private fun releaseSavedTree() {
        val str = prefs().getString(keyTreeUri, null) ?: return
        try {
            val uri = Uri.parse(str)
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.releasePersistableUriPermission(uri, flags)
        } catch (_: Exception) {
            // best-effort
        }
        prefs().edit().remove(keyTreeUri).apply()
    }

    /// Etiqueta legible del destino actual. "" significa el destino por defecto.
    private fun currentSaveLabel(): String {
        val uri = savedTreeUri() ?: return ""
        return try {
            val docId = DocumentsContract.getTreeDocumentId(uri) // p.ej. "1A2B-3C4D:Flash"
            val parts = docId.split(":", limit = 2)
            val volume = parts.getOrNull(0) ?: ""
            val path = parts.getOrNull(1)?.takeIf { it.isNotEmpty() } ?: docId
            val place = if (volume.equals("primary", ignoreCase = true)) {
                "Almacenamiento interno"
            } else {
                "Tarjeta SD"
            }
            "$place/$path"
        } catch (e: Exception) {
            "Carpeta elegida"
        }
    }

    private fun mimeOf(fileName: String): String {
        val ext = fileName.substringAfterLast('.', "").lowercase()
        if (ext.isEmpty()) return "application/octet-stream"
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: "application/octet-stream"
    }
}
