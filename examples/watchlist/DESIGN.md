# DESIGN.md

## Visual world
A watchlist you open in the evening, on a phone in one hand or on a TV across the room. Deep green as the single action colour, warm near-neutrals behind it, a serif for titles so a list of films reads differently from a settings screen.

## Color
| Role | Value |
|---|---|
| primary | #1B7F5C |
| onPrimary | #FFFFFF |
| surface | #FBFAF8 |
| onSurface | #14171A |
| onSurfaceVariant | #5C6360 |
| outlineVariant | #DCDEDA |
| error | #B3261E |

Dark comes from the same seed, with its own tones chosen and checked for contrast.

## Type
Display font: Fraunces
Font: Söhne

Type ramp, font size: 36, 24, 20, 16, 13

## Spacing and shape
Spacing steps: 4, 8, 12, 16, 24, 32, 48
Corner radius: 4, 8, 12

Elevation is tonal, with a shadow only under the app bar.

## Motion
Fade-through between destinations, container transform from a row into detail. Curves.easeOutCubic at 200-300ms. On TV, focus scale at 180ms.

## Known drift
None. The app was built against this document.
