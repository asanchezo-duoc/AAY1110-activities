# AAY1110 — Sistemas Operativos Corporativos en Cloud

Material de apoyo para las actividades prácticas de la asignatura **AAY1110 (Sistemas Operativos Corporativos en Cloud)**, enfocado en Shell scripting, Docker y Git.

Este repositorio **no reemplaza** las guías oficiales entregadas en AVA: las **amplía**. Cada actividad conserva el mismo caso/objetivo del laboratorio oficial, pero agrega más contexto, ejemplos intermedios, comandos explicados paso a paso y troubleshooting típico, para que puedas avanzar con menos fricción antes de llegar al aula/laboratorio.

## Estructura

```
EA2/
├── Act_2.1.2/   Ejecución de scripts (fundamentos de Shell)
├── Act_2.2.2/   Script de respaldo automatizado con cron
├── Act_2.3.1/   Práctica de conceptos: contenedores, Docker y Git
├── Act_2.3.2/   Instalación de Docker (Desktop y Engine)
├── Act_2.3.3/   Creación de imágenes con Dockerfile y DockerHub
└── Act_2.3.4/   Fundamentos de Docker + Git/GitHub

recursos/
├── bash-basico/   Un script de ejemplo por cada elemento básico de Bash
└── cron-at/       Ejemplos comentados de cron y at
```

Cada carpeta `Act_2.X.Y` tiene su propio `README.md` con:

- Metadata oficial de la actividad (RA, IL, tiempo estimado).
- Contexto ampliado y conceptos clave explicados.
- Guía paso a paso con comandos de referencia y su explicación.
- Errores comunes / troubleshooting.
- Checklist de verificación antes de entregar en AVA.
- Recursos adicionales para profundizar.

> Este material **no contiene las soluciones finales** que se entregan como evidencia — es apoyo para entender el "cómo" y el "por qué" antes de resolver el caso planteado por tu docente.

Ver [EA2/README.md](EA2/README.md) para el detalle de la evaluación y el listado completo de actividades.

## Recursos de referencia (independientes de la evaluación)

- [recursos/bash-basico](recursos/bash-basico/) — hola mundo, `echo`, `printf`, `for`, `while`, `if`: un ejemplo mínimo por elemento, para repasar antes de las actividades de EA2.
- [recursos/cron-at](recursos/cron-at/) — ejemplos comentados de `cron` (tareas recurrentes) y `at` (tareas de una sola ejecución futura).
