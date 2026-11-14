# Cadenas del instalador de BC OS — español (España). Por defecto.
S_TITLE="Instalador de BC OS"
S_WELCOME="Bienvenido al instalador de BC OS.\n\nLIGERO. POTENTE. FLUIDO.\n\nSe te preguntará el disco, el idioma del teclado, la zona horaria y tu usuario. El disco elegido se borrará por completo."
S_NEED_ROOT="Este instalador debe ejecutarse como administrador (root)."
S_NEED_TOOL="Falta la herramienta necesaria: %s"
S_NEED_TUI="Falta whiptail o dialog para el modo interactivo. Usa --auto o instala whiptail."
S_NEED_ARM="Este instalador solo puede instalar el sistema ARM64 desde un equipo ARM64 o con qemu-user (binfmt) registrado."
S_NO_DISKS="No se ha encontrado ningún disco donde instalar."
S_CHOOSE_DISK="Elige el disco de destino. SE BORRARÁ TODO su contenido:"
S_DISK_BAD="El destino no es un dispositivo de bloques válido: %s"
S_DISK_MOUNTED="El disco %s tiene particiones montadas; no se puede instalar en él."
S_DISK_LIVE="El disco %s es el medio desde el que se ejecuta el sistema; elige otro."
S_ERASE_PROMPT="Se BORRARÁ TODO el contenido de %s.\n\nEscribe BORRAR (en mayúsculas) para continuar:"
S_ERASE_WORD="BORRAR"
S_CANCELLED="Instalación cancelada. No se ha modificado ningún disco."
S_ENCRYPT_ASK="¿Quieres cifrar el disco (LUKS2)?\n\nTendrás que escribir la contraseña de cifrado en cada arranque."
S_PASS_LUKS="Contraseña de cifrado del disco:"
S_PASS_LUKS2="Repite la contraseña de cifrado:"
S_PASS_MISMATCH="Las contraseñas no coinciden."
S_PASS_EMPTY="La contraseña no puede estar vacía."
S_HOSTNAME="Nombre del equipo:"
S_HOSTNAME_BAD="Nombre de equipo no válido: %s (solo letras, números y guiones)."
S_USER="Nombre de usuario (minúsculas, sin espacios):"
S_USER_BAD="Nombre de usuario no válido: %s"
S_PASS="Contraseña de %s:"
S_PASS2="Repite la contraseña:"
S_KEYMAP="Distribución del teclado:"
S_TZ="Zona horaria:"
S_TZ_OTHER="Otra (escribirla)"
S_TZ_ASK="Escribe la zona horaria (por ejemplo Europe/Madrid):"
S_TZ_BAD="Zona horaria no válida: %s"
S_LOCALE_BAD="Idioma del sistema no admitido: %s (usa es_ES.UTF-8 o en_US.UTF-8)."
S_SUMMARY="Resumen de la instalación:\n\n  Disco:      %s\n  Cifrado:    %s\n  Equipo:     %s\n  Usuario:    %s\n  Teclado:    %s\n  Zona:       %s\n  Idioma:     %s\n\n¿Continuar? Se borrará el disco."
S_YES="sí"
S_NO="no"
S_NEEDS_ARGS="En modo --auto son obligatorios: --disk, --user y --password-file."
S_NO_SRC="El origen %s no contiene un sistema BC OS válido (falta %s)."
P_PART="Particionando el disco (GPT)..."
P_FORMAT="Creando sistemas de archivos..."
P_LUKS="Configurando el cifrado LUKS2..."
P_MOUNT="Montando particiones..."
P_COPY="Copiando el sistema (puede tardar unos minutos)..."
P_CONFIG="Configurando idioma, teclado, zona horaria y usuario..."
P_INITRD="Generando el initramfs..."
P_BOOT="Instalando el gestor de arranque (systemd-boot)..."
P_CLEAN="Finalizando y desmontando..."
S_DONE="BC OS se ha instalado correctamente en %s.\n\nRetira el medio de instalación y reinicia."
S_FAIL="La instalación ha fallado. Consulta el registro: %s"
S_CRYPT_PKG="Instalando cryptsetup en el sistema destino (se necesita red)..."
S_CRYPT_PKG_FAIL="No se pudo instalar cryptsetup en el destino. Añádelo a la imagen origen."
S_BOOT_TITLE="BC OS"
S_BOOT_TITLE_SAFE="BC OS (modo seguro, sin animación)"
S_NO_PLYMOUTH="Aviso: el sistema origen no tiene Plymouth; se instalará sin animación de arranque."
S_NO_PLY_THEME="Aviso: falta el tema Plymouth «%s»; se usará el tema por defecto."
S_NO_GREETD="Aviso: el sistema origen no tiene greetd; el inicio de sesión será en modo texto (tty1)."
S_NO_INITRD="No se ha generado el initramfs."
S_USAGE="Uso: bc-install [opciones]

Instalador de BC OS (ARM64). Sin opciones arranca el asistente interactivo.

  --auto                    Modo no interactivo (requiere --disk, --user, --password-file)
  --disk DISPOSITIVO        Disco de destino (se BORRA), p. ej. /dev/vda
  --user NOMBRE             Usuario a crear
  --password-file FICHERO   Fichero con la contraseña del usuario
  --encrypt                 Cifrar la raíz con LUKS2
  --luks-passphrase-file F  Fichero con la clave de cifrado (por defecto, la contraseña del usuario)
  --hostname NOMBRE         Nombre del equipo (bcos)
  --keymap TECLADO          Distribución de teclado (es)
  --timezone ZONA           Zona horaria (Europe/Madrid)
  --locale LOCALE           Idioma del sistema (es_ES.UTF-8)
  --source DIR              Sistema origen (por defecto /)
  --lang es_ES|en           Idioma del instalador
  --log FICHERO             Registro (/var/log/bc-install.log)
  --dry-run                 Muestra lo que haría sin tocar nada
  -h, --help                Esta ayuda"
