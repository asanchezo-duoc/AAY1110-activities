# Act 3.2.2 — Configuración y gestión de firewall en Linux

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | 3.2.2 Guía Firewall |
| **RA** | RA3 |
| **IL** | IL 3.4 — Implementa mecanismos de auditoría y monitoreo para detectar y responder a incidentes de seguridad en Linux |
| **Tiempo estimado** | 1 hora |

> **Prerequisito:** haber completado [Act_3.1.2](../Act_3.1.2/) — allí se configuró SSH y un firewall básico. Aquí vamos a profundizar en tres herramientas de firewall distintas.

## Contexto

Eres el administrador de sistemas de una empresa que ofrece servicios web a sus clientes. Tu servidor Linux aloja una aplicación web y un servidor de base de datos. Debes configurar un firewall que:

- Limite el acceso **solo** a los servicios necesarios (SSH, HTTP, HTTPS).
- Aplique una política restrictiva por defecto (denegar todo lo que no esté explícitamente permitido).
- Permita monitorear el tráfico para detectar intentos de intrusión.

En este laboratorio vas a configurar las **cuatro herramientas de firewall** más comunes en Linux, para que entiendas las diferencias y puedas elegir la adecuada según el entorno:

| Herramienta | Qué es | Cuándo usarla |
|---|---|---|
| **firewalld** | Servicio de firewall dinámico con zonas y gestión en caliente | Red Hat / CentOS / Fedora (viene preinstalado) |
| **UFW** | Frontend simplificado de iptables/nftables | Servidores Ubuntu/Debian, configuración rápida |
| **iptables** | Interfaz clásica del kernel para filtrado de paquetes (netfilter) | Entornos legacy, reglas muy específicas |
| **nftables** | Reemplazo moderno de iptables (desde kernel 3.13+) | Distribuciones nuevas (RHEL 9+), rendimiento, sintaxis unificada |

> **Nota sobre Red Hat 9:** RHEL 9 usa `nftables` como backend por defecto. `firewalld` es un frontend que habla con `nftables` por detrás y es el método **recomendado** en Red Hat. En este laboratorio vamos a trabajar con `firewalld` (la forma "oficial") y luego directamente con cada herramienta de bajo nivel para entender qué pasa por debajo.

---

## Paso 0 — Levantar la VM en AWS Academy

Si ya tienes la VM de [Act_3.1.2](../Act_3.1.2/) corriendo, puedes reutilizarla. Si no:

1. Ingresa a **https://awsacademy.instructure.com/** → **Learner Lab** → **Start Lab**.

2. Lanza una instancia EC2:

   | Campo | Valor |
   |---|---|
   | **Name** | `firewall-lab` |
   | **AMI** | Red Hat Enterprise Linux 9 (x86_64, Free tier eligible) |
   | **Instance type** | `t2.micro` |
   | **Key pair** | `vockey` (la llave por defecto del Learner Lab) |
   | **Security Group** | Permite SSH (22), HTTP (80), HTTPS (443) desde tu IP |

3. Conéctate con **EC2 Instance Connect**: selecciona la instancia → **Connect** → pestaña **EC2 Instance Connect** → usuario `ec2-user` → **Connect**.

   > **¿No conecta?** Red Hat no trae Instance Connect preinstalado. Sigue la guía [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) (solo una vez por instancia).

4. Verifica:

   ```bash
   cat /etc/redhat-release   # Red Hat Enterprise Linux release 9.x
   ```

> **Importante para este laboratorio:** vamos a probar tres firewalls distintos. Para evitar conflictos, en cada tarea desactivamos el anterior antes de activar el siguiente.

---

## Tarea 1 — Configurar firewall con firewalld

`firewalld` es el **firewall estándar en Red Hat, CentOS y Fedora**. A diferencia de iptables/nftables (donde escribes reglas directamente), firewalld trabaja con el concepto de **zonas**: cada zona define un nivel de confianza y las reglas se aplican a interfaces o conexiones asignadas a esa zona.

### 1.1 Instalar y activar firewalld

En la AMI de Red Hat del Learner Lab, `firewalld` **no viene preinstalado**. Instálalo primero:

```bash
sudo dnf install -y firewalld
sudo systemctl enable --now firewalld
sudo firewall-cmd --state
# Salida esperada: running
```

### 1.2 Explorar la configuración actual

```bash
# Ver la zona activa y sus reglas
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
```

Salida típica en una instancia EC2 nueva:

```
public (active)
  target: default
  interfaces: eth0
  services: cockpit dhcpv6-client ssh
  ...
```

> La zona `public` es la zona por defecto. Los servicios listados (`ssh`, etc.) son los que están permitidos. Todo lo demás se rechaza.

### 1.3 Definir las reglas — solo SSH, HTTP y HTTPS

```bash
# Permitir HTTP y HTTPS
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https

# Verificar que SSH está permitido (ya debería estarlo por defecto)
sudo firewall-cmd --permanent --query-service=ssh
# Si usas puerto 2222 en vez de 22:
# sudo firewall-cmd --permanent --add-port=2222/tcp
# sudo firewall-cmd --permanent --remove-service=ssh

# Remover servicios innecesarios que vengan por defecto
sudo firewall-cmd --permanent --remove-service=cockpit
sudo firewall-cmd --permanent --remove-service=dhcpv6-client

# Aplicar los cambios
sudo firewall-cmd --reload
```

> **¿Qué es `--permanent`?** Sin este flag, los cambios son temporales y se pierden al reiniciar `firewalld`. Con `--permanent` se guardan en la configuración persistente, pero no se aplican hasta hacer `--reload`.

### 1.4 Verificar la configuración final

```bash
sudo firewall-cmd --list-all
```

Salida esperada:

```
public (active)
  target: default
  interfaces: eth0
  services: http https ssh
  ports:
  ...
```

### 1.5 Reglas avanzadas: restringir SSH a una IP específica

`firewalld` soporta **rich rules** para reglas más granulares:

```bash
# Permitir SSH solo desde tu IP (reemplaza <TU_IP>)
sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<TU_IP>/32" service name="ssh" accept'

# Remover la regla genérica de SSH (ahora solo entra tu IP)
sudo firewall-cmd --permanent --remove-service=ssh

sudo firewall-cmd --reload
sudo firewall-cmd --list-rich-rules
```

> Este tipo de restricción por IP de origen es mucho más engorroso en iptables puro. Es una de las ventajas de firewalld.

### 1.6 Probar desde afuera

```bash
nc -zv <IP_PUBLICA> 22     # debería conectar (o solo desde tu IP si usaste rich rules)
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar (MySQL no está permitido)
```

### 1.7 Desactivar firewalld (para la siguiente tarea)

```bash
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```

---

## Tarea 2 — Configurar firewall con UFW

UFW (Uncomplicated Firewall) es el frontend más simple. No viene en Red Hat por defecto, así que primero lo instalamos.

### 2.1 Preparación

```bash
# Detener firewalld para evitar conflictos
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Instalar UFW (requiere EPEL)
sudo dnf install -y epel-release
sudo dnf install -y ufw
```

### 2.2 Definir políticas por defecto

La filosofía de un buen firewall es: **denegar todo por defecto, permitir solo lo necesario.**

```bash
sudo ufw default deny incoming    # bloquear todo el tráfico entrante
sudo ufw default allow outgoing   # permitir todo el tráfico saliente
```

> **¿Por qué permitir el saliente?** Tu servidor necesita descargar actualizaciones, resolver DNS, enviar respuestas a clientes. Bloquear el saliente es posible pero requiere reglas mucho más granulares y no es el foco de este laboratorio.

### 2.3 Permitir solo los servicios necesarios

```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP
sudo ufw allow 443/tcp     # HTTPS
```

> Si vienes de Act_3.1.2 y cambiaste SSH al puerto 2222, usa `sudo ufw allow 2222/tcp` en lugar de `22/tcp`.

### 2.4 Activar UFW

```bash
sudo ufw enable
```

Te preguntará si estás seguro (porque podría interrumpir conexiones existentes). Responde `y`.

### 2.5 Verificar

```bash
sudo ufw status verbose
```

Salida esperada:

```
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), disabled (routed)

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW IN    Anywhere
80/tcp                     ALLOW IN    Anywhere
443/tcp                    ALLOW IN    Anywhere
22/tcp (v6)                ALLOW IN    Anywhere (v6)
80/tcp (v6)                ALLOW IN    Anywhere (v6)
443/tcp (v6)               ALLOW IN    Anywhere (v6)
```

### 2.6 Probar desde afuera

Desde tu máquina local:

```bash
nc -zv <IP_PUBLICA> 22     # debería conectar (o 2222 si lo cambiaste)
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar (MySQL no está permitido)
```

### 2.7 Desactivar UFW (para la siguiente tarea)

```bash
sudo ufw disable
sudo systemctl stop ufw 2>/dev/null
```

---

## Tarea 3 — Configurar firewall con iptables

`iptables` es la herramienta clásica de filtrado de paquetes en Linux. Trabaja directamente con las tablas del kernel (netfilter). Es más verbosa que UFW, pero te da control total.

### 3.1 Preparación

```bash
# Asegurarse de que UFW y firewalld están apagados
sudo ufw disable 2>/dev/null
sudo systemctl stop firewalld 2>/dev/null

# Instalar iptables-services para poder guardar reglas
sudo dnf install -y iptables-services
sudo systemctl enable iptables
sudo systemctl start iptables

# Limpiar reglas existentes (empezar de cero)
sudo iptables -F
sudo iptables -X
```

### 3.2 Definir políticas por defecto

```bash
# Denegar todo el tráfico entrante
sudo iptables -P INPUT DROP

# Permitir todo el tráfico saliente
sudo iptables -P OUTPUT ACCEPT

# Denegar reenvío (no somos router)
sudo iptables -P FORWARD DROP
```

> **¿Qué es `-P`?** Policy (política). Si un paquete no coincide con ninguna regla explícita, se le aplica la política por defecto. `DROP` = descartar silenciosamente.

### 3.3 Permitir tráfico en puertos específicos

```bash
# Permitir tráfico en la interfaz de loopback (comunicación interna del servidor)
sudo iptables -A INPUT -i lo -j ACCEPT

# Permitir conexiones ya establecidas (respuestas a peticiones que salieron)
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Permitir SSH (puerto 22, o 2222 si lo cambiaste)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Permitir HTTP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# Permitir HTTPS
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

Desglose de la sintaxis:

| Parte | Significado |
|---|---|
| `-A INPUT` | Append: agrega la regla al final de la cadena INPUT (tráfico entrante) |
| `-p tcp` | Protocolo TCP |
| `--dport 22` | Puerto de destino 22 |
| `-j ACCEPT` | Jump to ACCEPT: permitir el paquete |
| `-m conntrack --ctstate ESTABLISHED,RELATED` | Módulo de seguimiento de conexiones: permite paquetes que pertenecen a una conexión ya iniciada |

### 3.4 Verificar las reglas

```bash
sudo iptables -L -n -v
```

Salida esperada:

```
Chain INPUT (policy DROP)
 pkts bytes target     prot opt in     out     source    destination
    0     0 ACCEPT     all  --  lo     *       0.0.0.0/0 0.0.0.0/0
    X     X ACCEPT     all  --  *      *       0.0.0.0/0 0.0.0.0/0  ctstate RELATED,ESTABLISHED
    X     X ACCEPT     tcp  --  *      *       0.0.0.0/0 0.0.0.0/0  tcp dpt:22
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0 0.0.0.0/0  tcp dpt:80
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0 0.0.0.0/0  tcp dpt:443

Chain FORWARD (policy DROP)

Chain OUTPUT (policy ACCEPT)
```

### 3.5 Guardar las reglas (persistir tras reinicio)

```bash
sudo service iptables save
# Esto guarda en /etc/sysconfig/iptables
```

> Sin este paso, las reglas se pierden al reiniciar el servidor. Este es un error frecuente con iptables.

### 3.6 Probar desde afuera

```bash
nc -zv <IP_PUBLICA> 22     # debería conectar
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar (timeout/refused)
```

### 3.7 Limpiar (para la siguiente tarea)

```bash
sudo iptables -F
sudo iptables -P INPUT ACCEPT   # volver a política permisiva temporalmente
sudo systemctl stop iptables
```

---

## Tarea 4 — Configurar firewall con nftables

`nftables` es el sucesor moderno de iptables. Tiene una sintaxis más limpia, mejor rendimiento, y es el backend por defecto en Red Hat 9+.

### 4.1 Preparación

```bash
# Asegurarse de que los otros firewalls están apagados
sudo systemctl stop iptables 2>/dev/null
sudo ufw disable 2>/dev/null

# Habilitar nftables
sudo systemctl enable nftables
sudo systemctl start nftables

# Limpiar reglas existentes
sudo nft flush ruleset
```

### 4.2 Crear una tabla y cadena de reglas

En nftables, las reglas se organizan en **tablas** (agrupación lógica) y **cadenas** (punto de enganche en el flujo de red):

```bash
# Crear una tabla llamada "myfilter" para la familia inet (IPv4 + IPv6)
sudo nft add table inet myfilter

# Crear una cadena de entrada con política DROP (denegar por defecto)
sudo nft add chain inet myfilter input { type filter hook input priority 0 \; policy drop \; }
```

> **¿Qué es `inet`?** La familia `inet` maneja IPv4 e IPv6 con las mismas reglas. En iptables necesitabas `iptables` + `ip6tables` por separado.

### 4.3 Agregar reglas de filtrado

```bash
# Permitir loopback
sudo nft add rule inet myfilter input iif lo accept

# Permitir conexiones establecidas
sudo nft add rule inet myfilter input ct state established,related accept

# Permitir SSH (puerto 22, o 2222 si lo cambiaste)
sudo nft add rule inet myfilter input tcp dport 22 accept

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
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
    }
}
```

> Observa lo legible que es comparado con la salida de `iptables -L`. Esta es una de las ventajas de nftables.

### 4.5 Guardar la configuración (persistir tras reinicio)

```bash
sudo nft list ruleset | sudo tee /etc/nftables.conf
```

Esto sobreescribe el archivo de configuración que `nftables.service` carga al inicio.

### 4.6 Probar desde afuera

```bash
nc -zv <IP_PUBLICA> 22     # debería conectar
nc -zv <IP_PUBLICA> 80     # debería conectar
nc -zv <IP_PUBLICA> 3306   # debería fallar
```

---

## Comparativa de las cuatro herramientas

| Aspecto | firewalld | UFW | iptables | nftables |
|---|---|---|---|---|
| **Complejidad** | Baja-Media (zonas + servicios) | Baja (frontend amigable) | Media-Alta (sintaxis verbosa) | Media (sintaxis limpia) |
| **Concepto central** | Zonas de confianza | Reglas allow/deny simples | Cadenas + reglas (ACCEPT/DROP) | Tablas + cadenas + reglas |
| **IPv4 + IPv6** | Una regla cubre ambos | Una regla cubre ambos | Requiere `iptables` + `ip6tables` | Una tabla `inet` cubre ambos |
| **Cambios en caliente** | Sí (`--reload` sin perder conexiones) | Requiere `ufw reload` | Inmediatos pero pueden cortar conexiones | Inmediatos |
| **Persistencia** | Automática con `--permanent` | Automática (`ufw enable`) | Manual (`service iptables save`) | Manual (`nft list ruleset > /etc/nftables.conf`) |
| **Default en Red Hat 9** | Estándar pero no siempre preinstalado (la AMI del Learner Lab requiere `dnf install firewalld`) | No (requiere EPEL) | Disponible pero legacy | Sí (backend de firewalld) |
| **Default en Ubuntu** | Disponible pero no por defecto | Sí (preinstalado) | Disponible | Disponible |
| **Producción empresarial** | Recomendado en RHEL/CentOS/Fedora | Servidores Ubuntu simples | Legacy / scripts existentes | Recomendado para reglas manuales avanzadas |

> **¿Cuál usar?** En Red Hat, la recomendación oficial es usar **`firewalld`** (que internamente usa nftables). Si necesitas reglas muy específicas que firewalld no cubre, usa `nft` directamente. `iptables` solo tiene sentido si administras sistemas legacy que ya lo usan. UFW es ideal para servidores Ubuntu/Debian simples.

---

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| Me quedé fuera del servidor al activar el firewall | No permitiste el puerto SSH antes de activar | Usa **EC2 Instance Connect** desde la consola web para entrar y corregir (ver [guía de Instance Connect en Red Hat](../../recursos/instance-connect-rhel/)), o termina la instancia y crea una nueva |
| `ufw: command not found` | UFW no está instalado en Red Hat | `sudo dnf install -y epel-release && sudo dnf install -y ufw` |
| Las reglas de iptables desaparecen al reiniciar | No se guardaron con `service iptables save` | Ejecuta `sudo service iptables save` después de configurar |
| `nft: command not found` | El paquete `nftables` no está instalado | `sudo dnf install -y nftables` |
| `firewall-cmd` dice "FirewallD is not running" | El servicio está detenido | `sudo systemctl start firewalld` |
| `firewalld` interfiere con mis reglas manuales | `firewalld` sobreescribe reglas de nftables/iptables | Detén `firewalld` antes: `sudo systemctl stop firewalld && sudo systemctl disable firewalld` |
| `nft add chain` falla con "Error: Could not process rule" | Falta escapar el punto y coma (`\;`) en bash, o falta cerrar la llave | Asegúrate de escapar: `{ type filter hook input priority 0 \; policy drop \; }` |
| `nc -zv` da timeout en un puerto que debería estar abierto | El Security Group de AWS no tiene ese puerto permitido | Edita el Security Group en la consola EC2 y agrega el puerto |

## Checklist antes de entregar

- [ ] Configuraste firewalld con los servicios http, https y ssh permitidos, y removiste servicios innecesarios.
- [ ] Configuraste UFW con política deny incoming / allow outgoing, y permitiste solo SSH, HTTP y HTTPS.
- [ ] Configuraste iptables con política DROP en INPUT, y reglas ACCEPT para SSH, HTTP, HTTPS y conexiones establecidas.
- [ ] Configuraste nftables con una tabla y cadena propia, política drop, y reglas para los puertos necesarios.
- [ ] Guardaste la configuración de nftables en `/etc/nftables.conf`.
- [ ] Puedes explicar la diferencia principal entre las cuatro herramientas y cuándo usar cada una.
- [ ] Verificaste desde afuera (con `nc`, `nmap` o pruebas manuales) que solo los puertos permitidos están abiertos.
- [ ] Puedes mostrar la salida de `sudo firewall-cmd --list-all` y/o `sudo nft list ruleset` con las reglas activas.

## Recursos adicionales

- [Habilitar EC2 Instance Connect en Red Hat](../../recursos/instance-connect-rhel/) — si te quedas fuera del servidor al configurar el firewall, esta guía te permite entrar desde la consola web de AWS.
- `man ufw` — referencia de UFW.
- `man iptables` — referencia de iptables.
- `man nft` — referencia de nftables.
- [Red Hat — Getting started with nftables](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_firewalls_and_packet_filters/getting-started-with-nftables_firewall-packet-filters)
- [nftables Wiki](https://wiki.nftables.org/) — documentación oficial del proyecto.
- [UFW Essentials (DigitalOcean)](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands) — guía práctica de UFW.
- [iptables vs nftables (Red Hat Blog)](https://www.redhat.com/en/blog/iptables-nftables-comparison) — comparativa oficial.
