# Verificación de guardado — 2026-09-13

La versión desplegada de Firestore (2026-09-07) solo permitía las claves de la primera versión de tarjetas. Rechazaba kind, layout, bio, photoPath, visibleFields y professional. Se respaldó esa versión en build/diagnostics/deployed-firestore.rules y se publicó firestore.rules del proyecto en reson-app.

Validación:
- Siete pruebas del emulador aprobadas, incluyendo aislamiento por propietario, correo verificado, campos profesionales y creación atómica de perfil y tarjeta.
- Prueba real en Chrome con Firebase Auth y FirestoreCardsRepository de Flutter: creación de tarjeta Studio en 1727 ms; edición y lectura explícita Source.server confirmadas en 2483 ms acumulados.
- Se utilizó una cuenta temporal independiente y se eliminaron su tarjeta, perfil y cuenta al terminar. No se modificaron cuentas ni tarjetas existentes.
- Esta prueba no incluyó subir una fotografía.

Para futuros cambios de esquema, validar las reglas y desplegarlas junto con los campos nuevos del cliente:

```powershell
.\tools\firestore-tests\node_modules\.bin\firebase.cmd deploy --only firestore:rules --project reson-app
```

No es necesario ampliar los tiempos de espera para resolver esta incompatibilidad de reglas. La respuesta HTTP 200 del servidor de desarrollo solo comprueba que entrega la página, no que Firebase acepte una escritura.

## Corrección posterior: subida de fotografías

La prueba anterior no cubría fotografías. La revisión autenticada del 2026-09-13 confirmó:
- GET del bucket reson-app.firebasestorage.app: 404, bucket inexistente.
- Listado de buckets del proyecto: vacío.
- billingEnabled: false.

Por lo tanto, la corrección de Firestore no bastaba para tarjetas con una foto nueva. Las subidas quedan deshabilitadas por defecto mediante RESON_PHOTO_UPLOADS_ENABLED. El formulario informa de la disponibilidad y el repositorio rechaza inmediatamente intentos de subida mientras esté desactivada. Un error de fotografía se muestra junto al guardado y ofrece guardar sin la foto nueva; no elimina una fotografía previamente guardada al editar.

Para habilitar fotos: activar Blaze explícitamente desde la consola, crear el bucket de Firebase Storage, publicar storage.rules y verificar subida/lectura privada en Chrome y móvil. Configurar CORS para la lectura web si es necesario. Solo después ejecutar con --dart-define=RESON_PHOTO_UPLOADS_ENABLED=true. No se activó facturación automáticamente.

## Storage habilitado y probado

El usuario activó Blaze y creó reson-app.firebasestorage.app en US-CENTRAL1. Se publicaron storage.rules privadas y se aplicó config/storage.cors.json. Fotografías habilitadas por defecto; RESON_PHOTO_UPLOADS_ENABLED=false sigue disponible para entornos sin Storage. Chrome usa el puerto 5211 en VS Code; otros orígenes deben añadirse expresamente a CORS.

Prueba real con los repositorios Dart de producción, Firebase y Chrome: subida PNG 1246 ms; descarga idéntica en bytes, guardado de tarjeta con photoPath y lectura Source.server confirmadas en 3719 ms acumulados. Descargar la imagen sin sesión fue rechazado. Cuenta, imagen y tarjeta temporales eliminadas tras la prueba. Doce pruebas del formulario aprobadas y flutter analyze sin incidencias. La prueba del navegador utilizó un PNG pequeño de diagnóstico; no es una medición de rendimiento para fotografías grandes.
