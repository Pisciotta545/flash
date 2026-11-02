package com.velocidad.flash

import android.net.Uri
import androidx.core.content.FileProvider

/// G4: FileProvider que siempre reporta "application/octet-stream" como tipo.
/// Se usa al compartir "como documento": apps como WhatsApp consultan el tipo del
/// URI y, al ver uno genérico, lo envían como archivo (sin comprimir) en vez de
/// como foto/video. El nombre y la extensión del archivo se conservan.
class DocFileProvider : FileProvider() {
    override fun getType(uri: Uri): String = "application/octet-stream"
}
