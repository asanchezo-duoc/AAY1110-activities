# EA3 — Actividades de apoyo

**Asignatura:** AAY1110 · Sistemas Operativos Corporativos en Cloud
**Resultado de Aprendizaje:** RA3 — Implementa configuraciones avanzadas de seguridad en sistemas Linux utilizando técnicas de hardening para minimizar riesgos de seguridad de acuerdo con las buenas prácticas de la industria.

## Indicadores de logro cubiertos

| IL | Descripción |
|----|-------------|
| IL 3.1 | Implementa hardening en servidores Linux para aumentar el nivel de seguridad acorde las buenas prácticas de la industria. |
| IL 3.4 | Implementa mecanismos de auditoría y monitoreo para detectar y responder a incidentes de seguridad en Linux acorde las buenas prácticas de la industria. |
| IL 3.5 | Gestiona los archivos de LOG para detectar problemas en el sistema y sus servicios mediante scripts. |

## Actividades

| Carpeta | Tema | IL principal | Herramientas |
|---|---|---|---|
| [Act_3.1.2](Act_3.1.2/) | Hardening de un servidor Linux (SSH, firewall básico, Fail2Ban) | IL 3.1 | SSH, UFW, Fail2Ban, AWS Academy Learner Lab |
| [Act_3.2.2](Act_3.2.2/) | Configuración y gestión de firewall en Linux (firewalld, UFW, iptables, nftables) | IL 3.4 | firewalld, UFW, iptables, nftables, AWS Academy Learner Lab |
| [Act_3.3.2](Act_3.3.2/) | Auditoría y monitoreo en Linux (auditd, htop, vnstat, iftop) | IL 3.4 | auditd, htop, vnstat, iftop, AWS Academy Learner Lab |
| [Act_3.3.3](Act_3.3.3/) | Gestión de logs en Linux (journalctl, grep, logrotate, scripts de reporte) | IL 3.5 | journalctl, rsyslog, logrotate, Bash, AWS Academy Learner Lab |
| [Lab_Resumen_EA3](Lab_Resumen_EA3/) | **Laboratorio resumen:** hardening SSH + firewall (firewalld y nftables) + Fail2Ban, de cero a servidor asegurado | IL 3.1, IL 3.4 | SSH, firewalld, nftables, Fail2Ban, AWS Academy Learner Lab |

## Recomendación de avance

Las actividades están ordenadas de forma incremental: Act_3.1.2 cubre hardening general del servidor (SSH, firewall básico y Fail2Ban), Act_3.2.2 profundiza en firewalls comparando cuatro herramientas (firewalld, UFW, iptables, nftables), Act_3.3.2 agrega auditoría con `auditd` y herramientas de monitoreo, y Act_3.3.3 enseña a consultar, filtrar y rotar los logs generados. Conviene resolverlas en orden, ya que cada una construye sobre lo anterior.

El **Lab Resumen** integra Act_3.1.2 y Act_3.2.2 en un único laboratorio extenso de 4 horas pedagógicas (~3 horas), pensado para una sesión completa de práctica.

Todas usan **AWS Academy Learner Lab** para levantar la máquina virtual Linux (Red Hat). Recuerda siempre **detener/eliminar la instancia al terminar** para no seguir consumiendo créditos del laboratorio.
