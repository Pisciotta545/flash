# 📄 Política de Privacidad — Transferencias Flash

> Texto **listo para publicar**. Google Play exige que esta política esté accesible
> en una **URL pública** (p. ej. una página gratuita en GitHub Pages, Google Sites,
> Notion público o un blog) y que esa URL se cargue en la ficha de la app.
>
> Antes de publicar, completar los campos marcados con `⟦…⟧`.
> Relacionado: `MEJORAS.md` → ítem **G5**.

---

## Campos a completar antes de publicar
- **Responsable / desarrollador:** ⟦TU NOMBRE O SEUDÓNIMO DE DESARROLLADOR⟧
- **Correo de contacto:** ⟦TU EMAIL DE CONTACTO⟧ (sugerido: `gusty63pisiotta@gmail.com` — confirmar)
- **Última actualización:** 12 de junio de 2026

---

# Política de Privacidad de "Transferencias Flash"

**Última actualización: 12 de junio de 2026**

Esta Política de Privacidad describe cómo la aplicación **Transferencias Flash**
(en adelante, "la App"), desarrollada por ⟦TU NOMBRE O SEUDÓNIMO⟧, trata la
información cuando la usás. Te pedimos que la leas para entender nuestro compromiso:
**la App está diseñada para no recolectar tus datos personales.**

## 1. Resumen claro
Transferencias Flash sirve para **enviar y recibir archivos directamente entre
dispositivos conectados a la misma red local (Wi-Fi)**. Las transferencias son
**directas de un dispositivo a otro**: **no pasan por internet, no se suben a ningún
servidor nuestro y no recolectamos, almacenamos ni vendemos ninguna información tuya.**

## 2. Información que NO recolectamos
La App **no recopila** datos personales identificables. En particular, **no**
recolectamos ni transmitimos a nosotros ni a terceros:
- Tu nombre, correo, teléfono ni datos de cuenta.
- El contenido de los archivos que envías o recibís.
- Tu ubicación geográfica.
- Identificadores publicitarios ni datos de uso/analítica.

No usamos servicios de analítica, publicidad ni seguimiento de terceros.

## 3. Información que se maneja en tu dispositivo
Para funcionar, la App guarda **localmente en tu dispositivo** (nunca en servidores
externos):
- **El nombre que elegís mostrar** en la red (por defecto "Usuario Flash"), para que
  el otro equipo sepa quién le envía. Se guarda solo en tu teléfono.
- **La carpeta de destino** que elegís para guardar lo recibido.

Esta información permanece en tu dispositivo y podés borrarla desinstalando la App.

## 4. Permisos que solicita la App y por qué
- **Archivos y almacenamiento:** los archivos que recibís se guardan en tu carpeta
  **Descargas/Flash**. En Android 10 y superior **no se requiere ningún permiso de
  almacenamiento** para esto. En Android 9 y anteriores se usa el permiso de
  almacenamiento clásico únicamente para guardar lo recibido. La App **no** solicita
  el permiso de "acceso a todos los archivos" (*MANAGE_EXTERNAL_STORAGE*).
  Opcionalmente podés elegir **otra carpeta de destino** (por ejemplo en la tarjeta de
  memoria) usando el selector del sistema; en ese caso la App solo puede escribir en la
  carpeta que vos elegís y el permiso queda guardado únicamente en tu dispositivo.
- **Ubicación / dispositivos cercanos (Wi-Fi):** Android **exige** este permiso para
  poder **descubrir otros equipos en tu red local** mediante el protocolo de
  descubrimiento (mDNS/NSD). **No usamos la ubicación para rastrearte** ni la
  enviamos a ningún lado; se utiliza únicamente para encontrar dispositivos cercanos
  en la misma Wi-Fi.
- **Red e información de Wi-Fi:** para establecer la conexión directa entre los dos
  dispositivos durante la transferencia.

## 5. Modo Web (servidor local)
La App incluye un "Modo Web" que, **solo cuando vos lo activás**, levanta un servidor
local temporal en tu dispositivo (puerto 8080) para que otro equipo de la **misma red
local** (por ejemplo un iPhone o una PC) pueda enviar o descargar archivos desde su
navegador.
- Este servidor funciona **solo dentro de tu red local** y **solo mientras lo
  mantenés activo**; se apaga cuando lo cerrás o salís de ese modo.
- Mientras está activo, cualquier dispositivo de tu red local que conozca la dirección
  puede conectarse. Te recomendamos usarlo **solo en redes de confianza** (tu casa,
  tu oficina) y cerrarlo al terminar.

## 6. Cómo viajan tus archivos
Los archivos se transfieren **directamente entre los dos dispositivos** a través de tu
red local. **No se almacenan copias en internet ni en servidores nuestros.** La
seguridad de la transferencia depende de la seguridad de tu propia red Wi-Fi.

## 7. Datos de menores
La App no está dirigida a menores de 13 años y no recopila intencionalmente datos de
ellos. Como no recolectamos datos personales de ningún usuario, esto aplica a todos
por igual.

## 8. Seguridad
Como las transferencias son locales y no guardamos tus datos, la exposición es mínima.
Aun así, te recomendamos usar la App en redes de confianza.

## 9. Cambios en esta Política
Podemos actualizar esta Política ocasionalmente. Publicaremos la versión vigente en
esta misma dirección e indicaremos la fecha de "Última actualización".

## 10. Contacto
Si tenés preguntas sobre esta Política de Privacidad, escribinos a:
**⟦TU EMAIL DE CONTACTO⟧**

---

## 🔧 Notas para la implementación
- ✅ **G3 ya aplicado:** la sección 4 fue actualizada: se quitó `MANAGE_EXTERNAL_STORAGE`
  y el almacenamiento clásico quedó solo para Android ≤9.
- Si **G6** reemplaza el permiso de ubicación por `NEARBY_WIFI_DEVICES` (Android 13+),
  ajustar la redacción de la sección 4 (hoy menciona ambos casos).
- El formulario **Data Safety** de Play Console debe responderse coherente con esto:
  "No se recopilan ni comparten datos del usuario".
