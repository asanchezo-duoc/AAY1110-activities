# Act 2.2.2 — Script de respaldo automatizado con cron

| | |
|---|---|
| **Asignatura** | AAY1110 — Sistemas Operativos Corporativos en Cloud |
| **Recurso oficial** | Laboratorio de Ejecución de script de Respaldo de información |
| **RA** | RA2 |
| **IL** | IL 2.1, IL 2.3, IL 2.4 |
| **Tiempo estimado** | 1 hora |

## Caso (según guía oficial)

Eres el administrador de sistemas de una empresa que requiere respaldar diariamente `/home/usuario/datos` hacia `/backups`. Cada respaldo debe:

- Estar comprimido en `.tar.gz`.
- Incluir fecha y hora en el nombre del archivo (`YYYYMMDD_HHMMSS`).
- Ejecutarse automáticamente todos los días a las 2:00 AM vía **cron**.
- Quedar registrado en un **log** con inicio/fin, tamaño del archivo y errores.
- Presentarse además como **infografía** del laboratorio.

> Esta actividad **sí es evidencia evaluada** (el script + la infografía se entregan en AVA). Este README explica los conceptos y te da una plantilla incompleta (`scripts/plantilla_backup.sh`) — el script final que entregues debe ser tuyo, adaptado a las rutas y requisitos exactos de tu caso.

## Conceptos clave

**Tipos de respaldo (IL 2.3).** Antes de programar, conviene tener claro qué tipo de respaldo estás haciendo:

| Tipo | Qué copia | Ventaja | Desventaja |
|---|---|---|---|
| Completo (full) | Todo el contenido, siempre | Restauración simple: un solo archivo | Más tiempo y espacio por corrida |
| Incremental | Solo lo que cambió desde el **último respaldo (de cualquier tipo)** | Rápido y liviano | Restaurar requiere el full + todos los incrementales en orden |
| Diferencial | Solo lo que cambió desde el **último full** | Restaurar es full + último diferencial | Crece con el tiempo hasta el próximo full |

El caso planteado (respaldo diario simple con `tar`) corresponde a un **respaldo completo** — justifícalo así en tu entrega, y menciona por qué no usaste incremental/diferencial (por ejemplo: simplicidad y bajo volumen de datos).

**`tar` + compresión.** `tar` empaqueta archivos en un solo `.tar`; la bandera `-z` lo comprime con `gzip` en el mismo paso, dando `.tar.gz`:

```bash
tar -czf destino.tar.gz -C /ruta/origen .
```

- `-c`: crear archivo. `-z`: comprimir con gzip. `-f`: nombre del archivo de salida.
- `-C /ruta/origen .`: se posiciona **dentro** de `/ruta/origen` antes de empaquetar, así el `.tar.gz` no incluye la ruta absoluta completa (evita rutas feas al restaurar).

**Fecha y hora en el nombre.** `date` con formato controla exactamente el string:

```bash
FECHA=$(date +"%Y%m%d_%H%M%S")   # ej: 20260912_020000
```

**Automatización con cron.** `cron` ejecuta comandos en horarios definidos. Se edita con:

```bash
crontab -e
```

Más ejemplos comentados de líneas de crontab (y de `at`, para tareas de una sola ejecución) en [recursos/cron-at](../../recursos/cron-at/).

Formato de una línea de crontab:

```
minuto hora dia-mes mes dia-semana   comando
0      2    *       *   *            /ruta/al/script.sh
```

Para correr a las 2:00 AM todos los días:

```
0 2 * * * /home/usuario/backup.sh >> /backups/cron.log 2>&1
```

- `>> archivo 2>&1` redirige tanto salida estándar como errores al log — útil porque cron **no muestra nada en pantalla**, corre en segundo plano sin que nadie lo vea fallar si no lo logueas.
- El script debe usar **rutas absolutas** en todo (no `~` ni rutas relativas): cron ejecuta con un entorno mínimo, distinto al de tu sesión interactiva.

**Logging.** El log debe registrar como mínimo: timestamp de inicio, timestamp de fin, tamaño del archivo generado, y cualquier error. Verifica el código de retorno del comando anterior con `$?`:

```bash
tar -czf "$destino" -C "$origen" .
if [ $? -eq 0 ]; then
  echo "OK"
else
  echo "ERROR"
fi
```

## Guía paso a paso

1. **Diseña la estructura antes de escribir código.** Define: variables (origen, destino, log), nombre del archivo con timestamp, y qué vas a loguear.
2. **Escribe el script en tu VM** (puedes partir de `scripts/plantilla_backup.sh` como referencia de estructura, pero completa los `TODO` con tu propia lógica y las rutas reales del caso).
3. **Dale permisos de ejecución:** `chmod +x backup.sh`.
4. **Pruébalo manualmente varias veces** antes de programarlo en cron — es mucho más fácil depurar corriendo el script a mano que esperando a las 2 AM.
5. **Revisa el log generado** y confirma que tiene fecha/hora de inicio y fin, tamaño del archivo, y que un error simulado (por ejemplo, apuntando `ORIGEN` a una ruta que no existe) efectivamente queda registrado.
6. **Programa la tarea en cron** con `crontab -e` y la línea `0 2 * * * /ruta/backup.sh >> /ruta/log 2>&1`.
7. **Verifica que cron esté corriendo:** `sudo systemctl status cron` (Ubuntu/Debian) o revisa `/var/log/syslog | grep CRON`.
8. **Para no esperar hasta las 2 AM en la demo:** cambia temporalmente el horario a `* * * * *` (cada minuto), confirma que funciona, y luego vuelve a dejarlo en `0 2 * * *` para la entrega final.
9. **Crea la infografía** resumiendo: el caso, la estructura del script, el cron configurado y una captura del log con al menos una ejecución exitosa.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| El script funciona a mano pero no vía cron | Usa rutas relativas, `~`, o depende de variables de entorno que cron no tiene | Usa siempre rutas absolutas; si necesitas variables, defínelas explícitamente al inicio del script |
| `tar: Removing leading '/' from member names` | Empaquetaste con ruta absoluta en vez de `-C ruta .` | Usa `-C /ruta/origen .` para posicionarte antes de empaquetar |
| El log queda vacío tras la ejecución por cron | No agregaste redirección `>> log 2>&1` en la línea de crontab, o el script escribe a otro log distinto | Verifica que la ruta del log en el script y en crontab coincidan, y que ambas sean absolutas |
| `crontab: command not found` o el servicio no corre | `cron`/`cronie` no está instalado o el servicio está detenido | `sudo apt install -y cron && sudo systemctl enable --now cron` |
| El `.tar.gz` no incluye la fecha esperada | `date` se ejecutó una sola vez al declarar la variable y el script tardó en llegar al `tar` | Normal si el formato es a nivel de segundos — para este caso es aceptable; solo ten cuidado si generas el nombre en un paso y lo usas mucho después en scripts más largos |

## Checklist antes de entregar

- [ ] El respaldo queda en `.tar.gz`, con fecha/hora en el nombre, en el directorio destino correcto.
- [ ] El log muestra inicio, fin, tamaño del archivo y, si corresponde, mensajes de error.
- [ ] La tarea cron está configurada para las 2:00 AM y confirmaste que corre (probando con `* * * * *` temporalmente).
- [ ] Puedes explicar por qué este es un respaldo **completo** y no incremental/diferencial.
- [ ] Infografía lista y disponible según lo pedido por el docente.
- [ ] Máquina virtual detenida/eliminada al terminar.

## Recursos adicionales

- `man tar`, `man crontab`, `man 5 crontab` (formato del archivo).
- [crontab.guru](https://crontab.guru/) — para verificar visualmente expresiones cron.
