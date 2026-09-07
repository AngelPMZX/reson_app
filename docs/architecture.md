# Arquitectura propuesta

Organización por funcionalidad con capas: presentation -> application -> domain.
Data implementa los contratos de repositorio de domain. Domain no importa Firebase.
Riverpod compone dependencias y observa streams; no se necesita generación de providers.
Usar flutter_localizations + gen-l10n, ARB inglés/español.

- app: raíz, navegación y composición.
- core: Firebase, errores y conversión de temas.
- features/auth: sesión y cuenta.
- features/cards: CRUD privado, selección activa y personalización.
- features/sharing: publicación y representación del QR.

Los providers de tarjetas dependen del UID autenticado y se descartan al cambiar
la sesión. Un StreamProvider observa users/{uid}/cards. La selección activa apunta
a un cardId propio; si desaparece se elige otra tarjeta o el tema predeterminado.
El MaterialApp observará el tema de esa tarjeta. Validar #RRGGBB y derivar colores
de texto con contraste adecuado, sin aplicar colores arbitrarios a todo el texto.

# Firestore propuesto (todavía no desplegado)

users/{uid}
- displayName: string
- preferredLocale: en | es
- activeCardId: string | null
- createdAt, updatedAt: Timestamp
- schemaVersion: 1

users/{uid}/cards/{cardId}
- ownerId: uid (inmutable)
- label: Corporativo | Freelance | etiqueta personalizada
- identity: { displayName, jobTitle, company, bio }
- contact: { email, phoneE164, website }
- links: lista acotada de { label, url }
- theme: { primaryHex, secondaryHex, backgroundHex, brightness }
- assets: { logoPath, bannerPath }
- createdAt, updatedAt: Timestamp
- schemaVersion: 1

users/{uid}/publications/{cardId} (solo backend escribe)
- publicId: identificador aleatorio opaco estable
- publishedAt: Timestamp

publicCards/{publicId} (proyección publicada; solo backend escribe)
- identity, contact, links: solo campos elegidos para compartir
- theme, assets: solo elementos publicados
- updatedAt: Timestamp
- schemaVersion: 1

Reglas futuras: denegar por defecto. En users y cards exigir sesión y coincidencia
request.auth.uid == uid del path. Al crear cards exigir ownerId == uid y al
actualizar impedir cambios a ownerId y createdAt. Validar campos permitidos, tipos,
longitudes y colores. activeCardId debe ser null o referir una tarjeta propia.
Publications: lectura del dueño, sin escrituras del cliente. PublicCards: lectura
individual pública (get), sin list ni escrituras del cliente.

Firestore entrega documentos completos: separar los datos privados de lo público.
Una callable Function publica o retira la proyección en transacción, verifica la
sesión, deriva uid del token y comprueba propiedad. Admin SDK omite las reglas:
estas comprobaciones deben existir en el backend. No aceptar ownerId del cliente
como prueba de propiedad. El servidor conserva publicId entre republicaciones.
Retirar o borrar la tarjeta debe eliminar su proyección pública y sus assets
publicados; borrar un documento no elimina automáticamente sus subcolecciones.

Storage: users/{uid}/cards/{cardId}/{assetId}, acceso privado del dueño, límites
de tamaño y MIME de imágenes. El backend copia solo los assets elegidos a una ruta
pública por publicId. Evitar publicar URLs con token de descarga de assets privados.

# Intercambio

El QR contiene https://<dominio>/p/{publicId}. Un endpoint HTTPS sirve HTML público
y /p/{publicId}/contact.vcf genera vCard 3.0 UTF-8 con escape, CRLF y plegado de
líneas. Enviar Content-Type text/vcard y Content-Disposition attachment. El sistema
operativo decide si descarga o muestra la importación; no garantizar guardado automático.
Servir solo la proyección pública y responder 404 si se retiró. Evitar cachés que
mantengan accesible una tarjeta retirada. No se requiere escáner dentro de la app.
cloud_functions permitirá solicitar publicación desde Flutter; el endpoint HTTP
y su despliegue son trabajo posterior. No se ha desplegado backend ni sitio web.

Estos perfiles comparten dueño, no son tenants empresariales con miembros. Si se
agregan equipos, modelar organizations y memberships explícitamente.
