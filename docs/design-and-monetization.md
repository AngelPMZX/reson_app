# Diseño, guardado y propuesta comercial — septiembre 2026

## Guardado
La captura no permite establecer si el bloqueo remoto proviene de Storage,
CORS, red o Firestore. El propietario confirmó que habilitó Storage y publicó
las reglas. Se encontró que la app esperaba las operaciones sin un plazo visible.

- Fotografía: máximo 25 segundos; solicita cancelación y espera hasta 2 segundos.
  Un fallo de cancelación no continúa al guardado de la tarjeta.
- Descarga de retrato: 15 segundos.
- Obtención de sesión para guardar: 10 segundos.
- Token de autenticación: 10 segundos por solicitud.
- Transacción Firestore: timeout de 20 segundos y máximo dos intentos.
- Espera de la UI al guardar el documento: 30 segundos. Un timeout de la UI NO
  cancela la escritura remota. Se desbloquean campos y navegación, pero no otro
  guardado hasta que termine la solicitud anterior. La confirmación tardía no
  sobrescribe el borrador ni navega automáticamente.
- El ID permanece estable en los reintentos del mismo editor.

La subida real del propietario no se ha reproducido. Si sigue fallando, revisar
la pestaña Red/Consola de Chrome y el código de error de Firebase, sin compartir
tokens ni contraseñas. La foto se puede quitar para aislar Storage del guardado
de texto.

## Diseños
Se conservan Firma, Minimalista e Impacto. Se añaden Aurora (ondas vectoriales),
Ejecutiva (líneas y marco geométrico) y Editorial (composición tipográfica).
Hay 16 colores predefinidos y entrada hexadecimal, todavía gratuita.
Las animaciones duran 650 ms, se ejecutan al aparecer o cambiar de estilo/color
y respetan disableAnimations. No hay animación continua ni nueva dependencia.

IMPORTANTE: publica firestore.rules actualizado. La lista permitida de layout
ahora incluye aurora, executive y editorial; las reglas anteriores los rechazan.
No se han desplegado reglas remotas desde esta tarea.

## Monetización propuesta (no implementada)
Estas son hipótesis para validar con usuarios; no hay cobros ni restricciones
nuevas en la app.

1. Gratis: tarjeta útil, intercambio básico, una selección buena de estilos.
2. Paquete de marca Pro: paleta propia guardada, logo/banner, diseños exclusivos,
   firma de correo y quitar la marca de Reson. Considerar pago único para funciones
   puramente visuales y suscripción solo cuando haya valor continuo.
3. Plan de equipos B2B: precio por usuario, plantillas corporativas, administración
   central de tarjetas y altas/bajas de empleados.
4. Servicios adicionales: dominio propio, estadísticas agregadas y exportación
   de contactos, cuando esos módulos estén implementados.
5. Tarjetas NFC físicas como producto adicional, con costes y logística propios.

No recomiendo anuncios invasivos dentro de tarjetas profesionales.
Antes de fijar precios, medir uso, costes de almacenamiento y disposición a pagar.
No cobrar por una función ya ofrecida sin definir una política para usuarios previos.

Para ventas digitales móviles, diseñar las compras según las reglas vigentes
de cada tienda/mercado:
- https://developer.apple.com/app-store/review/guidelines/#in-app-purchase
- https://support.google.com/googleplay/android-developer/answer/9858738

Arquitectura futura: proveedor de compras -> backend que verifica transacciones ->
permisos por cuenta de solo lectura para el cliente. La UI consulta capacidades;
ni un booleano local ni un campo editable por el usuario concede Pro. Procesar
restauración, cancelaciones y reembolsos antes de lanzar cobros.
