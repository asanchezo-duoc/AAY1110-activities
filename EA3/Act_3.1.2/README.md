# Act 3.1.2 — Hardening de un servidor Linux

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | 3.1.2 Guía Hardening Linux |
| **RA** | RA3 |
| **IL** | IL 3.1 — Implementa hardening en servidores Linux para aumentar el nivel de seguridad acorde las buenas prácticas de la industria |
| **Tiempo estimado** | 1 hora |

## Contexto

Eres el administrador de sistemas de una empresa que maneja información sensible de clientes y operaciones críticas. Se te ha asignado la tarea de asegurar un servidor Linux que contiene una aplicación web y una base de datos. El objetivo es aplicar medidas de **hardening** (endurecimiento) para proteger el sistema de posibles ataques.

Hardening no es instalar un solo producto de seguridad: es un conjunto de configuraciones que **reducen la superficie de ataque** — menos puertos abiertos, menos servicios innecesarios, acceso restringido solo a lo que se necesita.

En este laboratorio vas a:

1. Endurecer la configuración de SSH (deshabilitar root, cambiar puerto, solo claves públicas).
2. Configurar un firewall básico con UFW para permitir solo el tráfico necesario.
3. Instalar y configurar Fail2Ban para bloquear ataques de fuerza bruta contra SSH.
4. Verificar que las medidas aplicadas funcionan correctamente.

---

## Paso 0 — Levantar la VM en AWS Academy

1. Abre tu navegador e ingresa a **https://awsacademy.instructure.com/**

   > **IMPORTANTE:** No te registres en https://aws.amazon.com/es/ — ese es el sitio comercial y te pedirá tarjeta de crédito.

2. Elige **Inicio de sesión de estudiante** e ingresa con el correo electrónico donde recibiste la invitación de AWS Academy.

3. Abre el curso **AWS Academy - Learner Lab** y haz clic en **Start Lab** (o "Iniciar laboratorio").

4. Espera a que el indicador pase a **verde** (la cuenta de laboratorio está activa).

5. Haz clic en **AWS** (el enlace que aparece junto al indicador verde) para abrir la consola de AWS.

### Crear la instancia EC2 (Red Hat)

6. En la consola de AWS, busca **EC2** en la barra de búsqueda y entra al servicio.

7. Haz clic en **Launch instance** (Lanzar instancia).

8. Configura la instancia:

   | Campo | Valor |
   |---|---|
   | **Name** | `hardening-lab` |
   | **AMI** | Red Hat Enterprise Linux 9 (busca "Red Hat" en el buscador de AMIs, selecciona la versión HVM x86_64 que aparezca como Free tier eligible) |
   | **Instance type** | `t2.micro` (capa gratuita) |
   | **Key pair** | Selecciona `vockey` (la llave por defecto del Learner Lab) |
   | **Security Group** | Crea uno nuevo o usa el existente. Asegúrate de que permita **SSH (puerto 22)** desde tu IP |
   | **Storage** | 10 GiB gp3 (valor por defecto, suficiente) |

9. Haz clic en **Launch instance**.

10. Espera a que el **Instance state** sea `Running`.

### Conectarte con EC2 Instance Connect

11. Selecciona tu instancia → botón **Connect** (Conectar) → pestaña **EC2 Instance Connect** → usuario `ec2-user` → **Connect**.

    Se abrirá una terminal directamente en el navegador, sin necesidad de descargar llaves `.pem` ni configurar SSH en tu equipo.

    > **¿No conecta?** Red Hat no trae Instance Connect preinstalado. Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — solo se necesita hacer **una vez** por instancia.

12. Verifica que estás dentro:

    ```bash
    whoami          # ec2-user
    cat /etc/redhat-release   # Red Hat Enterprise Linux release 9.x
    ```

---

## Tarea 1 — Endurecer la configuración de SSH

SSH es la puerta de entrada a tu servidor. Por defecto viene con configuraciones permisivas que conviene restringir.

### 1.1 Editar la configuración de SSH

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak   # respaldo antes de tocar
sudo nano /etc/ssh/sshd_config
```

Busca y modifica (o agrega) las siguientes directivas:

```text
# Deshabilitar acceso directo como root
PermitRootLogin no

# Cambiar el puerto por defecto a uno no estándar
Port 2222

# Permitir únicamente autenticación por clave pública (deshabilitar contraseña)
PubkeyAuthentication yes
PasswordAuthentication no
```

> **¿Por qué cambiar el puerto?** El puerto 22 es el primero que escanean los bots automáticos. Cambiar a un puerto no estándar no es "seguridad real" (security through obscurity), pero **reduce enormemente el ruido** de intentos de fuerza bruta en los logs.
>
> **¿Por qué deshabilitar PasswordAuthentication?** Las contraseñas se pueden adivinar por fuerza bruta. Las claves SSH son criptográficamente mucho más resistentes. En AWS Learner Lab ya accedes con clave pública (ya sea vía Instance Connect o con la llave `.pem` del lab), así que no pierdes nada.

### 1.2 Abrir el nuevo puerto en el Security Group de AWS

**Antes de reiniciar SSH**, debes permitir el puerto 2222 en la consola de AWS, o te vas a quedar fuera:

1. En la consola EC2, ve a **Security Groups** (menú lateral, bajo "Network & Security").
2. Selecciona el security group de tu instancia.
3. Pestaña **Inbound rules** → **Edit inbound rules** → **Add rule**:
   - Type: **Custom TCP**
   - Port range: **2222**
   - Source: **My IP** (o `0.0.0.0/0` si estás en una red que cambia de IP, pero es menos seguro)
4. **Save rules**.

### 1.3 Abrir el puerto 2222 en el firewall del sistema

En Red Hat, el firewall del sistema es `firewalld`:

```bash
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
```

### 1.4 Reiniciar SSH y probar

```bash
sudo systemctl restart sshd
```

> **No cierres esta sesión SSH todavía.** Abre una **segunda terminal** y prueba conectarte por el nuevo puerto:

```bash
ssh -i ~/Downloads/labsuser.pem -p 2222 ec2-user@<IP_PUBLICA>
```

Si la conexión funciona, el cambio está bien. Si no funciona, vuelve a la sesión original (que sigue abierta en el puerto anterior) y revisa la configuración.

### 1.5 Verificaciones

```bash
# Confirmar que root no puede entrar por SSH
sudo grep "^PermitRootLogin" /etc/ssh/sshd_config
# Debe decir: PermitRootLogin no

# Confirmar el puerto activo
sudo ss -tlnp | grep sshd
# Debe mostrar *:2222

# Confirmar que la contraseña está deshabilitada
sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config
# Debe decir: PasswordAuthentication no
```

---

## Tarea 2 — Configurar firewall para permitir solo tráfico necesario

El objetivo es bloquear todo el tráfico entrante **excepto** los servicios que realmente necesitas: SSH (en el nuevo puerto), HTTP y HTTPS.

### Opción A: Usar `firewalld` (el firewall nativo de Red Hat)

Red Hat usa `firewalld` por defecto en lugar de UFW. Los conceptos son los mismos: política restrictiva + excepciones explícitas.

```bash
# Ver el estado actual
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# Permitir HTTP y HTTPS
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# El puerto SSH 2222 ya lo agregamos en el paso anterior.
# Si no lo has hecho:
# sudo firewall-cmd --permanent --add-port=2222/tcp

# Remover el servicio SSH estándar (puerto 22) si ya migraste a 2222
sudo firewall-cmd --permanent --remove-service=ssh

# Aplicar cambios
sudo firewall-cmd --reload

# Verificar la configuración final
sudo firewall-cmd --list-all
```

La salida debería mostrar:
- `services: http https` (no `ssh`)
- `ports: 2222/tcp`
- La política por defecto de `firewalld` ya deniega todo lo que no esté explícitamente permitido.

### Opción B: Usar UFW (si prefieres la sintaxis de Ubuntu/Debian)

UFW no viene instalado en Red Hat, pero se puede instalar para tener la misma experiencia:

```bash
# Instalar UFW (requiere EPEL)
sudo dnf install -y epel-release
sudo dnf install -y ufw

# Detener firewalld para evitar conflictos
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Configurar UFW
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 2222/tcp    # SSH en el nuevo puerto
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
sudo ufw enable

# Verificar
sudo ufw status verbose
```

> **Elige una opción, no ambas.** Tener dos firewalls activos al mismo tiempo causa conflictos. Si usas `firewalld`, no instales UFW, y viceversa.

### Verificación (ambas opciones)

Desde tu máquina local (o una segunda instancia), comprueba que solo los puertos permitidos responden:

```bash
# Si tienes nmap instalado localmente:
nmap -Pn <IP_PUBLICA>

# O prueba manualmente:
nc -zv <IP_PUBLICA> 22     # debería fallar (puerto cerrado/filtrado)
nc -zv <IP_PUBLICA> 2222   # debería conectar
nc -zv <IP_PUBLICA> 80     # debería conectar (si tienes un web server)
nc -zv <IP_PUBLICA> 443    # debería conectar (si tienes un web server)
```

---

## Tarea 3 — Instalar y configurar Fail2Ban

Fail2Ban monitorea los logs del sistema y **bloquea automáticamente** las IPs que fallan muchos intentos de login. Es la defensa contra ataques de fuerza bruta.

### 3.1 Instalar Fail2Ban

```bash
# En Red Hat, Fail2Ban está en EPEL
sudo dnf install -y epel-release
sudo dnf install -y fail2ban

# Habilitar e iniciar el servicio
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 3.2 Configurar la "jail" para SSH

Nunca edites `/etc/fail2ban/jail.conf` directamente — se sobreescribe con actualizaciones. Usa un archivo local:

```bash
sudo nano /etc/fail2ban/jail.local
```

Contenido:

```ini
[DEFAULT]
bantime  = 600      # bloquear la IP por 10 minutos
findtime = 600      # ventana de tiempo para contar intentos
maxretry = 3        # máximo 3 intentos fallidos

[sshd]
enabled  = true
port     = 2222     # el puerto que configuramos en Tarea 1
logpath  = /var/log/secure
backend  = systemd
```

> **¿Qué significan estos valores?**
> - `maxretry = 3`: si una IP falla 3 veces en los últimos 10 minutos (`findtime`), se bloquea.
> - `bantime = 600`: el bloqueo dura 10 minutos. En producción podrías usar valores más agresivos (3600 = 1 hora, o `-1` = permanente).
> - `logpath`: en Red Hat los intentos de login se registran en `/var/log/secure` (en Debian/Ubuntu sería `/var/log/auth.log`).
> - `backend = systemd`: le dice a Fail2Ban que lea los logs a través de systemd/journald.

### 3.3 Reiniciar y verificar

```bash
sudo systemctl restart fail2ban

# Ver el estado de la jail de SSH
sudo fail2ban-client status sshd
```

Salida esperada:

```
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     0
|  `- File list:        /var/log/secure
`- Actions
   |- Currently banned: 0
   |- Total banned:     0
   `- Banned IP list:
```

### 3.4 Probar Fail2Ban (opcional, con cuidado)

> **Advertencia:** esta prueba bloquea temporalmente tu propia IP. Solo hazlo si tienes otra forma de acceder (EC2 Instance Connect desde la consola web, o una segunda instancia).

Desde tu máquina local, intenta conectarte con una contraseña (que no existe, porque deshabilitamos `PasswordAuthentication`) o con una clave incorrecta, 3+ veces:

```bash
ssh -p 2222 ec2-user@<IP_PUBLICA> -o PubkeyAuthentication=no
# Repetir 3+ veces (cada intento fallará)
```

Después, vuelve al servidor (por la consola web u otra IP) y verifica:

```bash
sudo fail2ban-client status sshd
# Debería mostrar tu IP en "Banned IP list"

# Para desbanear manualmente:
sudo fail2ban-client set sshd unbanip <TU_IP>
```

---

## Tarea 4 — Verificación final de seguridad

Desde una segunda máquina (o tu equipo local), haz un escaneo de puertos para confirmar que solo lo necesario está expuesto:

```bash
nmap -Pn <IP_PUBLICA>
```

**Resultado esperado:**

| Puerto | Estado | Servicio |
|---|---|---|
| 22/tcp | filtered/closed | SSH antiguo (ya no responde) |
| 2222/tcp | open | SSH nuevo |
| 80/tcp | open | HTTP (si instalaste un web server) |
| 443/tcp | open | HTTPS (si instalaste un web server) |
| Todo lo demás | filtered | Bloqueado por firewall |

Si no tienes `nmap`, puedes usar `nc` (netcat) para probar puertos puntuales, o la herramienta online https://www.yougetsignal.com/tools/open-ports/.

---

## Resumen de lo aplicado

| Medida de hardening | Qué logramos | Herramienta |
|---|---|---|
| Deshabilitar root por SSH | Nadie puede entrar directamente como root, incluso con la clave correcta | `sshd_config` |
| Cambiar puerto SSH | Reduce el ruido de bots que atacan el puerto 22 por defecto | `sshd_config` + Security Group |
| Solo clave pública | Elimina la posibilidad de ataques por fuerza bruta de contraseña | `sshd_config` |
| Firewall restrictivo | Solo los puertos 2222, 80 y 443 están abiertos; todo lo demás bloqueado | `firewalld` o `ufw` |
| Fail2Ban | IPs que fallen 3+ intentos se bloquean automáticamente por 10 minutos | `fail2ban` |

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| Me quedé fuera del servidor tras cambiar el puerto SSH | No abriste el puerto 2222 en el Security Group de AWS antes de reiniciar `sshd` | Usa **EC2 Instance Connect** desde la consola web de AWS para entrar y revertir el cambio, o edita el Security Group desde la consola |
| `fail2ban-client status sshd` dice "Sorry but the jail 'sshd' does not exist" | El archivo `jail.local` tiene un error de sintaxis, o el servicio no se reinició | Revisa la sintaxis de `jail.local` (sin espacios en los nombres de sección) y ejecuta `sudo systemctl restart fail2ban` |
| `firewall-cmd: command not found` | `firewalld` no está instalado o no está activo | `sudo dnf install -y firewalld && sudo systemctl enable --now firewalld` |
| `nmap` muestra el puerto 22 como "open" todavía | No removiste el servicio `ssh` del firewall, o no hiciste `--reload` | `sudo firewall-cmd --permanent --remove-service=ssh && sudo firewall-cmd --reload` |
| `dnf install fail2ban` falla con "No match" | EPEL no está habilitado | Ejecuta `sudo dnf install -y epel-release` primero |
| Instance Connect dice "No se pudo conectar a la instancia" | Red Hat no trae el paquete Instance Connect preinstalado | Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) |

## Checklist antes de entregar

- [ ] Tu servidor solo acepta conexiones SSH por el puerto 2222 (el 22 está cerrado).
- [ ] El login como `root` por SSH está deshabilitado.
- [ ] La autenticación por contraseña está deshabilitada (solo clave pública).
- [ ] El firewall solo permite tráfico en los puertos 2222, 80 y 443.
- [ ] Fail2Ban está activo y configurado para proteger SSH.
- [ ] Puedes mostrar el resultado de `sudo fail2ban-client status sshd`.
- [ ] Un escaneo de puertos (o pruebas manuales con `nc`) confirma que solo los puertos permitidos están abiertos.

## Recursos adicionales

- [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — si la consola de AWS dice "No se pudo conectar a la instancia", sigue esta guía para instalar y activar Instance Connect en RHEL. Es tu plan B si te quedas fuera del servidor.
- `man sshd_config` — referencia completa de directivas de SSH.
- `man firewall-cmd` — referencia de `firewalld`.
- [Fail2Ban Wiki](https://github.com/fail2ban/fail2ban/wiki) — documentación oficial.
- [Red Hat — Configuring firewalld](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_firewalls_and_packet_filters/using-and-configuring-firewalld_firewall-packet-filters)
- [CIS Benchmarks for Red Hat](https://www.cisecurity.org/benchmark/red_hat_linux) — el estándar de la industria para hardening.
