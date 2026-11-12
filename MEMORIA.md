# Memoria de Reson

Actualizada: **11 de noviembre de 2026**. Referencia de continuidad para el propietario y para nuevos chats de desarrollo. Describe el estado del código al preparar el commit que incluye este archivo; no contiene contraseñas, tokens ni claves administrativas.

## 1. Qué estamos construyendo

**Reson**, de **TheDarkingStudios**, es una aplicación principalmente móvil de identidad profesional, tarjetas digitales y networking. La dirección del producto es una red profesional propia, inspirada en la utilidad de LinkedIn, centrada en intercambiar tarjetas y conectar personas. Una cuenta puede representar varias facetas: trabajo, freelance y personal.

El usuario quiere código mantenible, arquitectura escalable, una experiencia elegante y animaciones cuidadas. Prefiere implementar las ideas directamente y probarlas; no quedarse solamente en propuestas. Español e inglés desde el inicio. La web permite desarrollar en Windows, probar en Chrome y compartir tarjetas con visitantes que no tienen la app.

La última versión fue aceptada visualmente por el usuario. El último pedido es guardar esta memoria y hacer commit/push de toda la versión actual. No rehacer el diseño por defecto al iniciar otro chat.

## 2. Repositorio, equipos y entornos

- Repositorio del proyecto: **https://github.com/AngelPMZX/reson_app**; se utiliza como repositorio privado del usuario.
- Remoto `origin`: `https://github.com/AngelPMZX/reson_app.git`.
- Rama actual: `main`.
- Último commit de esta entrega: `4945c25` (`Let a refusal be undone, and settle the chrome into the system`), ya en `origin/main`. La versión vieja se sustituyó hace tiempo en `75b85ee`; no hace falta borrar ni forzar historia.
- Carpeta en esta PC: `C:\Proyectos\reson_app`.
- Windows, PowerShell, VS Code con Flutter/Dart.
- Flutter local: `C:\flutter-sdk\flutter`; versión usada **3.41.6**, Dart **3.11.4**.
- Desarrollo web: **http://127.0.0.1:5211**. Un servidor local puede no seguir ejecutándose después de cerrar la sesión: comprobarlo, no asumirlo.
- Aplicación publicada: **https://reson-app.web.app**.
- Dominio alternativo de Firebase: `reson-app.firebaseapp.com`.
- Web usa rutas con hash, por ejemplo `/#/home`; los enlaces públicos usan `/c/<id>` sin hash.
- Clonar Git no copia las sesiones ni datos de Firebase. Cada equipo inicia sesión por separado en Firebase CLI y GitHub. Los datos reales se mantienen en el mismo backend.

## 3. Tecnologías y versiones fijadas

Fuente de verdad: `pubspec.yaml`, `pubspec.lock` y los respectivos `package-lock.json`. Mantener los lockfiles.

| Componente | Versión / uso |
| --- | --- |
| Flutter / Dart | 3.41.6 / 3.11.4; constraint Dart >=3.11.4 <4.0.0 |
| flutter_riverpod | 3.3.2; estado, streams de sesión y repositorios |
| go_router | 17.5.0; navegación y guardias de autenticación |
| flutter_localizations / intl | SDK Flutter / 0.20.2; ES y EN |
| firebase_core | 4.14.0 |
| firebase_auth | 6.6.1 |
| cloud_firestore | 6.9.0 |
| firebase_storage | 13.5.0 |
| cloud_functions | 6.4.0 |
| google_sign_in | 7.2.0 |
| image_picker | 1.2.3 |
| audioplayers | 6.5.1; sonido opcional de conexión |
| qr_flutter | 4.1.0 |
| shared_preferences | 2.5.5; preferencias locales |
| url_launcher | 6.3.2 |
| flutter_lints | 6.0.0 |
| Functions runtime | Node.js 22; backend JavaScript CommonJS |
| firebase-admin / firebase-functions | 14.4.0 / 7.4.0 |
| Herramientas de reglas | firebase-tools 15.30.0, firebase 12.19.0, rules-unit-testing 5.0.2 |

Override temporal: **firebase_core_web 3.10.0**, por compatibilidad con Dart 3.11, referenciado en `pubspec.yaml` a flutterfire issue 18611. Revisarlo al actualizar Flutter; no quitarlo a ciegas. Audioplayers 6.5.1 se eligió por compatibilidad: una versión más reciente requería un Flutter posterior. Node local utilizado para algunas pruebas era 24.14.1; para Functions mantener runtime 22.

## 4. Estructura y responsabilidades

```text
lib/
  main.dart                         Arranque
  firebase_options.dart             Configuración cliente de Firebase
  app/reson_app.dart                 Router, sesión, temas e idioma
  app/reson_shell.dart               Barra inferior y carril lateral de los cuatro destinos
  core/
    firebase/firebase_bootstrap.dart Inicialización y providers de Firebase
    firebase/google_oauth_config.dart IDs OAuth públicos vía dart-define
    theme/reson_palette.dart        Paleta central
    theme/reson_theme.dart          Temas claro/oscuro, apariencia e idioma
    theme/reson_chrome.dart         Cabecera compartida y controles globales
    theme/reson_tokens.dart         ResonMotion y ResonCredentials
    theme/reson_surfaces.dart       ResonType, ResonSpace, ResonRadius, ResonSurfaces
    theme/reson_motion.dart         ResonPanel, ResonNotice, ResonReveal, ResonStagger
    theme/reson_skeleton.dart       Esqueletos de carga
  features/
    auth/
      domain/auth_repository.dart
      data/firebase_auth_repository.dart
      presentation/                 Intro, registro, login, recuperación, verificación
    cards/
      domain/                       DigitalCard, ProfessionalProfile y contratos
      data/                         FirestoreCardsRepository y CardMediaRepository
      application/cards_providers.dart
      presentation/                 Home, editor, credenciales, cartera, trayectoria
    profile/                        Perfil: vista, editor, repositorio y avatar
    network/
      network_service.dart          Callables y providers de Firestore
      network_widgets.dart          Shell y paneles compartidos
      share_card_page.dart          Selección de campos, publicar, QR, despublicar
      receive_card_page.dart        Recibir, guardar, solicitar conexión
      network_page.dart             Personas: solicitudes, conexiones, en pausa, guardadas
      messages_page.dart            Lista de conversaciones con búsqueda
      received_wallet.dart          Cartera de tarjetas recibidas con filtros
      chat_page.dart                Conversación, paginación, bloquear, reportar
    settings/settings_page.dart     Apariencia, idioma, sonido y cerrar sesión
  l10n/                             ARB ES/EN y código generado
functions/
  index.js                          Tres Cloud Functions y validaciones de acciones
  domain.js                         Proyección pública, URLs, HTML y vCard
  render.js                         HTML/CSS de tarjeta pública
  test/                             Pruebas unitarias y de integración social
test/                               Pruebas de Flutter
tools/firestore-tests/              CLI local y pruebas de reglas
tools/social-live-smoke.cjs          Prueba optativa en Firebase real
assets/sounds/connected.wav          Sonido original generado para Reson
config/storage.cors.json             Orígenes web autorizados para lectura de fotos
docs/                               Historial y guías por módulo
firestore.rules / storage.rules      Seguridad declarativa
firebase.json                       Rules, Functions y Hosting
firebase.emulators.json             Configuración aislada de pruebas
android/ ios/ web/ ...              Plataformas Flutter
```

**El backend JavaScript está formateado desde el 11/11/2026.** Estaba escrito como si fuera código minificado: `index.js` tenía 98 líneas con una de 496 caracteres, `domain.js` 15 líneas con una de 628 y `render.js` 12 con una de 1884 — y es el código crítico de seguridad del proyecto. Ahora pasa por Prettier (`functions/.prettierrc.json`, ancho 100): `npm run format` y `npm run format:check` dentro de `functions/`. Las líneas largas que quedan en `render.js` son el literal HTML/CSS de la página pública y deben seguir compactas. El reformateo se demostró sin cambio de comportamiento comparando el hash SHA-256 de 25 salidas reales (snapshot, vCard, HTML en ES y EN, safeUrl, connectionId, escapeHtml) antes y después: idéntico.

La arquitectura es por funcionalidades, con contratos/repositorios en auth y cards. Profile y network todavía agrupan parte de datos/presentación en menos archivos: es una base modular, no una arquitectura limpia exhaustiva. Mantener seguridad y lógica de publicación en backend; no moverlas al widget.

## 5. Firebase y configuración

- Proyecto: **reson-app**; número **1066611577415**.
- Firebase Authentication: email/contraseña y Google habilitados por el usuario.
- Cloud Firestore: tarjetas, perfiles, preferencias y red social.
- Cloud Storage: bucket **reson-app.firebasestorage.app**, región **US-CENTRAL1**.
- Plan **Blaze** activado por el usuario para Storage/backend. No es correcto documentar el proyecto como Spark o sin bucket actualmente.
- Cloud Functions: **us-central1**, Node 22, 256 MiB, timeout 30 s, máximo tres instancias por función.
- Functions desplegadas: `socialAction` (callable autenticada), `getSharedCard` (callable de lectura pública por ID), `sharedCard` (HTTP HTML/foto/vCard).
- Firebase Hosting sirve `build/web`; `/c/**` se reescribe a `sharedCard`, el resto a `index.html`.
- `index.html` usa Cache-Control no-cache; las respuestas de tarjeta pública usan no-store.
- Política de limpieza de imágenes de compilación de Artifact Registry: siete días, us-central1.
- No hay `.firebaserc` en el repositorio: pasar explícitamente `--project reson-app` al desplegar y `--project demo-reson` al probar emuladores.
- Configuración cliente: `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`. Sus identificadores/API keys cliente no son claves administrativas. No sustituirlos por cuentas de servicio.
- Identificadores actuales Android e iOS: **com.thedarkingstudios.reson**. Las capturas históricas mostraban `com.example...`; no usarlas como fuente de verdad.
- CORS versionado permite localhost/127.0.0.1 en puertos 5211 y 5212 y ambos dominios Firebase de producción, GET/HEAD. Otros puertos necesitan configuración explícita para fotos.
- Iniciar sesión en Firebase Console no autentica automáticamente Firebase CLI ni a los usuarios de Reson.
- Las reglas sociales, Functions y Hosting se desplegaron y probaron el 20/09/2026. Ante otra sesión, comprobar el estado remoto si se modificó desde Console.

No se guardan aquí tokens CLI, refresh tokens, passwords, JSON de servicio ni datos privados de usuarios. La CLI conserva su sesión fuera del repo. Hay exclusiones de `.env`, certificados, cachés, `.firebase`, `.tools`, `node_modules` y `build`.

## 6. Autenticación y rutas

Intro antes del login, registro email/contraseña, recuperación de contraseña y Google web. Las acciones muestran carga y errores traducidos. Google web usa popup desde un gesto del usuario.

Firebase **sí crea el usuario de Authentication antes de verificar el correo**. La solución aplicada no promete lo contrario: bloquea acceso a funciones privadas con router, repositorios y reglas hasta `emailVerified` y claim `email_verified`. Verificación tiene envío, reenvío con espera, recarga del usuario y renovación de token. Un correo ya verificado no requiere otra verificación en cada login.

Rutas: `/`, `/login`, `/register`, `/reset-password`, `/session`, `/verify-email`, `/home`, `/network`, `/messages`, `/profile`, `/profile/edit`, `/settings`, `/cards/new`, `/cards/:id/edit`, `/cards/:id/share`, `/receive/:id`, `/chat/:id`.

**`/home`, `/network`, `/messages` y `/profile` son los cuatro destinos de la barra** y viven en un `StatefulShellRoute.indexedStack`, una rama cada uno: cambiar de destino no tira el estado de los otros tres. Las demás rutas son pantalla completa, sin barra — el chat incluido, igual que en cualquier app de mensajería.

Al entrar por `/receive/:id` sin sesión se guarda el destino en memoria del router y se retoma después de login/verificación. El destino pendiente no es un sistema de deep links persistente entre cierres completos. Se quitaron redirecciones imperativas a home tras email login/registro para no perderlo.

Cerrar sesión vive en **`/settings`** desde el 11/11/2026, no en el perfil ni como acción principal del inicio. En el perfil quedó un enlace a Ajustes: allí estaba enredado con la guardia de cambios sin guardar del formulario.

Google Android/iOS todavía necesita completar OAuth y pruebas reales: SHA-1/SHA-256, archivos Firebase renovados, client IDs y URL scheme iOS. `GOOGLE_WEB_CLIENT_ID`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_IOS_READY=true` son dart-defines; no habilitar la guardia iOS antes de configurar REVERSED_CLIENT_ID en Info.plist. No se han validado builds nativos ni se debe asumir que Google móvil funciona por funcionar en web.

## 7. Perfil y tarjetas privadas

Perfil reutilizable: `users/{uid}/settings/identity`. Campos opcionales: nombre, puesto, empresa, bio, email de contacto, teléfono, web, idiomas, servicios, disponibilidad, trayectoria y preferencia de avatar. El correo de acceso verificado se muestra aparte: editar el email de contacto no cambia Authentication.

Avatar: foto propia JPG/PNG/WebP hasta 3 MB, foto del proveedor Google o iniciales. La foto Google se usa en perfil/home, pero no se copia su URL a una tarjeta privada. Una foto propia sí se reutiliza como referencia privada al crear tarjetas.

Una tarjeta nueva espera el perfil y lo usa como valores iniciales. Las tarjetas existentes conservan sus datos, no se sobreescriben al editar el perfil. Label y nombre visible son necesarios; el resto del contacto/trayectoria es opcional. Ocultar datos modifica `visibleFields`, no borra sus valores privados.

Tipos trabajo/freelance/personal; ocho layouts (signature/credencial, minimal, bold, aurora, executive, editorial, noir, studio; revisar enum/lista del editor al cambiarlos). Paletas predefinidas y color hexadecimal propio ya existen: todavía no hay cobro ni restricción premium por color.

Información profesional: sector, especialidad, modalidad, ubicación, LinkedIn, habilidades, experiencia, educación, proyectos y certificaciones. Hasta cuatro entradas por sección y ocho en total entre las listas profesionales. Los límites también se validan en reglas; editar el modelo exige adaptar reglas y pruebas. Los perfiles no equivalen todavía a una bolsa de empleo, buscador de profesionales o feed público.

## 8. Modelo de Firestore y Storage

| Ruta | Uso / acceso |
| --- | --- |
| `users/{uid}` | Preferencias, activeCardId, timestamps, schemaVersion; dueño verificado |
| `users/{uid}/settings/identity` | Perfil base opcional; dueño verificado |
| `users/{uid}/cards/{cardId}` | Tarjetas privadas; dueño verificado |
| `users/{uid}/publications/{cardId}` | Mapeo a ID público, revisión, label, active; cliente lee, servidor escribe |
| `users/{uid}/received/{publicId}` | Tarjetas guardadas con su instantánea completa y `active`; propietario lee, servidor escribe |
| `users/{uid}/blocks/{otherUid}` | Bloqueos; servidor administra |
| `publicCards/{publicId}` | Instantánea publicada y metadatos internos; sin acceso directo del cliente |
| `connections/{connectionId}` | Dos miembros, requester/recipient, estado, nombres, tarjetas, timestamps, `respondedAt`, `lastMessage {text, sender}` y `reads {uid: timestamp}` |
| `connections/{connectionId}/messages/{messageId}` | sender, text, createdAt; lectura solo miembros aceptados, escritura servidor |
| `directory/{uid}` | Entrada del buscador; solo de quien lo activó. Lectura: cuenta verificada. Escritura: servidor |
| `reports/{connectionId_uid}` | Reportes para administración; no lectura pública |
| `socialLimits/{uid}` | Límite de frecuencia backend |

Tarjeta privada: `ownerId`, `label`, `kind`, `layout`, `bio`, `professional`, `photoPath`, `visibleFields`, `identity {displayName, jobTitle, company}`, `contact {email, phone, website}`, `theme {primaryHex}`, `schemaVersion: 1`, `createdAt`, `updatedAt`.

Guardar usa transacción, conserva createdAt y crea preferencias del usuario si no existen. Selección activa valida que la tarjeta exista. Streams ordenan por createdAt. La pertenencia se valida tanto por ruta como por datos; no confiar en UID enviado por cliente.

Fotos privadas bajo `users/{uid}/...`, incluyendo `profile/{assetId}`. Objetos inmutables evitan cambiar fotos de tarjetas previas cuando se reemplaza el avatar. Acceso privado requiere dueño verificado. Copias públicas: `sharedPhotos/{publicId}/{revision}`, sin Firebase download token, servidas vía HTTP únicamente si la publicación está activa. No habilitar lectura pública del bucket.

## 9. Publicación, QR, vCard y contactos

1. Propietario abre Compartir / QR, elige campos y publica explícitamente.
2. Backend intersecta campos seleccionados con campos visibles privados y genera una instantánea saneada. Nombre y etiqueta son obligatorios. No filtra ownerId, rutas privadas ni datos ocultos en la respuesta pública.
3. Enlace aleatorio de 32 caracteres hex: `https://reson-app.web.app/c/<id>`; QR contiene ese enlace real, no localhost.
4. HTML público independiente de Flutter, adaptable a móvil, claro/oscuro, ES/EN (`?lang=en`), CSP, escape HTML, URLs HTTP/HTTPS validadas, noindex/nofollow.
5. `/c/<id>/photo` sirve la copia de foto y `/c/<id>/contact.vcf` descarga vCard 3.0 con escape y plegado UTF-8 de líneas.
6. Contacto sin cuenta: guardar vCard, correo, llamada, web, LinkedIn y WhatsApp opcional si el titular publica teléfono apropiado.
7. Guardar en Reson abre `/#/receive/<id>` y requiere cuenta verificada.

Actualizar datos privados no actualiza la publicación automáticamente. Hay botón de actualizar publicación. Despublicar desactiva HTML, foto y vCard, incrementa revisión y retira copia pública. El control de revisiones evita que una subida concurrente reactive una publicación retirada. No puede revocar una vCard/foto previamente descargada por un visitante.

La página pública tiene su propia composición; no pretende reproducir idénticamente todos los layouts Flutter. La lista pública de campos permitidos tiene 17 entradas y está centralizada en `functions/domain.js`.

## 10. Mi red y chat

Guardar una tarjeta y solicitar conexión son acciones distintas. Guardar no envía mensajes. Para solicitar conexión se elige una tarjeta propia ya publicada. El backend impide conectarse consigo mismo, valida ambos titulares y revisa bloqueos.

ID de conexión determinista: SHA-256 del par de UIDs ordenados. Estados pending, accepted, declined, blocked. Solo destinatario puede aceptar/rechazar la solicitud pendiente. Solicitudes existentes no generan duplicados.

**Rechazo y bloqueo dejaron de ser definitivos (11/11/2026).** Antes, un «Rechazar» tocado por error cerraba ese par de cuentas para siempre y `unblock` no existía en ninguna capa. Ahora:

- **El destinatario puede aceptar una solicitud que él mismo rechazó**, sin espera. Es la salida al toque accidental y no abre superficie de abuso: deshace su propia decisión.
- **El solicitante puede volver a pedir tras un rechazo**, pasado `RECONNECT_AFTER_MS` (**7 días**, constante en `functions/index.js`; cambiarla ahí). Evita insistencia inmediata sin convertir la negativa en permanente.
- **`unblock`** retira el bloqueo propio. Autoriza **tener** el bloqueo (`users/{uid}/blocks/{other}`), no un campo en la conexión: así nadie levanta un bloqueo ajeno y la conexión nunca registra quién bloqueó. Con bloqueo mutuo el par sigue cerrado hasta que ambos lo retiren.
- Reactivar conserva historia: `createdAt`, el hilo de mensajes y `lastMessageAt` sobreviven. `respondedAt` marca la última respuesta y alimenta la espera.

La máquina de estados vive como **política pura** en `functions/domain.js` (`requestOutcome`, `respondOutcome`), no dentro de las transacciones. Por eso se prueba sin emulador: 8 de las 12 pruebas de backend cubren sus ramas. Al cambiar reglas de conexión, cambiar esas funciones y sus pruebas, no el cuerpo de la transacción.

En la UI, `blockedProvider` lee la colección de bloqueos propia para ofrecer «Desbloquear» solo a quien bloqueó; a la otra parte le muestra «Conexión bloqueada» sin botón. Desbloquear es `OutlinedButton` a propósito: es una reparación, no la acción principal de la pantalla.

Chat de texto en tiempo real, habilitado tras aceptación. Mensajes de 1 a 2000 caracteres, ID cliente reutilizado en reintentos para evitar duplicados. Lectura descendente con 50 mensajes inicialmente y botón para aumentar el límite. Conexiones se filtran por membresía; escritura exclusivamente por callable. Límites: 40 acciones sociales/minuto/usuario y mínimo de 700 ms entre mensajes de la conexión. Errores conservan el borrador.

Bloquear detiene mensajes y nuevas solicitudes. Reportar registra motivo para revisión administrativa. No existe aún UI de desbloqueo, consola de moderación ni respuesta automática a reportes. El chat no ofrece todavía adjuntos, indicadores de escritura, leído/no leído, push o cifrado de extremo a extremo.

**Listas acotadas (11/11/2026).** Conexiones y recibidas se traían enteras y se ordenaban en el dispositivo: abrir Mi red costaba una lectura por cada contacto acumulado. Ahora piden **25 por página** (`networkPageSize`) y la pantalla ofrece «Ver más» (`NetworkMore`) cuando la página vuelve llena, para que acotar no esconda datos. El orden de conexiones pasó al servidor, lo que **exige el índice compuesto** de `firestore.indexes.json` — ver sección 14; sin desplegarlo, Mi red falla.

Sigue pendiente el **cursor real del chat**: hoy `limit += 50` recrea el stream, así que ver mensajes antiguos vuelve a leer los anteriores. Es una ventana acotada, no un desbordamiento, pero el coste por página crece. Conviene abordarlo junto al rediseño del chat.

### Cuatro destinos, no un solo scroll (11 de noviembre de 2026)

Pedido por el propietario: separar conexiones, chats y lo demás, con el aire de LinkedIn o Facebook. Se eligió **barra inferior de cuatro destinos**, que en pantalla ancha (≥760) pasa a carril lateral: `lib/app/reson_shell.dart`.

- **Inicio** `/home` — la cartera, sin cambios.
- **Mi red** `/network` — personas, con pestañas **Conexiones** y **Guardadas**. Dentro de Conexiones: solicitudes, conexiones y «en pausa». Ya no contiene conversaciones.
- **Mensajes** `/messages` — pantalla nueva, con buscador por nombre, avatar, último mensaje, hora relativa, negrita y punto para lo no leído. **Insignia con el total** en la barra.
- **Perfil** `/profile`.

El chat es pantalla completa, fuera de la barra, y vuelve a `/messages`. Tras bloquear sale a `/network`, porque un hilo bloqueado ya no pertenece a Mensajes.

Se quitaron los accesos que la barra sustituye: el botón «Mi red · Conexiones y chats» del inicio, el «Volver a mis tarjetas» del perfil y el de `NetworkShell` (parámetro `back`, falso en los destinos).

**Trampa de Riverpod que costó encontrar**: `unreadCountProvider` deriva de `connectionsProvider`, y un provider que nadie sobreescribe **se crea en el contenedor raíz**. En una prueba con `ProviderScope` anidado, la pantalla leía los datos del scope anidado mientras la insignia leía los vacíos del raíz. Por eso `launch()` en `test/auth_flow_test.dart` acepta `connections` y `networkService` y los aplica **en el contenedor**, no en un scope anidado. Si algo derivado aparece vacío en una prueba, es esto.

Esa misma barra montó los streams de Firestore en **todas** las pantallas, no solo en la de red: `launch()` los sobreescribe por defecto o cada prueba acaba con el temporizador de reintento de Riverpod pendiente y no asienta nunca.

### Una conversación se ve (11 de noviembre de 2026)

El propietario reportó que los mensajes «parecían no funcionar». **No había nada roto: faltaba todo el feedback.** No existía ningún indicador de mensajes en ninguna parte —ni no leídos, ni vista previa, ni hora— y `lastMessageAt`, que el backend ya guardaba, no se mostraba nunca. Enviabas un mensaje, volvías atrás y la fila decía «Conexión aceptada» junto a un iconito, exactamente igual que si no hubieras escrito nada.

- La acción `message` guarda ahora `lastMessage {text, sender}` en la conexión, recortado por `preview()` en `domain.js`: una línea, sin saltos, máximo 120 caracteres.
- Nueva acción **`markRead`**: mueve solo `reads.{uid}` del que lee y **no toca `updatedAt`**, para que leer un hilo no reordene la lista del otro. El chat la llama al abrirse y traga el error en silencio: un punto de no leído no merece un mensaje de error.
- No leído = hay `lastMessage`, no lo mandé yo, y `reads[uid]` falta o es anterior a `lastMessageAt`.

**Mi red se reorganizó en secciones.** Antes era un scroll único con un ajuste de sonido arriba, luego las cuatro clases de conexión mezcladas en una lista y al final las tarjetas. Ahora:

- **Solicitudes**, solo si las hay, separando «quiere conectar contigo» de «esperando respuesta».
- **Conversaciones**: la fila entera abre el chat, con avatar, último mensaje, hora relativa (`shortMoment`) y punto de no leído. Ya no es un icono de 24px.
- **Tarjetas recibidas**.
- **En pausa**, al final y solo si hay algo: rechazadas y bloqueadas, con su botón de recuperación.

El ajuste de sonido se fue a `/settings`; estaba por encima de las solicitudes de otras personas.

Mi red muestra solicitudes, estados y tarjetas recibidas. Al aceptar hay una animación y diálogo de éxito; sonido original opcional (`assets/sounds/connected.wav`, 0.65 s), desactivado por defecto y almacenado como `connectionSound`. El navegador puede impedir reproducir audio; eso no invalida la conexión.

## 11. Diseño vigente

La evolución fue morado -> credenciales -> rojo -> cartera refinada. **El diseño actual aceptado es carmín/grafito**, no regresar al morado como marca principal.

Paleta central: carmín `#C8102E`, rojo brillante `#EF4057`, vino `#650D1B`, vino profundo `#300B12`, carbón `#101012`, grafito `#1D1D20`, marfil `#FAF9F7`, blanco. Los colores propios de cada tarjeta siguen siendo personalizables, pero no recolorean arbitrariamente toda la app.

Home con cartera de pases superpuestos, hasta tres visibles, selección por cabeceras, botones y swipe para recorrer todas. Debajo se presenta detalle de tarjeta seleccionada. Filtro por tipo y tarjeta activa son conceptos independientes. Diseño tipo credencial, foto/identidad/jerarquía visual; trayectoria expandible.

Animaciones de entrada, cartera, selección, expansiones, formularios y conexión. Respetar `disableAnimations`/reducir movimiento. Controles globales de tema e idioma arriba a la derecha: dejar espacio en nuevas pantallas, como en AppBar del chat, para evitar superposición en móvil.

### Sistema de diseño en el tema (noviembre 2026)

`lib/core/theme/reson_tokens.dart` define dos `ThemeExtension` registradas en `ResonTheme.forSeed`:

- **`ResonMotion`**: seis duraciones por intención (`press` 150, `expand` 320, `transition` 420, `entrance` 650, `meter` 800, `showcase` 1200), curvas nombradas y `deckSpring`, el resorte de la cartera. Antes había diez duraciones sueltas, cada una usada una sola vez. Leer siempre por `context.motion`, que ya devuelve cero cuando el dispositivo pide movimiento reducido: no repetir el ternario de `disableAnimationsOf`.
- **`ResonCredentials`**: geometría del mazo (`passFace`, `passStep`, `passInset`, `passElevation`, radios) y un `ResonCredentialSkin` por cada uno de los ocho layouts, con `ink`, `muted`, `backdrop`, `blend`, `surface` y `accent`.

**Trampa conocida**: `AnimatedSize` se re-ensucia durante su propio layout si recibe `Duration.zero`. Con movimiento reducido hay que **quitar el widget**, no ponerle duración cero. Comprobar `motion.isStill`. Ya mordió en la cartera y en el editor de trayectoria; hay pruebas de regresión en `test/reduced_motion_test.dart`.

Las credenciales ya **no conservan neutros lavanda**: los ocho layouts usan neutros cálidos derivados del carmín, nombrados en `ResonPalette` (`roseVeil`, `roseMist`, `wineInk`, `wineGrey`, `wineShadow`, `nightWine`, `duskWine`, `parchment`, `studioInk`…). No quedan colores crudos en `card_preview.dart` ni en `credential_card.dart`. Los **17 presets de color que ofrece el editor siguen siendo variados a propósito**: son la elección del titular, no la marca.

### Repolish y cabecera compartida (11 de noviembre de 2026)

Refinamiento **dentro** del carmín/grafito, decidido con el propietario: no se tocaron paleta, cartera, física del mazo, los ocho layouts ni la tipografía de las credenciales.

**`lib/core/theme/reson_chrome.dart`** es la pieza central. Los controles de tema e idioma **ya no flotan**: eran dos `Positioned` en un `Stack` dentro de `MaterialApp.builder`, con `right: 76` y `right: 18`, y cada pantalla tenía que dejarles hueco a mano — 132px de acción vacía en el `AppBar` del chat, 80px de padding superior en el perfil, y un acuerdo tácito en el resto. Ahora son layout:

- `ResonControls`: los dos botones, una sola vez en el código.
- `ResonHeader`: la banda superior de toda pantalla; `leading` sustituye la marca (el chat pone ahí su enlace de vuelta), `onBrand` la dibuja en blanco sobre los fondos oscuros de intro y acceso.
- `ResonWordmark`: la marca. Reemplaza a `ResonLogo`, que se eliminó de `brand_widgets.dart`.
- `resonCompact(context)`: **un solo umbral (360px)** para toda la app. Por debajo, la marca suelta la palabra, el chat deja el volver en icono y «Ver tarjeta» se pliega al menú. Sin esto la cabecera desbordaba 27px a 320.

Por eso `localeProvider` se movió de `app/reson_app.dart` a `core/theme/reson_theme.dart`, junto a `appearanceProvider`: así la cabecera vive en `core` y no importa hacia la capa `app`.

**El chat entró al sistema.** Mantiene `Scaffold` propio y no `NetworkShell` —su cabecera y su redactor deben quedarse fijos mientras solo ruedan los mensajes— pero comparte cabecera, ancho y ritmo. Perdió el `AppBar`; bloquear y reportar están ahora junto a la persona a la que afectan. Las burbujas usan `surfaceContainerHigh` (mist) y no `surfaceContainerHighest` (silver, frío junto al blush), tienen la esquina inferior cuadrada del lado de quien escribe, y la hora va al 62% de opacidad: es una nota al pie, no una segunda frase.

Sus streams pasaron a providers (`connectionProvider`, `messagesProvider`, `messagesPageProvider`): antes guardaba sus propios handles de Firestore y recreaba el stream desde `setState`, lo que lo hacía **imposible de probar**. Ahora hay `test/chat_design_test.dart` con 7 pruebas y capturas en claro y oscuro.

**Tokens nuevos** en `reson_surfaces.dart`:

- `ResonRadius` (`sm` 12, `md` 18, `lg` 24, `xl` 28). Había once radios: 8, 11, 12, 18, 20, 22, 23, 24, 25, 28 y 30. El centro de esa serie es indistinguible a ojo y evidentemente no planificado en código.
- `ResonSpace.screen`: el margen que toda pantalla guarda con el borde. Cada una elegía el suyo (22, 24, 20).

**`ResonNotice`** (en `reson_motion.dart`) unifica vacío, error y «nada aún», con icono, título, cuerpo y acción opcionales. Antes cada pantalla improvisaba: un `Text` centrado, un `Text` en rojo de error, un spinner. La carga usa `ResonSkeleton`/`ResonCardSkeleton`, no `LinearProgressIndicator`.

**Tema**: `filledButtonTheme` fijaba `backgroundColor: ResonPalette.carmine`, lo que (a) dejaba el modo oscuro con el carmín claro en vez de su `brightRed`, y (b) hacía `FilledButton.tonal` **indistinguible** de una acción primaria. Ahora lee `scheme.primary`. Se añadieron estados deshabilitados, `outlinedButtonTheme`, bordes de foco y error en los campos, y temas de diálogo y snackbar con los radios del sistema.

### Buscador de personas, solo para quien se apunta (12 de noviembre de 2026)

Era el hueco que separaba una tarjeta digital de una red: solo se podía conectar escaneando un QR o abriendo un enlace. **Decisión del propietario: encontrable solo quien lo active.**

- Colección **`directory/{uid}`**, una entrada por persona listada. La escribe solo el backend (`setDiscoverable`); las reglas dan lectura a cuentas verificadas y **escritura a nadie**, con prueba de reglas que lo comprueba.
- **Publicar una tarjeta no lista a nadie.** Son dos consentimientos distintos: compartir una tarjeta con una persona no es querer salir en un directorio. La entrada contiene solo lo que su dueño ya había hecho público, copiado de la instantánea.
- Despublicar la tarjeta con la que apareces **retira la entrada**, o el buscador devolvería resultados muertos.
- Firestore no tiene búsqueda de texto. `searchTerms` guarda **prefijos sin acentos** de nombre, puesto, empresa, sector y ubicación (tope 120, porque un array también es un índice) y `searchQuery` manda **la palabra más larga** al servidor —solo se permite un `array-contains` por consulta— y filtra el resto en el dispositivo. Hay una copia en Dart en `network_service.dart`: **si cambias una, cambia la otra**, y las pruebas de ambos lados usan el mismo ejemplo.
- `array-contains` sin `orderBy` **no necesita índice compuesto**; el orden se hace en cliente a propósito.
- El interruptor vive en Ajustes, con selector de tarjeta cuando hay más de una publicada. Sin tarjeta publicada no hay interruptor, solo la explicación.
- Entrada al buscador desde Mi red, y cada resultado abre el perfil de esa persona.

### Listo para un tercer idioma (12 de noviembre de 2026)

El propietario avisó de que en el futuro habrá más idiomas. **Ya no queda ni un texto que elija idioma en código.**

- Las **76 llamadas `tr(context, 'es', 'en')`** del módulo de red pasaron al ARB, más tres con condicionales dentro que hubo que reescribir a mano. El ayudante `tr()` se eliminó.
- `networkError(error, bool es)` **ya no existe**: era el último sitio que decidía entre dos idiomas con un booleano, imposible de extender. Ahora `networkErrorCode(error)` solo devuelve el código y `networkErrorText(context, error)` lee el ARB.
- El **arte de las credenciales también se tradujo**: «IDENTIDAD PROFESIONAL», «TALENTO INDEPENDIENTE», «CONEXIONES PERSONALES», «Tu nombre», «Tu nueva identidad» y la coletilla estaban en ternarios dentro de `card_preview.dart` y `credential_card.dart`. Los tamaños siguen a mano —eso es arte— pero el texto no es arte.
- El conmutador de idioma de la cabecera **recorre `AppLocalizations.supportedLocales`** en vez de alternar es↔en. Añadir un idioma al ARB basta para alcanzarlo desde ahí.
- ARB: **358 claves** en ES y EN, con exactamente las mismas en los dos archivos.

**Para añadir un idioma** basta con: copiar `lib/l10n/app_es.arb` a `app_<código>.arb`, traducir los valores, y `flutter gen-l10n`. `supportedLocales` se genera solo. Lo que **no** cubre el ARB y habría que revisar: `functions/render.js` (la página pública acepta `?lang=en` y tiene dos idiomas a mano) y los correos de verificación, que reciben `languageCode` desde la app.

`test/network_errors_test.dart` incluye una guarda que falla si algún archivo de `lib/features/network` vuelve a traer texto inline o a ramificar por idioma.

### La tarjeta pública se veía genérica (12 de noviembre de 2026)

El propietario señaló que la página compartida no se ve bien. Mirando el HTML real de una publicada había dos defectos de verdad:

- **El color que elige el dueño no se usaba.** El degradado y los botones estaban fijos en carmín dentro del CSS, así que todas las tarjetas se veían iguales por mucho que su dueño eligiera otro color. Ahora `shade()` deriva un tono oscuro y uno claro del color real y la página los usa en variables CSS.
- **Se emitían párrafos vacíos.** `<p>${role}</p><p>${company}</p><p>${bio}</p>` salía siempre, así que un campo vacío dejaba un hueco bajo el nombre. Ahora puesto y empresa van en una sola línea y la biografía solo aparece si existe.

Hay pruebas de las dos cosas y de que un color inválido no produzca una variable CSS rota.

### Cartera de tarjetas recibidas (12 de noviembre de 2026)

Idea del propietario: que las tarjetas que te pasan se guarden y se consulten en una cartera aparte con filtros. La mitad existía —`users/{uid}/received` y la pestaña Guardadas— pero **solo almacenaba `publicId`, `name`, `label` y `savedAt`**, así que no había con qué dibujar la credencial y la pestaña era una lista de dos líneas.

- `save` guarda ahora **la instantánea saneada completa** más `active`. Leerla por callable al abrir habría costado un viaje de red por tarjeta. La redacción del backend sobrevive la copia y hay prueba de ello.
- Nueva acción **`refreshSaved`**: una tarjeta guardada es una copia y envejece. Trae la actual y, si su dueño la retiró, **marca `active: false` en vez de fallar**; la cartera la conserva atenuada con «Su dueño retiró esta tarjeta» en lugar de hacerla desaparecer sin explicación.
- `cardFromSnapshot` en `network_service.dart` es el conversor compartido de instantánea a `DigitalCard`; la pantalla de recibir lo reutiliza en vez de repetir el mapeo.
- `received_wallet.dart` dibuja `CardPreview` real, con buscador por nombre, empresa, puesto, etiqueta o ubicación, y filtros por tipo en `Wrap` (no en carril: con cuatro, un carril deja el último fuera).
- Las cuentas que guardaron antes del cambio no tienen `snapshot`: la cartera las muestra como fila de nombre y etiqueta en lugar de quedarse en blanco. Hay prueba.

**Decisión tomada, no olvido**: no se guarda automáticamente lo que solo miras. El propietario mencionó «o que has visto sus perfiles»; guardar sin pedirlo convierte la cartera en un historial ruidoso y registra a quién has mirado. El guardado sigue siendo explícito.

### El perfil de otra persona (12 de noviembre de 2026)

`/receive/:id` **lidera ahora con la persona, no con la tarjeta**. Antes una conexión era una credencial y nada más: sin cara, sin trayectoria, sin forma de ver con quién ibas a hablar.

Reutiliza las piezas tal cual: `ProfileHero` con su foto pública, nombre, puesto · empresa y chips de ubicación/modalidad; «Sobre mí»; y `ProfessionalSummary` abierto, la misma presentación de trayectoria del perfil propio. La tarjeta sigue ahí, abajo, bajo «Su tarjeta»: ya no es el tema, es una parte.

- `ProfileHero` ganó `imageUrl` (la copia pública de la foto) e `inset`, para cuando quien lo usa ya aporta su propio margen.
- `ProfileAvatar.googleUrl` se renombró a **`imageUrl`**: la foto pública de Reson no es de Google y el nombre mentía.
- `DigitalCard.withVisibleFields` y `withoutIdentityChips` evitan que ubicación y modalidad salgan dos veces, una regla que ahora comparten el perfil propio y el ajeno.

### El perfil pasó a ser un perfil (12 de noviembre de 2026)

El propietario lo describió como «soso y medio feo». El problema de fondo no era el aspecto: **era un editor disfrazado de perfil**. 602 líneas, unas veinte entradas seguidas, y ninguna forma de verte como te ven los demás. Lo más rico que recoge la app —sector, habilidades, experiencia, educación, proyectos, certificaciones— solo se veía dentro de un formulario o en una tarjeta publicada.

- **`/profile`** es ahora la presentación: banda de marca, avatar montado sobre ella, nombre, puesto · empresa, chips de ubicación/modalidad y disponibilidad, «Sobre mí», idiomas, servicios y la trayectoria.
- **`/profile/edit`** es el formulario de antes, intacto, detrás de un botón. **Carga el perfil él mismo**: al separarlo se quedó sin el `initial` que le pasaba su padre y abría en blanco sobre datos reales. Si vuelve a aparecer vacío, es eso.
- La trayectoria **reutiliza `ProfessionalSummary`**, el mismo widget que presentan las tarjetas, en vez de duplicar la presentación. Se le añadió `open`: una tarjeta la deja plegada porque el protagonista es la credencial; un perfil la abre porque ahí la trayectoria **es** el contenido.
- Para no decir las cosas dos veces, la tarjeta sintética oculta `location` y `workMode` (ya son chips de identidad) y las habilidades las pinta solo el bloque de trayectoria.

### Ajustes (11 de noviembre de 2026)

`lib/features/settings/settings_page.dart`, ruta `/settings`. Reúne lo que estaba disperso —el sonido vivía en Mi red, cerrar sesión al fondo del formulario de perfil— y **añade algo que antes era imposible: volver a seguir al dispositivo.** Un conmutador de dos estados no puede decir «lo que tenga mi teléfono», así que una vez tocabas el de la cabecera te quedabas fijado para siempre.

- `Appearance.set(ThemeMode)` guarda `themeMode` (`system`/`light`/`dark`) y sigue leyendo el `darkMode` booleano antiguo para cuentas que ya lo tenían.
- `LocaleController` **persiste el idioma** en `locale` y tiene `follow()` para soltarlo. Antes vivía solo en memoria: la app olvidaba la elección en cada arranque.
- Los chips llevan clave `grupo-id` (`appearance-dark`, `language-en`). «Sistema» aparece en dos filas, así que una etiqueta no basta para identificar cuál es.

### Fundamentos visuales (noviembre 2026)

`lib/core/theme/reson_surfaces.dart` añade tres piezas más al sistema:

- **`ResonType`**: escala tipográfica de ocho roles montada sobre `TextTheme` (`displaySmall`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelSmall`). Antes había 21 tamaños sueltos. **`bodyMedium` debe conservar `onSurface`**: Material lo usa como estilo por defecto de todo `Text` sin color propio, y teñirlo de gris vuelve gris la app entera, titulares incluidos. Hay prueba que lo fija.
- **`ResonSpace`**: ritmo de 4pt (`xs` 4 … `huge` 48) frente a las 20 separaciones distintas que había.
- **`ResonSurfaces`**: `resting`, `raised` y `floating`, con sombras distintas por brillo. La app tenía **5 sombras en total**: todo se separaba con borde de 1px y nada vivía por encima de nada. El borde pasa a ser la excepción; hoy solo lo usa la tarjeta activa, porque ahí es un estado, no un contenedor.

Widgets nuevos: `ResonPanel` (superficie elevada, sustituye al `Container` con borde que cada pantalla construía a mano), `ResonStagger` (entrada en cascada sin temporizadores, para que `pumpAndSettle` siga asentando) y `ResonSkeleton`/`ResonCardSkeleton` (sustituyen al spinner; el barrido no corre con movimiento reducido, porque una animación en bucle impide asentar las pruebas).

**La tipografía de las credenciales no sigue la escala de la app a propósito**: la credencial es una pieza de diseño, no cromo. Los tamaños de `card_preview.dart`, `credential_card.dart` y `animated_wallet.dart` se dejan a mano.

El tema arranca en **`ThemeMode.system`** y solo fija un lado cuando el usuario toca el conmutador; la elección se guarda en `darkMode`. El icono debe leer `Theme.of(context).brightness`, no el `ThemeMode`, porque con `system` el modo no dice qué se está viendo.

La migración **sí está terminada ahora** (repolish del 11/11/2026). Medido fuera de los archivos de arte: **0 separaciones crudas** (eran 46), **0 radios crudos** (eran 11) y **4 `fontSize`**, los cuatro responsivos o proporcionales y correctos: `wide ? 56 : 42` en intro, `wide ? 40 : null` en cards, `compact ? 27 : 36` en `auth_welcome` y `size * .36` en `profile_avatar`. No migrarlos: dependen del ancho o del tamaño del avatar, no son valores sueltos.

Una versión anterior de esta memoria ya afirmaba «cero» cuando quedaban 46. Si se vuelve a tocar el tema, **medir antes de afirmar**:

```sh
grep -ro "SizedBox(height: [0-9]\|EdgeInsets.all([0-9]\|fromLTRB([0-9]\|horizontal: [0-9]\|vertical: [0-9]\|BorderRadius.circular([0-9]" lib --include=*.dart \
  | grep -vE "card_preview|credential_card|animated_wallet|home_identity_art|brand_widgets|reson_chrome|/generated/" | wc -l
```

Lo que conserva valores a mano es deliberado y no debe migrarse: `card_preview.dart`, `credential_card.dart`, `animated_wallet.dart`, `home_identity_art.dart` y la tarjeta de muestra de `brand_widgets.dart`. Esa última vive en un lienzo de alto fijo (250px): ajustar sus gaps al ritmo la desborda.

Los filtros de inicio se probaron como carril horizontal y **se revirtió a `Wrap`**: con solo cuatro, un carril deja el cuarto fuera de pantalla. La fila huérfana es preferible a esconder un filtro.

La cartera responde al dedo: arrastre continuo con posición fraccionaria y asentamiento por resorte, no por tween. La credencial vuela con `Hero` entre cartera, editor y compartir; esas dos rutas usan `context.push` y no `go`, porque un `Hero` necesita una ruta apilada. `/cards/new` sigue con `go` al no tener credencial de origen.

## 12. Incidencias resueltas y lecciones

- Guardado interminable inicialmente: reglas desplegadas obsoletas rechazaban nuevos campos. Se reconstruyeron/validaron/desplegaron reglas. No arreglar incompatibilidad de esquema ampliando timeouts.
- Segundo error al guardar con foto: bucket no existía y facturación estaba deshabilitada. El usuario activó Blaze y creó Storage; se publicaron reglas/CORS y se verificó subida/lectura real.
- Fotos hoy habilitadas por defecto; `RESON_PHOTO_UPLOADS_ENABLED=false` permite entornos sin Storage. El editor muestra fallo de foto y permite guardar sin la nueva foto sin borrar una anterior.
- Confirmaciones tardías y escrituras: no perder formulario ni duplicar envíos; hay pruebas de regresión.
- Evaluación de reglas profesionales: validaciones concatenadas para no exceder límite de expresiones al validar muchas entradas.
- Entrar por enlace y autenticarse: dejar al router restaurar destino en vez de forzar home en la pantalla de login.
- Sonido nuevo requiere reiniciar servidor Flutter después de añadir plugin; hot reload solo no siempre registra plugins.
- Primer deploy Functions completó funciones pero CLI acabó con aviso/error de política de artefactos ausente; se configuró retención siete días y después se verificó funcionamiento real.
- HTTP 200 en localhost solo demuestra entrega del frontend, no guardado de Firestore ni subida de Storage.

## 13. Ejecutar desde otra computadora

```powershell
git clone https://github.com/AngelPMZX/reson_app.git
cd reson_app
flutter doctor
flutter pub get
flutter gen-l10n
flutter run -d chrome --web-port 5211
```

O servidor sin abrir Chrome:

```powershell
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5211
```

VS Code: abrir carpeta con pubspec.yaml, seleccionar destino y F5. `.vscode/launch.json` contiene lanzamientos portables. Android requiere SDK/Android Studio/licencias/emulador o teléfono. iOS requiere macOS/Xcode/CocoaPods. No se han validado compilaciones móviles desde esta PC.

Para backend/herramientas:

```powershell
npm ci --prefix functions
npm ci --prefix tools/firestore-tests
.\tools\firestore-tests\node_modules\.bin\firebase.cmd login
```

Google puede ofrecer Gemini y telemetría al iniciar CLI: son opcionales y no necesarios para Reson. Finalizar hasta confirmar login exitoso. Nunca pegar códigos/tokens en documentación o chat.

Flags: `RESON_PREVIEW_ONLY=true` es preview sin backend real; no usarlo para validar guardados. OAuth móvil y fotos tienen los flags descritos arriba.

## 14. Verificación y despliegue

Estado al 11/11/2026, todo ejecutado y en verde:

- **141 pruebas Flutter** (149 con `RESON_SCREENSHOTS=true`, que habilita las de captura).
- **33 pruebas de backend y reglas con emulador**, incluida la social de extremo a extremo completa, ninguna saltada.
- `flutter analyze` sin incidencias, `flutter build web --release` correcta, `npm run format:check` limpio en `functions/`.

**Java para el emulador: no hace falta instalarlo.** Android Studio trae OpenJDK 21 en `C:\Program Files\Android\Android Studio\jbr`. Basta ponerlo en PATH para el comando; la nota antigua sobre un JRE en `.tools` ya no aplica:

```powershell
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:PATH = "$env:JAVA_HOME\bin;$env:PATH"
```

La prueba `publish → save → request → accept → chat → block → revoke` cubre ahora también el desbloqueo y la reconexión: que solo desbloquee quien bloqueó, que el bloqueo se borre, que el estado pase a `declined`, que el solicitante siga esperando la cuarentena y que el destinatario pueda aceptar en el acto.

Entrega anterior: 80 pruebas Flutter y 17 backend/reglas. Las tres pruebas sociales de captura también pasaron. Se revisaron visualmente inicio publicado, página pública, Mi red y diálogo de conexión. Se comprobó Firebase real con cuentas temporales, posteriormente eliminadas: redacción de datos, foto/vCard, guardar, pedir/aceptar conexión, idempotencia, denegación de acceso ajeno, bloqueo y revocación. No equivale a pruebas nativas Android/iOS.

```powershell
flutter analyze
flutter test
flutter build web --release
```

Pruebas de backend y reglas (Node compatible y Java 21 en PATH):

```powershell
.\tools\firestore-tests\node_modules\.bin\firebase.cmd emulators:exec --only firestore --project demo-reson --config firebase.emulators.json 'node --test tools/firestore-tests/rules.test.cjs functions/test/*.test.js'
```

`firebase.emulators.json` usa Firestore 127.0.0.1:8085; `firebase.json` contiene configuración por defecto 8080. Usar el archivo de pruebas explícito. El JRE local en `.tools` no se sube a Git. Ejecutar solo npm test en functions omite integración si falta FIRESTORE_EMULATOR_HOST.

Prueba contra producción: `tools/social-live-smoke.cjs`, optativa con `RESON_LIVE_SMOKE=1`, sesión CLI y permisos administrativos. Crea tres cuentas verificadas temporales, publicaciones, foto y mensajes; borra sus propios recursos en finally. No ejecutarla automáticamente en cada build. Tokens se usan en memoria, no se imprimen. Las pruebas Flutter normales usan repositorios falsos y no envían emails.

Desplegar tras revisar cambios y pruebas. **`firestore:indexes` ya se desplegó el 11/11/2026** y el índice de `connections` (`members` CONTAINS + `updatedAt` DESC) está creado en `reson-app`: Mi red puede ordenar en el servidor. Mantenerlo en el comando para que futuros índices no se queden atrás, y recordar que un índice nuevo **se despliega antes o a la vez que el hosting**, porque la consulta falla hasta que termina de construirse. Antes de este archivo el proyecto no tenía ningún índice compuesto, así que desplegarlos es aditivo; si algún día Console muestra índices creados a mano, añadirlos aquí antes de desplegar o la CLI ofrecerá borrarlos.

```powershell
.\tools\firestore-tests\node_modules\.bin\firebase.cmd deploy --only functions,firestore:rules,firestore:indexes,storage,hosting --project reson-app
```

Para solo frontend, construir web y usar `--only hosting`. Subir un commit no despliega Firebase. No hay CI/CD configurado que lo haga automáticamente. Conservar sincronizados esquema, reglas y backend al cambiar campos.

Las capturas de diseño salen con `flutter test test/card_design_test.dart --dart-define=RESON_SCREENSHOTS=true --dart-define=RESON_FONT_DIR=C:/flutter-sdk/flutter/bin/cache/artifacts/material_fonts` y aterrizan en `build/design-preview/`. Sin `RESON_FONT_DIR` el texto sale en cajas. Comparar sus hashes antes y después es la forma de demostrar que un refactor visual no cambió ni un píxel.

Los logs y capturas de esta sesión viven en `build/` (ignorados): social-final-tests.log, social-backend-tests.log, social-hosted-smoke.log, social-final-build.log, social-hosting.log y design-preview/. No existen necesariamente tras clonar; se regeneran.

## 15. Pendientes y siguiente trabajo recomendado

### Qué se cerró el 11 de noviembre de 2026

Una sola sesión, en este orden. Sirve para no volver a abrir nada de esto:

1. **Los errores ya no salen siempre en español.** De las 13 llamadas a `networkError`, ocho pasaban un `true` literal, así que un lector en inglés veía español al fallar al aceptar, bloquear, reportar o cargar la lista. Todas pasan ahora por `networkErrorText(context, error)`. `test/network_errors_test.dart` incluye una guarda de código fuente que falla si una pantalla vuelve a fijar el idioma.
2. **Rechazar y bloquear dejaron de ser definitivos** (sección 10). Era el hueco funcional de verdad: un toque accidental cerraba ese par de cuentas para siempre y `unblock` no existía en ninguna capa.
3. **El backend se formateó** (sección 4), demostrando con hash que no cambió ni un byte de comportamiento.
4. **Conexiones y recibidas se acotaron** con paginación y «Ver más»; el índice compuesto quedó desplegado en producción (secciones 10 y 14).
5. **Repolish de diseño** dentro del carmín/grafito (sección 11): cabecera compartida, chat dentro del sistema, `ResonRadius`, `ResonSpace.screen`, `ResonNotice`, estados del tema y arreglo del modo oscuro en los botones.
6. **Las conversaciones se ven** y dejaron de parecer rotas: vista previa, hora y no leídos (sección 10).
7. **Ajustes** como pantalla propia, recogiendo lo disperso (sección 11).
8. **Cuatro destinos con barra inferior** al estilo LinkedIn, separando personas de conversaciones (sección 10).

Las pruebas pasaron de 80 a 94 en Flutter y de 4 a 25 en backend con emulador.

### Lo que sigue abierto, por prioridad

**Las capturas de diseño viven en `build/design-preview/`, que está en `.gitignore`**: no viajan en los commits y hay que regenerarlas con el comando de la sección 14. Sin `RESON_FONT_DIR` el texto sale en cajas.

**Ahora mismo, antes que nada:** el código está en `main` pero **no desplegado**. Falta `functions`, `firestore:rules`, `storage` y `hosting`; el índice sí está. Hasta que se despliegue, `unblock` y `markRead` no existen en el backend real y la app publicada sigue siendo la anterior. La interfaz aguanta mientras tanto —una conexión sin `lastMessage` dice «Sin mensajes todavía» y `markRead` falla en silencio— pero nadie verá vistas previas ni no leídos hasta desplegar Functions. Ver sección 14.

**Diagnóstico del 12/11/2026 sobre lo que le falta al producto**, por tamaño del hueco:

- ~~No se puede encontrar a nadie~~ **resuelto el 12/11/2026** con el buscador opt-in (sección 10).
- ~~No existe «persona», solo «tarjeta»~~ **resuelto el 12/11/2026** (sección 11). Lo que sigue en pie: la instantánea guardada envejece, y `refreshSaved` existe pero **no se llama desde ninguna pantalla todavía**.
- **El chat es solo texto.** Sin adjuntos ni imágenes, sin responder a un mensaje, sin editar ni borrar, sin indicador de escribiendo. Los acuses de lectura **ya tienen los datos** (`reads`) y no se muestran: es decisión de producto, no olvido.
- **Nada avisa de nada** sin push: la app solo existe cuando se abre.
- **Nadie sabe si su tarjeta funciona**: no hay métricas de aperturas ni de contactos guardados. Para quien reparte tarjetas en un evento, eso es la mitad del valor.
- **Falta lo legal**: borrar cuenta, exportar datos, términos y privacidad. Bloquea las tiendas.

**Corto plazo, barato y verificable aquí:**

- Terminar de pasar los `tr(context, 'es', 'en')` al ARB. Los de ajustes y las secciones nuevas de Mi red ya están en claves; el resto del módulo `network` sigue en Dart, así que añadir un tercer idioma aún obliga a editar código.
- `/cards/:id/share` es la única pantalla sin pruebas de pantalla.
- Los estados de foco con teclado se definieron en el tema pero no hay prueba que los capture; hay que mirarlos en Chrome.
- El **cursor real del chat**: sigue creciendo el límite y releyendo lo anterior.
- Los no leídos se calculan por conexión, no por mensaje: no hay contador de cuántos, solo un punto. Suficiente por ahora; un contador exige contar en backend.
- `reads` es visible para ambos miembros, así que la base ya permite acuses de lectura. La interfaz **no los muestra** y esa es una decisión de producto, no un olvido.

**Requiere decisiones de producto o acceso que no está en el repositorio:** todo lo de las dos listas siguientes.

### Antes de lanzamiento móvil

- Completar OAuth Google Android/iOS y validar dispositivos reales, cámara/galería, teclado, accesibilidad, tamaños, audio y deep links.
- Configurar firma de producción, Play Console/App Store Connect, iconos/splash finales, fichas y versiones de release.
- Notificaciones push con FCM, permiso contextual, manejo foreground/background, tokens por dispositivo, baja de tokens y preferencias del usuario.
- Universal Links/App Links para que enlaces abran app instalada conservando fallback web.
- Privacidad/términos/soporte, eliminación de cuenta y datos, retención de mensajes y archivos, exportación de datos; no están implementados como flujo completo.
- Proceso de moderación y revisión de reportes: `reports/` se escribe pero **nadie lo lee**; no hay consola ni respuesta automática. El desbloqueo por parte del usuario ya existe (sección 10); lo que falta es la moderación del lado del equipo. Evaluar App Check y controles adicionales; no afirmar que están habilitados.
- Monitorización, alertas de errores y presupuesto/cuotas Blaze. Límites de instancias no son un límite monetario absoluto.

### Escalabilidad/mantenimiento

- Conexiones y recibidas ya están acotadas con paginación y «Ver más» (sección 10). Queda el **cursor del chat**, que todavía crece el límite y reelee lo anterior.
- `/cards/:id/share` sigue **sin pruebas de pantalla**; `/chat/:id` y `/messages` ya tienen las suyas.
- Revisar los estados de foco con teclado en un navegador real: se definieron en el tema pero no hay prueba automática que los capture.
- Definir migraciones de schemaVersion, limpieza de fotos antiguas sin referencias y ciclo de vida al borrar tarjetas/cuentas.
- Unificar strings de network (helper `tr`) en ARB: siguen **82 `tr(context, 'es', 'en')`** más 6 pares en `networkError` escritos en Dart, frente a 228 claves en ARB. Añadir un tercer idioma hoy obliga a editar Dart, no a traducir. Los errores que forzaban español **ya están corregidos**: todas las pantallas pasan por `networkErrorText(context, error)`, que lee el locale, y `test/network_errors_test.dart` impide que vuelva un indicador de idioma fijo.
- Mantener o fortalecer cobertura de Storage Emulator, fallos de red, concurrencia de publicación y pruebas de extremo a extremo móviles.
- Separar configuración staging/producción y CI para pruebas/build/deploy con permisos mínimos. Hoy demo-reson se usa para emulador, no como staging publicado.
- Quitar override firebase_core_web solamente tras actualizar y probar; revisar dependencias por compatibilidad.
- Auditar colecciones/índices al introducir búsquedas; no hay buscador público global.

### Ideas de producto, no confundir con funciones terminadas

- Notas privadas, etiquetas y recordatorios de seguimiento en contactos.
- Modo evento y tarjetas/contextos temporales.
- CTA configurable para agendar, portafolio o CV.
- Plantillas por profesión, portafolio con medios y métricas de visitas con consentimiento.
- Equipos B2B, plantillas corporativas, roles y altas/bajas: los múltiples perfiles actuales son por usuario, no un sistema multiempresa con administradores.
- Monetización futura: packs de diseños premium, personalización avanzada, analítica, marca propia y planes de equipo. Todavía no hay suscripciones, compras ni pagos; color personalizado actual no cobra.
- Estados de mensaje, adjuntos, búsqueda, badges y notificaciones, tras validar el uso básico.

Prioridad razonable: estabilizar experiencia móvil/seguridad operativa -> notificaciones y seguimiento -> herramientas B2B y monetización. No convertir en obligatorio completar un CV extenso para crear una tarjeta.

## 16. Documentación complementaria y continuidad

`docs/sharing-and-chat.md` es la guía del módulo social vigente. También están architecture.md, firebase-setup.md, firestore-setup.md, card-customization.md, save-verification.md, professional-profiles-google.md, personal-profile-wallet.md, credential-design.md, carmine-graphite-palette.md, refined-wallet.md, professional-network-direction.md y design-and-monetization.md.

**Algunos documentos son históricos**: pueden decir que Storage, publicación o despliegue estaban pendientes en esa fecha. El código actual y esta memoria describen el estado de esta entrega; no repetir instalaciones o arreglos resueltos basándose solo en un párrafo antiguo.

Para comenzar otro chat, copiar:

> Estamos trabajando en Reson. Lee MEMORIA.md, README.md y el estado actual de Git antes de cambiar nada. Conserva el diseño carmín/grafito, la cartera y el sistema de tokens: están aceptados y la migración del cromo está terminada, así que no introduzcas valores sueltos de espaciado, radio ni tamaño de letra fuera de los archivos de arte. El proyecto Firebase es reson-app y está publicado en https://reson-app.web.app, pero comprueba qué se ha desplegado: subir un commit no despliega nada. Auth, perfil, tarjetas, QR público, vCard, conexiones, chat, desbloqueo y reconexión están implementados; revisa los pendientes de la sección 15 y no asumas que Google móvil o push ya funcionan. Continúa con: [objetivo concreto].

Antes de trabajar desde otra PC: `git pull --ff-only` con árbol limpio. Al terminar: revisar diff, probar lo necesario, commit y push. No usar force push ni sobrescribir cambios del usuario para sincronizar. Actualizar esta memoria cuando cambien decisiones, arquitectura, despliegues o pendientes.
