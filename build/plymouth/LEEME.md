# Arranque animado BC OS (Plymouth, tema `bcos`)

- Tema script 2D (sin 3D): fondo negro con orbes de color (azul, violeta, cian) que flotan, logo que crece con destello y respira, barra blanca fina con el progreso real. Sin pantalla/DRM, plymouth degrada a texto.
- Regenerar PNG: `build/plymouth/build-theme.sh` (requiere `rsvg-convert` y PIL).
- Imagen: paquete `plymouth` (ALARM extra); `configure-rootfs.sh` instala el tema y lo fija por defecto antes de `mkinitcpio -P`; hook `plymouth` justo tras `systemd` en `mkinitcpio.conf.d/bcos.conf`; `splash` en la entrada de systemd-boot (sin `quiet`) y `plymouth.ignore-serial-consoles` (sin él, con `console=ttyAMA0` al final plymouth cae a texto: verificado).
- SALIDA DE EMERGENCIA: en systemd-boot pulsar `e` sobre la entrada y añadir `plymouth.enable=0` (desactiva el splash; log normal). También sirve quitar `splash`.
- Instalador (`build/installer/bc-install`): genera su propio initramfs; debe usar `HOOKS=(base systemd plymouth modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)` (plymouth antes de sd-encrypt para ver el prompt de LUKS) y `splash` en options. Pendiente de aplicar ahí.
