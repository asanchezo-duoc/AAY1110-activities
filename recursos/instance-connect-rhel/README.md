# Habilitar EC2 Instance Connect en Red Hat

EC2 Instance Connect es la opción de "Conectar" desde la consola web de AWS: genera una **llave SSH temporal** (válida 60 segundos), se la envía al servicio de AWS y el `sshd` de la instancia la consulta al momento del login. **Amazon Linux y Ubuntu traen el paquete necesario instalado. Red Hat no.**

Si intentas conectarte desde la consola (**EC2 → tu instancia → Conectar → Conexión de la instancia EC2**), verás: **"No se pudo conectar a la instancia"**.

## 1. Entrar una vez por SSH con la llave del lab

Como Instance Connect aún no funciona, la primera conexión debe ser con la llave `.pem`:

```bash
ssh -i ~/Downloads/labsuser.pem -o StrictHostKeyChecking=no ec2-user@<IP_PUBLICA>
```

## 2. Instalar el paquete de Instance Connect

```bash
sudo dnf install -y \
  https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect.rhel8.rpm \
  https://amazon-ec2-instance-connect-us-west-2.s3.us-west-2.amazonaws.com/latest/linux_amd64/ec2-instance-connect-selinux.noarch.rpm
```

El paquete instala el script `/opt/aws/bin/eic_run_authorized_keys`, pero **no lo activa** en `sshd`. Compruébalo:

```bash
sudo sshd -T | grep -i authorizedkeyscommand
# authorizedkeyscommand none
```

## 3. Activar Instance Connect en sshd

Crea un archivo de configuración propio (no edites `sshd_config` directamente):

```bash
sudo tee /etc/ssh/sshd_config.d/40-ec2-instance-connect.conf <<'EOF'
AuthorizedKeysCommand /opt/aws/bin/eic_run_authorized_keys %u %f
AuthorizedKeysCommandUser ec2-instance-connect
EOF
```

## 4. Validar y reiniciar

```bash
# Validar ANTES de reiniciar (si tiene error y reinicias, puedes quedarte sin SSH)
sudo sshd -t

# Si no hay errores, reiniciar
sudo systemctl restart sshd
```

## 5. Verificar que quedó activo

```bash
sudo sshd -T | grep -i authorizedkeyscommand
# authorizedkeyscommand /opt/aws/bin/eic_run_authorized_keys %u %f
# authorizedkeyscommanduser ec2-instance-connect
```

## 6. Probar desde la consola

Sal con `exit` y vuelve a **EC2 → Conectar → Conexión de la instancia EC2 → usuario `ec2-user` → Conectar**. Ahora debería abrirse la terminal directamente en el navegador.

> **¿Por qué es útil?** Si durante el laboratorio te quedas fuera del servidor (por ejemplo, cambiaste el puerto SSH y olvidaste abrir el nuevo en el Security Group), Instance Connect es tu **plan B** para entrar y corregir sin tener que terminar la instancia.

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| `sshd -t` muestra un error de sintaxis | El archivo `.conf` tiene un error de formato | Revisa el contenido de `/etc/ssh/sshd_config.d/40-ec2-instance-connect.conf` — debe tener exactamente las dos líneas del paso 3 |
| Sigue diciendo `authorizedkeyscommand none` después del reinicio | El archivo `.conf` no se está cargando | Verifica que `/etc/ssh/sshd_config` contiene la línea `Include /etc/ssh/sshd_config.d/*.conf` (viene por defecto en RHEL 9) |
| Instance Connect conecta pero luego se cae en 2 segundos | El Security Group no permite tráfico desde el rango de IPs del servicio de Instance Connect | Asegúrate de que el puerto SSH (22 o 2222) está abierto en el Security Group al menos desde `0.0.0.0/0` o desde el rango de IPs de EC2 Instance Connect de tu región |
| `dnf install` falla con "No se pudo resolver el host" | La instancia no tiene acceso a internet | Verifica que la instancia tiene una IP pública y que el Security Group permite tráfico saliente |
