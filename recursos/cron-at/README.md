# Ejemplos — cron y at

Dos mecanismos de Linux para programar tareas, con un propósito distinto:

| | `cron` | `at` |
|---|---|---|
| Se repite | Sí, según un horario recurrente | No — se ejecuta **una sola vez** |
| Se define en | El crontab (`crontab -e`) | Un comando puntual (`at ...`) |
| Caso típico | Respaldo diario, monitoreo cada N minutos | "Reinicia el servicio a las 22:00 de hoy", "recuérdame algo mañana a las 9" |
| Usado en | [Act_2.2.2](../../EA2/Act_2.2.2/) (respaldo automatizado) | Tareas puntuales que no ameritan una regla permanente |

## cron

Ver [`ejemplos_crontab.txt`](ejemplos_crontab.txt) para casos de uso comentados. Comandos básicos:

```bash
crontab -e      # editar tu crontab (abre un editor)
crontab -l      # listar las tareas programadas actuales
crontab -r      # eliminar TODO tu crontab (con cuidado)
```

Estructura de una línea:

```
minuto  hora  dia-mes  mes  dia-semana   comando
 0-59   0-23   1-31    1-12   0-7*        ...
```

`*` significa "cualquier valor". `*/15` significa "cada 15 unidades". `1-5` significa "rango". `0-7` para día de semana: tanto `0` como `7` representan domingo.

> Regla de oro: usa siempre **rutas absolutas** dentro del comando y redirige salida y errores (`>> log 2>&1`), porque cron corre con un entorno mínimo y no muestra nada en pantalla si algo falla.

## at

Ver [`ejemplo_at.sh`](ejemplo_at.sh) para la sintaxis comentada. Comandos básicos:

```bash
echo "comando_a_ejecutar" | at now + 5 minutes   # relativo a ahora
echo "comando_a_ejecutar" | at 14:30              # hora específica
echo "comando_a_ejecutar" | at 22:00 2026-12-31   # fecha y hora específica

atq              # listar jobs pendientes (con su número de job)
at -c <numero>   # ver el contenido de un job pendiente
atrm <numero>    # cancelar un job pendiente
```

`at` depende del servicio `atd` — si no está instalado/activo, los jobs no se ejecutan aunque el comando `at` los haya aceptado sin error aparente.

## Errores comunes / troubleshooting

| Síntoma | Causa probable | Solución |
|---|---|---|
| La tarea de cron nunca corre | El servicio cron no está activo | `sudo systemctl status cron` / `sudo systemctl enable --now cron` |
| La tarea corre a mano pero no vía cron | Rutas relativas o variables de entorno que cron no tiene | Usa siempre rutas absolutas; define explícitamente lo que necesites al inicio del script |
| `at: command not found` | Paquete `at` no instalado | `sudo apt install -y at` |
| Un job de `at` "desaparece" sin ejecutarse | El servicio `atd` no está corriendo | `sudo systemctl enable --now atd` |
| No sé qué tareas de cron/at tengo pendientes | — | `crontab -l` para cron; `atq` para at |

## Recursos adicionales

- [crontab.guru](https://crontab.guru/) — para verificar visualmente expresiones cron.
- `man crontab`, `man 5 crontab`, `man at` directamente en la VM.
