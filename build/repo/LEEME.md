# Repositorio propio de BC OS: `[bc]`

- **Qué es**: un repositorio pacman alojado en GitHub Releases (etiqueta `repo`):
  `https://github.com/borjacandeel/BC-OS/releases/download/repo`.
- **Paquetes**: `bc-shell` (escritorio y apps), `bc-core` (servicios), `bc-escritorio` (sesión, scripts `bc-*`,
  configuración de sway, `.desktop`, iconos de apps, fondos y sonidos) y `bc-os` (metapaquete: los tres + los paquetes
  base de la imagen, `build/packages/base.txt`; si se añade un paquete a la lista, llega a todos en la siguiente
  actualización).
- **Cómo se publica**: `.github/workflows/repo.yml` en cada push a `main` que toque `shell/`, `core/`, `build/overlay/`,
  `build/repo/`, `assets/` o `build/packages/` (o a mano). Versión = fecha y hora UTC (`AAAAMMDD.HHMM`).
- **En el sistema**: la imagen añade `[bc]` antes de `[core]` en `/etc/pacman.conf`. `bc-actualizar` (y la Tienda ▸
  Actualizaciones) hace `pacman -Syu` y, la primera vez, instala `bc-os` adoptando los archivos de BC que puso la imagen
  (`--overwrite` solo en rutas de BC).
- **Firma**: de momento `SigLevel = Optional TrustAll` (la descarga va por HTTPS de GitHub). Para firmar: el creador crea
  una clave GPG, añade el secreto `BC_REPO_GPG_KEY` al repositorio, se firma en el workflow (`repo-add -s`, `makepkg --sign`)
  y la imagen incluye la clave pública con `SigLevel = Required`.
- **Probar a mano**: `sudo build/repo/build-repo.sh <rootfs-alarm> <salida>`.
