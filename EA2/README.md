# EA2 — Actividades de apoyo

**Asignatura:** AAY1110 · Sistemas Operativos Corporativos en Cloud
**Resultado de Aprendizaje:** RA2 — Automatiza procesos y tareas de sistemas operativos para asegurar la continuidad operacional de los servicios de red en servidores Linux y Windows.

## Indicadores de logro cubiertos

| IL | Descripción |
|----|-------------|
| IL 2.1 | Construye rutinas para automatizar tareas administrativas en los sistemas operativos de acuerdo con los casos planteados. |
| IL 2.2 | Despliega aplicaciones utilizando contenedores optimizando recursos para mejorar la escalabilidad y portabilidad en entornos de desarrollo y producción. |
| IL 2.3 | Diferencia los tipos de respaldo de datos en un sistema de acuerdo con los requerimientos específicos. |
| IL 2.4 | Gestiona respaldos y recuperación de datos a través de scripting y crontab según las políticas de seguridad definidas por la organización. |

## Actividades

| Carpeta | Tema | IL principal | Herramientas |
|---|---|---|---|
| [Act_2.1.2](Act_2.1.2/) | Ejecución de scripts (fundamentos de Shell) | IL 2.1 | Bash, AWS Academy Learner Lab |
| [Act_2.2.1](Act_2.2.1/) | Qué respaldar, y cómo crear/ejecutar/loguear un script en Linux y Windows (contraparte de la clase teórica en PPT) | IL 2.1, IL 2.3, IL 2.4 | Bash, `logger`, PowerShell, Event Log, Programador de tareas |
| [Act_2.2.2](Act_2.2.2/) | Script de respaldo automatizado con cron | IL 2.1, IL 2.3, IL 2.4 | Bash, tar, cron |
| [Act_2.3.1](Act_2.3.1/) | Práctica de conceptos: contenedores, Docker y Git (contraparte de la clase teórica en PPT) | IL 2.2 | Docker docs, GitHub Skills |
| [Act_2.3.2](Act_2.3.2/) | Instalación de Docker (Desktop y Engine) | IL 2.2 | Docker Desktop, Docker Engine |
| [Act_2.3.3](Act_2.3.3/) | Creación de imágenes con Dockerfile y DockerHub | IL 2.2 | Docker Build, DockerHub |
| [Act_2.3.4](Act_2.3.4/) | Fundamentos de Docker + Git/GitHub | IL 2.2 | Git, GitHub, Docker CLI |

## Recomendación de avance

Las actividades están ordenadas de forma incremental: cada una da por hecho lo que ya se practicó en la anterior (ej. Act_2.2.2 asume que ya sabes crear/ejecutar un script con logging desde Act_2.2.1; Act_2.3.2 asume los conceptos vistos en Act_2.3.1; Act_2.3.4 asume que Docker ya está instalado desde Act_2.3.2, y que ya existe una imagen construida desde Act_2.3.3). Conviene resolverlas en orden.

> Act_2.2.1 y Act_2.3.1 son la contraparte práctica de clases teóricas que se dictan en PPT (no un `.docx` de laboratorio como el resto) — por eso su formato es distinto: menos "instalar y verificar", más ejercicios guiados sobre un ejemplo genérico, sin ser la evidencia final a entregar.

Todas usan **AWS Academy Learner Lab** para levantar la máquina virtual Linux. Recuerda siempre **detener/eliminar la instancia al terminar** para no seguir consumiendo créditos del laboratorio.
