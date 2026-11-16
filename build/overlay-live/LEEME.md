# overlay-live

Archivos que solo lleva la **ISO live** (los copia `build/mkiso.sh` antes de crear el squashfs):
la app «Instalar BC OS» en el menú y el permiso polkit para que el usuario de la sesión live la ejecute sin contraseña.
El sistema instalado no los lleva (bc-install excluye `/usr/share/applications/bc-installer.desktop` y la regla).
