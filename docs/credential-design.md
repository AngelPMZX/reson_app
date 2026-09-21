# Dirección visual: credenciales

Referencia visual: [Medical Health Mobile App, Vectorfair](https://www.figma.com/community/file/1343379534839915650/medical-health-mobile-app-dermatology-app-ui-kit-doctor-mobile-app). Se revisó la vista previa pública: superficies claras, retratos destacados y controles redondeados. Implementación propia en Flutter, sin importar recursos del kit.

El diseño `signature`, presentado ahora como Credencial, adapta la composición al tipo Trabajo, Freelance o Personal. No cambia el esquema de datos ni requiere migraciones. Las tarjetas guardadas con ese diseño reciben la nueva presentación; los otros siete estilos siguen disponibles. Se respetan los campos ocultos y los colores elegidos. La información profesional adicional continúa debajo de la credencial.

El inicio ajusta su cabecera al modo claro/oscuro. Los chips y formularios comparten superficies suaves y redondeadas. La composición de la credencial pasa a vertical en pantallas estrechas o texto ampliado, y mantiene la animación existente con soporte para movimiento reducido.

Validación: 55 pruebas funcionales, pruebas visuales para las tres credenciales e inicio en claro/oscuro, y tamaño de texto 1.8 en ancho 320. Capturas locales en build/design-preview.
