# 🛠️ FLASH — Catálogo de mejoras y agregados

> Propuestas concretas y priorizadas para mejorar la app. **Nada de esto está
> implementado todavía**: por la regla 2, no se toca código hasta que el dueño
> lo autorice. Cada ítem está descrito para poder ejecutarlo apenas se dé el OK.
>
> Documento relacionado: [`PROYECTO_FLASH.md`](PROYECTO_FLASH.md) (arquitectura e inventario).

## ✅ Decisiones del dueño (confirmadas 2026-06-12)
1. **"Versión web" = el Modo Web embebido** (el `HttpServer` que se habilita dentro
   de la app). **Queda descartada** la idea de una web app de navegador aparte.
2. **Objetivo: publicar en Google Play Store.** Esto activa la sección 🟣 *Publicación*,
   con varios **bloqueantes** que hay que resolver sí o sí.
3. **`applicationId` = `com.velocidad.flash`** (definitivo y **permanente**). Reemplaza
   a `com.example.flash` en `build.gradle.kts`, `namespace` y la ruta de `MainActivity`. → `G1`.
4. **Nombre visible = "Transferencias Flash"** (20/30 caracteres; mejora el ASO y evita
   choque con marcas como Adobe Flash / The Flash). Va en `android:label`. → `G7`.

## Cómo leer las prioridades
- **P0 — Crítico / Bloqueante**: corrige fallas reales (seguridad, datos corruptos,
  velocidad) o **impide publicar** en Play Store.
- **P1 — Alto valor**: mejora notable de experiencia o robustez.
- **P2 — Deseable**: pulido, calidad de código, extras.

| ID | Prioridad | Mejora | Esfuerzo |
|----|-----------|--------|----------|
| **G1** | **P0** | `applicationId`/`namespace` propios (hoy `com.example.flash` → rechazo) | Bajo |
| **G2** | **P0** | Firma de *release* con *keystore* propio (hoy usa claves de *debug*) | Bajo |
| **G3** | **P0** | Quitar/justificar `MANAGE_EXTERNAL_STORAGE` (Play lo restringe) | Alto |
| **G4** | **P0** | `targetSdk` al día + generar **App Bundle (.aab)** | Bajo |
| S1 | P0 | Bloquear *path traversal* en nombres de archivo | Bajo |
| V1 | P0 | Quitar `setState` por *chunk* (matar el cuello de botella de velocidad) | Medio |
| P1 | P0 | Cabecera de protocolo robusta (no romper con `\|`) | Bajo |
| G5 | P1 | Política de privacidad + formulario *Data Safety* | Bajo |
| G6 | P1 | Justificar permiso de ubicación (lo usa el mDNS) ante Play | Bajo |
| G7 | P1 | Icono, nombre y *splash* propios (hoy son los de la plantilla) | Bajo |
| V2 | P1 | Buffers de socket grandes + `TCP_NODELAY` | Bajo |
| U1 | P1 | Velocidad en vivo (MB/s) + ETA + tamaños legibles | Bajo |
| U2 | P1 | Mantener pantalla encendida durante la transferencia (wakelock) | Bajo |
| U4 | P1 | Pantalla de ayuda / onboarding (el flujo no es obvio) | Medio |
| R1 | P1 | Verificación de integridad (hash) al terminar | Medio |
| G8 | P2 | Activar R8/`minify` + `shrinkResources` (app más liviana) | Bajo |
| U3 | P2 | Código QR para el Modo Web | Bajo |
| U5 | P2 | Soportar tema claro además del oscuro | Bajo |
| I1 | P2 | Internacionalización (i18n); hoy todo el texto está fijo en español | Medio |
| R2 | P2 | Cancelar / reanudar transferencias | Alto |
| Q1 | P2 | Separar `main.dart` en módulos + README real + tests | Medio |
| Q2 | P2 | Reemplazar APIs deprecadas (`withOpacity`) | Bajo |

---

## 🟣 Publicación en Play Store (bloqueantes y requisitos)

### G1. `applicationId` y `namespace` propios — **BLOQUEANTE** ✔️ decidido
**Problema.** En `android/app/build.gradle.kts` figura `applicationId = "com.example.flash"`
y `namespace = "com.example.flash"`. Google Play **rechaza** cualquier app cuyo ID
empiece con `com.example`. Además el ID es **permanente**: no se puede cambiar una
vez publicada.
**Decidido → `com.velocidad.flash`.** Al implementar, actualizar de forma consistente:
`applicationId` y `namespace` en `build.gradle.kts`, y mover/renombrar `MainActivity.kt`
a la ruta de paquete `com/velocidad/flash/` (con su `package`).

### G2. Firma de *release* con *keystore* propio — **BLOQUEANTE**
**Problema.** El bloque `release` usa `signingConfig = signingConfigs.getByName("debug")`.
Una app firmada con claves de *debug* **no se puede subir** a Play.
**Solución.** Generar un *keystore* propio (`keytool`), guardarlo a buen resguardo
(si se pierde, no se puede volver a actualizar la app), y configurar la firma de
*release* leyendo las credenciales desde un archivo local fuera del control de versiones.
Recomendado además activar **Play App Signing**.

### G3. `MANAGE_EXTERNAL_STORAGE` — **BLOQUEANTE probable**
**Problema.** El manifiesto pide `MANAGE_EXTERNAL_STORAGE` ("acceso a todos los
archivos"). Google **lo restringe** a categorías muy puntuales (gestores de archivos,
antivirus, backups). Una app de transferencia normalmente **es rechazada** si lo pide.
**Solución (la correcta para publicar).** Migrar al modelo moderno de almacenamiento:
- Para **elegir** archivos a enviar: el selector del sistema (lo que ya hace
  `file_picker`) no requiere permisos amplios.
- Para **guardar** lo recibido: usar `MediaStore` / `Storage Access Framework`
  (carpeta elegida por el usuario) en vez de escribir rutas absolutas a
  `/storage/emulated/0/...`.
- Quitar `MANAGE_EXTERNAL_STORAGE` y los permisos de almacenamiento obsoletos.
> Es el ítem de **mayor esfuerzo** porque toca cómo se guardan los archivos. Sustituye
> y amplía al viejo **S2**.

### G4. `targetSdk` al día + App Bundle (.aab)
**Problema.** Play exige un `targetSdk` reciente (al día de hoy, Android 14/API 34
o superior) y que se suba un **`.aab`**, no un `.apk`.
**Solución.** Fijar `compileSdk`/`targetSdk` a la versión exigida y compilar con
`flutter build appbundle --release`. Verificar `versionCode`/`versionName` y la
política de incrementarlos en cada subida.

### G5. Política de privacidad + *Data Safety* — ✔️ texto redactado
**Problema.** La app pide permisos sensibles (ubicación, almacenamiento) y maneja
archivos del usuario; Play **obliga** a publicar una política de privacidad y
completar el formulario *Data Safety*.
**Estado.** El texto completo ya está listo en
**[`POLITICA_PRIVACIDAD.md`](POLITICA_PRIVACIDAD.md)**.
**Pendiente del dueño:** completar los campos `⟦…⟧` (nombre/desarrollador y email),
**subirla a una URL pública** y cargar esa URL en la ficha de Play. Si **G3/G6**
cambian los permisos, actualizar la sección 4 de ese documento para que coincida.

### G6. Justificar el permiso de ubicación
**Problema.** Se pide `Permission.location`. En Android es **necesario** para que
el descubrimiento por mDNS (`nsd`) funcione, pero Play pide **justificar** los
permisos de ubicación y puede pedir un formulario de uso.
**Solución.** Documentar que la ubicación se usa **solo** para descubrir equipos en
la Wi-Fi local (no se rastrea ni se envía a ningún lado). Evaluar si alcanza con
`NEARBY_WIFI_DEVICES` (Android 13+) para reducir el alcance del permiso.

### G7. Identidad visual propia — nombre ✔️ decidido
**Problema.** El icono (`ic_launcher`) y el `android:label="flash"` son los de la
plantilla. Una app publicada necesita icono propio, nombre presentable y, opcional,
*splash screen*.
**Solución.** Poner `android:label="Transferencias Flash"` (nombre ya decidido),
generar iconos con `flutter_launcher_icons` y un *splash* con `flutter_native_splash`.
**Pendiente:** falta el **arte del icono** (imagen base) — lo tenés que aportar o
decidir si lo diseñamos.

### G8. Reducción de tamaño (R8 / *shrink*)
Activar `isMinifyEnabled = true` y `isShrinkResources = true` en *release* para que
el `.aab` sea más liviano. No es bloqueante, es pulido.

---

## 🔴 P0 — Críticas (funcionamiento y seguridad)

### S1. Bloquear *path traversal* en el nombre de archivo
**Problema.** Tanto en el Modo Web (`POST /upload?name=...`) como en el receptor
nativo (cabecera `...|nombreArchivo|...`), el nombre recibido se usa directo para
construir la ruta: `savePath = '$savedDirPath/$fileName'`. Si el otro extremo manda
un nombre como `../../algo`, se puede **escribir fuera de la carpeta Flash**.
**Solución.** Quedarse solo con el nombre base (descartar `/`, `\` y `..`) antes de
construir la ruta. Saneamiento de pocas líneas.

### V1. Quitar `setState` por cada *chunk* — el verdadero cuello de botella
**Problema.** En recepción y en envío se llama a `setState()` por **cada bloque de
bytes**, lo que reconstruye toda la pantalla decenas de miles de veces durante un
archivo pesado. Frena la transferencia justo cuando el objetivo es la velocidad.
**Solución.** Aislar la barra con `ValueNotifier` + `ValueListenableBuilder` (solo
se repinta la barra), **o** *throttlear* el progreso (cada ~150 ms o ~1 %).

### P1. Cabecera de protocolo robusta
**Problema.** El protocolo nativo separa con `|`: `emisor|archivo|tamaño\n`. Un
nombre con `|` rompe el *parseo*.
**Solución.** Cabecera con longitud prefijada o JSON en una línea (codificado), y
*parseo* por campos en vez de *split* posicional.

---

## 🟠 P1 — Alto valor

### V2. Buffers de socket grandes + `TCP_NODELAY`
Subir los buffers de envío/recepción y desactivar Nagle
(`setOption(SocketOption.tcpNoDelay, true)`) para exprimir la LAN. Complementa a **V1**.

### U1. Velocidad en vivo, ETA y tamaños legibles
Mostrar **MB/s** instantáneos, **tiempo restante** y tamaño en KB/MB/GB en cada tarea.
Refuerza la sensación de "alta velocidad" y ayuda a diagnosticar.

### U2. Mantener pantalla encendida (wakelock)
El HTML ya lo pide al usuario, pero no se fuerza. Agregar `wakelock_plus` y activarlo
mientras hay transferencia en curso; liberarlo al terminar.

### U4. Pantalla de ayuda / onboarding
El flujo Receptor/Emisor/Modo Web no es obvio para alguien nuevo. Una pantalla breve
de "cómo funciona" (la primera vez o desde un botón de ayuda) reduce abandono y malas
reseñas en Play.

### R1. Verificación de integridad al terminar
Calcular un hash (CRC32 o SHA-1) y compararlo entre emisor y receptor. Si no coincide,
marcar la tarea como error en vez de dar por buena una transferencia corrupta.

---

## 🟡 P2 — Deseables

### U3. Código QR para el Modo Web
Mostrar un **QR** (paquete `qr_flutter`) que el iPhone escanea, en vez de tipear
`http://IP:8080`.

### U5. Tema claro
Hoy la UI es solo oscura (`ThemeData.dark`). Soportar tema claro/seguir el del sistema.

### I1. Internacionalización (i18n)
Todos los textos están fijos en español dentro del código. Extraerlos a archivos de
localización abre la puerta a inglés y otros idiomas (más alcance en Play).

### R2. Cancelar / reanudar transferencias
Botón para **cancelar** una tarea y, más ambicioso, **reanudar** una transferencia
cortada (depende de un protocolo con *offset* → se apoya en **P1**).

### Q1. Calidad de código
- Separar `lib/main.dart` (~980 líneas) en `models/`, `services/` (red, web,
  descubrimiento) y `ui/` (widgets).
- README real (reemplazar la plantilla).
- Tests reales (hoy `widget_test.dart` es plantilla).

### Q2. Reemplazar APIs deprecadas
`Color.withOpacity(x)` → `Color.withValues(alpha: x)` y lo que marque `flutter analyze`.

---

## 🧭 Orden recomendado de ataque
Cuando se autorice tocar código, sugiero esta secuencia:

1. **Definir el `applicationId`** (G1) — hay que decidirlo antes que nada.
2. **Seguridad y velocidad del core:** S1 → V1 → P1 → V2 → U1.
3. **Bloqueantes de Play:** G3 (almacenamiento moderno) → G2 (firma) → G4 (targetSdk/.aab) → G7 (icono/nombre).
4. **Trámite de Play:** G5 (privacidad/Data Safety) → G6 (ubicación).
5. **Pulido:** U2, U4, R1, y luego los P2.

> ⚠️ **G3** (sacar `MANAGE_EXTERNAL_STORAGE` y migrar a almacenamiento moderno) es el
> trabajo más grande y el que más condiciona la aprobación. Conviene encararlo temprano.

### 🧪 Paso final obligatorio: build APK para probar (pedido del dueño)
Cuando se complete toda la implementación, **antes de pensar en subir a Play**, generar
un **APK de prueba** para instalarlo en el teléfono y verificar que todo funciona en un
dispositivo real:
- Comando: `flutter build apk --release` (o `--debug` para iterar más rápido).
- El APK queda en `build/app/outputs/flutter-apk/`.
- Se instala directo en el teléfono (no requiere Play).
- **Aclaración:** el APK es para **probar**. Para **publicar** en Play se usa el
  **App Bundle** (`flutter build appbundle --release` → `.aab`, ver `G4`). Son dos
  artefactos distintos del mismo código.
- Recién cuando la prueba en el dispositivo sea satisfactoria se avanza a la publicación.

---

## ❓ Pendiente de definir con el dueño
- **Arte del icono** de la app (imagen base para `flutter_launcher_icons`) → necesario para `G7`.
- **Keystore de release** (ver `G2`): generarlo y crear `android/key.properties`.
- **Probar el APK de release en un teléfono** (`build/app/outputs/flutter-apk/app-release.apk`),
  en especial que lo recibido aparezca en **Descargas/Flash** (verificación de `G3`).

---

## ✅ Estado de implementación
*(El dueño autorizó tocar código el 2026-06-12. `flutter analyze` pasa sin errores
ni warnings.)*

### Hecho ✅
- [x] **G1** — `applicationId` y `namespace` = `com.velocidad.flash`; `MainActivity.kt`
  movido a `com/velocidad/flash/` y el paquete `com/example/` eliminado.
- [x] **G7 (nombre)** — `android:label = "Transferencias Flash"`.
- [x] **G2** — firma de *release* leyendo `android/key.properties` (con `key.properties.example`
  de plantilla); si el archivo no existe, cae a debug para no bloquear el build local.
- [x] **G4/G8** — `isMinifyEnabled` + `isShrinkResources` activados con `proguard-rules.pro`;
  listo para `flutter build appbundle --release`.
- [x] **G3** — **`MANAGE_EXTERNAL_STORAGE` eliminado.** Los recibidos van a **Descargas/Flash**
  vía un `MethodChannel` nativo (`MediaStore` en Android 10+ sin permisos; copia directa en
  Android ≤9 con `WRITE_EXTERNAL_STORAGE` acotado a `maxSdkVersion=28`). Flutter escribe a un
  temporal en caché y Kotlin lo mueve, así que no se pierde velocidad. Se quitó `media_scanner`
  (MediaStore ya indexa). **Compila en debug y release** (`flutter build apk`); falta probar en
  dispositivo real.
- [x] **S1** — `safeFileName()` saneando nombre base en el receptor nativo y en el Modo Web.
- [x] **P1** — cabecera de protocolo ahora es **JSON en una línea** (`{"sender","name","size"}\n`);
  los nombres con `|` o caracteres raros ya no rompen el parseo. Cabecera inválida → se aborta
  esa conexión sin tirar el receptor.
- [x] **V1** — eliminado el `setState` por *chunk*. El progreso viaja por un `ValueNotifier`
  con *throttle* (~120 ms); solo se repinta la barra de cada tarea.
- [x] **V2** — `TCP_NODELAY` activado en emisor y receptor.
- [x] **U1** — cada tarea muestra **%, tamaños legibles (KB/MB/GB), velocidad (MB/s) y ETA**.
- [x] **Q2** — `withOpacity` → `withValues(alpha:)`.
- [x] **U2** — `wakelock_plus`: la pantalla queda encendida mientras se recibe, se envía o
  está activo el Modo Web; se libera al terminar/cancelar.
- [x] **U3** — código **QR** (`qr_flutter`) en el Modo Web con `http://IP:8080` para escanear
  desde el iPhone/PC.
- [x] **U4** — pantalla de **ayuda/onboarding** que explica los 3 modos: automática en el
  primer arranque (`shared_preferences`) y reabrible con el botón `?` del AppBar.
- [x] **I1** — **internacionalización** con `flutter_localizations` + archivos `.arb`. La app
  sigue el idioma del teléfono: **español (plantilla), inglés y portugués**; si no hay
  traducción cae a español. Toda la UI nativa está traducida (~70 cadenas). *La página HTML
  del Modo Web queda en español a propósito* (es contenido servido al navegador del otro
  equipo). Identidad por defecto ("Usuario Flash") sin traducir a propósito.
- [x] **Q1 (parcial)** — el `widget_test.dart` de plantilla (roto, referenciaba `MyApp`) se
  reemplazó por **tests unitarios reales** de las funciones puras (`safeFileName`, `humanSize`,
  `humanSpeed`, `humanEta`, y `Crc32`). `flutter test` → **15 verdes**.
- [x] **R1 (integridad)** — `Crc32` puro/incremental. El emisor manda el CRC en la cabecera
  JSON; el receptor lo recalcula sobre lo recibido (sin I/O extra) y, si no coincide, descarta
  el archivo y marca la tarea en error. Las subidas del Modo Web (navegador) van sin CRC.
- [x] **U5 (tema)** — modo **Sistema/Claro/Oscuro** elegible en Ajustes y persistido. Temas
  Material 3 (seed amarillo) para ambas luminancias; se adaptaron los colores fijos que rompían
  en claro (encabezado, AppBar, diálogos, tarjeta de IP, progreso, iconos).
- [x] **I1 (HTML)** — la página del Modo Web se traduce según el idioma del teléfono (es/en/pt),
  incluido el `lang` del HTML y los textos dinámicos del JS.
- [x] **Tarjeta SD (nuevo)** — Ajustes permite elegir una **carpeta destino** (incluida la SD)
  con el Storage Access Framework; el permiso queda persistido y los recibidos se guardan ahí.
  Si la SD se quita o se revoca el permiso, vuelve a Descargas/Flash. **No agrega permisos** al
  manifiesto (el SAF no los necesita).
- [x] **Reintento de envío (nuevo, sesión 12)** — cada archivo se reintenta **hasta 3 veces**
  automáticamente y, si igual falla, la tarea queda en error con un **botón ↻** que la reenvía
  al último receptor usado. Cubre parcialmente el "cancelar/reanudar" de **R2** (falta el
  offset/reanudación real, que depende de cambiar el protocolo).
- [x] **Optimización de envío (sesión 12)** — lectura en **bloques de 256 KB** (`RandomAccessFile`)
  en vez de los ~64 KB de `openRead()`. Pendiente futuro: CRC "trailer" para no releer el archivo.
- [x] **Fix "app tildada" al elegir de galería (sesión 12)** — overlay **"Preparando archivos…"**
  durante la copia a caché del selector; `handleSharedFiles` pasó a `length()` async.

### Pendiente ⏳
- [ ] **G2 (acción del dueño)** — generar el `keystore` real y crear `android/key.properties`
  (ver `key.properties.example`). Sin eso, el `.aab` se firma con debug y **Play lo rechaza**.
- [ ] **G3 (verificación)** — implementado y compilando; falta **probar en un dispositivo real**
  que los archivos efectivamente lleguen a Descargas/Flash en Android 10+ (y la copia directa en
  Android ≤9). Si MediaStore fallara en algún equipo, el receptor marca la tarea en error.
- [ ] **G4 (acción del dueño)** — verificar `compileSdk`/`targetSdk` exigidos por Play al momento
  de subir (hoy se toman de `flutter.targetSdkVersion`) y subir el incremento de `versionCode`.
- [ ] **G5/G6** — trámite de Play (privacidad, *Data Safety*, justificación de ubicación).
- [ ] **G7 (icono/splash)** — falta el **arte del icono**; el nombre ya quedó.
- [ ] **R1 / Tarjeta SD (verificación)** — implementados y compilando; falta **probar en
  dispositivo real**: que el guardado en la SD funcione end-to-end y que el CRC no marque
  falsos errores en transferencias grandes.
- [ ] **I1 (extra opcional)** — agregar más idiomas si hiciera falta (la base ya está lista;
  solo sumar `app_<idioma>.arb`). La página HTML del Modo Web ya quedó traducida.

> ⚠️ **Para probar ya mismo** en un teléfono: `flutter build apk --release` (instala el APK
> directo, sin Play). El `.aab` para publicar queda condicionado a resolver **G2** (keystore)
> y **G3** (almacenamiento).
