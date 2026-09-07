# Activar las tarjetas privadas

## Consola Firebase: paso pendiente del propietario

1. En reson-app, abrir Firestore Database y Crear base de datos.
2. Elegir Standard, base (default), modo de producción. Ubicación propuesta:
   us-central1. La ubicación no se puede cambiar después de crear la base.
3. En Reglas, reemplazar las reglas iniciales con el contenido de firestore.rules
   de la raíz de este proyecto y pulsar Publicar. Esta instrucción aplica a la
   base nueva y vacía; no sobrescribir reglas de otra aplicación o base con datos.
4. Reiniciar Reson, confirmar el correo y crear una tarjeta.

No se han desplegado reglas desde esta sesión. El archivo firebase.json permite
usar Firebase CLI posteriormente: firebase deploy --only firestore:rules --project reson-app.
El CLI necesitará que el propietario inicie sesión.

## Flujo implementado

Firebase Authentication crea un usuario pendiente. Las rutas privadas exigen
emailVerified. La pantalla /verify-email envía un enlace, permite reenviarlo
después de 60 segundos y tiene una comprobación explícita. Al comprobar se recarga
el usuario y se renueva el token. Solo entonces se abre /home.

El repositorio también verifica UID y la claim email_verified del token antes de
consultar/escribir. Las reglas publicadas serán la protección definitiva frente a
clientes modificados: exigen propietario y email_verified en cada operación.

users/{uid} se crea junto con la primera tarjeta en una transacción, después de
verificar el correo. Contiene displayName, activeCardId, schemaVersion y timestamps.
No se crea un perfil de Firestore mientras la cuenta está pendiente.

users/{uid}/cards/{id} contiene:
- ownerId, label, schemaVersion, createdAt, updatedAt.
- identity: displayName, jobTitle, company.
- contact: email, phone, website.
- theme: primaryHex (#RRGGBB).

Crear/editar es transaccional. Reintentar un guardado en el mismo formulario
reutiliza el ID para evitar duplicados. El listado se actualiza en tiempo real.
La tarjeta activa se guarda en users/{uid}. Al salir se descartan las suscripciones
y el tema. No se habilitan lecturas públicas ni borrado en esta fase.

Las reglas validan campos permitidos, tamaños, ownerId inmutable, timestamps,
hexadecimal y que la selección activa apunte a una tarjeta propia.

## Validación

flutter test cubre navegación bloqueada, verificación, reenvío, formularios,
crear/editar, selección activa y cierre de sesión con repositorios de prueba.
Las pruebas no envían correos ni escriben en Firestore real.
Las reglas todavía no se han ejecutado contra el emulador: este equipo no tiene
Java disponible. Antes del lanzamiento deben verificarse en el emulador los casos
anónimo, no verificado, dueño verificado, otro usuario, campos extra, cambio de
propiedad y referencia a una tarjeta ajena. firebase.json prepara el puerto 8080.

Pendiente validar el guardado real tras crear la base y publicar las reglas.
Logotipos/banners, enlaces públicos, vCard y QR son etapas posteriores.
