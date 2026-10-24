# EA3 — Actividades de apoyo

**Asignatura:** AAY1110 · Sistemas Operativos Corporativos en Cloud
**Resultado de Aprendizaje:** RA3 — Implementa configuraciones avanzadas de seguridad en sistemas Linux utilizando técnicas de hardening para minimizar riesgos de seguridad de acuerdo con las buenas prácticas de la industria.

## Indicadores de logro cubiertos

| IL | Descripción |
|----|-------------|
| IL 3.1 | Implementa hardening en servidores Linux para aumentar el nivel de seguridad acorde las buenas prácticas de la industria. |
| IL 3.4 | Implementa mecanismos de auditoría y monitoreo para detectar y responder a incidentes de seguridad en Linux acorde las buenas prácticas de la industria. |

## Actividades

| Carpeta | Tema | IL principal | Herramientas |
|---|---|---|---|
| [Act_3.1.2](Act_3.1.2/) | Hardening de un servidor Linux (SSH, firewall básico, Fail2Ban) | IL 3.1 | SSH, UFW, Fail2Ban, AWS Academy Learner Lab |
| [Act_3.2.2](Act_3.2.2/) | Configuración y gestión de firewall en Linux (firewalld, UFW, iptables, nftables) | IL 3.4 | firewalld, UFW, iptables, nftables, AWS Academy Learner Lab |

## Recomendación de avance

Las actividades están ordenadas de forma incremental: Act_3.1.2 cubre hardening general del servidor (SSH, firewall básico con UFW y protección contra fuerza bruta con Fail2Ban), mientras que Act_3.2.2 profundiza exclusivamente en firewalls, comparando tres herramientas distintas (UFW, iptables, nftables). Conviene resolver 3.1.2 primero, ya que introduce UFW y conceptos de filtrado que 3.2.2 amplía.

Ambas usan **AWS Academy Learner Lab** para levantar la máquina virtual Linux (Red Hat / Amazon Linux). Recuerda siempre **detener/eliminar la instancia al terminar** para no seguir consumiendo créditos del laboratorio.
