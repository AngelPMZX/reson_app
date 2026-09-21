# Perfil personal y cartera

El perfil reutilizable vive en users/{uid}/settings/identity, separado del documento de preferencias users/{uid} y de sus tarjetas. Todos sus campos son opcionales. Nombre y contacto no modifican Firebase Authentication; la pantalla muestra por separado el correo de acceso verificado.

Al abrir una tarjeta nueva se espera a cargar el perfil y se copian nombre, puesto, empresa, biografía, contacto y trayectoria. Las tarjetas guardadas conservan sus propios datos. Los campos de contacto y trayectoria de cada tarjeta siguen siendo opcionales; el nombre visible y la etiqueta de la tarjeta siguen siendo necesarios. La fotografía subida al perfil también se copia como referencia privada a las tarjetas nuevas; cada tarjeta puede reemplazarla. La foto de Google se muestra en el perfil y el inicio, sin copiar su URL a las tarjetas.

Mi perfil contiene las opciones de cierre de sesión. Las rutas /profile, /home y /cards/* están bloqueadas para usuarios no verificados. La verificación de correo existente incluye envío, reenvío con espera y actualización del token. Una cuenta con correo ya verificado no vuelve a recibir un correo cada vez que inicia sesión.

La cartera permite botones anterior/siguiente y deslizamiento horizontal. Conserva el filtro de tipo y la selección de tarjeta activa como operaciones distintas. Las animaciones respetan disableAnimations. El perfil advierte de cambios sin guardar y no permite escrituras duplicadas cuando una confirmación tarda; una confirmación tardía no borra cambios posteriores del formulario.

Validación: reglas privadas verificadas en emulador y publicadas; creación/lectura real del perfil con token de una cuenta temporal verificada, posteriormente eliminada. Pruebas de widgets para autollenado, independencia, campos vacíos, acceso no verificado, guardado lento y navegación de cartera. Capturas móviles en build/design-preview/profile.png y wallet.png (archivos de diagnóstico no versionados).

## Foto y detalles profesionales

El usuario puede subir JPG, PNG o WebP de hasta 3 MB, usar la foto de su proveedor Google o elegir iniciales. La preferencia se conserva al guardar. Las fotos propias viven en users/{uid}/profile/{assetId}, con lectura y creación limitadas al propietario verificado. Son objetos inmutables para que cambiar la foto del perfil no modifique tarjetas anteriores.

Disponibilidad, idiomas y servicios son opcionales y, por ahora, pertenecen al perfil personal. El encabezado actualiza nombre y puesto mientras se edita. Las preferencias de foto se guardan con el formulario. No se ha comprobado un acceso interactivo real mediante Google en esta revisión.

Verificación adicional: prueba Flutter web contra Firebase real con cuenta temporal: subida de foto, persistencia del perfil, reutilización en tarjeta, descarga privada y rechazo de lectura anónima.
