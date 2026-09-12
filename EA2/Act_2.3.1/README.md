# Act 2.3.1 — Práctica de conceptos: Contenedores, Docker y Git

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Implementación de contenedores en la nube pública (clase teórica, PPT) |
| **RA** | RA2 |
| **IL** | IL 2.2 |
| **Tiempo estimado** | 1 hora |

## Contexto

Esta es la **contraparte práctica** de la clase teórica "Implementación contenedores en la nube pública" que se pasa en PPT. Esa clase cubre tres bloques conceptuales — bare-metal vs. VM vs. contenedores, fundamentos de Docker, y fundamentos de Git/GitHub — y trae **dos actividades embebidas** que conviene resolver antes de llegar a [Act_2.3.2](../Act_2.3.2/) (instalación de Docker): un resumen guiado de la documentación oficial de Docker, y el curso oficial "Introduction to GitHub" de GitHub Skills.

Aquí encontrarás una guía para completar esas dos actividades con más estructura, más un ejercicio corto para fijar el concepto de contenedor antes de instalar nada.

## Parte A — Bare-metal vs. Máquinas Virtuales vs. Contenedores

La clase presenta tres formas de ejecutar software, en orden de menos a más eficiente para desplegar en distintos entornos:

| Modelo | Qué comparte con el host | Aislamiento | Peso |
|---|---|---|---|
| Bare-metal | Todo (instalación directa en el servidor físico) | Ninguno | — |
| Máquina Virtual | Solo el hardware (vía hipervisor) | Total: cada VM tiene su propio SO completo | Pesado (SO completo por VM) |
| Contenedor | El kernel del sistema operativo host | Procesos aislados, pero comparten kernel | Liviano (sin SO propio) |

**Ejercicio de reflexión (individual o en pareja, 10 min):** completa esta tabla con tus propias palabras, pensando en un caso concreto (por ejemplo, desplegar la misma aplicación web en 5 servidores distintos):

| Pregunta | Tu respuesta |
|---|---|
| ¿Por qué instalar el software 5 veces "a mano" (bare-metal) es riesgoso? | |
| ¿Qué gana una VM que no tiene el bare-metal? ¿Qué le cuesta más caro? | |
| ¿Qué gana un contenedor que no tiene una VM? | |
| Si el contenedor comparte el kernel del host, ¿qué implica eso para correr un contenedor Linux sobre Windows? (pista: revisa [Act_2.3.2](../Act_2.3.2/) — Docker Desktop y WSL2) | |

## Parte B — Resumen guiado: Docker Overview

La clase pide, en parejas y en 15 minutos: revisar `docs.docker.com/get-started/docker-overview` y hacer un resumen de una plana. Para que ese resumen tenga sustancia (y no sea solo copiar párrafos), respondan estas preguntas **con sus propias palabras** — ese conjunto de respuestas ya es su resumen de una plana:

1. ¿Qué problema concreto resuelve Docker que antes obligaba a decir "en mi máquina funciona"?
2. ¿Qué es el Docker Daemon y con qué se comunica el Docker Client?
3. ¿Qué diferencia hay entre una imagen y un contenedor? (deberían poder explicarlo sin mirar el apunte)
4. ¿Qué es un Registry, y qué rol cumple DockerHub como uno de ellos?
5. Nombren un caso de uso donde usarían Docker en su futuro trabajo, y por qué no usarían una VM completa para eso.

> Guarden este resumen — les sirve como base conceptual antes de instalar Docker en [Act_2.3.2](../Act_2.3.2/).

## Parte C — GitHub Skills: "Introduction to GitHub"

La clase deriva a un curso oficial y gratuito de GitHub para aprender lo básico de GitHub haciendo, no solo leyendo. A diferencia de [Act_2.3.4](../Act_2.3.4/) (que versiona con Git el Dockerfile del laboratorio), este curso es un ejercicio autocontenido centrado en el **flujo de colaboración de GitHub** (branches, commits, pull requests), usando GitHub mismo como entorno — no requiere tu VM Linux.

**Pasos:**

1. Si no tienes cuenta, créala en [github.com](https://github.com).
2. Ve al curso **"Introduction to GitHub"** dentro de [GitHub Skills](https://skills.github.com/) (busca "Introduction to GitHub" en el catálogo).
3. Acepta la invitación del curso — esto crea automáticamente un repositorio de práctica en tu cuenta, con instrucciones que aparecen como *issues*.
4. Sigue las instrucciones del curso, que te van a pedir, en este orden:
   - Crear una rama (branch).
   - Confirmar un archivo (commit) — el curso te hace editar un README en Markdown.
   - Abrir un pull request desde tu rama hacia `main`.
   - Fusionar (merge) tu propio pull request.
5. El resultado queda como un repositorio real en tu cuenta de GitHub, con un README que puedes seguir usando como perfil.

**Por qué este orden importa (conexión con lo que ya sabes de Git):** `branch` te da un espacio aislado para trabajar sin tocar `main` directamente; el `commit` registra el cambio; el `pull request` es la instancia de **revisión** antes de integrar (en equipos reales, alguien más lo aprueba); el `merge` es lo que finalmente lleva el cambio a `main`. Es el mismo flujo que después vas a usar "a mano" con la línea de comandos en Act_2.3.4, solo que aquí lo haces completo desde la interfaz web de GitHub.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| No encuentro "Introduction to GitHub" en GitHub Skills | El catálogo de cursos cambia de nombre/orden ocasionalmente | Busca por "GitHub Skills" en Google y entra al catálogo desde ahí; el curso también puede aparecer como parte de una ruta de aprendizaje ("learning path") |
| El curso no me deja hacer merge de mi propio pull request | Configuración de protección de rama poco común en cuentas nuevas, o falta de permisos | Verifica que el repositorio de práctica sea tuyo (lo crea el curso automáticamente); si persiste, revisa la sección de ayuda del propio curso (son *issues* con instrucciones) |
| Confundo `branch`, `commit`, `pull request` y `merge` | Son conceptos nuevos y se usan juntos | Vuelve a la tabla de la Parte A y a [Act_2.3.4](../Act_2.3.4/), donde se explican los mismos comandos vía terminal |

## Checklist antes de continuar a Act_2.3.2

- [ ] Completaste la tabla de reflexión bare-metal / VM / contenedores.
- [ ] Tienes tu resumen de una plana de Docker Overview (las 5 preguntas respondidas).
- [ ] Terminaste el curso "Introduction to GitHub" — tienes un repositorio propio con al menos un commit y un pull request fusionado.
- [ ] Puedes explicar, sin mirar el apunte, la diferencia entre imagen y contenedor.

## Recursos adicionales

- [Docker overview (docs oficiales)](https://docs.docker.com/get-started/docker-overview/)
- [GitHub Skills — catálogo de cursos](https://skills.github.com/)
- [¿Qué es Git? (docs oficiales)](https://git-scm.com/book/es/v2/Inicio---Sobre-el-Control-de-Versiones-Acerca-del-Control-de-Versiones)
