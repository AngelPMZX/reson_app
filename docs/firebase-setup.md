# Firebase en Reson

Configurado para reson-app (1066611577415). Android e iOS usan
com.thedarkingstudios.reson. lib/firebase_options.dart selecciona automáticamente
las opciones por plataforma, preparadas desde los archivos del propietario.

## Ejecutar
- Chrome: flutter run -d chrome
- Android/iOS: seleccionar el dispositivo y ejecutar flutter run.
- VS Code: Reson · Chrome o Reson · Dispositivo móvil.
- Solo diseño: flutter run -d chrome --dart-define=RESON_PREVIEW_ONLY=true

Ya no se necesitan --dart-define-from-file. Los archivos de config/ se conservan
como referencia del paso anterior y no controlan la inicialización.

## Configuración nativa
- android/app/google-services.json contiene el cliente coincidente.
- Google Services 4.5.0 está declarado en settings.gradle.kts y aplicado en app.
- ios/Runner/GoogleService-Info.plist está incluido en los recursos de Runner.
- Mínimos configurados: Android API 23 e iOS 15.
- ios/Podfile configura los plugins Flutter mediante CocoaPods.
- La inicialización pertenece al proveedor Dart. No añadir FirebaseApp.configure()
  a AppDelegate ni copiar la inicialización SwiftUI de las instrucciones nativas.
- FlutterFire resuelve sus SDK nativos; no añadir otro BoM manual.

La configuración del cliente es pública; no incluir claves de cuentas de servicio,
contraseñas ni tokens administrativos. Al cambiar proyecto, sincronizar las
opciones Dart y los archivos nativos. Si se adopta FlutterFire CLI, revisar su diff.

## Autenticación y validación
El propietario confirmó Correo/Contraseña habilitado. La consulta pública a
Identity Toolkit confirmó una clave y appId web válidos y localhost autorizado.
Esto no valida un registro ni el envío de correos.

Registro, acceso, cierre de sesión, recuperación y verificación usan Firebase
Authentication. El nombre se guarda en el perfil de Authentication. Firestore
y las tarjetas siguen pendientes; no se guardan contraseñas en documentos.

En este equipo flutter doctor no detecta Android SDK. Instalar Android Studio
y sus SDK, Platform Tools y Command-line Tools; ejecutar flutter doctor y
flutter doctor --android-licenses. Conectar Android con depuración USB o un emulador.
iOS necesita macOS, Xcode y CocoaPods; no se ha compilado en Windows.

Con una cuenta propia de prueba: registrarse, comprobar el usuario en Firebase,
cerrar sesión, entrar, recargar Chrome, verificar correo y recuperar contraseña.
flutter test usa un repositorio falso, no envía correos ni crea usuarios.

Fuentes:
- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/password-auth
- https://firebase.google.com/docs/auth/flutter/manage-users

Actualización: el acceso al panel exige correo verificado. El módulo de tarjetas y las reglas están implementados; falta crear Firestore y publicar las reglas. Ver firestore-setup.md.
