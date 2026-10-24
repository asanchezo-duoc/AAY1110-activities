# Act 3.3.2 — Auditoría y monitoreo en Linux

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | 3.3.2 Guía Auditoría y Monitoreo |
| **RA** | RA3 |
| **IL** | IL 3.4 — Implementa mecanismos de auditoría y monitoreo para detectar y responder a incidentes de seguridad en Linux |
| **Tiempo estimado** | 1 hora |

> **Prerequisito:** haber completado [Act_3.1.2](../Act_3.1.2/) (hardening SSH) y [Act_3.2.2](../Act_3.2.2/) (firewall). Aquí sumamos la capa de auditoría y monitoreo sobre un servidor ya asegurado.

## Contexto

Eres el administrador de sistemas de una empresa que maneja información sensible. Ya aseguraste el servidor (SSH endurecido, firewall configurado). Ahora necesitas **registrar qué ocurre** en el sistema para poder investigar incidentes y **observar en tiempo real** el estado de los recursos.

- **Auditoría** responde a la pregunta: **¿qué pasó?** — registra eventos para tener un historial.
- **Monitoreo** responde a la pregunta: **¿qué está pasando?** — observa el sistema en tiempo real.

En este laboratorio vas a:

1. Instalar y configurar `auditd` para registrar eventos del kernel.
2. Crear reglas de auditoría para vigilar archivos críticos y comandos privilegiados.
3. Buscar y generar reportes de los eventos capturados.
4. Instalar herramientas de monitoreo en tiempo real (`htop`, `vnstat`, `iftop`).

---

## Paso 0 — Preparar la VM en AWS Academy

Si ya tienes la instancia Red Hat de las actividades anteriores, puedes reutilizarla. Si no:

1. Ingresa a **https://awsacademy.instructure.com/** → **Learner Lab** → **Start Lab**.

2. Lanza una instancia EC2:

   | Campo | Valor |
   |---|---|
   | **Name** | `audit-lab` |
   | **AMI** | Red Hat Enterprise Linux 9 (x86_64, Free tier eligible) |
   | **Instance type** | `t2.micro` |
   | **Key pair** | `vockey` (la llave por defecto del Learner Lab) |
   | **Security Group** | Permite SSH (22) desde tu IP |

3. Conéctate con **EC2 Instance Connect**: selecciona la instancia → **Connect** → pestaña **EC2 Instance Connect** → usuario `ec2-user` → **Connect**.

   > **¿No conecta?** Red Hat no trae Instance Connect preinstalado. Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) (solo una vez por instancia).

4. Verifica:

   ```bash
   cat /etc/redhat-release   # Red Hat Enterprise Linux release 9.x
   ```

---

## Tarea 1 — Instalar y habilitar auditd

`auditd` es el demonio del **Linux Audit Framework**. El kernel evalúa cada evento contra las reglas definidas y `auditd` escribe los que coinciden en `/var/log/audit/audit.log`.

### 1.1 Instalar el paquete

```bash
sudo dnf install -y audit
```

### 1.2 Habilitar e iniciar el servicio

```bash
sudo systemctl enable --now auditd
sudo systemctl status auditd
```

Debe decir `active (running)`.

### 1.3 Conocer los componentes

El paquete `audit` incluye varias herramientas que trabajan juntas:

| Componente | Qué hace |
|---|---|
| `auditd` | Demonio que captura y escribe los eventos en `/var/log/audit/audit.log` |
| `auditctl` | Agrega, lista o elimina reglas de auditoría en caliente |
| `/etc/audit/rules.d/` | Directorio donde se guardan las reglas persistentes (sobreviven reinicios) |
| `ausearch` | Busca eventos en el log por clave, usuario, fecha, etc. |
| `aureport` | Genera reportes resumidos de los eventos registrados |

> **Importante:** `auditd` **no bloquea** ninguna acción — solo deja evidencia. No es un firewall ni un antivirus; es un registrador de eventos a nivel de kernel.

---

## Tarea 2 — Crear reglas de auditoría

Las reglas le dicen a `auditd` qué vigilar. Cada regla lleva una **clave** (`-k`) que después sirve para filtrar los eventos en el log.

### 2.1 Regla 1: vigilar cambios en la configuración de SSH

```bash
sudo auditctl -w /etc/ssh/sshd_config -p wa -k sshd_config_change
```

| Parte | Significado |
|---|---|
| `-w /etc/ssh/sshd_config` | Watch: vigilar este archivo |
| `-p wa` | Permisos a vigilar: `w` (escritura) y `a` (cambio de atributos) |
| `-k sshd_config_change` | Clave para buscar estos eventos después |

### 2.2 Regla 2: vigilar cambios en /etc/passwd

```bash
sudo auditctl -w /etc/passwd -p wa -k passwd_change
```

`/etc/passwd` contiene la lista de usuarios del sistema. Cualquier cambio (agregar, modificar o eliminar un usuario) quedará registrado.

### 2.3 Regla 3: vigilar ejecución de comandos como root

```bash
sudo auditctl -a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
```

| Parte | Significado |
|---|---|
| `-a always,exit` | Siempre registrar, al salir de la llamada al sistema |
| `-F arch=b64` | Solo arquitectura de 64 bits |
| `-S execve` | Llamada al sistema `execve` (ejecutar un programa) |
| `-F euid=0` | Solo cuando el usuario efectivo es root (UID 0) |
| `-k root_commands` | Clave para buscar después |

### 2.4 Verificar que las reglas están activas

```bash
sudo auditctl -l
```

Salida esperada:

```
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/passwd -p wa -k passwd_change
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
```

### 2.5 Hacer las reglas persistentes

Las reglas creadas con `auditctl` se pierden al reiniciar. Para que persistan, escríbelas en un archivo:

```bash
sudo tee /etc/audit/rules.d/custom.rules <<'EOF'
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/passwd -p wa -k passwd_change
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands
EOF
```

Recarga las reglas para confirmar que el archivo se lee correctamente:

```bash
sudo augenrules --load
sudo auditctl -l
```

---

## Tarea 3 — Buscar y reportar eventos

Ahora vamos a **generar eventos** a propósito y después buscarlos en el log de auditoría.

### 3.1 Generar eventos de prueba

```bash
# Evento 1: modificar sshd_config (agrega un comentario inocuo)
sudo bash -c 'echo "# prueba auditd" >> /etc/ssh/sshd_config'

# Evento 2: crear un usuario de prueba
sudo useradd usuario_prueba

# Evento 3: ejecutar un comando privilegiado
sudo ls /root
```

### 3.2 Buscar eventos por clave

```bash
# Buscar cambios en sshd_config
sudo ausearch -k sshd_config_change
```

Vas a ver una salida con campos como:

```
type=SYSCALL ... key="sshd_config_change"
type=PATH ... name="/etc/ssh/sshd_config"
```

Los campos más importantes de cada evento:

| Campo | Significado |
|---|---|
| `type=SYSCALL` | La llamada al sistema que se interceptó |
| `uid=` | UID del usuario que ejecutó la acción |
| `exe=` | Programa que hizo la llamada |
| `key=` | La clave de la regla que disparó el evento |
| `success=yes/no` | Si la operación tuvo éxito |

```bash
# Buscar cambios en /etc/passwd (el useradd debería aparecer)
sudo ausearch -k passwd_change
```

### 3.3 Generar reportes

```bash
# Reporte de acceso a archivos
sudo aureport -f

# Reporte resumido (totales por tipo de evento)
sudo aureport --summary

# Reporte de autenticación
sudo aureport -au

# Reporte de logins
sudo aureport -l
```

> `aureport` te da la vista "de gerencia" (totales, resúmenes). `ausearch` te da la vista "de investigación" (cada evento individual con detalle).

### 3.4 Limpiar la prueba

```bash
# Remover el comentario de prueba
sudo sed -i '/# prueba auditd/d' /etc/ssh/sshd_config

# Eliminar el usuario de prueba
sudo userdel -r usuario_prueba 2>/dev/null
```

---

## Tarea 4 — Herramientas de monitoreo en tiempo real

La auditoría mira el pasado. El monitoreo mira el **presente**: CPU, memoria, red, procesos.

### 4.1 top / htop — procesos y recursos

`top` viene preinstalado. `htop` es una versión mejorada con interfaz interactiva:

```bash
sudo dnf install -y epel-release
sudo dnf install -y htop
```

```bash
# Vista básica (preinstalada)
top

# Vista interactiva con colores y barras (salir con q)
htop
```

**Para qué sirve:** encontrar el proceso que está consumiendo la CPU o la memoria. En `htop`, usa las flechas para navegar y `F9` para matar un proceso.

### 4.2 vnstat — tráfico de red acumulado

```bash
sudo dnf install -y vnstat
sudo systemctl enable --now vnstat
```

```bash
# Tráfico en tiempo real
vnstat -l

# Tráfico diario acumulado (necesita horas de recolección para datos útiles)
vnstat -d

# Tráfico por hora
vnstat -h
```

**Para qué sirve:** detectar picos de tráfico anómalos, ver cuánto ancho de banda consume el servidor por día/mes.

> `vnstat` necesita recolectar datos por un rato antes de mostrar estadísticas históricas. El modo `-l` (live) funciona de inmediato.

### 4.3 iftop — conexiones de red en vivo

```bash
sudo dnf install -y iftop
```

```bash
sudo iftop -i eth0 -n -P
```

| Flag | Significado |
|---|---|
| `-i eth0` | Interfaz de red a monitorear (puede ser `ens5` en EC2, verifica con `ip link`) |
| `-n` | No resolver DNS (más rápido) |
| `-P` | Mostrar puertos |

**Para qué sirve:** ver en vivo **quién está hablando con quién** y cuánto ancho de banda consume cada conexión. Ideal para detectar conexiones sospechosas.

> Si la interfaz no se llama `eth0`, averíguala con `ip link show` y usa ese nombre.

Salir con `q`.

### 4.4 Resumen de herramientas

| Herramienta | Qué muestra | Pregunta que responde |
|---|---|---|
| `top` / `htop` | Procesos, CPU, memoria | ¿Qué proceso consume los recursos? |
| `vnstat` | Tráfico por interfaz (histórico) | ¿Cuánto tráfico hubo hoy/esta semana? |
| `iftop` | Conexiones activas en vivo | ¿Quién se está conectando al servidor ahora? |

---

## Tarea 5 — Verificación final

```bash
# 1. auditd está corriendo
sudo systemctl status auditd | grep Active
# Active: active (running)

# 2. Las reglas están cargadas
sudo auditctl -l
# Debe mostrar las 3 reglas creadas

# 3. Las reglas son persistentes
cat /etc/audit/rules.d/custom.rules
# Debe mostrar las mismas 3 reglas

# 4. Hay eventos capturados
sudo aureport --summary
# Debe mostrar contadores > 0

# 5. htop, vnstat e iftop están instalados
which htop vnstat iftop
```

---

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `auditctl: command not found` | El paquete `audit` no está instalado | `sudo dnf install -y audit` |
| `auditctl -l` no muestra reglas | Las reglas se perdieron al reiniciar y no están en `/etc/audit/rules.d/` | Crea el archivo `custom.rules` (paso 2.5) y ejecuta `sudo augenrules --load` |
| `ausearch` no muestra eventos | No se han generado eventos que coincidan con las reglas | Genera eventos de prueba (paso 3.1) y vuelve a buscar |
| `aureport` muestra "no events" | El log está vacío o el rango de tiempo no coincide | Verifica con `sudo wc -l /var/log/audit/audit.log` que hay eventos |
| `dnf install htop` falla | EPEL no está habilitado | `sudo dnf install -y epel-release` primero |
| `iftop` dice "interface not found" | El nombre de la interfaz no es `eth0` | Usa `ip link show` para ver el nombre real (puede ser `ens5` en EC2) y pásalo con `-i` |
| Instance Connect dice "No se pudo conectar" | Red Hat no trae Instance Connect preinstalado | Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) |

## Checklist antes de entregar

- [ ] `auditd` está instalado, habilitado y corriendo.
- [ ] Creaste reglas para vigilar `/etc/ssh/sshd_config`, `/etc/passwd` y ejecución de comandos como root.
- [ ] Las reglas están guardadas en `/etc/audit/rules.d/custom.rules` (persisten al reiniciar).
- [ ] Generaste eventos de prueba y los encontraste con `ausearch` usando las claves (`-k`).
- [ ] Generaste al menos un reporte con `aureport`.
- [ ] Puedes explicar la diferencia entre `ausearch` (investigación) y `aureport` (resumen).
- [ ] Instalaste `htop`, `vnstat` e `iftop`, y puedes explicar para qué sirve cada una.
- [ ] Puedes explicar la diferencia entre auditoría (pasado) y monitoreo (presente).

## Recursos adicionales

- [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — si la consola de AWS dice "No se pudo conectar a la instancia".
- `man auditctl` — referencia completa de reglas de auditoría.
- `man ausearch` — referencia de búsqueda en el log de auditoría.
- `man aureport` — referencia de reportes.
- [Red Hat — System Auditing](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/auditing-the-system_security-hardening) — documentación oficial.
- `man htop`, `man vnstat`, `man iftop` — referencia de herramientas de monitoreo.
