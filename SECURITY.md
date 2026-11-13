# Política de seguridad

## Versiones soportadas

BC OS está en fase de fundación (pre‑0.1.0). No hay versiones estables soportadas todavía.

## Informar de una vulnerabilidad

No abras un issue público. Usa el aviso privado de seguridad de GitHub del repositorio («Security» → «Report a vulnerability»). Incluye versión, pasos de reproducción e impacto. Respuesta objetivo: acuse en 7 días.

## Modelo de seguridad previsto

| Área | Medida |
|---|---|
| Cuentas | `root` bloqueado; administración con `sudo` (grupo `wheel`); contraseña inicial caducada en el primer acceso |
| Red | cortafuegos nftables, entrada denegada por defecto (se permite tráfico establecido, loopback, ICMP, DHCP) |
| Paquetes | verificación de firmas de pacman activa; no se desactivan firmas |
| Actualizaciones | exclusivamente vía repositorios firmados; sin protocolos criptográficos propios |
| Servicios | mínimo privilegio; servicios BC Core sin root salvo operaciones puntuales vía polkit |
| Disco | cifrado completo opcional (LUKS2) en el instalador [planificado] |
| Secretos | nunca en el repositorio; credenciales en llaveros del sistema [planificado] |

## Limitaciones conocidas

- La contraseña inicial del usuario de la imagen de desarrollo es temporal y de conocimiento público; **caduca en el primer inicio de sesión** y debe cambiarse. No usar la imagen de desarrollo en producción.
- Las medidas marcadas «planificado» aún no están implementadas.
