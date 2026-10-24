# Laboratorio resumen EA3 — Hardening y Firewall en un servidor Linux

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Laboratorio resumen EA3 — Hardening y Firewall |
| **RA** | RA3 — Implementa configuraciones avanzadas de seguridad en sistemas Linux utilizando técnicas de hardening para minimizar riesgos de seguridad de acuerdo con las buenas prácticas de la industria |
| **IL** | IL 3.1 — Implementa hardening en servidores Linux para aumentar el nivel de seguridad acorde las buenas prácticas de la industria · IL 3.4 — Implementa mecanismos de auditoría y monitoreo para detectar y responder a incidentes de seguridad en Linux |
| **Tiempo estimado** | 4 horas pedagógicas (~3 horas) |

## Contexto

Eres el administrador de sistemas de una empresa que acaba de desplegar un servidor Red Hat nuevo en AWS. El servidor hospedará una aplicación web y una base de datos con información sensible de clientes. **Tu trabajo es asegurarlo por completo antes de pasarlo a producción.**

Vas a recorrer, en una sola sesión, todo el ciclo de endurecimiento de un servidor Linux:

| Fase | Qué harás | Tiempo |
|---|---|---|
| 1 | Preparar el entorno y diagnosticar el estado inicial | 30 min |
| 2 | Endurecer SSH (puerto, root, claves) | 45 min |
| 3 | Configurar firewall con firewalld (zonas, servicios, rich rules) | 30 min |
| 4 | Configurar firewall con nftables (tablas, cadenas, reglas directas) | 30 min |
| 5 | Proteger contra fuerza bruta con Fail2Ban | 20 min |
| 6 | Verificación integral de toda la configuración | 15 min |
| 7 | Documentación y entrega de evidencias | 10 min |

> Este laboratorio integra el contenido de [Act_3.1.2](../Act_3.1.2/) (hardening) y [Act_3.2.2](../Act_3.2.2/) (firewall). Si ya completaste ambas por separado, este lab te sirve como repaso guiado y práctica de velocidad.

---

## Fase 1 — Preparación del entorno (30 min)

### 1.1 Iniciar el Learner Lab

1. Ingresa a **https://awsacademy.instructure.com/** → **Learner Lab** → **Start Lab**.
2. Espera a que el indicador pase a **verde** y haz clic en **AWS** para abrir la consola.

### 1.2 Lanzar la instancia EC2

En la consola de AWS → **EC2** → **Launch instance**:

| Campo | Valor |
|---|---|
| **Name** | `lab-resumen-ea3` |
| **AMI** | Red Hat Enterprise Linux 9 (x86_64, Free tier eligible) |
| **Instance type** | `t2.micro` |
| **Key pair** | `vockey` |
| **Security Group** | Crea uno nuevo. Agrega reglas de entrada para: **SSH (22)**, **HTTP (80)**, **HTTPS (443)** desde tu IP |
| **Storage** | 10 GiB gp3 |

Haz clic en **Launch instance** y espera a que el estado sea `Running`.

### 1.3 Conectarte con EC2 Instance Connect

Selecciona tu instancia → **Connect** → pestaña **EC2 Instance Connect** → usuario `ec2-user` → **Connect**.

> **¿No conecta?** Red Hat no trae Instance Connect preinstalado. Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — solo se hace una vez por instancia.

### 1.4 Diagnosticar el estado inicial (antes de tocar nada)

Antes de aplicar cualquier medida, registra cómo está el servidor "de fábrica":

```bash
# ¿Qué puertos están escuchando?
sudo ss -tlnp
```

Vas a ver algo como:

```
State  Recv-Q Send-Q  Local Address:Port  Peer Address:Port  Process
LISTEN 0      128           0.0.0.0:22         0.0.0.0:*      users:(("sshd",...))
LISTEN 0      128              [::]:22            [::]:*      users:(("sshd",...))
```

Solo SSH en el puerto 22 — no hay firewall, no hay protección contra fuerza bruta, root puede entrar por SSH. Todo lo que haremos en las siguientes fases cambia esto.

```bash
# ¿Hay firewall activo?
sudo firewall-cmd --state 2>&1
# Resultado esperado: "not running" o "command not found"
# → No hay firewall. Cualquiera que llegue al Security Group de AWS accede directo.

# ¿SSH permite root?
sudo grep "^PermitRootLogin\|^PasswordAuthentication" /etc/ssh/sshd_config
# Probablemente no aparece nada (usa los valores por defecto, que son permisivos)

# ¿Qué usuario soy y qué sistema es?
whoami                   # ec2-user
cat /etc/redhat-release  # Red Hat Enterprise Linux release 9.x
```

> **Reflexión:** en este momento, tu servidor depende **exclusivamente** del Security Group de AWS como protección. Si alguien expone el Security Group (`0.0.0.0/0` en SSH), cualquier bot del mundo puede intentar entrar. Las fases siguientes agregan capas de defensa **dentro** del servidor.

### 1.5 Instalar las herramientas que vamos a necesitar

```bash
# firewalld (no viene en la AMI del Learner Lab) + EPEL para Fail2Ban
sudo dnf install -y firewalld epel-release

# Fail2Ban y netcat (para pruebas de puertos)
sudo dnf install -y fail2ban nmap-ncat
```

> **No actives `firewalld` todavía** — lo haremos en la Fase 2, después de configurar SSH, para no quedarnos fuera.

---

## Fase 2 — Hardening de SSH (45 min)

SSH es la puerta de entrada al servidor. Vamos a cerrar tres vectores de ataque.

### 2.1 Respaldar la configuración actual

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
```

> Siempre respaldas antes de editar archivos de configuración críticos. Si algo sale mal, puedes restaurar con `sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config`.

### 2.2 Editar sshd_config

```bash
sudo nano /etc/ssh/sshd_config
```

Busca y modifica (o agrega al final) las siguientes directivas:

```text
# 1. Deshabilitar acceso directo como root
PermitRootLogin no

# 2. Cambiar el puerto por defecto a uno no estándar
Port 2222

# 3. Permitir únicamente autenticación por clave pública
PubkeyAuthentication yes
PasswordAuthentication no
```

Guarda y sal (`Ctrl+O`, `Enter`, `Ctrl+X` en nano).

> **¿Por qué estas tres medidas?**
>
> | Medida | Vector que cierra |
> |---|---|
> | `PermitRootLogin no` | Si alguien obtiene la clave, no puede entrar como root directamente |
> | `Port 2222` | Reduce el ruido de bots que atacan el puerto 22 por defecto (no es seguridad real, pero sí reduce los intentos en un 99%) |
> | `PasswordAuthentication no` | Elimina ataques de fuerza bruta de contraseña; solo funciona la clave SSH |

### 2.3 Abrir el puerto 2222 en el Security Group de AWS

**Antes de reiniciar SSH**, abre el puerto 2222 en AWS o te quedarás fuera:

1. En la consola EC2 → **Security Groups** (menú lateral).
2. Selecciona el security group de tu instancia.
3. **Inbound rules** → **Edit inbound rules** → **Add rule**:
   - Type: **Custom TCP**
   - Port range: **2222**
   - Source: **My IP**
4. **Save rules**.

### 2.4 Activar firewalld y abrir el puerto 2222

```bash
sudo systemctl enable --now firewalld

# Abrir el nuevo puerto SSH
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload
```

### 2.5 Reiniciar SSH

```bash
sudo systemctl restart sshd
```

> **No cierres esta sesión.** Abre una **segunda pestaña** de Instance Connect (o una terminal local) y prueba:
>
> ```bash
> ssh -p 2222 ec2-user@<IP_PUBLICA>
> ```
>
> Si conecta, todo está bien. Si no, vuelve a la sesión original y revisa.

### 2.6 Verificar las tres medidas

```bash
# Root deshabilitado
sudo grep "^PermitRootLogin" /etc/ssh/sshd_config
# PermitRootLogin no

# Puerto cambiado
sudo ss -tlnp | grep sshd
# Debe mostrar *:2222 (no *:22)

# Contraseña deshabilitada
sudo grep "^PasswordAuthentication" /etc/ssh/sshd_config
# PasswordAuthentication no
```

**Captura estas tres salidas** — son parte de la evidencia.

---

## Fase 3 — Firewall con firewalld (30 min)

Ahora vamos a configurar firewalld de forma completa: política restrictiva, solo los servicios necesarios, y una regla avanzada para limitar SSH por IP.

### 3.1 Ver la configuración actual

```bash
sudo firewall-cmd --list-all
```

Salida típica después de la Fase 2:

```
public (active)
  target: default
  interfaces: eth0
  services: cockpit dhcpv6-client ssh
  ports: 2222/tcp
  ...
```

> Hay servicios que no necesitamos (`cockpit`, `dhcpv6-client`) y el servicio `ssh` apunta al puerto 22 (que ya no usamos). Vamos a limpiar.

### 3.2 Configurar solo lo necesario

```bash
# Permitir HTTP y HTTPS
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Remover el servicio SSH estándar (puerto 22 — ya migramos a 2222)
sudo firewall-cmd --permanent --remove-service=ssh

# Remover servicios innecesarios
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client

# Aplicar
sudo firewall-cmd --reload
```

### 3.3 Verificar

```bash
sudo firewall-cmd --list-all
```

Salida esperada:

```
public (active)
  target: default
  interfaces: eth0
  services: http https
  ports: 2222/tcp
```

Solo HTTP, HTTPS y nuestro puerto SSH personalizado.

### 3.4 Rich rules: restringir SSH a tu IP

Para mayor seguridad, puedes limitar SSH a una IP (o rango) específico:

```bash
# Averigua tu IP pública (desde tu máquina local, no la EC2)
# Puedes buscarla en https://ifconfig.me o en el Security Group (donde dice "My IP")

# Agregar rich rule: SSH solo desde tu IP
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<TU_IP>/32" port port="2222" protocol="tcp" accept'

# Ahora puedes quitar el puerto genérico 2222 (abierto a todo el mundo)
sudo firewall-cmd --permanent --remove-port=2222/tcp

sudo firewall-cmd --reload
```

> **Cuidado:** si tu IP cambia (ej. red móvil), perderás acceso SSH. En ese caso, Instance Connect sigue funcionando como plan B.

### 3.5 Verificar las rich rules

```bash
sudo firewall-cmd --list-rich-rules
# Debe mostrar la regla con tu IP y el puerto 2222

sudo firewall-cmd --list-all
# services: http https
# ports: (vacío — ya no hay 2222 genérico)
# rich rules: la regla de arriba
```

**Captura esta salida** — es parte de la evidencia.

### 3.6 Probar desde afuera

Desde tu máquina local (o la terminal del Learner Lab):

```bash
nc -zv <IP_PUBLICA> 22     # debería fallar (cerrado)
nc -zv <IP_PUBLICA> 2222   # debería conectar (desde tu IP)
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar (no permitido)
```

---

## Fase 4 — Firewall con nftables (30 min)

Ahora vamos a hacer lo mismo pero con nftables directamente, para entender qué pasa "por debajo" de firewalld.

### 4.1 Preparación: desactivar firewalld

No se pueden tener dos firewalls activos a la vez:

```bash
# Primero, quitar la rich rule para volver a abrir 2222 genérico (para no perder acceso)
sudo firewall-cmd --permanent --add-port=2222/tcp
sudo firewall-cmd --reload

# Ahora sí, detener firewalld
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

### 4.2 Crear la tabla y cadena

```bash
# Limpiar reglas existentes
sudo nft flush ruleset

# Crear tabla para IPv4+IPv6
sudo nft add table inet myfilter

# Crear cadena de entrada con política DROP (denegar todo por defecto)
sudo nft add chain inet myfilter input { type filter hook input priority 0 \; policy drop \; }
```

### 4.3 Agregar reglas de filtrado

```bash
# Permitir loopback (comunicación interna del servidor)
sudo nft add rule inet myfilter input iif lo accept

# Permitir conexiones ya establecidas (respuestas a peticiones que salieron)
sudo nft add rule inet myfilter input ct state established,related accept

# Permitir SSH en el puerto 2222
sudo nft add rule inet myfilter input tcp dport 2222 accept

# Permitir HTTP
sudo nft add rule inet myfilter input tcp dport 80 accept

# Permitir HTTPS
sudo nft add rule inet myfilter input tcp dport 443 accept
```

### 4.4 Verificar las reglas

```bash
sudo nft list ruleset
```

Salida esperada:

```
table inet myfilter {
    chain input {
        type filter hook input priority filter; policy drop;
        iif "lo" accept
        ct state established,related accept
        tcp dport 2222 accept
        tcp dport 80 accept
        tcp dport 443 accept
    }
}
```

> Compara esta salida con la de `firewall-cmd --list-all`. Ambas logran exactamente lo mismo, pero nftables muestra las reglas directamente como el kernel las interpreta.

### 4.5 Guardar la configuración

```bash
sudo nft list ruleset | sudo tee /etc/nftables.conf
```

Sin este paso, las reglas se pierden al reiniciar.

### 4.6 Probar desde afuera

```bash
nc -zv <IP_PUBLICA> 22     # debería fallar
nc -zv <IP_PUBLICA> 2222   # debería conectar
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar
```

### 4.7 Comparativa: ¿firewalld o nftables?

| Aspecto | firewalld | nftables |
|---|---|---|
| Abrir SSH | `firewall-cmd --permanent --add-port=2222/tcp` + `--reload` | `nft add rule inet myfilter input tcp dport 2222 accept` |
| Persistencia | Automática con `--permanent` | Manual: `nft list ruleset > /etc/nftables.conf` |
| Restringir por IP | Rich rules (una línea larga) | `nft add rule ... ip saddr <IP> tcp dport 2222 accept` (más directo) |
| IPv4+IPv6 | Automático | Una tabla `inet` cubre ambos |
| Recomendación Red Hat | Sí (forma oficial) | Para reglas muy específicas |

> **En producción:** usa firewalld salvo que necesites reglas que no puedas expresar con zonas/servicios/rich rules.

---

## Fase 5 — Protección contra fuerza bruta con Fail2Ban (20 min)

Fail2Ban monitorea los logs y bloquea automáticamente las IPs que fallan muchos intentos de login.

### 5.1 Volver a firewalld

Para la configuración final de producción, usamos firewalld (la herramienta recomendada):

```bash
# Limpiar nftables
sudo nft flush ruleset

# Re-activar firewalld
sudo systemctl enable --now firewalld

# Verificar que nuestras reglas siguen (--permanent las guardó)
sudo firewall-cmd --list-all
```

> Si las reglas de la Fase 3 se perdieron, vuelve a aplicarlas:
> ```bash
> sudo firewall-cmd --permanent --add-service=http
> sudo firewall-cmd --permanent --add-service=https
> sudo firewall-cmd --permanent --add-port=2222/tcp
> sudo firewall-cmd --permanent --remove-service=ssh
> sudo firewall-cmd --reload
> ```

### 5.2 Configurar Fail2Ban

Nunca edites `/etc/fail2ban/jail.conf` — se sobreescribe con actualizaciones. Usa un archivo local:

```bash
sudo nano /etc/fail2ban/jail.local
```

Contenido:

```ini
[DEFAULT]
bantime  = 600
findtime = 600
maxretry = 3

[sshd]
enabled  = true
port     = 2222
logpath  = /var/log/secure
backend  = systemd
```

| Parámetro | Significado |
|---|---|
| `maxretry = 3` | Si una IP falla 3 veces en los últimos 10 min (`findtime`), se bloquea |
| `bantime = 600` | El bloqueo dura 10 minutos |
| `logpath` | En Red Hat los intentos de login van a `/var/log/secure` |
| `backend = systemd` | Lee los logs a través de systemd/journald |

### 5.3 Habilitar e iniciar

```bash
sudo systemctl enable --now fail2ban
```

### 5.4 Verificar

```bash
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

**Captura esta salida** — es parte de la evidencia.

---

## Fase 6 — Verificación integral (15 min)

Ahora vas a verificar que **todo** funciona como se espera. Piensa en esto como la revisión que haría un auditor de seguridad.

### 6.1 Verificaciones desde el servidor

```bash
# 1. SSH está en el puerto 2222 y solo acepta claves
sudo ss -tlnp | grep sshd
# Debe mostrar *:2222, NO *:22

sudo grep "^PermitRootLogin\|^Port\|^PasswordAuthentication" /etc/ssh/sshd_config
# PermitRootLogin no
# Port 2222
# PasswordAuthentication no

# 2. Firewall activo con solo lo necesario
sudo firewall-cmd --list-all
# services: http https
# ports: 2222/tcp (o rich rule con tu IP)

# 3. Fail2Ban protegiendo SSH
sudo fail2ban-client status sshd
# enabled, monitoreando /var/log/secure

# 4. Puertos que realmente están escuchando
sudo ss -tlnp
# Solo debería verse sshd en 2222
```

### 6.2 Verificaciones desde afuera

Desde tu máquina local o la terminal del Learner Lab:

```bash
# Puerto 22 (SSH antiguo) — debe fallar
nc -zv <IP_PUBLICA> 22
# Connection refused o timeout

# Puerto 2222 (SSH nuevo) — debe conectar
nc -zv <IP_PUBLICA> 2222
# Connection succeeded

# Puerto 80 (HTTP) — debe conectar
nc -zv <IP_PUBLICA> 80
# Connection succeeded (aunque no haya web server, el firewall lo permite)

# Puerto 443 (HTTPS) — debe conectar
nc -zv <IP_PUBLICA> 443

# Puerto 3306 (MySQL) — debe fallar
nc -zv <IP_PUBLICA> 3306
# Connection refused o timeout

# Puerto 23 (Telnet) — debe fallar
nc -zv <IP_PUBLICA> 23
# Connection refused o timeout
```

### 6.3 Resumen de lo que aseguraste

| Medida | Herramienta | Qué previene |
|---|---|---|
| Deshabilitar root por SSH | `sshd_config` | Acceso directo como root, incluso con la clave correcta |
| Cambiar puerto SSH a 2222 | `sshd_config` + Security Group + firewalld | Bots que atacan el puerto 22 por defecto |
| Solo autenticación por clave | `sshd_config` | Ataques de fuerza bruta de contraseña |
| Firewall restrictivo (firewalld) | `firewall-cmd` | Acceso a puertos no autorizados |
| Rich rules (SSH por IP) | `firewall-cmd` | SSH desde IPs no autorizadas |
| Firewall directo (nftables) | `nft` | Lo mismo que firewalld, pero con control manual |
| Fail2Ban | `fail2ban` | IPs que repiten intentos fallidos (fuerza bruta) |

---

## Fase 7 — Documentación y entrega (10 min)

### 7.1 Comandos para capturar evidencias

Ejecuta estos comandos y captura las salidas (screenshot o copiar/pegar):

```bash
# Evidencia 1: Configuración de SSH
sudo grep "^PermitRootLogin\|^Port\|^PasswordAuthentication" /etc/ssh/sshd_config

# Evidencia 2: Puerto SSH activo
sudo ss -tlnp | grep sshd

# Evidencia 3: Firewall (firewalld)
sudo firewall-cmd --list-all

# Evidencia 4: Rich rules (si las configuraste)
sudo firewall-cmd --list-rich-rules

# Evidencia 5: Fail2Ban
sudo fail2ban-client status sshd

# Evidencia 6: Configuración de nftables guardada
cat /etc/nftables.conf

# Evidencia 7: Pruebas de puertos (ejecutar desde afuera)
# nc -zv <IP_PUBLICA> 22    → falla
# nc -zv <IP_PUBLICA> 2222  → conecta
# nc -zv <IP_PUBLICA> 80    → conecta
# nc -zv <IP_PUBLICA> 3306  → falla
```

### 7.2 Limpieza

Al terminar, **detén o elimina la instancia** para no consumir créditos del Learner Lab:

```bash
# Desde la consola EC2: selecciona la instancia → Instance state → Stop instance (o Terminate)
```

---

## Troubleshooting

| Fase | Síntoma | Causa probable | Solución |
|---|---|---|---|
| 1 | Instance Connect dice "No se pudo conectar" | Red Hat no trae Instance Connect preinstalado | Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) |
| 2 | Me quedé fuera del servidor tras cambiar el puerto SSH | No abriste el puerto 2222 en el Security Group **o** en firewalld antes de reiniciar `sshd` | Usa Instance Connect desde la consola web para entrar y revertir. Si Instance Connect tampoco funciona, edita el Security Group y reinicia la instancia |
| 2 | `sshd` no reinicia: "error: Bind to 0.0.0.0 port 2222 failed" | Otro proceso ya usa el puerto 2222 | `sudo ss -tlnp \| grep 2222` para ver qué lo ocupa; elige otro puerto |
| 3 | `firewall-cmd: command not found` | `firewalld` no está instalado | `sudo dnf install -y firewalld && sudo systemctl enable --now firewalld` |
| 3 | Después del `--reload`, las reglas no aparecen | Se agregaron sin `--permanent` | Vuelve a ejecutar los comandos con `--permanent` y luego `--reload` |
| 3 | `nc -zv` conecta a un puerto que debería estar cerrado | El servicio no se removió del firewall, o no se hizo `--reload` | `sudo firewall-cmd --list-all` para confirmar; remueve el servicio y recarga |
| 4 | `nft add chain` falla: "Error: Could not process rule" | Falta escapar el punto y coma (`\;`) en bash | Asegúrate de usar `\;` dentro de `{ }` |
| 4 | Después de reiniciar, las reglas de nftables desaparecen | No se guardaron con `nft list ruleset > /etc/nftables.conf` | Reconfigura y guarda |
| 5 | `fail2ban-client status sshd`: "Sorry but the jail 'sshd' does not exist" | Error de sintaxis en `jail.local`, o el servicio no se reinició | Revisa la sintaxis; `sudo systemctl restart fail2ban` |
| 5 | `dnf install fail2ban` falla con "No match" | EPEL no está habilitado | `sudo dnf install -y epel-release` primero |
| 5 | Fail2Ban no banea las IPs de prueba | `PasswordAuthentication` está deshabilitado, así que los intentos fallan antes de llegar al conteo | Los intentos con usuario inexistente sí generan líneas `Invalid user` en `/var/log/secure` y cuentan para Fail2Ban |
| 6 | `nc -zv` da timeout en un puerto que debería estar abierto | El Security Group de AWS no tiene ese puerto permitido | Edita el Security Group en la consola EC2 |
| * | No recuerdo mi IP pública para el Security Group | — | En la consola EC2 al editar reglas, elige **My IP** como Source |

---

## Checklist antes de entregar

### SSH (Fase 2)
- [ ] `PermitRootLogin no` está configurado y verificado.
- [ ] SSH escucha en el puerto 2222 (el 22 ya no responde).
- [ ] `PasswordAuthentication no` está configurado (solo clave pública).
- [ ] El puerto 2222 está abierto en el Security Group de AWS.

### Firewall — firewalld (Fase 3)
- [ ] `firewalld` está instalado, activo y configurado.
- [ ] Solo los servicios `http` y `https` están permitidos (más el puerto 2222 o rich rule).
- [ ] Los servicios innecesarios (`cockpit`, `dhcpv6-client`, `ssh`) fueron removidos.
- [ ] `sudo firewall-cmd --list-all` muestra la configuración correcta.

### Firewall — nftables (Fase 4)
- [ ] Configuraste una tabla y cadena con política `drop`.
- [ ] Las reglas permiten loopback, established/related, puertos 2222, 80 y 443.
- [ ] La configuración está guardada en `/etc/nftables.conf`.
- [ ] Puedes mostrar la salida de `sudo nft list ruleset`.

### Fail2Ban (Fase 5)
- [ ] Fail2Ban está activo con la jail `sshd` habilitada en el puerto 2222.
- [ ] `sudo fail2ban-client status sshd` muestra la jail funcionando.

### Verificación (Fase 6)
- [ ] Desde afuera, el puerto 22 no responde.
- [ ] Desde afuera, el puerto 2222 conecta.
- [ ] Desde afuera, el puerto 3306 no responde.
- [ ] Puedes explicar qué herramienta usaste para cada medida y por qué.

### Entrega (Fase 7)
- [ ] Capturaste las 7 evidencias listadas en la Fase 7.
- [ ] La instancia está detenida o eliminada.

---

## ¿Qué aprendiste?

Al completar este laboratorio, conecta cada fase con los indicadores de logro:

| Fase | Qué hiciste | IL |
|---|---|---|
| 2 — Hardening SSH | Restringiste el acceso al servidor: sin root, sin contraseña, puerto no estándar | **IL 3.1** — Hardening para aumentar el nivel de seguridad |
| 3 — firewalld | Aplicaste una política restrictiva (denegar todo, abrir solo lo necesario) con la herramienta estándar de Red Hat | **IL 3.1** — Hardening con buenas prácticas de la industria |
| 4 — nftables | Configuraste el mismo firewall directamente en el motor del kernel, entendiendo qué hace firewalld "por debajo" | **IL 3.1** — Hardening a nivel de kernel |
| 5 — Fail2Ban | Implementaste detección y respuesta automática ante intentos de fuerza bruta | **IL 3.4** — Mecanismos de auditoría y monitoreo para detectar y responder a incidentes |
| 6 — Verificación | Validaste que todas las medidas funcionan como se espera, simulando una auditoría de seguridad | **IL 3.1 + IL 3.4** — Verificación integral |

**Pregunta de reflexión:** si mañana te piden asegurar un servidor Ubuntu (en vez de Red Hat), ¿qué herramientas cambiarían y cuáles serían exactamente iguales? (Pista: SSH y Fail2Ban son idénticos; el firewall cambia de `firewalld` a `ufw`; nftables funciona igual en ambos.)

---

## Recursos adicionales

- [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — guía de instalación para la AMI de RHEL.
- [Act_3.1.2 — Hardening de un servidor Linux](../Act_3.1.2/) — la actividad individual de hardening.
- [Act_3.2.2 — Configuración y gestión de firewall](../Act_3.2.2/) — la actividad individual de firewall.
- `man sshd_config` — referencia completa de directivas de SSH.
- `man firewall-cmd` — referencia de `firewalld`.
- `man nft` — referencia de nftables.
- [Fail2Ban Wiki](https://github.com/fail2ban/fail2ban/wiki) — documentación oficial.
- [Red Hat — Configuring firewalld](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_firewalls_and_packet_filters/using-and-configuring-firewalld_firewall-packet-filters)
- [CIS Benchmarks for Red Hat](https://www.cisecurity.org/benchmark/red_hat_linux) — el estándar de la industria para hardening.
