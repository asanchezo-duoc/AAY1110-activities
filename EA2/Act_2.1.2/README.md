# Act 2.1.2 — Ejecución de scripts (fundamentos de Shell)

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Ejecución de script de ejemplo |
| **RA** | RA2 |
| **IL** | IL 2.1 — Construye rutinas para automatizar tareas administrativas |
| **Tiempo estimado** | 1 hora |

## Contexto ampliado

Antes de automatizar respaldos o construir imágenes Docker (próximas actividades), necesitas dominar lo básico: **qué es un script, cómo el sistema decide con qué intérprete ejecutarlo, y cómo darle permisos**. Esta actividad usa dos scripts de ejemplo ya provistos por la asignatura (carpeta `scripts/`) para practicar exactamente eso, sin la presión de escribir lógica nueva todavía.

## Conceptos clave

**¿Qué es un script?** Un archivo de texto plano con una secuencia de comandos que el shell interpreta línea por línea, como si los escribieras tú a mano en la terminal.

**El shebang (`#!/bin/bash`)** — la primera línea del archivo. Le dice al sistema operativo *con qué intérprete* debe ejecutar el resto del archivo, sin importar qué shell estés usando tú en ese momento (bash, zsh, sh...). Si falta, el comportamiento depende de cómo invoques el script.

**Permisos de ejecución.** En Linux, todo archivo tiene permisos de lectura (`r`), escritura (`w`) y ejecución (`x`) para tres niveles: dueño, grupo y otros. Un `.sh` recién copiado normalmente **no** trae el bit de ejecución activado — por eso el primer paso siempre es revisarlo y otorgarlo.

**Dos formas de ejecutar un script:**

| Forma | Comando | Requiere permiso `x` | Corre en |
|---|---|---|---|
| Como programa | `./script.sh` | Sí | subshell (proceso hijo) |
| Interpretado explícitamente | `bash script.sh` | No | subshell igual |
| "Sourceado" | `source script.sh` o `. script.sh` | No | **el mismo shell actual** (útil si el script exporta variables que quieres conservar) |

## Guía paso a paso

1. **Conéctate a tu VM Linux** en AWS Academy Learner Lab (ver guía de la asignatura para crear/acceder a la instancia).

2. **Copia los scripts a la VM.** Si trabajas desde tu equipo local, `scp` es la herramienta típica:
   ```bash
   scp -i tu-llave.pem scripts/tablas.sh scripts/horserace.sh usuario@IP_VM:~/
   ```
   Si ya estás dentro de la VM (por ejemplo la creaste con una consola web), puedes copiar y pegar el contenido con un editor (`nano`, `vim`) y crear los archivos ahí directamente.

3. **Revisa los permisos actuales:**
   ```bash
   ls -l tablas.sh horserace.sh
   ```
   Vas a ver algo como `-rw-r--r--` — sin la `x`, no se puede ejecutar como programa todavía.

4. **Otorga permiso de ejecución:**
   ```bash
   chmod +x tablas.sh horserace.sh
   ```
   `chmod +x` agrega el bit de ejecución para dueño, grupo y otros. Si quisieras ser más estricto y dárselo solo al dueño: `chmod u+x archivo.sh`.

5. **Ejecuta `tablas.sh`:**
   ```bash
   ./tablas.sh
   ```
   Te pedirá un número y una cantidad de términos, e imprimirá la tabla de multiplicar correspondiente. Es un buen ejemplo mínimo de: lectura de entrada (`read`), aritmética con `let`, y un ciclo `while`.

6. **Ejecuta `horserace.sh`:**
   ```bash
   ./horserace.sh
   ```
   Este script es más avanzado: usa colores ANSI, un directorio temporal único, `trap` para limpiar recursos si lo interrumpes con `Ctrl+C`, y depende de utilidades externas (`bc`, `md5sum`). Es un buen ejemplo de **script defensivo**: antes de hacer nada, verifica que sus dependencias existan.

7. **Reflexiona (para el plenario):**
   - ¿Qué pasa si ejecutas `bash tablas.sh` en vez de `./tablas.sh`? (Pista: revisa si necesitas el permiso `+x` en ese caso.)
   - ¿Por qué `horserace.sh` verifica `which bc` y `which md5sum` antes de continuar? ¿Qué pasaría si no lo hiciera y esas herramientas no estuvieran instaladas?
   - ¿Para qué sirve el `trap` al inicio del script? Prueba interrumpir el script con `Ctrl+C` a mitad de carrera y observa qué limpia.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `bash: ./script.sh: Permission denied` | Falta el bit `+x` | `chmod +x script.sh` |
| `bash: ./script.sh: No such file or directory` (aunque el archivo existe) | El shebang apunta a un intérprete que no existe, o el archivo tiene finales de línea `CRLF` (típico si se editó en Windows) | Revisa con `file script.sh`; si dice `CRLF`, conviértelo con `dos2unix script.sh` |
| `bc is not installed` al correr `horserace.sh` | Falta la utilidad `bc` en la VM | `sudo apt update && sudo apt install -y bc` (Ubuntu/Debian) |
| El script corre pero las variables que exporta no quedan disponibles después | Lo ejecutaste con `./script.sh` en vez de `source script.sh` | Usa `source script.sh` cuando necesites conservar variables/entorno en tu shell actual |

## Checklist antes de continuar a Act_2.2.2

- [ ] Puedo explicar qué hace el shebang y por qué importa.
- [ ] Sé identificar y otorgar permisos de ejecución con `chmod`.
- [ ] Entiendo la diferencia entre `./script.sh`, `bash script.sh` y `source script.sh`.
- [ ] Probé interrumpir un script en ejecución y entendí qué hace `trap`.

## Recursos adicionales

- `man chmod`, `man bash` directamente en la VM.
- [Bash Guide for Beginners (TLDP)](https://tldp.org/LDP/Bash-Beginners-Guide/html/)
- [Advanced Bash-Scripting Guide](https://tldp.org/LDP/abs/html/) — de donde proviene originalmente `horserace.sh` como ejemplo didáctico.
