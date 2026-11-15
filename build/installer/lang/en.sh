# BC OS installer strings — English (secondary language).
S_TITLE="BC OS Installer"
S_WELCOME="Welcome to the BC OS installer.\n\nLIGHTWEIGHT. POWERFUL. FLUID.\n\nYou will be asked for the target disk, keyboard layout, time zone and your user. The selected disk will be erased completely."
S_NEED_ROOT="This installer must be run as root."
S_NEED_TOOL="Required tool is missing: %s"
S_NEED_TUI="whiptail or dialog is required for interactive mode. Use --auto or install whiptail."
S_NEED_ARM="This installer can only install the ARM64 system from an ARM64 machine or with qemu-user (binfmt) registered."
S_NO_DISKS="No disk found to install to."
S_CHOOSE_DISK="Choose the target disk. ALL its contents WILL BE ERASED:"
S_DISK_BAD="Target is not a valid block device: %s"
S_DISK_MOUNTED="Disk %s has mounted partitions; cannot install on it."
S_DISK_LIVE="Disk %s is the medium the system is running from; choose another."
S_ERASE_PROMPT="ALL contents of %s will be ERASED.\n\nType ERASE (uppercase) to continue:"
S_ERASE_WORD="ERASE"
S_CANCELLED="Installation cancelled. No disk was modified."
S_ENCRYPT_ASK="Encrypt the disk (LUKS2)?\n\nYou will need to type the passphrase on every boot."
S_PASS_LUKS="Disk encryption passphrase:"
S_PASS_LUKS2="Repeat the encryption passphrase:"
S_PASS_MISMATCH="Passwords do not match."
S_PASS_EMPTY="The password cannot be empty."
S_HOSTNAME="Computer name:"
S_HOSTNAME_BAD="Invalid host name: %s (letters, digits and hyphens only)."
S_USER="User name (lowercase, no spaces):"
S_USER_BAD="Invalid user name: %s"
S_PASS="Password for %s:"
S_PASS2="Repeat the password:"
S_KEYMAP="Keyboard layout:"
S_TZ="Time zone:"
S_TZ_OTHER="Other (type it)"
S_TZ_ASK="Type the time zone (for example Europe/Madrid):"
S_TZ_BAD="Invalid time zone: %s"
S_LOCALE_BAD="Unsupported system language: %s (use es_ES.UTF-8 or en_US.UTF-8)."
S_SUMMARY="Installation summary:\n\n  Disk:       %s\n  Encryption: %s\n  Hostname:   %s\n  User:       %s\n  Keyboard:   %s\n  Time zone:  %s\n  Language:   %s\n\nContinue? The disk will be erased."
S_YES="yes"
S_NO="no"
S_NEEDS_ARGS="--auto requires: --disk, --user and --password-file."
S_NO_SRC="Source %s does not contain a valid BC OS system (missing %s)."
P_PART="Partitioning the disk (GPT)..."
P_FORMAT="Creating file systems..."
P_LUKS="Setting up LUKS2 encryption..."
P_MOUNT="Mounting partitions..."
P_COPY="Copying the system (may take a few minutes)..."
P_CONFIG="Configuring language, keyboard, time zone and user..."
P_INITRD="Generating the initramfs..."
P_BOOT="Installing the boot loader (systemd-boot)..."
P_CLEAN="Finishing and unmounting..."
S_DONE="BC OS was installed successfully on %s.\n\nRemove the installation medium and reboot."
S_FAIL="Installation failed. See the log: %s"
S_CRYPT_PKG="Installing cryptsetup in the target system (network required)..."
S_CRYPT_PKG_FAIL="Could not install cryptsetup in the target. Add it to the source image."
S_BOOT_TITLE="BC OS"
S_BOOT_TITLE_SAFE="BC OS (safe mode, no animation)"
S_NO_PLYMOUTH="Warning: the source system has no Plymouth; installing without boot animation."
S_NO_PLY_THEME="Warning: Plymouth theme \"%s\" is missing; the default theme will be used."
S_NO_GREETD="Warning: the source system has no greetd; login will be text mode (tty1)."
S_NO_INITRD="The initramfs was not generated."
S_USAGE="Usage: bc-install [options]

BC OS installer (ARM64). Without options it starts the interactive wizard.

  --auto                    Non-interactive mode (requires --disk, --user, --password-file)
  --disk DEVICE             Target disk (ERASED), e.g. /dev/vda
  --user NAME               User to create
  --password-file FILE      File containing the user's password
  --encrypt                 Encrypt the root with LUKS2
  --luks-passphrase-file F  File with the encryption passphrase (default: the user's password)
  --hostname NAME           Host name (bcos)
  --keymap KEYMAP           Keyboard layout (es)
  --timezone ZONE           Time zone (Europe/Madrid)
  --locale LOCALE           System language (es_ES.UTF-8)
  --source DIR              Source system (default /)
  --lang es_ES|en           Installer language
  --log FILE                Log file (/var/log/bc-install.log)
  --dry-run                 Show what would be done without touching anything
  -h, --help                This help
  --bootloader systemd-boot|grub   gestor de arranque / boot manager
  --secure-boot                    arranque seguro con sbctl / Secure Boot with sbctl"
S_BOOTLOADER_ASK="Boot manager"
S_BL_SDBOOT="systemd-boot (recommended, fast)"
S_BL_GRUB="GRUB (works with more firmwares)"
S_SECUREBOOT_ASK="Enable Secure Boot?\n\nOwn keys are created with sbctl and the boot loader and kernel are signed. To enroll them, the firmware must be in Setup Mode."
