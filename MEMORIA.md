# Memoria de Reson

Actualizada: **20 de septiembre de 2026**. Referencia de continuidad para el propietario y para nuevos chats de desarrollo. Describe el estado del código al preparar el commit que incluye este archivo; no contiene contraseñas, tokens ni claves administrativas.

## 1. Qué estamos construyendo

**Reson**, de **TheDarkingStudios**, es una aplicación principalmente móvil de identidad profesional, tarjetas digitales y networking. La dirección del producto es una red profesional propia, inspirada en la utilidad de LinkedIn, centrada en intercambiar tarjetas y conectar personas. Una cuenta puede representar varias facetas: trabajo, freelance y personal.

El usuario quiere código mantenible, arquitectura escalable, una experiencia elegante y animaciones cuidadas. Prefiere implementar las ideas directamente y probarlas; no quedarse solamente en propuestas. Español e inglés desde el inicio. La web permite desarrollar en Windows, probar en Chrome y compartir tarjetas con visitantes que no tienen la app.

La última versión fue aceptada visualmente por el usuario. El último pedido es guardar esta memoria y hacer commit/push de toda la versión actual. No rehacer el diseño por defecto al iniciar otro chat.

## 2. Repositorio, equipos y entornos

- Repositorio del proyecto: **https://github.com/AngelPMZX/reson_app**; se utiliza como repositorio privado del usuario.
- Remoto `origin`: `https://github.com/AngelPMZX/reson_app.git`.
- Rama actual: `main`.
- Commit anterior a esta entrega: `75b85ee` (`Replace legacy app with current Reson implementation`). La versión vieja ya se sustituyó; no hace falta borrar ni forzar historia.
- Carpeta en esta PC: `C:\Proyectos\Reson`.
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
  app/reson_app.dart                 Router, sesión, temas, idioma y controles globales
  core/
    firebase/firebase_bootstrap.dart Inicialización y providers de Firebase
    firebase/google_oauth_config.dart IDs OAuth públicos vía dart-define
    theme/reson_palette.dart        Paleta central
    theme/reson_theme.dart          Temas claro/oscuro
    theme/reson_motion.dart         Movimiento reutilizable
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
    profile/                        Perfil reutilizable, repositorio, avatar y pantalla
    network/
      network_service.dart          Callables y providers de Firestore
      network_widgets.dart          Shell y paneles compartidos
      share_card_page.dart          Selección de campos, publicar, QR, despublicar
      receive_card_page.dart        Recibir, guardar, solicitar conexión
      network_page.dart             Mi red, solicitudes, tarjetas guardadas, sonido
      chat_page.dart                Conversación, paginación, bloquear, reportar
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

Rutas: `/`, `/login`, `/register`, `/reset-password`, `/session`, `/verify-email`, `/home`, `/profile`, `/cards/new`, `/cards/:id/edit`, `/cards/:id/share`, `/network`, `/receive/:id`, `/chat/:id`.

Al entrar por `/receive/:id` sin sesión se guarda el destino en memoria del router y se retoma después de login/verificación. El destino pendiente no es un sistema de deep links persistente entre cierres completos. Se quitaron redirecciones imperativas a home tras email login/registro para no perderlo.

Cerrar sesión está en opciones del perfil, no como acción principal del inicio.

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
| `users/{uid}/received/{publicId}` | Tarjetas guardadas; propietario lee, servidor escribe |
| `users/{uid}/blocks/{otherUid}` | Bloqueos; servidor administra |
| `publicCards/{publicId}` | Instantánea publicada y metadatos internos; sin acceso directo del cliente |
| `connections/{connectionId}` | Dos miembros, requester/recipient, estado, nombres, tarjetas, timestamps |
| `connections/{connectionId}/messages/{messageId}` | sender, text, createdAt; lectura solo miembros aceptados, escritura servidor |
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

ID de conexión determinista: SHA-256 del par de UIDs ordenados. Estados pending, accepted, declined, blocked. Solo destinatario puede aceptar/rechazar la solicitud pendiente. Solicitudes existentes no generan duplicados; la versión actual no permite reenviar tras rechazo/bloqueo.

Chat de texto en tiempo real, habilitado tras aceptación. Mensajes de 1 a 2000 caracteres, ID cliente reutilizado en reintentos para evitar duplicados. Lectura descendente con 50 mensajes inicialmente y botón para aumentar el límite. Conexiones se filtran por membresía; escritura exclusivamente por callable. Límites: 40 acciones sociales/minuto/usuario y mínimo de 700 ms entre mensajes de la conexión. Errores conservan el borrador.

Bloquear detiene mensajes y nuevas solicitudes. Reportar registra motivo para revisión administrativa. No existe aún UI de desbloqueo, consola de moderación ni respuesta automática a reportes. El chat no ofrece todavía adjuntos, indicadores de escritura, leído/no leído, push o cifrado de extremo a extremo.

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

### Fundamentos visuales (noviembre 2026)

`lib/core/theme/reson_surfaces.dart` añade tres piezas más al sistema:

- **`ResonType`**: escala tipográfica de ocho roles montada sobre `TextTheme` (`displaySmall`, `headlineMedium`, `titleLarge`, `titleMedium`, `bodyLarge`, `bodyMedium`, `labelLarge`, `labelSmall`). Antes había 21 tamaños sueltos. **`bodyMedium` debe conservar `onSurface`**: Material lo usa como estilo por defecto de todo `Text` sin color propio, y teñirlo de gris vuelve gris la app entera, titulares incluidos. Hay prueba que lo fija.
- **`ResonSpace`**: ritmo de 4pt (`xs` 4 … `huge` 48) frente a las 20 separaciones distintas que había.
- **`ResonSurfaces`**: `resting`, `raised` y `floating`, con sombras distintas por brillo. La app tenía **5 sombras en total**: todo se separaba con borde de 1px y nada vivía por encima de nada. El borde pasa a ser la excepción; hoy solo lo usa la tarjeta activa, porque ahí es un estado, no un contenedor.

Widgets nuevos: `ResonPanel` (superficie elevada, sustituye al `Container` con borde que cada pantalla construía a mano), `ResonStagger` (entrada en cascada sin temporizadores, para que `pumpAndSettle` siga asentando) y `ResonSkeleton`/`ResonCardSkeleton` (sustituyen al spinner; el barrido no corre con movimiento reducido, porque una animación en bucle impide asentar las pruebas).

**La tipografía de las credenciales no sigue la escala de la app a propósito**: la credencial es una pieza de diseño, no cromo. Los tamaños de `card_preview.dart`, `credential_card.dart` y `animated_wallet.dart` se dejan a mano.

El tema arranca en **`ThemeMode.system`** y solo fija un lado cuando el usuario toca el conmutador; la elección se guarda en `darkMode`. El icono debe leer `Theme.of(context).brightness`, no el `ThemeMode`, porque con `system` el modo no dice qué se está viendo.

La migración está **completa en el cromo**: cero `fontSize` y cero separaciones crudas fuera del arte. Lo que conserva valores a mano es deliberado y no debe migrarse: `card_preview.dart`, `credential_card.dart`, `animated_wallet.dart`, `home_identity_art.dart` y la tarjeta de muestra de `brand_widgets.dart`. Esa última vive en un lienzo de alto fijo (250px): ajustar sus gaps al ritmo la desborda.

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

Última entrega: **80 pruebas Flutter**, **17 pruebas backend/reglas**, analyze sin incidencias, build web release correcto. Las tres pruebas sociales de captura también pasaron. Se revisaron visualmente inicio publicado, página pública, Mi red y diálogo de conexión. Se comprobó Firebase real con cuentas temporales, posteriormente eliminadas: redacción de datos, foto/vCard, guardar, pedir/aceptar conexión, idempotencia, denegación de acceso ajeno, bloqueo y revocación. No equivale a pruebas nativas Android/iOS.

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

Desplegar tras revisar cambios y pruebas:

```powershell
.\tools\firestore-tests\node_modules\.bin\firebase.cmd deploy --only functions,firestore:rules,storage,hosting --project reson-app
```

Para solo frontend, construir web y usar `--only hosting`. Subir un commit no despliega Firebase. No hay CI/CD configurado que lo haga automáticamente. Conservar sincronizados esquema, reglas y backend al cambiar campos.

Las capturas de diseño salen con `flutter test test/card_design_test.dart --dart-define=RESON_SCREENSHOTS=true --dart-define=RESON_FONT_DIR=C:/flutter-sdk/flutter/bin/cache/artifacts/material_fonts` y aterrizan en `build/design-preview/`. Sin `RESON_FONT_DIR` el texto sale en cajas. Comparar sus hashes antes y después es la forma de demostrar que un refactor visual no cambió ni un píxel.

Los logs y capturas de esta sesión viven en `build/` (ignorados): social-final-tests.log, social-backend-tests.log, social-hosted-smoke.log, social-final-build.log, social-hosting.log y design-preview/. No existen necesariamente tras clonar; se regeneran.

## 15. Pendientes y siguiente trabajo recomendado

### Antes de lanzamiento móvil

- Completar OAuth Google Android/iOS y validar dispositivos reales, cámara/galería, teclado, accesibilidad, tamaños, audio y deep links.
- Configurar firma de producción, Play Console/App Store Connect, iconos/splash finales, fichas y versiones de release.
- Notificaciones push con FCM, permiso contextual, manejo foreground/background, tokens por dispositivo, baja de tokens y preferencias del usuario.
- Universal Links/App Links para que enlaces abran app instalada conservando fallback web.
- Privacidad/términos/soporte, eliminación de cuenta y datos, retención de mensajes y archivos, exportación de datos; no están implementados como flujo completo.
- Proceso de moderación, revisión de reportes, desbloqueo y política frente a abuso. Evaluar App Check y controles adicionales; no afirmar que están habilitados.
- Monitorización, alertas de errores y presupuesto/cuotas Blaze. Límites de instancias no son un límite monetario absoluto.

### Escalabilidad/mantenimiento

- Paginar conexiones y recibidas; actualmente conexiones se cargan por membresía y ordenan en cliente. Chat aumenta el límite en lugar de usar cursor persistente.
- Definir migraciones de schemaVersion, limpieza de fotos antiguas sin referencias y ciclo de vida al borrar tarjetas/cuentas.
- Unificar strings nuevos de network (helper `tr`) en ARB si crece la localización; revisar errores que todavía fuerzan español.
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

> Estamos trabajando en Reson. Lee MEMORIA.md, README.md y el estado actual de Git antes de cambiar nada. Conserva el diseño carmín/grafito y cartera aceptado. El proyecto Firebase es reson-app y ya está publicado en https://reson-app.web.app. Auth, perfil, tarjetas, QR público, vCard, conexiones y chat están implementados; revisa los pendientes documentados y no asumas que Google móvil o push ya funcionan. Continúa con: [objetivo concreto].

Antes de trabajar desde otra PC: `git pull --ff-only` con árbol limpio. Al terminar: revisar diff, probar lo necesario, commit y push. No usar force push ni sobrescribir cambios del usuario para sincronizar. Actualizar esta memoria cuando cambien decisiones, arquitectura, despliegues o pendientes.
