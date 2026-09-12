# Act 2.3.2 — Instalación de Docker (Desktop y Engine)

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Instalación de Docker |
| **RA** | RA2 |
| **IL** | IL 2.2 — Despliega aplicaciones utilizando contenedores |
| **Tiempo estimado** | 1 hora |

## Contexto ampliado

La guía pide instalar Docker en **dos variantes**: Docker Desktop (Windows) y Docker Engine (Linux, ej. Ubuntu), y que puedas explicar la diferencia entre ambas. Esta actividad es más "instalación guiada" que "caso a resolver", así que aquí sí conviene tener el comando exacto a mano — lo que se evalúa es que entiendas **qué instalaste y por qué es distinto** en cada plataforma.

## Conceptos clave

**Imagen vs. contenedor.** Una *imagen* es una plantilla de solo lectura (sistema de archivos + metadata: variables de entorno, comando por defecto, etc.). Un *contenedor* es una instancia en ejecución de esa imagen, con una capa de escritura propia encima. Muchos contenedores pueden nacer de la misma imagen sin interferirse entre sí.

**Docker Desktop vs. Docker Engine — la diferencia real:**

| | Docker Engine | Docker Desktop |
|---|---|---|
| Qué es | El daemon (`dockerd`) + CLI, corriendo nativamente sobre el kernel Linux | Una aplicación de escritorio (Win/Mac) que **por debajo** levanta una VM Linux liviana y dentro corre Docker Engine |
| Por qué existe | Los contenedores Linux comparten el kernel del host — necesitan un kernel Linux real | Windows/macOS no tienen kernel Linux nativo, así que Desktop resuelve eso con una VM (en Windows, vía WSL2) |
| Incluye | Solo el motor y la CLI | Motor + VM + GUI + Docker Compose + extensiones, todo empaquetado |
| Uso típico | Servidores, VMs en la nube, CI/CD | Estaciones de trabajo de desarrolladores |

En otras palabras: en Linux, Docker corre "directo"; en Windows/Mac, siempre hay una VM Linux invisible de por medio — Desktop solo te la esconde y te da una interfaz gráfica encima.

## Guía paso a paso

### A. Docker Engine en Ubuntu (VM Linux en AWS Academy)

1. Conéctate a tu instancia Linux del Learner Lab.
2. Actualiza los repositorios e instala dependencias:
   ```bash
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg
   ```
3. Agrega la clave GPG oficial y el repositorio de Docker (pasos detallados y actualizados siempre en la documentación oficial — la versión exacta de Ubuntu la define tu docente):
   ```bash
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```
4. Instala el motor:
   ```bash
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
5. Verifica:
   ```bash
   sudo docker --version
   sudo docker run hello-world
   ```
6. (Recomendado) Evita usar `sudo` en cada comando agregando tu usuario al grupo `docker`:
   ```bash
   sudo usermod -aG docker $USER
   ```
   Cierra sesión y vuelve a entrar para que el cambio de grupo tome efecto.

### B. Docker Desktop en Windows

1. Descarga el instalador desde la documentación oficial de Docker (enlace abajo) para la versión de Windows que definas con tu docente.
2. Durante la instalación, Desktop te pedirá habilitar **WSL2** (Windows Subsystem for Linux) si no lo tienes activo — es el mecanismo que le da a Windows un kernel Linux real para correr los contenedores.
3. Reinicia si el instalador lo solicita.
4. Abre Docker Desktop y espera a que el ícono de la ballena indique "Docker is running".
5. Verifica desde PowerShell o CMD:
   ```powershell
   docker --version
   docker run hello-world
   ```

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `permission denied while trying to connect to the Docker daemon socket` (Linux) | Tu usuario no pertenece al grupo `docker` | `sudo usermod -aG docker $USER` y reinicia sesión, o usa `sudo docker ...` mientras tanto |
| Docker Desktop no arranca / se queda "Starting" | WSL2 no está habilitado o desactualizado (Windows) | Habilita WSL2 en "Turn Windows features on or off" y actualiza el kernel WSL con `wsl --update` |
| `Cannot connect to the Docker daemon` (Linux) | El servicio `docker` no está corriendo | `sudo systemctl status docker` / `sudo systemctl start docker` |
| `docker: command not found` tras instalar | Instalación incompleta o terminal no recargada | Verifica el paso de instalación de `docker-ce-cli`; abre una terminal nueva |

## Checklist antes de entregar

- [ ] `docker run hello-world` corre exitosamente en la VM Linux (Engine).
- [ ] Docker Desktop instalado y funcionando en Windows (o lo documentaste si no tienes acceso a Windows y usaste una alternativa acordada con tu docente).
- [ ] Puedes explicar con tus palabras la diferencia entre Docker Desktop y Docker Engine — no solo "uno es para Windows y otro para Linux", sino **por qué** (el tema del kernel/VM).
- [ ] Máquina virtual detenida/eliminada al terminar.

## Recursos adicionales

- [Get Docker — documentación oficial](https://docs.docker.com/get-docker/)
- [Docker Engine install (Ubuntu)](https://docs.docker.com/engine/install/ubuntu/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
