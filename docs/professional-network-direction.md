# Identidad roja y trayectoria profesional

La interfaz usa rojo cereza como color de marca estable, fondos cálidos claros y superficies vino en oscuro. Los colores elegidos en las tarjetas permanecen independientes. Las tarjetas nuevas usan rojo como sugerencia inicial.

La cartera sustituye las pestañas superpuestas por un selector horizontal con tipo, nombre y estado de selección, manteniendo gestos, flechas y transiciones que respetan movimiento reducido. Explorar una tarjeta no cambia la tarjeta activa de la cuenta.

El modelo profesional incorpora sector, especialidades/servicios, modalidad de trabajo, proyectos y certificaciones. Son opcionales, editables como texto libre para incluir profesiones y oficios diversos, y cada sección puede ocultarse en cada tarjeta. Se copian del perfil a tarjetas nuevas. Las entradas admiten título, entidad, periodo y descripción. Hay hasta 8 entradas en total y 4 por sección. Las reglas validan las secciones como una lista combinada para mantener el coste de evaluación acotado. Datos existentes continúan siendo válidos.

## Próximo módulo propuesto: conexiones

Todavía no existe intercambio entre cuentas, mensajería ni búsqueda pública. La siguiente entrega debería implementar compartir una versión explícita de la tarjeta, guardar tarjetas recibidas y aceptar/rechazar solicitudes. Las tarjetas privadas no deben exponerse por habilitar descubrimiento. Publicar una tarjeta requiere seleccionar campos y distinguir borrador privado de versión compartida. Después: búsqueda por sector/especialidad, bloqueo y reportes; mensajería solo entre conexiones aceptadas. Evitar estadísticas y personas ficticias en la interfaz.

Validación: 55 pruebas de Flutter, 11 de reglas en emulador, revisión visual de inicio, perfil, acceso y cartera; reglas publicadas en reson-app. Nuevos campos comprobados mediante edición/guardado en pruebas y restricciones de acceso en emulador.
