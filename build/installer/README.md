# bc-install — instalador de BC OS (ARM64)

Instalador en Bash (whiptail/dialog) para escribir BC OS en un disco. Textos en `lang/es_ES.sh` (por defecto) y `lang/en.sh`; añadir un idioma = añadir `lang/<id>.sh` con las mismas variables `S_*` / `P_*`.

## Qué hace

1. Elige disco (`lsblk`), **excluyendo el medio live** y los discos con particiones montadas.
2. Pide confirmación escribiendo `BORRAR`.
3. Particiona GPT: ESP 512 MiB FAT32 (`BC-ESP`) + raíz ext4 (`bc-root`). Opcional: raíz en **LUKS2** (argon2id, 256 MiB).
4. Copia el sistema origen (`--source`, por defecto `/` del live) con `rsync -aHAXx`.
5. Configura: nombre de equipo, idioma `es_ES.UTF-8`, teclado (por defecto `es`; consola en `vconsole.conf` y sway en `/etc/bc/sway/keyboard.conf`), zona horaria (por defecto `Europe/Madrid`), usuario (grupos `wheel,audio,video,input`), `root` bloqueado, NetworkManager y la sesión gráfica de la imagen: `greetd` (bc-greeter) → `bc-session` (sway), `graphical.target` y el respaldo `bc-login-fallback.path`.
6. Elimina las cuentas por defecto de la imagen (`bc`, `alarm`) y el autologin de tty1.
7. Regenera el initramfs con los mismos hooks que la imagen (`base systemd plymouth modconf kms keyboard sd-vconsole block [sd-encrypt] filesystems fsck`; `plymouth` siempre antes de `sd-encrypt`), tras fijar el tema Plymouth `bcos` como predeterminado, y escribe `fstab` por UUID.
8. Instala systemd-boot en la ESP (`EFI/BOOT/BOOTAA64.EFI`, `EFI/systemd/`), `Image` e `initramfs-linux.img` en la ESP y las dos entradas de la imagen: `loader/entries/bcos.conf` (por defecto, `splash`) y `loader/entries/bcos-seguro.conf` (modo seguro, `plymouth.enable=0`), ambas con `fsck.mode=skip`. `loader.conf`: `default bcos.conf`, `timeout 5`, `editor no` (la imagen de pruebas usa `editor yes`).

La línea de arranque usa `root=UUID=…` (no `LABEL=`) para no confundirse con el medio live, que también se llama `bc-root`. Con cifrado, en las dos entradas: `rd.luks.name=<UUID-LUKS>=bc-root root=/dev/mapper/bc-root`. Con la entrada normal la clave LUKS se pide en la pantalla de Plymouth (no en la consola serie, por `plymouth.ignore-serial-consoles`); por consola serie hay que arrancar el modo seguro.

## Uso

```bash
sudo bc-install                       # asistente interactivo
sudo bc-install --auto --disk /dev/vda --user borja --password-file /ruta/pw \
     [--encrypt [--luks-passphrase-file /ruta/luks]] [--hostname bcos] [--keymap es] \
     [--timezone Europe/Madrid] [--locale es_ES.UTF-8] [--source /] [--lang en]
sudo bc-install --auto --dry-run ...  # muestra los pasos sin tocar nada
```

Las contraseñas se leen de fichero o del asistente; nunca van en argumentos ni en el registro (`/var/log/bc-install.log`, modo 600).

## Dependencias en el medio live

`sfdisk wipefs mkfs.vfat (dosfstools) mkfs.ext4 rsync lsblk blkid findmnt cryptsetup whiptail (libnewt)` + el origen con `systemd-bootaa64.efi`, `boot/Image` y `mkinitcpio`. `cryptsetup` también debe estar en el **sistema origen** (hook `sd-encrypt`); si falta, el instalador intenta `pacman -S cryptsetup` en el destino (requiere red).

## Pruebas (`test/`)

- `dry-run.sh`: prueba en seco (sin discos ni root), con y sin cifrado; compara entradas de arranque, `loader.conf` y hooks con `build/overlay`.
- `prepare-live.sh`: añade el instalador y un servicio de prueba a una **copia** de la imagen live.
- `qemu-run.exp`: arranca QEMU aarch64 UEFI (modo `install` o `boot`, con clave LUKS por consola serie).

Limitación del contenedor de desarrollo: su kernel no tiene `vfat` ni device-mapper, así que la instalación real se prueba **dentro de QEMU** (kernel ARM64 de Arch Linux ARM), no con `losetup` en el host.

## No probado

El asistente interactivo (whiptail) solo se ha revisado con `bash -n`; la ruta automática es la verificada. Sin pruebas todavía en VirtualBox ni en hardware real. Las dos entradas de arranque, el hook `plymouth` y la clave LUKS sobre Plymouth solo están comprobados en seco (`test/dry-run.sh`), no en QEMU; `qemu-run.exp boot` con cifrado espera la clave por consola serie, lo que ahora exige elegir el modo seguro en el menú.
