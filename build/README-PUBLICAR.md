# Publicar un prerelease sin herramientas MCP

Escribe la versión (p. ej. `0.2.0-alpha`) en `build/PUBLICAR` y haz commit a `main`:
el workflow `image.yml` construye la imagen ARM64 y publica el **prerelease** `v<versión>`.
Cada versión nueva debe ser distinta de las ya publicadas. Nunca para versiones estables.
