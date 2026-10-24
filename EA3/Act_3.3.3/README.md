# Act 3.3.3 — Gestión de logs en Linux

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | 3.3.3 Guía Logs en Linux |
| **RA** | RA3 |
| **IL** | IL 3.5 — Gestiona los archivos de LOG para detectar problemas en el sistema y sus servicios mediante scripts |
| **Tiempo estimado** | 1 hora |

> **Prerequisito:** haber completado [Act_3.3.2](../Act_3.3.2/) — allí se instaló `auditd` y se crearon reglas de auditoría que están generando eventos en el log. Aquí vamos a explorar, filtrar y analizar esos logs.

## Contexto

Ya tienes un servidor con SSH endurecido, firewall configurado y `auditd` registrando eventos. Ahora necesitas **saber dónde buscar** cuando algo falla, **entender cómo se organizan** los logs en Linux, y poder **generar reportes automáticos** para no depender de revisar manualmente cada archivo.

En este laboratorio vas a:

1. Explorar la estructura de `/var/log` y entender qué archivo guarda qué.
2. Consultar el journal de systemd con `journalctl`.
3. Filtrar logs con `grep` y `tail` para encontrar eventos específicos.
4. Analizar el log de auditoría con `ausearch` y `aureport`.
5. Configurar la rotación de logs con `logrotate`.
6. Crear un script de reporte de seguridad automatizado.

---

## Paso 0 — Preparar la VM en AWS Academy

Usa la misma instancia de [Act_3.3.2](../Act_3.3.2/). Si no la tienes:

1. Ingresa a **https://awsacademy.instructure.com/** → **Learner Lab** → **Start Lab**.

2. Lanza una instancia EC2 Red Hat 9 (`t2.micro`, key pair `vockey`).

3. Conéctate con **EC2 Instance Connect**: selecciona la instancia → **Connect** → **EC2 Instance Connect** → usuario `ec2-user` → **Connect**.

   > **¿No conecta?** Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/).

---

## Tarea 1 — Explorar /var/log

En Linux, los logs viven en `/var/log`. Cada archivo recibe mensajes de un tipo específico, gracias al sistema de **facility** y **prioridad** de syslog.

### 1.1 Listar los archivos principales

```bash
ls -lh /var/log/
```

### 1.2 Archivos clave en Red Hat (RHEL / Rocky / Fedora)

| Archivo | Qué contiene | Facility de syslog |
|---|---|---|
| `/var/log/secure` | Autenticación: logins SSH, `sudo`, cambios de usuario | `authpriv.*` |
| `/var/log/messages` | Eventos generales del sistema (todo lo que no va a otro archivo) | `*.info` (excepto auth, cron, mail) |
| `/var/log/cron` | Ejecuciones de tareas programadas (cron) | `cron.*` |
| `/var/log/maillog` | Correo (postfix, sendmail) | `mail.*` |
| `/var/log/audit/audit.log` | Eventos de auditoría del kernel (auditd) | — (escribe auditd directo) |
| `/var/log/dnf.log` | Instalaciones y actualizaciones de paquetes | — (escribe dnf directo) |
| `/var/log/boot.log` | Mensajes del arranque del sistema | — |

> **Diferencia con Ubuntu/Debian:** en Ubuntu, la autenticación va a `/var/log/auth.log` y los eventos generales a `/var/log/syslog` (no `/var/log/messages`).

### 1.3 ¿Por qué SSH va a `secure` y no a `messages`?

El archivo `/etc/rsyslog.conf` define las **reglas de enrutamiento**. Revísalas:

```bash
grep -v "^#\|^$" /etc/rsyslog.conf | head -20
```

Vas a ver líneas como:

```
authpriv.*                  /var/log/secure
cron.*                      /var/log/cron
*.info;mail.none;authpriv.none;cron.none    /var/log/messages
```

Esto significa: los mensajes de `authpriv` (autenticación) van a `secure`, los de `cron` van a `cron`, y **todo lo demás** (info o peor, excluyendo mail, auth y cron) va a `messages`.

### 1.4 Ver las primeras líneas de cada log

```bash
sudo head -5 /var/log/secure
sudo head -5 /var/log/messages
sudo head -5 /var/log/audit/audit.log
```

---

## Tarea 2 — journalctl: consultar el journal de systemd

`journalctl` es la herramienta de systemd para consultar el **journal** — un sistema de logs estructurado que corre en paralelo a rsyslog.

### 2.1 Comandos esenciales

```bash
# Últimos eventos con explicaciones (ideal para diagnosticar un servicio que falló)
journalctl -xe

# Filtrar por unidad (servicio)
journalctl -u sshd

# Filtrar por rango de tiempo
journalctl --since "1 hour ago"
journalctl --since "2026-10-24 10:00" --until "2026-10-24 12:00"

# Filtrar por prioridad (err = error y todo lo más grave)
journalctl -p err

# Seguir en vivo (como tail -f)
journalctl -f
```

> `journalctl -f` es muy útil: déjalo corriendo en una terminal mientras haces pruebas en otra, y verás los eventos aparecer en tiempo real.

### 2.2 Niveles de prioridad de syslog

Cada mensaje tiene un nivel de gravedad. `journalctl -p` filtra por estos niveles:

| Nivel | Nombre | Significado | Ejemplo |
|---|---|---|---|
| 0 | `emerg` | Sistema inutilizable | Kernel panic |
| 1 | `alert` | Hay que actuar de inmediato | Filesystem lleno |
| 2 | `crit` | Condición crítica | Hardware dañado |
| 3 | `err` | Error | Servicio que no arranca |
| 4 | `warning` | Advertencia | Disco al 90% |
| 5 | `notice` | Normal pero relevante | Servicio reiniciado |
| 6 | `info` | Informativo | Login exitoso |
| 7 | `debug` | Depuración | Detalle interno del programa |

Cuando filtras con `-p err`, ves todos los mensajes de nivel 0 a 3 (err y todo lo más grave).

### 2.3 journalctl vs /var/log

| | journalctl (journal) | /var/log (rsyslog) |
|---|---|---|
| **Formato** | Estructurado (binario) | Texto plano |
| **Consulta** | Filtros por unidad, prioridad, tiempo | `grep`, `tail`, `awk` |
| **Persistencia** | Por defecto volátil (se pierde al reiniciar) en RHEL | Persistente en disco |
| **Cuándo usarlo** | Diagnosticar un servicio específico | Buscar en archivos de texto, scripts de reporte |

---

## Tarea 3 — Filtrar logs con grep y tail

Las herramientas de texto de Linux (`grep`, `tail`, `wc`) son la forma más directa de buscar en los archivos de log.

### 3.1 Seguir un log en vivo

```bash
# En una terminal, sigue el log de autenticación
sudo tail -f /var/log/secure
```

Déjalo corriendo. En otra terminal (o pestaña de Instance Connect), haz algo que genere un evento — por ejemplo, ejecuta un comando con `sudo`. Verás la línea aparecer en tiempo real.

Para salir: `Ctrl+C`.

### 3.2 Buscar intentos de login fallidos

```bash
# Buscar logins fallidos (contraseña incorrecta)
sudo grep "Failed" /var/log/secure

# Buscar intentos con usuarios inexistentes (ataques de fuerza bruta)
sudo grep "Invalid user" /var/log/secure

# Contar cuántos intentos hubo
sudo grep "Invalid user" /var/log/secure | wc -l
```

> Si completaste [Act_3.1.2](../Act_3.1.2/) y probaste Fail2Ban, deberías ver algunos intentos registrados aquí.

### 3.3 Buscar accesos exitosos

```bash
# Logins SSH exitosos
sudo grep "Accepted" /var/log/secure

# Últimos 5 accesos exitosos
sudo grep "Accepted" /var/log/secure | tail -5
```

### 3.4 Buscar uso de sudo

```bash
# Todos los comandos ejecutados con sudo
sudo grep "sudo" /var/log/secure | tail -20

# Contar cuántas veces se usó sudo
sudo grep "sudo" /var/log/secure | wc -l
```

### 3.5 Combinar filtros

```bash
# Errores de hoy en messages
sudo grep "$(date +%b\ %d)" /var/log/messages | grep -i "error"

# Eventos de sshd en la última hora del journal
journalctl -u sshd --since "1 hour ago" --no-pager
```

---

## Tarea 4 — Analizar audit.log

En [Act_3.3.2](../Act_3.3.2/) creaste reglas de auditoría con `auditd`. Ahora vamos a analizar lo que capturaron.

### 4.1 Buscar eventos con formato legible

```bash
# Cambios en sshd_config (formato interpretado, más legible)
sudo ausearch -k sshd_config_change -i

# Cambios en /etc/passwd
sudo ausearch -k passwd_change -i
```

El flag `-i` traduce UIDs a nombres de usuario y timestamps a fechas legibles.

### 4.2 Generar reportes

```bash
# Reporte de autenticación (quién se autenticó y cuándo)
sudo aureport -au

# Reporte de logins (sesiones de usuario)
sudo aureport -l

# Reporte de acceso a archivos
sudo aureport -f

# Reporte resumido (totales por tipo)
sudo aureport --summary
```

### 4.3 Leer un evento crudo de audit.log

```bash
sudo tail -5 /var/log/audit/audit.log
```

Cada línea tiene formato `type=... msg=audit(timestamp:id): ...`. Los campos clave:

| Campo | Significado |
|---|---|
| `type` | Tipo de evento (`SYSCALL`, `PATH`, `USER_LOGIN`, etc.) |
| `msg=audit(1234567890.123:456)` | Timestamp Unix y número de evento |
| `uid=` / `auid=` | UID del proceso / UID del usuario que inició la sesión |
| `exe=` | Programa que ejecutó la acción |
| `key=` | Clave de la regla que disparó el evento |
| `res=success/failed` | Resultado de la operación |

> El log crudo es difícil de leer — por eso existen `ausearch -i` y `aureport`. Pero conviene verlo al menos una vez para entender qué hay detrás de los reportes.

---

## Tarea 5 — Configurar logrotate

Los logs crecen sin parar. Sin rotación, eventualmente **llenan el disco** y el servidor deja de funcionar. `logrotate` se encarga de comprimir y eliminar los logs antiguos automáticamente.

### 5.1 Ver la configuración actual

```bash
# Configuración global
cat /etc/logrotate.conf

# Configuraciones específicas por servicio
ls /etc/logrotate.d/
```

### 5.2 Crear una configuración de rotación personalizada

Supongamos que tienes (o tendrás) una aplicación que escribe en `/var/log/custom-app.log`. Crea una configuración de rotación:

```bash
sudo tee /etc/logrotate.d/custom-app <<'EOF'
/var/log/custom-app.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF
```

| Directiva | Significado |
|---|---|
| `daily` | Rotar una vez al día |
| `rotate 7` | Conservar 7 copias (una semana) |
| `compress` | Comprimir las copias antiguas (`.gz`) |
| `missingok` | No dar error si el archivo no existe |
| `notifempty` | No rotar si el archivo está vacío |

### 5.3 Probar la rotación

```bash
# Crear un log de prueba
sudo bash -c 'echo "evento de prueba" > /var/log/custom-app.log'

# Forzar la rotación (sin esperar al cron diario)
sudo logrotate -f /etc/logrotate.d/custom-app

# Ver el resultado
ls -la /var/log/custom-app*
```

Deberías ver `custom-app.log` (nuevo, vacío) y `custom-app.log.1.gz` (el anterior, comprimido).

### 5.4 Ver cómo se rota un log real

```bash
ls -la /var/log/secure*
ls -la /var/log/messages*
```

Verás archivos como `secure-20261018`, `messages-20261018` — logs anteriores ya rotados.

> **¿Por qué importa?** Un servidor con mucho tráfico SSH (legítimo o ataques) puede generar cientos de MB de logs por día en `/var/log/secure`. Sin rotación, en unas semanas el disco `/var` se llena y el servidor deja de funcionar.

---

## Tarea 6 — Script de reporte de seguridad

Vamos a crear un script que resuma el estado de seguridad del servidor en una sola ejecución. Esto es lo que la buena práctica de "automatizar los reportes" significa en la práctica.

### 6.1 Crear el script

```bash
sudo tee /usr/local/bin/reporte_seguridad.sh <<'SCRIPT'
#!/bin/bash
echo "========================================"
echo "  REPORTE DE SEGURIDAD - $(hostname)"
echo "  Fecha: $(date)"
echo "========================================"
echo ""

echo "--- Intentos de login con usuarios inexistentes ---"
COUNT_INVALID=$(grep -c "Invalid user" /var/log/secure 2>/dev/null || echo 0)
echo "Total: $COUNT_INVALID"
grep "Invalid user" /var/log/secure 2>/dev/null | tail -5
echo ""

echo "--- Últimos 5 accesos exitosos ---"
grep "Accepted" /var/log/secure 2>/dev/null | tail -5
echo ""

echo "--- Uso de sudo ---"
COUNT_SUDO=$(grep -c "sudo" /var/log/secure 2>/dev/null || echo 0)
echo "Total de comandos sudo: $COUNT_SUDO"
echo ""

echo "--- Estado de auditd ---"
auditctl -s 2>/dev/null || echo "auditd no está instalado"
echo ""

echo "--- Reglas de auditoría activas ---"
auditctl -l 2>/dev/null || echo "Sin reglas"
echo ""

echo "--- Espacio en disco ---"
df -h / /var 2>/dev/null
echo ""

echo "--- Servicios de seguridad ---"
for svc in auditd firewalld fail2ban sshd; do
    STATUS=$(systemctl is-active $svc 2>/dev/null || echo "no instalado")
    printf "  %-12s %s\n" "$svc:" "$STATUS"
done
echo ""
echo "========================================"
echo "  Fin del reporte"
echo "========================================"
SCRIPT
```

### 6.2 Dar permiso de ejecución y probar

```bash
sudo chmod +x /usr/local/bin/reporte_seguridad.sh
sudo /usr/local/bin/reporte_seguridad.sh
```

### 6.3 Ejemplo de salida esperada

```
========================================
  REPORTE DE SEGURIDAD - ip-172-31-XX-XX
  Fecha: vie oct 24 15:30:00 UTC 2026
========================================

--- Intentos de login con usuarios inexistentes ---
Total: 12
Oct 24 14:20:01 ... Invalid user admin1 from 203.0.113.5
...

--- Últimos 5 accesos exitosos ---
Oct 24 15:00:01 ... Accepted publickey for ec2-user from ...
...

--- Uso de sudo ---
Total de comandos sudo: 47

--- Estado de auditd ---
enabled 1
...

--- Reglas de auditoría activas ---
-w /etc/ssh/sshd_config -p wa -k sshd_config_change
-w /etc/passwd -p wa -k passwd_change
-a always,exit -F arch=b64 -S execve -F euid=0 -k root_commands

--- Espacio en disco ---
Filesystem      Size  Used Avail Use% Mounted on
/dev/xvda1       10G  1.5G  8.5G  15% /

--- Servicios de seguridad ---
  auditd:      active
  firewalld:   active
  fail2ban:    active
  sshd:        active

========================================
  Fin del reporte
========================================
```

> Este script se podría programar con `cron` para que se ejecute diariamente y envíe el resultado por correo o lo guarde en un archivo — exactamente lo que viste en [Act_2.2.2](../../EA2/Act_2.2.2/) con las tareas programadas.

---

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `journalctl` no muestra nada | El journal está vacío o el filtro es muy restrictivo | Prueba sin filtro: `journalctl -n 20` para ver los últimos 20 eventos |
| `grep` no encuentra nada en `/var/log/secure` | El servidor es nuevo y no ha tenido actividad de autenticación | Genera eventos: haz login, ejecuta `sudo`, o intenta un acceso fallido desde otra terminal |
| `ausearch` dice "no matches" | No se han generado eventos que coincidan con la clave | Genera un evento primero (ej. editar `sshd_config`) y vuelve a buscar |
| `logrotate -f` no crea el archivo rotado | El archivo de log original no existe | Créalo primero: `sudo touch /var/log/custom-app.log` |
| El script de reporte da "Permission denied" | Falta el permiso de ejecución, o no se ejecutó con `sudo` | `sudo chmod +x /usr/local/bin/reporte_seguridad.sh` y ejecuta con `sudo` |
| `/var/log/secure` no existe | Estás en una distribución que usa otro nombre | En Ubuntu/Debian el equivalente es `/var/log/auth.log` |
| Instance Connect dice "No se pudo conectar" | Red Hat no trae Instance Connect preinstalado | Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) |

## Checklist antes de entregar

- [ ] Puedes listar los archivos principales de `/var/log` y explicar qué contiene cada uno.
- [ ] Sabes usar `journalctl` con al menos 3 filtros distintos (`-u`, `-p`, `--since`).
- [ ] Puedes explicar la tabla de prioridades de syslog (emerg a debug).
- [ ] Encontraste eventos específicos en `/var/log/secure` con `grep` (logins fallidos, exitosos, sudo).
- [ ] Analizaste eventos de auditoría con `ausearch -i` y generaste un reporte con `aureport`.
- [ ] Configuraste una regla de rotación de logs con `logrotate` y la probaste con `-f`.
- [ ] Creaste y ejecutaste el script de reporte de seguridad.
- [ ] El script muestra correctamente: intentos fallidos, accesos exitosos, uso de sudo, estado de auditd y espacio en disco.

## Recursos adicionales

- [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — si la consola de AWS dice "No se pudo conectar a la instancia".
- `man journalctl` — referencia completa de filtros del journal.
- `man rsyslog.conf` — referencia de configuración de rsyslog (facility y prioridad).
- `man logrotate` — referencia de rotación de logs.
- [Red Hat — Configuring a remote logging solution](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/security_hardening/assembly_configuring-a-remote-logging-solution_security-hardening) — logs centralizados.
- [RFC 5424](https://datatracker.ietf.org/doc/html/rfc5424) — estándar de severidad de syslog.
