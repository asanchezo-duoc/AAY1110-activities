# Scripts de ejemplo — Fundamentos de Bash

Un script mínimo por cada elemento básico del lenguaje. Pensado como referencia rápida y punto de partida antes de abordar [Act_2.1.2](../../EA2/Act_2.1.2/) y el resto de las actividades de EA2, que ya asumen manejo de estos conceptos.

| Script | Elemento | Qué muestra |
|---|---|---|
| [`01_holamundo.sh`](01_holamundo.sh) | Hola Mundo | El script más simple posible: shebang + `echo` |
| [`02_echo.sh`](02_echo.sh) | `echo` | Impresión de texto, opciones `-n`/`-e`, interpolación de variables según el tipo de comillas |
| [`03_printf.sh`](03_printf.sh) | `printf` | Impresión con formato controlado (equivalente a "print" con formato en otros lenguajes) |
| [`04_for.sh`](04_for.sh) | `for` | Sobre una lista, con rango numérico estilo C, y sobre la salida de un patrón de archivos |
| [`05_while.sh`](05_while.sh) | `while` | Con contador, y el patrón clásico de leer un archivo línea por línea |
| [`06_if.sh`](06_if.sh) | `if` / `elif` / `else` | Comparación numérica, comparación de strings, y comprobación de existencia de archivos |

## Cómo ejecutarlos

```bash
chmod +x *.sh
./01_holamundo.sh
./02_echo.sh
./03_printf.sh
./04_for.sh
./05_while.sh
./06_if.sh
```

(Ver [Act_2.1.2](../../EA2/Act_2.1.2/) si no recuerdas por qué es necesario `chmod +x` antes de `./script.sh`.)

## Notas rápidas

- **`echo` vs `printf`**: `echo` es más simple pero su comportamiento con opciones (`-e`, `-n`) varía levemente entre shells. `printf` es más predecible y da control de formato (ancho de columna, tipo de dato) — para scripts "serios" suele preferirse `printf`.
- **Comillas dobles vs simples**: dentro de `"..."` las variables se interpolan (`$NOMBRE` se reemplaza por su valor); dentro de `'...'` todo se toma literal.
- **`[ ... ]` vs `(( ... ))`**: `[ "$numero" -gt 0 ]` es la sintaxis clásica de test (funciona igual en `sh` y `bash`); `(( ))` es una extensión de bash para aritmética, usada en `04_for.sh` para el estilo C.
- **Comprobar antes de comparar**: si vas a comparar un valor como número (`-gt`, `-lt`, `-eq`), y ese valor podría no ser numérico, agrega `2>/dev/null` como en `06_if.sh` para que un error de tipo no rompa el script (aunque en un script de producción conviene validar explícitamente con una expresión regular en vez de solo silenciar el error).
