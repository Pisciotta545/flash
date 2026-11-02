# ⚡ PROYECTO FLASH — Bitácora y documentación

> Documento maestro de seguimiento. Aquí se registra todo el proceso de trabajo
> sobre la app **Flash**. Se mantiene actualizado y sin redundancias.

---

## 🚫 REGLAS INVIOLABLES (acordadas con el dueño del proyecto)

1. ~~**Solo se permite modificar archivos `*.md`.**~~ → **Levantada el 2026-06-12.**
2. ~~**No se modifica ni una sola línea de código** hasta autorización explícita.~~
   → **Levantada el 2026-06-12:** el dueño dio permiso total para modificar código.
3. **Mantener los archivos `*.md` actualizados y sin redundancias** a medida que
   avanza el trabajo. *(Sigue vigente.)*

> Desde el 2026-06-12 se trabaja directamente sobre el código. El estado de cada
> mejora se lleva en [`MEJORAS.md`](MEJORAS.md) → sección "Estado de implementación".

---

## 🎯 Qué es Flash

App pensada para **transferir archivos pesados a alta velocidad** por red local
(Wi-Fi), sin pasar por internet ni servicios en la nube.

- Construida en **Flutter** (Dart SDK `^3.11.5`), versión `1.0.0+1`.
- Como no hay cuenta de pago para la App Store, se agregó un **modo web** que
  permite que un iPhone o una PC reciban/envíen desde el navegador.

---

## 🧩 Arquitectura actual

Todo el código vive en un único archivo: **`lib/main.dart`** (~1100 líneas).
La app tiene **tres modos de operación**:

### 1. Receptor (Android ↔ Android)
- Se anuncia en la red por **mDNS** (paquete `nsd`) como servicio `_flash._tcp`
  en el **puerto 4000**.
- Abre un **`ServerSocket` TCP** en el puerto 4000 y espera conexiones.
- **Protocolo propio**: el emisor envía primero una cabecera **JSON en una línea**
  `{"sender","name","size"}\n` (antes era `emisor|archivo|tamaño`, ver `P1`) y luego
  el flujo de bytes del archivo.
- Al terminar, llama a `MediaScanner` para que el archivo aparezca en la galería.

### 2. Emisor / "Buscar equipos"
- Descubre receptores por **mDNS** y los lista.
- Al tocar un dispositivo, conecta por **`Socket` TCP** y transmite cabecera + archivo.
- Tiene **fallback por IP manual** si el dispositivo no aparece en el descubrimiento.
- Soporta envío de **múltiples archivos** y carga vía "Compartir" del sistema
  (`receive_sharing_intent`).
- **Reintento ante error (post-sesión 12):** cada archivo se envía con **reintentos
  automáticos** (`_maxSendAttempts = 3`) y, si aun así falla, la tarea queda en error
  con un **botón de reintento manual** que la reenvía al último receptor usado
  (`_lastTargetHost`). El envío lee en **bloques de 256 KB** (`_sendBlockSize`) para
  más throughput.

### 3. Modo Web (iPhone / PC)
- Levanta un **`HttpServer`** en el **puerto 8080**.
- Sirve una página HTML embebida (función `_getHtmlPage()`) con:
  - `GET /` → página principal.
  - `GET /download` → descarga el archivo que Android está compartiendo.
  - `POST /upload?name=...` → recibe archivos desde el navegador.
- Pensado para interoperar con iPhone, donde no se puede instalar el `.apk`.

### Configuración y almacenamiento (post-G3)
- Lo recibido se guarda en **Descargas/Flash** mediante un `MethodChannel` nativo
  (`MediaStore` en Android 10+, copia directa en Android ≤9). Flutter escribe primero
  a un temporal en caché y Kotlin lo mueve.
- **Destino configurable (tarjeta SD):** desde Ajustes el usuario puede elegir una
  **carpeta propia** (por ejemplo en la tarjeta de memoria) con el **Storage Access
  Framework** (`ACTION_OPEN_DOCUMENT_TREE`). El permiso queda **persistido**; si la SD
  se extrae o se revoca el permiso, se vuelve solo a Descargas/Flash. No añade ningún
  permiso al manifiesto. Botón "Usar Descargas/Flash" para volver al destino por defecto.
- Guarda el nombre de usuario con `shared_preferences`.
- Permisos Android declarados: INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE,
  CHANGE_WIFI_MULTICAST_STATE, y READ/WRITE_EXTERNAL_STORAGE **acotados a `maxSdkVersion=28`**.
  **Ya no se pide `MANAGE_EXTERNAL_STORAGE`.**

---

## 📂 Inventario del repositorio

| Ruta | Rol |
|------|-----|
| `lib/main.dart` | **Toda** la lógica y UI de la app (~1100 líneas). |
| `pubspec.yaml` | Dependencias: `file_picker`, `permission_handler`, `path_provider`, `nsd`, `shared_preferences`, `media_scanner`, `receive_sharing_intent`. |
| `android/app/src/main/AndroidManifest.xml` | Permisos e *intent-filters* de "Compartir". |
| `web/` | Scaffold web por defecto de Flutter (`index.html`, `manifest.json`, iconos). |
| `test/widget_test.dart` | Test de widget por defecto (sin adaptar a la app). |
| `ios/`, `linux/`, `macos/`, `windows/` | Carpetas de plataforma generadas por Flutter. |
| `README.md` | Plantilla por defecto de Flutter (sin personalizar). |

---

## 🔍 Hallazgos y mejoras

El análisis detallado, priorizado y el **estado de implementación** viven en
**[`MEJORAS.md`](MEJORAS.md)**. Estado de los hallazgos clave:

- **Seguridad (`S1`) ✅ resuelto:** el nombre recibido ahora se sanea con `safeFileName()`
  (sin *path traversal*).
- **Velocidad (`V1`/`V2`) ✅ resuelto:** se eliminó el `setState` por *chunk* (ahora
  `ValueNotifier` con *throttle*) y se activó `TCP_NODELAY`.
- **Robustez (`P1`) ✅ resuelto:** cabecera JSON, ya no se rompe con `|`.
- **Almacenamiento (`G3`) ✅ implementado:** se quitó `MANAGE_EXTERNAL_STORAGE`; lo
  recibido va a Descargas/Flash vía `MediaStore`. Compila en debug y release; falta
  verificarlo en un dispositivo real.
- **Web:** la carpeta `web/` es solo el scaffold de Flutter; el "modo web" real es
  el `HttpServer` embebido en Android. Una web app de navegador **no es viable**
  con este código (usa `dart:io`).

---

## 🗂️ Plan de archivos `.md`

- **`PROYECTO_FLASH.md`** (este archivo) → documento maestro: reglas, arquitectura,
  inventario y bitácora.
- **`MEJORAS.md`** → catálogo priorizado de mejoras/agregados y estado de implementación.
- **`POLITICA_PRIVACIDAD.md`** → texto listo de la política de privacidad para Play (ítem `G5`).

> Cada tema vive en un solo lugar para evitar redundancias.

---

## 📝 Bitácora de sesiones

### 2026-06-12 — Sesión 1: Revisión inicial
- Exploración completa del repositorio.
- Lectura de `lib/main.dart`, `pubspec.yaml` y `AndroidManifest.xml`.
- Mapeo de la arquitectura (3 modos: Receptor, Emisor, Modo Web).
- Creado este documento maestro con las reglas inviolables.
- **Sin cambios de código** (regla 2 respetada).

### 2026-06-12 — Sesión 2: Catálogo de mejoras
- Creado **`MEJORAS.md`** con 12 mejoras priorizadas (P0/P1/P2) y esfuerzo estimado.
- Detectado riesgo de seguridad (*path traversal*, `S1`) y el cuello de botella de
  velocidad (`setState` por *chunk*, `V1`).
- Reorganizado `PROYECTO_FLASH.md`: las observaciones detalladas se movieron a
  `MEJORAS.md` para no duplicar.
- **Sin cambios de código** (regla 2 respetada).

### 2026-06-12 — Sesión 3: Enfoque Play Store
- El dueño confirmó: **versión web = Modo Web embebido** (se descarta web app de
  navegador) y **objetivo = publicar en Google Play Store**.
- Revisado `android/app/build.gradle.kts`: detectados **bloqueantes** de Play
  (`applicationId = com.example.flash`, firma *release* con claves de *debug*,
  `MANAGE_EXTERNAL_STORAGE`, `targetSdk`/.aab).
- Ampliado `MEJORAS.md` con la sección 🟣 *Publicación* (G1–G8) y nuevos ítems de
  UX/calidad (U4 onboarding, U5 tema claro, I1 i18n). Total: 21 mejoras priorizadas.
- Definido un **orden de ataque** recomendado.
- **Sin cambios de código** (regla 2 respetada).

### 2026-06-12 — Sesión 4: Identidad de la app definida
- Dueño confirmó **`applicationId = com.velocidad.flash`** (permanente) y
  **nombre visible = "Transferencias Flash"**.
- Registrado en `MEJORAS.md`: `G1` y `G7` marcados como decididos; depurada la
  sección de pendientes.
- **Sin cambios de código** (regla 2 respetada).

### 2026-06-12 — Sesión 5: Política de privacidad redactada
- Creado **`POLITICA_PRIVACIDAD.md`** con el texto completo, a medida de Flash
  (transferencias locales, sin servidores, sin recolección de datos).
- `MEJORAS.md` → `G5` marcado como "texto redactado" y enlazado al documento.
- **Sin cambios de código** (regla 2 respetada).
- Pendiente del dueño: completar campos `⟦…⟧` (nombre y email), **subir la política
  a una URL pública**, aportar el **arte del icono**, y dar el **OK para programar**.

### 2026-06-12 — Sesión 6: Flujo de prueba definido
- El dueño NO quiere checklist de publicación todavía. En su lugar, definió que al
  terminar toda la implementación se debe **generar un build APK para probar en un
  dispositivo real antes de subir** a Play.
- Registrado en `MEJORAS.md` como "Paso final obligatorio" (APK de prueba con
  `flutter build apk`; el `.aab` queda para publicar).
- **Sin cambios de código** (regla 2 respetada).

### 2026-06-12 — Sesión 7: Primera tanda de implementación (regla 2 levantada)
- El dueño dio **permiso total para tocar código**. Implementado y validado con
  `flutter analyze` (0 errores, 0 warnings):
  - **G1** `applicationId`/`namespace` = `com.velocidad.flash`; `MainActivity.kt`
    movido al nuevo paquete y `com/example/` borrado.
  - **G7 (nombre)** `android:label = "Transferencias Flash"`.
  - **G2** firma de *release* vía `android/key.properties` (+ plantilla `.example`),
    con *fallback* a debug si el archivo no existe.
  - **G4/G8** `minify` + `shrinkResources` + `proguard-rules.pro`.
  - **S1** saneo de nombre de archivo (`safeFileName`) en receptor y Modo Web.
  - **P1** cabecera de protocolo migrada a **JSON en una línea**.
  - **V1** progreso por `ValueNotifier` con *throttle* (se mató el `setState` por chunk).
  - **V2** `TCP_NODELAY` en ambos extremos.
  - **U1** velocidad (MB/s), ETA y tamaños legibles por tarea.
  - **Q2** `withOpacity` → `withValues`.
- **Detalle de archivos tocados:** `lib/main.dart`, `android/app/build.gradle.kts`,
  `android/app/src/main/AndroidManifest.xml`, `MainActivity.kt` (movido), nuevos
  `android/app/proguard-rules.pro` y `android/key.properties.example`.
- **Decisión registrada:** **G3** (sacar `MANAGE_EXTERNAL_STORAGE` + migrar a
  `MediaStore`/SAF) **NO se implementó**: es el ítem más riesgoso y necesita prueba
  en dispositivo real. Queda como principal bloqueante pendiente para Play.
- **Siguiente acción del dueño:** generar el `keystore` (G2) y aportar el arte del
  icono (G7). Para probar ya: `flutter build apk --release`.

### 2026-06-12 — Sesión 8: G3 (almacenamiento moderno)
- Implementado **G3** (el bloqueante grande de Play):
  - Nuevo `MethodChannel` nativo `com.velocidad.flash/storage` en `MainActivity.kt`:
    guarda en **Descargas/Flash** vía `MediaStore` (Android 10+, sin permisos) o copia
    directa (Android ≤9). Los bytes no cruzan el canal (Flutter escribe a temp en caché,
    Kotlin mueve) → sin penalidad de velocidad.
  - Quitado `MANAGE_EXTERNAL_STORAGE`; `READ/WRITE_EXTERNAL_STORAGE` acotados a
    `maxSdkVersion=28`. Quitado el plugin `media_scanner` (MediaStore ya indexa).
  - `requestPermissions` ya no pide `manageExternalStorage`; Ajustes pasó a ser informativo
    (se eliminó la elección de ruta Interna/SD y `savedDirPath`).
  - Receptor y Modo Web ahora reciben a temporal y mueven a Descargas al terminar.
- **Validación:** `flutter analyze` → *No issues found*. `flutter build apk --debug` y
  `flutter build apk --release` (con minify/shrink) → **ambos compilan OK**. Hubo que
  correr `flutter clean` por un caché de build con una ruta vieja (`...GusyMaca\Desktop...`).
- **Decisión consciente:** se eligió un `MethodChannel` propio en vez del plugin
  `media_store_plus` (0.1.3, 20 meses sin updates) para evitar riesgo de build con AGP moderno.
- **Pendiente:** verificación en dispositivo real (que lo recibido aparezca en Descargas/Flash).

### 2026-06-12 — Sesión 9: Pulido (U2, U3, U4)
- **U2** — `wakelock_plus`: pantalla encendida durante recepción/envío/Modo Web; se libera
  al cancelar, terminar y en `dispose`.
- **U3** — `qr_flutter`: QR con `http://IP:8080` en el panel del Modo Web (se oculta si no
  hay IP detectada).
- **U4** — onboarding que explica los 3 modos; automático en el primer arranque (flag en
  `shared_preferences`) y reabrible con un botón `?` nuevo en el AppBar.
- **Dependencias:** `wakelock_plus` quedó en `^1.5.2` (la 1.6.1 choca con `win32` que pide
  `file_picker`); `qr_flutter ^4.1.0`.
- **Decisiones conscientes:**
  - **U5 (tema claro) revertido:** la UI usa colores fijos para fondo oscuro; un tema claro a
    medias se vería roto. Se mantiene oscuro fijo hasta auditar colores.
  - **R1 (hash) no implementado:** cambia el protocolo y, sin prueba en dispositivo, arriesga
    corromper transferencias. Pospuesto.
- **Validación:** `flutter analyze` → *No issues found*; `flutter build apk --release` (minify
  on) → OK (~48.5 MB).

### 2026-06-12 — Sesión 10: Internacionalización (I1)
- i18n con `flutter_localizations` + `intl` y archivos `.arb` en `lib/l10n/`
  (`app_es.arb` plantilla, `app_en.arb`, `app_pt.arb`). Config en `l10n.yaml`,
  `generate: true` en pubspec. Clases generadas en `lib/l10n/app_localizations*.dart`.
- `MaterialApp` enganchado con `localizationsDelegates`/`supportedLocales`; la app sigue
  el idioma del teléfono y cae a español si no hay traducción.
- Se reemplazaron ~70 cadenas de la UI nativa por `AppLocalizations` (atajo `_t` en el State,
  usable también en callbacks async). Cadenas con variables resueltas con *placeholders* ARB.
- **Dejado en español a propósito:** la página HTML del Modo Web (contenido servido al otro
  navegador) y la identidad por defecto "Usuario Flash".
- **Q1 parcial:** `widget_test.dart` de plantilla (roto: usaba `MyApp`) reemplazado por tests
  unitarios de las funciones puras → `flutter test` 11/11 verdes.
- **Validación:** `flutter analyze` → *No issues found*; `flutter test` OK;
  `flutter build apk --release` → OK (~49.3 MB).

### 2026-06-14 — Sesión 11: Tarjeta SD + R1 + U5 + I1 (HTML)
- **Guardar en tarjeta de memoria (nuevo):** Ajustes permite elegir una **carpeta
  destino** (incluida la SD) vía Storage Access Framework. Kotlin: `pickSaveFolder`
  (abre el selector y persiste el permiso), `saveIncoming` (escribe en la carpeta
  elegida o cae a Descargas/Flash), `getSaveLabel`/`useDefaultFolder`. Se renombró el
  método del canal `saveToDownloads` → `saveIncoming`. Sin permisos nuevos en el manifiesto.
  En Ajustes el destino se muestra en un **recuadro resaltado con tilde** cuando es una
  carpeta propia (SD), y al cambiarlo aparece un aviso ("Ubicación de guardado actualizada").
- **R1 (integridad) ✅:** `Crc32` puro en Dart, incremental. El emisor precalcula el
  CRC del archivo (una pasada) y lo manda en la cabecera JSON (`crc32`); el receptor lo
  recalcula sobre lo recibido (sin I/O extra) y, si no coincide, **descarta el archivo y
  marca la tarea en error**. El Modo Web (subidas desde navegador) queda sin CRC. Test
  unitario del CRC32 (vector `123456789` = 0xCBF43926, incremental, sensibilidad).
- **U5 (tema) ✅:** modo **Sistema/Claro/Oscuro** elegible en Ajustes y persistido
  (`themeModeNotifier` + `shared_preferences`). Temas Material 3 con seed amarillo para
  ambas luminancias. Se auditaron y adaptaron los colores fijos que rompían en claro
  (encabezado de estado, iconos del AppBar, diálogos, tarjeta de IP del Modo Web, barra de
  progreso, iconos de lista). El QR sigue sobre fondo blanco a propósito.
- **I1 (HTML) ✅:** la página del Modo Web ahora se **traduce** según el idioma del
  teléfono (es/en/pt), incluido el `lang` del HTML y los mensajes dinámicos del JS. Se
  agregaron ~11 claves ARB nuevas (también para SD, tema y el error de integridad).
- **Validación:** `flutter gen-l10n` OK; `flutter analyze` → *No issues found*;
  `flutter test` → **15/15 verdes**; `flutter build apk --release` → **OK (~49.6 MB)**.
- **Pendiente de prueba en dispositivo real:** que el guardado en la SD funcione end-to-end
  y que el CRC no marque falsos errores en transferencias grandes.

### 2026-07-19 — Sesión 12: Reintento de envío, optimización y fix del "tildado"
- **Reintentar transferencia con error (nuevo):** el envío se refactorizó en helpers
  (`_sendTaskOnce`, `_sendTaskWithRetries`, `_retryTask`). Cada archivo se intenta hasta
  **3 veces** de forma automática (con 400 ms entre intentos) antes de marcarse en error.
  Si queda en error, aparece un **botón ↻ de reintento** en la lista que lo reenvía al
  **último receptor usado** (`_lastTargetHost`/`_lastTargetPort`, recordados en `triggerSend`).
  El botón solo se muestra en contexto de envío (no en recepción/Modo Web, donde el error
  es entrante). `TransferTask.reset()` reinicia contadores para que la barra arranque de 0.
- **Optimización de envío:** se reemplazó `file.openRead()` (~64 KB) por lectura con
  `RandomAccessFile` en **bloques de 256 KB** (`_sendBlockSize`) → menos iteraciones y menos
  llamadas al socket. *(Nota: se mantiene el CRC en la cabecera, que implica una pasada de
  lectura extra; migrarlo a un CRC "trailer" para leer el archivo una sola vez queda como
  optimización futura, pospuesta por tocar el protocolo sin prueba en dispositivo.)*
- **Fix "app tildada" al elegir de la galería:** `FilePicker` copia lo elegido a caché
  antes de devolver y no daba feedback. Se agregó un **overlay "Preparando archivos…"**
  (spinner + `AbsorbPointer`) que se renderiza durante esa copia (el hilo de UI no está
  bloqueado, solo esperando el canal nativo). Se aplica en `triggerSend`, `selectFileForWeb`
  y `handleSharedFiles`; este último además pasó de `lengthSync()` (bloqueaba UI) a
  `length()` async.
- **i18n:** +2 claves ARB (`preparingFiles`, `retryTooltip`) en es/en/pt.
- **Validación:** `flutter gen-l10n` OK; `flutter analyze` → *No issues found*;
  `flutter test` → **15/15 verdes**; `flutter build apk --release` → **OK (~49.7 MB)**.
- **Pendiente de prueba en dispositivo real:** que el reintento reconecte y complete bien,
  y que el overlay realmente elimine la sensación de congelado al elegir muchos archivos.
