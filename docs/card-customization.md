# Personalización de tarjetas y fotografías

## Incluido
- Tema morado claro/oscuro con preferencia local persistente.
- Estilos Firma, Minimalista e Impacto; perfiles Trabajo, Freelance y Personal.
- Vista previa inmediata, retrato e iniciales, biografía y visibilidad por campo.
- Las recomendaciones son sugerencias locales por tipo, no llamadas a IA.
- Cambiar una plantilla no borra datos. Ocultarlos solo afecta a la presentación.
- Las tarjetas anteriores se leen con valores predeterminados. Los nuevos atributos
  son opcionales dentro del esquema v1; no hace falta migrar los documentos.

## Actualizar Firebase antes de guardar el diseño
En Firebase Console > Firestore Database > Reglas, reemplaza las reglas por
el contenido de `firestore.rules` y pulsa Publicar. Las reglas previas rechazan
los atributos de personalización nuevos. Conservamos la restricción por UID y
correo verificado. No se habilita la lectura pública.

## Fotografías
1. En Firebase Console > Storage, activa el bucket del proyecto reson-app.
2. Storage requiere el plan Blaze. Revisa el plan y los costes antes de activarlo;
   esta implementación no cambia la facturación.
3. En Storage > Reglas, publica el contenido de `storage.rules`.
4. Elige una foto JPG, PNG o WebP de hasta 3 MB en el editor y guarda la tarjeta.

Alternativa CLI, desde este proyecto y con la cuenta autorizada:
```
firebase deploy --only firestore:rules,storage --project reson-app
```
La CLI requiere que la base y el bucket ya existan.

En Chrome, getData puede requerir CORS del bucket. Si la consola del navegador
muestra un error CORS, configura los orígenes concretos del desarrollo y producción
con el procedimiento oficial. No se usa una URL pública de descarga:
https://firebase.google.com/docs/storage/flutter/download-files

Los archivos se guardan en users/{uid}/cards/{cardId}/{assetId}.
Solo el propietario verificado puede descargarlos; cada reemplazo crea un objeto
inmutable. Quitar la foto elimina la referencia de la tarjeta, no el objeto del
bucket. Antes de producción se necesita limpieza programada de objetos sin
referencias; no se borran durante una escritura fallida cuyo resultado es incierto.
Los objetos seleccionados no se suben hasta pulsar Guardar.
Los bytes descargados se mantienen en un provider autoDispose ligado a la sesión.

El selector usa la galería. iOS incluye la explicación de permiso en Info.plist.
No se han compilado Android ni iOS en este equipo. Storage remoto y las reglas
no se han validado con una carga real ni con el emulador en este cambio.

## Verificación local
```
flutter analyze
flutter test
flutter run -d chrome
```
Las pruebas usan repositorios falsos y no crean cuentas ni envían correos.
La publicación web/vCard sigue siendo otro módulo: ocultar un campo aquí no
publica ningún documento de Firestore.

Referencia de requisitos de Storage:
https://firebase.google.com/docs/storage/faqs-storage-changes-announced-sept-2024
