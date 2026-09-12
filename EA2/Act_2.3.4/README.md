# Act 2.3.4 — Fundamentos de Docker + Git/GitHub

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Actividad Fundamentos de Docker y Git |
| **RA** | RA2 |
| **IL** | IL 2.2 |
| **Tiempo estimado** | 1 hora |

## Contexto ampliado

Esta actividad cierra el ciclo: versionas con Git los archivos que creaste en Act_2.3.3 (Dockerfile + código de la app), los subes a GitHub, los clonas en una instancia de nube nueva, y desde ahí levantas y administras el contenedor completo (estadísticas, reinicio, detención, rename, eliminación). Es, en esencia, un mini flujo de CI/CD manual.

## Conceptos clave

**Git vs. GitHub.** Git es el sistema de control de versiones (funciona 100% local, sin internet). GitHub es un servicio que **hospeda** repositorios Git remotos y agrega colaboración (pull requests, issues, etc.). Puedes usar Git sin GitHub; GitHub sin Git no tiene sentido.

**El flujo básico de Git:**

```
directorio de trabajo  --git add-->  área de staging  --git commit-->  historial local  --git push-->  remoto (GitHub)
```

| Comando | Qué hace |
|---|---|
| `git init` | Convierte la carpeta actual en un repositorio Git (crea `.git/`) |
| `git status` | Muestra qué archivos están modificados/sin trackear/en staging |
| `git add archivo` (o `git add .`) | Mueve cambios al área de staging — lo que **va a entrar** en el próximo commit |
| `git commit -m "mensaje"` | Guarda una fotografía (snapshot) permanente de lo que está en staging, en el historial local |
| `git remote add origin URL` | Registra la URL del repositorio remoto con el nombre `origin` |
| `git push -u origin main` | Sube los commits locales al remoto (la primera vez, `-u` fija el upstream para que después baste `git push`) |
| `git clone URL` | Descarga un repositorio remoto completo (con su historial) a una carpeta nueva |
| `git log --oneline` | Historial de commits, resumido |

**Comandos de gestión de contenedores que pide la guía:**

| Acción | Comando |
|---|---|
| Iniciar contenedor desde una imagen | `docker run -d --name mi_contenedor -p 8080:80 usuario/imagen:v1` |
| Ver estadísticas en vivo (CPU, memoria, red) | `docker stats mi_contenedor` |
| Reiniciar | `docker restart mi_contenedor` |
| Detener | `docker stop mi_contenedor` |
| Renombrar | `docker rename mi_contenedor nuevo_nombre` |
| Eliminar el contenedor (debe estar detenido, o usar `-f`) | `docker rm nuevo_nombre` / `docker rm -f nuevo_nombre` |
| Eliminar la imagen asociada | `docker rmi usuario/imagen:v1` |

## Guía paso a paso

1. **Instala Git** en tu equipo (Windows: instalador oficial; incluye Git Bash). En Linux (VM), normalmente ya está o se instala con `sudo apt install -y git`.
2. **Configura tu identidad** (una sola vez por equipo):
   ```bash
   git config --global user.name "Tu Nombre"
   git config --global user.email "tu_correo@duocuc.cl"
   ```
3. **Crea una cuenta en GitHub** (si no tienes) y crea un **repositorio público** nuevo desde la web (sin inicializarlo con README, para evitar conflictos al hacer el primer push).
4. **Organiza localmente** los archivos de Act_2.3.3 (Dockerfile, código de la app) en un directorio dedicado, por ejemplo `mi-proyecto-docker/`.
5. **Inicializa el repo y versiona:**
   ```bash
   cd mi-proyecto-docker
   git init
   git add .
   git commit -m "Primer commit: Dockerfile y app de Act_2.3.3"
   ```
6. **Conecta con el remoto y sube:**
   ```bash
   git remote add origin https://github.com/tu_usuario/tu_repositorio.git
   git branch -M main
   git push -u origin main
   ```
   Nota: desde 2021 GitHub ya no acepta autenticación con contraseña por HTTPS — necesitas un **Personal Access Token (PAT)** (Settings → Developer settings → Personal access tokens) o autenticación por SSH.
7. **Crea una instancia Linux nueva** en la nube (AWS Academy) — simula un entorno de despliegue distinto al que usaste para construir la imagen.
8. **Clona el repositorio ahí:**
   ```bash
   git clone https://github.com/tu_usuario/tu_repositorio.git
   ```
9. **Levanta el contenedor** a partir de la imagen (puedes usar la que subiste a DockerHub en Act_2.3.3, o reconstruirla localmente con el Dockerfile clonado — confirma con tu docente cuál corresponde a tu caso).
10. **Ejecuta y observa** cada comando de gestión: `docker stats`, `docker restart`, `docker stop`, `docker rename`, `docker rm`, `docker rmi` — en ese orden tiene sentido, porque no puedes eliminar un contenedor corriendo (sin `-f`) ni una imagen con contenedores dependiendo de ella.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `remote: Support for password authentication was removed` al hacer `push` | GitHub ya no acepta password por HTTPS | Usa un Personal Access Token como contraseña, o configura autenticación SSH |
| `fatal: refusing to merge unrelated histories` | Creaste el repo en GitHub con README/licencia y localmente también tienes commits | `git pull origin main --allow-unrelated-histories` y resuelve conflictos si aparecen, o evita inicializar el remoto con archivos al crearlo |
| `error: failed to push some refs` | El remoto tiene commits que no están en tu copia local | `git pull origin main` antes de volver a hacer `push` |
| `Error response from daemon: You cannot remove a running container` | Intentaste `docker rm` sobre un contenedor activo | `docker stop nombre` primero, o usa `docker rm -f nombre` |
| `Error response from daemon: conflict: unable to delete image ... image is being used by stopped container` | Hay contenedores (aunque detenidos) usando esa imagen | Elimina esos contenedores (`docker rm`) antes de `docker rmi` |

## Checklist antes de entregar

- [ ] Repositorio público en GitHub con al menos un commit del Dockerfile y la app.
- [ ] Instancia de nube nueva con el repo clonado exitosamente.
- [ ] Contenedor iniciado, con evidencia de `docker stats`, `restart`, `stop`, `rename`, `rm` y `rmi` ejecutados en orden lógico.
- [ ] Puedes explicar la diferencia entre Git y GitHub con tus palabras.
- [ ] Instancias/VMs detenidas o eliminadas al terminar.

## Recursos adicionales

- [Instalación de Git](https://git-scm.com/downloads)
- [Documentación de comandos Git](https://git-scm.com/docs)
- [GitHub — primeros pasos](https://docs.github.com/es/get-started)
- [Docker CLI reference](https://docs.docker.com/engine/reference/commandline/cli/)
