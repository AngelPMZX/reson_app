# Prompt para generar el logo de Reson

Reson es una app de identidad profesional y tarjetas digitales, de
TheDarkingStudios. El nombre viene de *resonancia*: lo que queda sonando
después de conocer a alguien. La marca actual es un glifo de barras verticales
tipo ecualizador sobre un cuadrado redondeado carmín, con el wordmark `reson`
en minúsculas y muy apretado.

Colores reales del producto, para no inventarlos:

| Uso | Hex |
| --- | --- |
| Carmín (marca) | `#C8102E` |
| Rojo brillante (acento en oscuro) | `#EF4057` |
| Vino | `#650D1B` |
| Vino profundo | `#300B12` |
| Carbón (fondo oscuro) | `#101012` |
| Marfil (fondo claro) | `#FAF9F7` |

---

## Prompt principal (en inglés, que es como mejor responden los modelos)

```
A minimal, modern app icon for "Reson", a professional identity and digital
business-card app. The mark is an abstract resonance glyph: three to five
vertical bars of uneven height, like a sound equalizer frozen mid-pulse,
suggesting a voice that carries. The bars are rounded at the ends, confidently
spaced, optically centered, and sit on a solid crimson square with generously
rounded corners (squircle, iOS/Android icon shape).

Colors: crimson #C8102E background, pure white bars. No gradient, no bevel,
no drop shadow, no 3D, no glow.

Style: geometric, flat, vector, Swiss graphic design restraint. The kind of
mark that still reads at 24 pixels. Think Stripe, Linear, Vercel — quiet
confidence, not decoration. Perfectly balanced negative space.

Composition: the glyph occupies roughly 55% of the square, centered, with
even breathing room on all sides. Nothing touches the edges.

Output: flat 2D vector-style icon, pure solid colors, crisp edges,
transparent or solid crimson background, no text, no letters, no mockup,
no device frame, no shadow, no reflection, square 1:1.
```

## Variante: marca más abstracta

Si el ecualizador resulta demasiado literal de "audio" para una app que no va
de sonido:

```
A minimal app icon for "Reson": two concentric arcs radiating from a single
solid dot in the lower left, like a ripple spreading outward, or a signal
leaving its source. Exactly one dot and two arcs — no more. Crimson #C8102E
square with very rounded corners, pure white glyph, flat vector, no gradient,
no shadow, no 3D. Geometric and calm, legible at 24 pixels. Swiss design
restraint. No text, no letters, square 1:1.
```

## Variante: monograma

```
A minimal monogram app icon: a lowercase letter "r" built from geometric
shapes, where the shoulder of the r arcs outward like a radio wave leaving an
antenna. Pure white on a crimson #C8102E squircle. Flat vector, no gradient,
no shadow. Tight, confident, modern grotesque letterform. Legible at 24
pixels. No other letters, square 1:1.
```

## Para el wordmark

```
A wordmark logotype reading "reson" in lowercase, set in a modern geometric
sans-serif with tight negative letter-spacing and a slightly condensed feel.
Deep crimson #C8102E on white. Perfectly even optical spacing. Flat vector
lettering, no effects, no icon, no tagline. Horizontal lockup, transparent
background.
```

---

## Qué pedir si el resultado no convence

- **Demasiado ocupado** → añade `extremely simple, only three shapes maximum`.
- **Sale con texto** → repite `no text, no letters, no typography` al final;
  muchos modelos solo obedecen la última instrucción.
- **Sale con brillos** → `completely flat, single solid color, no lighting`.
- **Mal centrado** → `optically centered with equal margins on all four sides`.

## Comprobaciones antes de darlo por bueno

1. **Reducirlo a 24 px.** Si no se distingue, no sirve: el glifo se usa a 36 px
   en la cabecera de la app.
2. **Verlo en gris.** Una marca que depende del color falla en un favicon
   monocromo y en impresión.
3. **Sobre carbón `#101012` y sobre marfil `#FAF9F7`.** La app arranca
   siguiendo el tema del sistema, así que se verá en los dos.
4. **Recortado en círculo.** Android recorta los iconos adaptativos; nada
   importante puede quedar cerca del borde.

## Dónde colocarlo después

- `web/icons/` y `web/favicon.png` para la web.
- `android/app/src/main/res/mipmap-*/` para Android.
- El glifo dentro de la app se dibuja hoy con código, no con imagen, en
  `ResonWordmark` (`lib/core/theme/reson_chrome.dart`): ahí se usa
  `Icons.graphic_eq_rounded` sobre un cuadrado carmín de 36 px con radio 11.
  Si el logo nuevo se aleja de esa forma, hay que sustituir ese widget.
