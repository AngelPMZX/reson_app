# Perfiles profesionales, Google y próximos módulos

## Incluido en esta actualización
- Experiencia y educación: hasta cuatro entradas de cada tipo por tarjeta.
- Puesto/título, empresa/institución, periodo libre y descripción.
- Ubicación, LinkedIn (solo HTTPS en linkedin.com) y habilidades separadas por comas.
- Visibilidad por sección. Ocultar no borra el dato.
- Trayectoria desplegable debajo de la tarjeta, con enlaces de LinkedIn funcionales.
- Registro renovado, entrada animada, repetición de la animación y botón de Google.
- Ocho estilos: Firma, Minimalista, Impacto, Aurora, Ejecutiva, Editorial, Noir y Estudio.
- Movimiento de entrada, respuesta al pulsar Google, expansión de trayectoria y
  transición al añadir/eliminar entradas. Se respeta reducir movimiento del sistema.

## Firebase
El archivo local anterior de Firestore contenía texto duplicado y no compilaba.
Se reconstruyó y validó con Firebase Emulator: lectura privada, correo verificado,
campos válidos, rechazo de entradas inválidas y máximo de cuatro entradas por sección.
Estas pruebas usan demo-reson; no tocan usuarios, documentos ni reglas de reson-app.

Publica el contenido completo de firestore.rules en Firebase Console > Firestore >
Reglas. También puedes usar una sesión propia de Firebase CLI:
```
firebase deploy --only firestore:rules --project reson-app
```
La publicación remota no se ha realizado desde esta sesión.

## Google: web
El usuario confirmó que el proveedor está habilitado. La app usa signInWithPopup
directamente desde el botón y conserva la protección de correo verificado del router.
No se crea un registro paralelo en Firestore ni se fusionan cuentas manualmente.
Cancelar el selector devuelve el control al formulario. Se muestran errores de
ventanas bloqueadas, dominios no autorizados y conflictos con otros proveedores.

Prueba en Chrome con tu cuenta. Si aparece un error de dominio, añade exactamente
localhost y/o 127.0.0.1 en Authentication > Settings > Authorized domains.
No basta con que Firebase Console esté abierto: la sesión de la aplicación es distinta.
El flujo de UI se probó con repositorios falsos; no se ha completado un login real
con Google desde el agente.

## Google: Android e iOS (configuración pendiente)
Los archivos cliente existentes no incluyen IDs OAuth. Después de habilitar Google:
1. Android: registra SHA-1/SHA-256 de debug y de producción cuando corresponda;
   descarga de nuevo google-services.json de com.thedarkingstudios.reson.
2. iOS: descarga de nuevo GoogleService-Info.plist del mismo bundle.
3. Copia ambos archivos en sus ubicaciones actuales.
4. Android usa el client_id de tipo 3 (web) de oauth_client como GOOGLE_WEB_CLIENT_ID.
5. iOS necesita CLIENT_ID como GOOGLE_IOS_CLIENT_ID y REVERSED_CLIENT_ID registrado
   en CFBundleURLTypes/CFBundleURLSchemes de ios/Runner/Info.plist.
6. Ejecuta con las definiciones GOOGLE_WEB_CLIENT_ID y, en iOS,
   GOOGLE_IOS_CLIENT_ID y GOOGLE_IOS_READY=true.

GoogleOAuthConfig centraliza estos IDs públicos. La guardia de iOS evita invocar el
SDK antes de configurar el URL scheme; no desactives la guardia sin completarlo.
No se han probado compilaciones móviles. Los identificadores OAuth no son
contraseñas; no hacen falta claves administrativas para esta configuración.

Referencias oficiales:
- https://firebase.google.com/docs/auth/flutter/federated-auth
- https://pub.dev/packages/google_sign_in
- https://pub.dev/packages/google_sign_in_android
- https://pub.dev/packages/google_sign_in_ios

## Pruebas de reglas reproducibles
Requiere Node.js compatible con firebase-tools y Java 21 en PATH.
```
npm ci --prefix tools/firestore-tests
tools/firestore-tests/node_modules/.bin/firebase emulators:exec --only firestore --project demo-reson --config firebase.emulators.json "node --test tools/firestore-tests/rules.test.cjs"
```
En PowerShell utiliza firebase.cmd en la última ruta. El JRE local de .tools y
node_modules están ignorados por Git; no forman parte de la app distribuida.

## Ideas para atraer usuarios (propuestas, todavía sin implementar)
1. Primero terminar QR, perfil público y vCard: la utilidad principal es intercambiar
   un contacto sin pedirle a la otra persona instalar la aplicación.
2. Portafolio breve: tres proyectos con imagen, resultado y enlace. Más concreto que
   convertir cada tarjeta en un currículum largo.
3. Modo evento: una tarjeta temporal con el contexto del evento y un recordatorio
   personal para dar seguimiento; publicaciones y mensajes siempre explícitos.
4. Agenda de contactos con notas privadas y etiquetas, sin importar libretas
   automáticamente ni enviar mensajes sin permiso.
5. Botón de acción elegido por el propietario: agendar reunión, ver portafolio,
   escribir o descargar CV.
6. Plantillas por profesión para reducir el esfuerzo de completar un perfil.
7. Equipos B2B: identidad corporativa consistente y gestión de altas/bajas.

Priorización sugerida: intercambio real -> portafolio/acción -> seguimiento ->
equipos. Validar con usuarios antes de convertir la personalización en un pago.
