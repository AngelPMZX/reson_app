# Reson · TheDarkingStudios

Aplicación Flutter de tarjetas de identidad digitales, diseñada principalmente
para Android e iOS y con soporte web para desarrollo.

## Abrir el proyecto en otra computadora

1. Instala Git, Flutter **3.41.6** (incluye Dart 3.11.4) y VS Code con la extensión Flutter.
2. Clona este repositorio privado usando tu cuenta autorizada de GitHub:
   `git clone <URL-del-repositorio>`
3. Entra en la carpeta clonada y ejecuta:

```sh
flutter doctor
flutter pub get
flutter gen-l10n
flutter run -d chrome
```

En VS Code abre la carpeta que contiene `pubspec.yaml`, selecciona Chrome o tu
dispositivo y pulsa F5. Las configuraciones están en `.vscode/launch.json`.

Para Android instala Android Studio, Android SDK y sus herramientas, acepta las
licencias con `flutter doctor --android-licenses` y configura un emulador o teléfono.
Para iOS necesitas macOS, Xcode y CocoaPods. Las compilaciones móviles todavía
no se han verificado en este proyecto.

## Funciones implementadas

- Presentación, registro, login, recuperación y verificación obligatoria de correo.
- Tarjetas privadas múltiples con edición y selección de tarjeta activa.
- Temas claro/oscuro, estilos visuales y recomendaciones por tipo de tarjeta.
- Fotografía por tarjeta, biografía y campos que se pueden ocultar.
- Riverpod, Firebase y traducciones en español e inglés.

Firebase está configurado para `reson-app`. Se incluyen sus configuraciones
**cliente** para Android, iOS y web; no son credenciales administrativas.
Clonar el repositorio no copia las cuentas, documentos ni fotos: ambas computadoras
se conectan al mismo backend. La sesión de usuario se inicia por separado en cada
dispositivo. El acceso a Firebase Console requiere permisos de Google independientes
del acceso al repositorio.

Antes de guardar los nuevos diseños, publica las reglas actualizadas de Firestore.
Las fotografías requieren Storage habilitado y sus reglas publicadas; Storage
requiere Blaze. Consulta [la guía de personalización](docs/card-customization.md).
No habilites lectura pública para solucionar errores de permisos.

## Trabajar desde dos computadoras

Antes de empezar, con el árbol de trabajo limpio:

```sh
git pull --ff-only
```

Al terminar:

```sh
git status
git add .
git commit -m "Describe el cambio"
git push
```

Haz commit y push antes de cambiar de computadora. Git no sincroniza cambios sin
commit ni archivos ignorados. No fuerces un push para resolver diferencias;
revisa los cambios si Git informa de conflictos.

## Comprobaciones

```sh
flutter analyze
flutter test
flutter build web
```

Las pruebas utilizan repositorios falsos; no crean cuentas ni envían correos.
Conserva `pubspec.lock`. Existe un override temporal de `firebase_core_web: 3.10.0`
por compatibilidad con Dart 3.11; revísalo al actualizar Flutter.

El repositorio excluye cachés, compilaciones, rutas locales, archivos .env,
certificados de firma y claves administrativas. No subas tokens ni cuentas
de servicio. La exportación de datos de Firebase no forma parte de Git.

## Documentación

- [Arquitectura](docs/architecture.md)
- [Configuración de Firebase](docs/firebase-setup.md)
- [Firestore](docs/firestore-setup.md)
- [Diseño y fotografías](docs/card-customization.md)

QR, vCard y publicación de perfiles siguen pendientes.
