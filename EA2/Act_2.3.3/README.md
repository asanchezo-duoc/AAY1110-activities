# Act 2.3.3 — Creación de imágenes con Dockerfile y DockerHub

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Creación de imágenes con Dockerfile |
| **RA** | RA2 |
| **IL** | IL 2.2 |
| **Tiempo estimado** | 1 hora |

## Contexto ampliado

Aquí pasas de *usar* Docker a *construir* tus propias imágenes. La guía oficial pide: registrarte en DockerHub, construir y subir (`push`) una imagen, y luego bajarla (`pull`) y correrla desde otro entorno Docker Engine. Este README explica la mecánica con un **ejemplo genérico** (`ejemplo/Dockerfile`, una página estática con nginx) — tu entrega debe usar tu propia imagen/aplicación, no este ejemplo.

> Guarda los archivos que generes aquí: la siguiente actividad (Act_2.3.4) los reutiliza para versionarlos con Git y desplegarlos desde un repositorio clonado en una VM.

## Conceptos clave

**Anatomía de un Dockerfile.** Cada instrucción crea una **capa**. Docker cachea capas: si no cambias una línea ni lo que depende de ella, la reconstrucción reutiliza la capa cacheada en vez de rehacerla — por eso el **orden importa** (poner lo que cambia menos, como instalar dependencias, antes de lo que cambia más, como copiar tu código).

| Instrucción | Para qué sirve |
|---|---|
| `FROM` | Imagen base — **siempre la primera instrucción real** |
| `LABEL` | Metadata (mantenedor, descripción, versión) |
| `RUN` | Ejecuta un comando **durante el build** (ej. instalar paquetes) |
| `COPY` / `ADD` | Copia archivos del contexto de build hacia la imagen |
| `WORKDIR` | Define el directorio de trabajo dentro de la imagen |
| `EXPOSE` | Documenta qué puerto usa la app (no lo publica por sí solo) |
| `ENV` | Define variables de entorno disponibles en el contenedor |
| `CMD` | Comando por defecto al iniciar un contenedor (se puede sobreescribir al hacer `docker run`) |
| `ENTRYPOINT` | Comando fijo que siempre corre; `CMD` pasa a ser sus argumentos por defecto |

Mira `ejemplo/Dockerfile` para ver estas instrucciones aplicadas a un caso mínimo real.

**Construir la imagen:**
```bash
docker build -t tu_usuario_dockerhub/nombre_imagen:v1 .
```
- `-t` le da nombre y tag (versión). El `.` al final es el **contexto de build**: la carpeta que Docker empaqueta y envía al daemon para construir (por eso el Dockerfile suele vivir junto al código que necesita `COPY`).

**Probar localmente antes de subir:**
```bash
docker run -d -p 8080:80 --name prueba tu_usuario_dockerhub/nombre_imagen:v1
```
- `-d`: en segundo plano (detached). `-p 8080:80`: mapea el puerto 8080 del host al 80 del contenedor. `--name`: le da un nombre legible en vez de un hash.

## Guía paso a paso

1. **Regístrate en DockerHub** (hub.docker.com) si aún no tienes cuenta.
2. **Autentícate desde la terminal:**
   ```bash
   docker login
   ```
3. **Diseña tu Dockerfile** para la aplicación/caso que te haya definido tu docente (usa `ejemplo/Dockerfile` solo como referencia de sintaxis, no lo copies literal).
4. **Construye la imagen** con un nombre que incluya tu usuario de DockerHub, porque así es como Docker sabe a qué repositorio remoto pertenece:
   ```bash
   docker build -t tu_usuario_dockerhub/nombre_imagen:v1 .
   ```
5. **Pruébala localmente** (`docker run ...` como arriba) y confirma que responde como esperas.
6. **Súbela a DockerHub:**
   ```bash
   docker push tu_usuario_dockerhub/nombre_imagen:v1
   ```
7. **Simula "otro entorno":** en la misma VM o en otra, elimina la imagen local y bájala de nuevo desde el repositorio para confirmar que el flujo build → push → pull → run realmente funciona de punta a punta:
   ```bash
   docker rmi tu_usuario_dockerhub/nombre_imagen:v1
   docker pull tu_usuario_dockerhub/nombre_imagen:v1
   docker run -d -p 8080:80 tu_usuario_dockerhub/nombre_imagen:v1
   ```
8. **Guarda tus archivos** (Dockerfile + código de la app) — los necesitarás en Act_2.3.4 para versionarlos con Git.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `denied: requested access to the resource is denied` al hacer `push` | El nombre de la imagen no incluye tu usuario de DockerHub, o no hiciste `docker login` | El tag debe ser `usuario/nombre:tag`; verifica sesión con `docker login` |
| El build tarda mucho / reconstruye todo cada vez | Copiaste todo el código antes de instalar dependencias, invalidando el cache en cada cambio | Copia primero los archivos de dependencias (ej. lockfiles), instala, y recién después copia el resto del código |
| `docker: Error response from daemon: driver failed programming external connectivity` | El puerto del host ya está en uso | Cambia el puerto del host: `-p 8081:80` en vez de `8080:80`, o detén el proceso que lo ocupa |
| El contenedor se detiene inmediatamente tras `docker run` | El proceso principal (`CMD`/`ENTRYPOINT`) terminó (por ejemplo, un proceso que no corre en primer plano) | Revisa logs con `docker logs nombre_contenedor`; asegúrate que el proceso principal se mantenga en foreground |

## Checklist antes de entregar

- [ ] Imagen construida localmente y probada con `docker run`.
- [ ] Imagen subida a un repositorio en DockerHub bajo tu cuenta.
- [ ] Verificaste el flujo completo: eliminar imagen local → `pull` desde DockerHub → correrla de nuevo.
- [ ] Guardaste el Dockerfile y los archivos de la app para la siguiente actividad.
- [ ] Puedes explicar qué es una capa y por qué el orden de instrucciones afecta el cache del build.

## Recursos adicionales

- [Docker Build — documentación oficial](https://docs.docker.com/build/)
- [Docker Compose](https://docs.docker.com/compose/)
- [DockerHub](https://docs.docker.com/docker-hub/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
