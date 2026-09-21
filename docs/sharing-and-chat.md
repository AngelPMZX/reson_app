# Compartir tarjetas y conectar

La versión web está publicada en https://reson-app.web.app.

## Recorrido del usuario

1. En una tarjeta, abre **Compartir / QR** y selecciona los datos que quieres publicar.
2. Publica para obtener un enlace y un QR. Las tarjetas permanecen privadas hasta esta acción.
3. Cualquier visitante puede ver el enlace sin instalar Reson, descargar el contacto
   en formato vCard y utilizar las opciones de contacto que hayas publicado.
4. Con una cuenta verificada de Reson puede guardar la tarjeta en **Mi red** o
   solicitar una conexión, eligiendo una de sus propias tarjetas publicadas.
5. La persona destinataria acepta o rechaza. El chat se habilita tras aceptar.

Editar una tarjeta privada no cambia automáticamente su versión pública:
hay que actualizar la publicación. Despublicar desactiva el enlace, la vCard
y la fotografía pública; no puede retirar copias ya descargadas por visitantes.

En **Mi red** se puede activar un sonido original breve al aceptar una conexión.
Está desactivado por defecto. Las animaciones respetan la preferencia de reducir
movimiento. El sonido depende de las restricciones de reproducción del navegador.

## Arquitectura

- Flutter: `lib/features/network`, separado en servicio, compartir, recibir, red y chat.
- Cloud Functions: `socialAction` valida las acciones autenticadas y verificadas;
  `getSharedCard` devuelve exclusivamente datos publicados; `sharedCard` sirve HTML,
  fotografía y vCard a través de Firebase Hosting.
- `users/{uid}/publications`: metadatos de publicaciones del propietario.
- `users/{uid}/received`: tarjetas guardadas por ese usuario.
- `publicCards/{id}`: instantánea con campos permitidos; acceso directo del cliente denegado.
- `connections/{id}/messages`: conversaciones con acceso limitado a miembros aceptados.
- `users/{uid}/blocks`, `reports` y `socialLimits`: protección y control del backend.

Las escrituras sociales pasan por funciones, con comprobación de pertenencia,
verificación de correo, límites de frecuencia e idempotencia de mensajes.
La fotografía pública es una copia sin token de descarga, servida únicamente
mientras la publicación esté activa. Nunca se expone la ruta privada original.

El menú del chat permite bloquear y reportar. Los reportes quedan registrados para
revisión administrativa; todavía no hay una consola de moderación ni respuesta automática.
El chat es de texto y se actualiza con la aplicación abierta. No incluye aún
notificaciones push, adjuntos, confirmaciones de lectura ni cifrado de extremo a extremo.

## Desarrollo y despliegue

Instala dependencias con `flutter pub get` y `npm ci --prefix functions`.
El backend utiliza Node.js 22 y Firebase Blaze. Desde una CLI de Firebase autenticada:

```sh
flutter analyze
flutter test
flutter build web --release
firebase deploy --only functions,firestore:rules,storage,hosting --project reson-app
```

Las funciones están en `us-central1`, con máximo de tres instancias por función.
Artifact Registry elimina artefactos de compilación con más de siete días.

Las pruebas de reglas y backend usan Firestore Emulator con el proyecto `demo-reson`.
`functions/test/domain.test.js` comprueba redacción de datos, HTML y vCard.
`test/social_flow_test.dart` cubre publicación explícita, regreso al enlace tras
autenticación y aceptación de una solicitud.

`tools/social-live-smoke.cjs` es una prueba optativa contra Firebase real: requiere
`RESON_LIVE_SMOKE=1`, sesión de Firebase CLI y permisos administrativos. Crea tres
cuentas temporales, comprueba publicación/foto/vCard, conexión/chat, denegación de
acceso ajeno, bloqueo y revocación. Elimina sus propios datos en `finally`.
No debe ejecutarse automáticamente en cada build. Las pruebas habituales de Flutter
no crean cuentas ni envían correos.
