# bc-install — instalador de BC OS (ARM64)

Instalador en Bash (whiptail/dialog) para escribir BC OS en un disco. Textos en `lang/es_ES.sh` (por defecto) y `lang/en.sh`; añadir un idioma = añadir `lang/<id>.sh` con las mismas variables `S_*` / `P_*`.

## Qué hace

1. Elige disco (`lsblk`), **excluyendo el medio live** y los discos con particiones montadas.
2. Pide confirmación escribiendo `BORRAR`.
3. Particiona GPT: ESP 512 MiB FAT32 (`BC-ESP`) + raíz ext4 (`bc-root`). Opcional: raíz en **LUKS2** (argon2id, 256 MiB).
4. Copia el sistema origen (`--source`, por defecto `/` del live) con `rsync -aHAXx`.
5. Configura: nombre de equipo, idioma `es_ES.UTF-8`, teclado (por defecto `es`), zona horaria (por defecto `Europe/Madrid`), usuario (grupos `wheel,audio,video,input`), `root` bloqueado, NetworkManager.
6. Elimina las cuentas por defecto de la imagen (`bc`, `alarm`) y el autologin de tty1.
7. Regenera el initramfs (con `sd-encrypt` si hay cifrado) y escribe `fstab` por UUID.
8. Instala systemd-boot en la ESP (`EFI/BOOT/BOOTAA64.EFI`, `EFI/systemd/`), `Image` e `initramfs-linux.img` en la ESP y la entrada `loader/entries/bcos.conf`.

La línea de arranque usa `root=UUID=…` (no `LABEL=`) para no confundirse con el medio live, que también se llama `bc-root`. Con cifrado: `rd.luks.name=<UUID-LUKS>=bc-root root=/dev/mapper/bc-root`.

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

- `prepare-live.sh`: añade el instalador y un servicio de prueba a una **copia** de la imagen live.
- `qemu-run.exp`: arranca QEMU aarch64 UEFI (modo `install` o `boot`, con clave LUKS por consola serie).

Limitación del contenedor de desarrollo: su kernel no tiene `vfat` ni device-mapper, así que la instalación real se prueba **dentro de QEMU** (kernel ARM64 de Arch Linux ARM), no con `losetup` en el host.

## No probado

El asistente interactivo (whiptail) solo se ha revisado con `bash -n`; la ruta automática es la verificada. Sin pruebas todavía en VirtualBox ni en hardware real.
