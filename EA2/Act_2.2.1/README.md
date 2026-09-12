# Act 2.2.1 — Crear y ejecutar un script con logging al sistema

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Gestión de Respaldos a través de Scripting y Tareas Programadas (clase teórica, PPT) |
| **RA** | RA2 |
| **IL** | IL 2.1, IL 2.3, IL 2.4 |
| **Tiempo estimado** | 1,5 horas |

## Contexto

Esta es la **contraparte práctica** de la clase teórica "Gestión de Respaldos a través de Scripting y Tareas Programadas", que precede a [Act_2.2.2](../Act_2.2.2/) (el laboratorio evaluado de respaldo con cron). Esa clase muestra un script en Linux (bash) y su equivalente en Windows (PowerShell), ambos con su propia tarea programada.

Aquí el foco es distinto y más detallado que la clase: qué se respalda y por qué, **cómo se construye un script paso a paso** (en Linux y en Windows), y sobre todo, cómo hacer que **quede registrado en el log del sistema** — no solo en un archivo de texto propio — para que después puedas revisarlo con las herramientas estándar de administración (`journalctl`/`/var/log/syslog` en Linux, Visor de Eventos en Windows). Esto es lo que la clase teórica llama "Verificación y Notificación" dentro del flujo de trabajo del respaldo automatizado.

> Los scripts de este README son **ejemplos genéricos** (`scripts/ejemplo_logger.sh` / `.ps1`), con rutas de prueba en `/tmp` o `C:\Temp`. No son el script de respaldo que se entrega en Act_2.2.2 — son para que practiques la mecánica de crear, ejecutar y loguear antes de resolver el caso real.

## Parte A — ¿Qué deberíamos respaldar?

Antes de escribir cualquier script, la pregunta que manda no es "¿cómo comprimo una carpeta?" sino **qué datos son realmente críticos**. En general, todo lo que hay que proteger cae en dos categorías:

| Categoría | Qué respaldar (ejemplos) | Por qué eso y no "todo el disco" |
|---|---|---|
| **Servicios** | La **configuración**, no el software instalado. Ej.: `/etc/nginx/` (sitios, certificados), `/etc/ssh/sshd_config` (hardening, puertos), `/etc/mysql/my.cnf` + un *dump* lógico de la base (`mysqldump`, no copiar los archivos crudos en caliente) | El paquete (`nginx`, `mysql-server`) se reinstala en segundos con el gestor de paquetes. Lo que **no** se puede recrear automáticamente es la configuración personalizada — dominios, reglas, credenciales, ajustes de seguridad ya aplicados |
| **Usuarios** | El **directorio personal**: `/home/usuario` en Linux, `C:\Users\usuario` en Windows — documentos, configuraciones propias (`.bashrc`, `.ssh/config`, `.gitconfig`), archivos de trabajo | Es contenido que el usuario generó y que no vive en ningún repositorio ni gestor de paquetes; si se pierde, se pierde para siempre |

**Lo que normalmente NO se respalda** (y por qué): binarios y paquetes instalados (se reinstalan desde el repositorio de paquetes), archivos temporales/cache (`/tmp`, `/var/cache`), logs ya rotados y antiguos (salvo que exista una obligación de retención por compliance).

**Ejercicio de reflexión:** el caso de [Act_2.2.2](../Act_2.2.2/) respalda `/home/usuario/datos` — ¿es un respaldo de "servicio" o de "usuario", según esta tabla? Si en vez de eso tu docente te pidiera respaldar `/etc/nginx`, ¿cambiaría en algo la lógica del script, o solo cambia qué carpeta se comprime?

## Parte B — Crear y ejecutar un script en Linux, paso a paso

1. **Crea el archivo** con un editor de texto en tu VM Linux (`nano ejemplo_logger.sh`, o cópialo desde `scripts/ejemplo_logger.sh`).
2. **Revisa el shebang** (`#!/bin/bash`, primera línea): le dice al sistema qué intérprete usar. Sin él, el comportamiento depende de cómo invoques el script (ver [Act_2.1.2](../Act_2.1.2/)).
3. **Dale permiso de ejecución:**
   ```bash
   chmod +x ejemplo_logger.sh
   ```
4. **Ejecútalo:**
   ```bash
   ./ejemplo_logger.sh
   ```
5. **Revisa qué generó:**
   ```bash
   cat /tmp/act221-ejemplo/destino/respaldo.log
   ls /tmp/act221-ejemplo/destino/
   ```

Hasta aquí es exactamente el patrón que ya conoces de Act_2.1.2 y Act_2.2.2: shebang → permisos → ejecución → revisar salida. Lo nuevo viene ahora.

## Parte C — Por qué no basta con un archivo de log propio

Un archivo de log propio (como `respaldo.log`) tiene un problema práctico: **solo tú sabes que existe y dónde está**. En un sistema real, un administrador que no escribió el script no va a ir a buscar `/tmp/tu-carpeta/tu-log.txt` — va a mirar donde miran **todos** los servicios del sistema: el log centralizado del sistema operativo.

Por eso este ejercicio agrega una segunda línea de registro, usando la herramienta que existe justamente para eso: `logger` (Linux).

## Parte D — `logger`: registrar en el log del sistema (Linux)

`logger` es un comando que **envía un mensaje al sistema de logging del sistema operativo** (syslog, o `journald` en distribuciones con systemd — Ubuntu, Debian, etc.), en vez de escribirlo tú mismo en un archivo.

```bash
logger -t "respaldo_ejemplo" "Inicio de respaldo: $ARCHIVO"
logger -t "respaldo_ejemplo" -p user.err "ERROR al generar respaldo (código $RESULTADO)"
```

- `-t "respaldo_ejemplo"`: el **tag** — una etiqueta que te permite luego filtrar solo los mensajes de tu script entre miles de otros mensajes del sistema.
- `-p user.err`: la **prioridad** (`facility.level`). `user` es la facility genérica para procesos de usuario; `err` marca que es un error (otros niveles comunes: `info`, `warning`, `crit`). Si no se especifica, el valor por defecto es `user.notice`.

**Revisar el mensaje después de ejecutar el script**, con la herramienta que corresponda a tu distribución:

```bash
# En distribuciones con systemd (Ubuntu, Debian moderno, etc.)
journalctl -t respaldo_ejemplo

# Alternativa universal (o si no usas systemd)
grep respaldo_ejemplo /var/log/syslog        # Debian/Ubuntu
grep respaldo_ejemplo /var/log/messages       # RHEL/CentOS/Amazon Linux
```

`journalctl -t respaldo_ejemplo -f` además te deja **siguiendo el log en vivo** (como `tail -f`), muy útil si programas el script en cron y quieres ver la próxima ejecución en tiempo real.

## Parte E — Fundamentos de scripting en PowerShell

Si vienes de bash, PowerShell tiene una lógica distinta que conviene fijar antes de escribir el script de respaldo en Windows:

| Concepto | Bash | PowerShell |
|---|---|---|
| Extensión de archivo | `.sh` | `.ps1` |
| Definir variable | `NOMBRE="valor"` | `$Nombre = "valor"` (siempre con `$`) |
| Imprimir en pantalla | `echo "texto"` | `Write-Output "texto"` (o simplemente `"texto"`) |
| Listar archivos | `ls` | `Get-ChildItem` (alias: `ls`, `dir`) |
| Ver contenido de un archivo | `cat archivo` | `Get-Content archivo` (alias: `cat`) |
| Comprobar si existe una ruta | `[ -f archivo ]` | `Test-Path archivo` |
| Nombrar comandos (cmdlets) | libre (`grep`, `awk`, `tar`...) | patrón fijo **Verbo-Sustantivo**: `Get-Date`, `New-Item`, `Compress-Archive`, `Write-EventLog` |

**Cmdlets, no "comandos sueltos":** en PowerShell casi todo tiene la forma `Verbo-Sustantivo` (`Get-`, `New-`, `Write-`, `Test-`, `Compress-`...). Una vez que reconoces el patrón, es fácil adivinar qué hace un cmdlet que no conocías.

**Política de ejecución (Execution Policy):** por seguridad, Windows **bloquea la ejecución de scripts `.ps1` por defecto** (para prevenir que un script malicioso se ejecute solo con doble clic, como pasaba con macros/VBS). Antes de poder correr un script tienes 2 caminos:

```powershell
# Opción 1: cambiar la política para tu usuario (una vez, requiere consentimiento pero no admin)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Opción 2: no cambiar nada globalmente, y forzarlo solo para esta ejecución puntual
powershell -ExecutionPolicy Bypass -File "C:\ruta\al\script.ps1"
```

La Opción 2 es la que vas a usar más adelante para programar la tarea, porque no depende de configurar cada máquina de antemano.

## Parte F — Crear, ejecutar y loguear el script de respaldo en Windows

1. **Crea el archivo** `ejemplo_logger.ps1` (cópialo desde `scripts/ejemplo_logger.ps1`, o escríbelo tú en el Bloc de notas / VS Code).
2. **Léelo con calma** — usa exactamente los conceptos de la Parte E: variables `$SourceDir`/`$BackupDir`, `Get-Date -Format` para el timestamp, `Compress-Archive` para comprimir (el equivalente de `tar -czf`), y `Write-EventLog` para loguear al sistema en vez de a un archivo.
3. **Abre PowerShell como Administrador** (solo necesario para el paso siguiente, una única vez):
   ```powershell
   New-EventLog -LogName Application -Source "RespaldoEjemplo"
   ```
   Esto "registra" tu script como una fuente válida de eventos — sin este paso, `Write-EventLog` falla.
4. **Ejecuta el script:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\ruta\a\ejemplo_logger.ps1"
   ```
5. **Revisa lo que generó:**
   - El archivo comprimido en `$BackupDir`.
   - El evento en el **Visor de eventos**: abre `eventvwr.msc` → *Registros de Windows* → *Aplicación* → busca "Origen" = `RespaldoEjemplo`.
   - O desde PowerShell:
     ```powershell
     Get-EventLog -LogName Application -Source RespaldoEjemplo -Newest 10
     ```

## Parte G — Programar la tarea en Windows (Programador de tareas)

Así como en Linux se usa `crontab -e`, en Windows el equivalente es el **Programador de tareas** (Task Scheduler):

1. Abre el **Programador de tareas** (`taskschd.msc`, o búscalo en el menú Inicio).
2. **Crear tarea básica** → dale un nombre (ej. "Respaldo Ejemplo").
3. Define el **desencadenador** (trigger): con qué frecuencia se ejecuta (diario, a una hora fija — el equivalente a los 5 campos de cron).
4. **Acción → Iniciar un programa:**
   - Programa/script: `powershell`
   - Argumentos: `-ExecutionPolicy Bypass -File "C:\ruta\a\ejemplo_logger.ps1"`
5. Termina el asistente y **haz clic derecho → Ejecutar** sobre la tarea recién creada, para probarla de inmediato sin esperar al horario programado.
6. Verifica igual que en el paso anterior: el archivo generado + el evento en el Visor de eventos.

> Nota: igual que recomendamos en Act_2.2.2 con cron (probar primero con `* * * * *`), aquí conviene probar la tarea con "Ejecutar" manual antes de confiar en que el disparador programado funcione como esperas.

## Parte H — Conectando con "buenas prácticas" (de la clase teórica)

La clase cierra con 5 buenas prácticas de gestión de respaldos. Con lo que acabas de practicar, ya puedes responder cuáles se benefician directamente de loguear al sistema en vez de a un archivo propio:

- **Notificaciones ante fallos:** un mensaje con prioridad `user.err`/`EntryType Error` en el log del sistema es lo que un proceso de monitoreo (por ejemplo, una herramienta que revisa el log centralizado) puede detectar automáticamente — un archivo `.log` perdido en `/tmp` no lo detecta nadie.
- **Verificación periódica:** poder correr `journalctl -t respaldo_ejemplo --since "7 days ago"` (o `Get-EventLog ... -Newest 20` en Windows) te da de inmediato un historial de ejecuciones exitosas/fallidas, sin tener que abrir y parsear un archivo de texto.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `logger: command not found` | Paquete `bsdutils`/`util-linux` no instalado (raro, pero puede pasar en imágenes mínimas) | `sudo apt install -y bsdutils` (Ubuntu/Debian) |
| `journalctl -t respaldo_ejemplo` no muestra nada | El sistema no usa systemd, o el mensaje fue a `/var/log/syslog` en vez de al journal | Prueba `grep respaldo_ejemplo /var/log/syslog` como alternativa |
| El mensaje aparece en el log pero sin el tag | Se llamó a `logger` sin `-t`, o el tag tiene espacios/caracteres especiales | Usa `-t "un_tag_sin_espacios"` |
| `No se puede cargar el archivo ...ps1 porque la ejecución de scripts está deshabilitada` | Execution Policy por defecto (`Restricted`) bloquea el script | Usa `powershell -ExecutionPolicy Bypass -File script.ps1`, o `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| `New-EventLog : Requested registry access is not allowed` (Windows) | PowerShell no se ejecutó como Administrador | Vuelve a abrir PowerShell con "Ejecutar como administrador" — este paso solo se necesita una vez |
| `Get-EventLog` no muestra eventos recientes | El origen (`Source`) no coincide exactamente entre `New-EventLog` y `Write-EventLog` | Verifica que el string de `-Source` sea idéntico en ambos comandos |
| La tarea programada no corre | El Programador de tareas usa una cuenta sin permisos, o la ruta del script tiene espacios sin comillas | Verifica la cuenta configurada en la tarea; envuelve la ruta del script entre comillas dobles en el argumento `-File` |

## Checklist antes de continuar a Act_2.2.2

- [ ] Puedes explicar la diferencia entre respaldar la configuración de un servicio y respaldar el home de un usuario, con un ejemplo de cada uno.
- [ ] Creaste, diste permisos y ejecutaste el script de ejemplo en tu VM Linux.
- [ ] Revisaste el log local (`respaldo.log`) **y** el log del sistema (`journalctl -t respaldo_ejemplo` o `/var/log/syslog`).
- [ ] Entiendes qué hace `-t` (tag) y `-p` (prioridad) en `logger`.
- [ ] Ejecutaste el script equivalente en PowerShell y lo revisaste en el Visor de eventos.
- [ ] Programaste (y probaste con "Ejecutar" manual) la tarea en el Programador de tareas de Windows.
- [ ] Puedes explicar por qué loguear al sistema es mejor que loguear solo a un archivo propio, para efectos de monitoreo y notificación de fallos.

## Recursos adicionales

- `man logger`, `man journalctl` directamente en la VM.
- [journalctl — Arch Wiki (referencia completa de filtros)](https://wiki.archlinux.org/title/Systemd/Journal)
- [Write-EventLog (docs de Microsoft)](https://learn.microsoft.com/powershell/module/microsoft.powershell.management/write-eventlog)
- [about_Execution_Policies (docs de Microsoft)](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Crear una tarea básica con el Programador de tareas (docs de Microsoft)](https://learn.microsoft.com/windows/win32/taskschd/task-scheduler-start-page)
