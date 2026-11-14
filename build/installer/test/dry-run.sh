#!/usr/bin/env bash
# Prueba en seco de bc-install (no toca ningún disco): comprueba que el instalador genera las dos
# entradas de arranque, loader.conf y los hooks del initramfs coherentes con la imagen oficial (build/overlay).
# Uso: test/dry-run.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OV="$HERE/../overlay"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
fallos=0
ok()  { printf 'OK    %s\n' "$1"; }
mal() { printf 'FALLO %s\n' "$1"; fallos=$((fallos + 1)); }
tiene()    { if grep -qF -- "$2" "$1"; then ok "$3"; else mal "$3 (falta: $2)"; fi; }
no_tiene() { if grep -qF -- "$2" "$1"; then mal "$3 (sobra: $2)"; else ok "$3"; fi; }

# Origen ficticio mínimo (solo lo que valida el instalador)
S="$T/src"; mkdir -p "$S/boot" "$S/usr/lib/systemd/boot/efi" "$S/usr/share/zoneinfo/Europe"
: >"$S/boot/Image"; : >"$S/usr/lib/systemd/boot/efi/systemd-bootaa64.efi"; : >"$S/usr/share/zoneinfo/Europe/Madrid"
printf 'clave-usuario-secreta\n' >"$T/pw"; printf 'clave-luks-secreta\n' >"$T/luks"

instalar() { # instalar <salida> [opciones…]
  local out="$1"; shift
  bash "$HERE/bc-install" --auto --dry-run --disk /dev/bc-prueba-inexistente --user borja \
    --password-file "$T/pw" --source "$S" --log "$T/log" "$@" >"$out" 2>&1
}
# Contenido que el instalador escribiría en <ruta> (líneas «    | » tras «+ escribir <ruta>»)
fichero() { awk -v r="$2" '$1=="+" && $2=="escribir" {on = ($3 ~ r"$")} on && /^    \| / {sub(/^    \| /, ""); print}' "$1"; }
# Línea options de la imagen con la raíz y el idioma neutralizados
norm() { sed -n 's/^options //p' | sed -E 's/(^| )rd\.luks\.name=[^ ]+//; s/root=[^ ]+/root=X/; s/^ +//'; }

HOOKS_IMG="$(sed -n 's/^HOOKS=(\(.*\))$/\1/p' "$OV/etc/mkinitcpio.conf.d/bcos.conf")"

for caso in plano cifrado; do
  echo "== $caso"
  O="$T/$caso.out"
  if [[ $caso == cifrado ]]; then instalar "$O" --encrypt --luks-passphrase-file "$T/luks"; else instalar "$O"; fi

  for e in bcos bcos-seguro; do
    fichero "$O" "/boot/loader/entries/$e.conf" >"$T/$e.conf"
    [[ -s "$T/$e.conf" ]] && ok "se escribe $e.conf" || mal "se escribe $e.conf"
    if [[ "$(norm <"$T/$e.conf")" == "$(norm <"$OV/boot/loader/entries/$e.conf")" ]]; then ok "$e.conf: parámetros iguales a la imagen"
    else mal "$e.conf: parámetros distintos de la imagen: $(norm <"$T/$e.conf")"; fi
    if diff <(grep -v '^options' "$T/$e.conf") <(grep -v '^options' "$OV/boot/loader/entries/$e.conf") >/dev/null; then ok "$e.conf: título/kernel/initrd iguales a la imagen"
    else mal "$e.conf: título/kernel/initrd distintos de la imagen"; fi
    if [[ $caso == cifrado ]]; then
      tiene "$T/$e.conf" "rd.luks.name=<UUID-LUKS>=bc-root root=/dev/mapper/bc-root " "$e.conf: parámetros LUKS"
    else
      tiene "$T/$e.conf" "options root=UUID=<UUID-RAIZ> " "$e.conf: raíz por UUID"
      no_tiene "$T/$e.conf" "rd.luks" "$e.conf: sin parámetros LUKS"
    fi
    tiene "$T/$e.conf" "fsck.mode=skip" "$e.conf: fsck.mode=skip"
  done
  tiene "$T/bcos.conf" "splash" "bcos.conf: splash"
  no_tiene "$T/bcos.conf" "plymouth.enable=0" "bcos.conf: Plymouth activo"
  tiene "$T/bcos-seguro.conf" "plymouth.enable=0" "bcos-seguro.conf: plymouth.enable=0"
  no_tiene "$T/bcos-seguro.conf" "splash" "bcos-seguro.conf: sin splash"

  fichero "$O" "/boot/loader/loader.conf" >"$T/loader.conf"
  for k in default timeout console-mode; do
    if [[ "$(grep "^$k " "$T/loader.conf")" == "$(grep "^$k " "$OV/boot/loader/loader.conf")" ]]; then ok "loader.conf: $k igual a la imagen"
    else mal "loader.conf: $k distinto de la imagen"; fi
  done

  fichero "$O" "/etc/mkinitcpio.conf.d/bcos.conf" >"$T/mk.conf"
  hooks="$(sed -n 's/^HOOKS=(\(.*\))$/\1/p' "$T/mk.conf")"
  if [[ "$(grep '^MODULES=' "$T/mk.conf")" == "$(grep '^MODULES=' "$OV/etc/mkinitcpio.conf.d/bcos.conf")" ]]; then ok "MODULES iguales a la imagen"; else mal "MODULES distintos de la imagen"; fi
  if [[ $caso == cifrado ]]; then
    [[ "${hooks/ sd-encrypt/}" == "$HOOKS_IMG" ]] && ok "HOOKS = imagen + sd-encrypt" || mal "HOOKS inesperados: $hooks"
    [[ "$hooks" =~ systemd\ plymouth\ .*\ block\ sd-encrypt\ filesystems ]] && ok "orden: systemd → plymouth → block → sd-encrypt → filesystems" || mal "orden de hooks: $hooks"
  else
    [[ "$hooks" == "$HOOKS_IMG" ]] && ok "HOOKS iguales a la imagen" || mal "HOOKS distintos de la imagen: $hooks"
  fi

  tema="$(grep -n 'plymouth-set-default-theme bcos' "$O" | head -n1 | cut -d: -f1)"
  mk="$(grep -n '(chroot) mkinitcpio -P' "$O" | head -n1 | cut -d: -f1)"
  [[ -n "$tema" && -n "$mk" && "$tema" -lt "$mk" ]] && ok "tema Plymouth bcos antes de mkinitcpio -P" || mal "tema Plymouth bcos antes de mkinitcpio -P"

  tiene "$O" "(chroot) useradd -m -G wheel,audio,video,input -s /usr/bin/fish borja" "usuario con grupos de la imagen"
  tiene "$O" "(chroot) systemctl enable greetd.service bc-login-fallback.path" "greetd activado"
  tiene "$O" "(chroot) systemctl set-default graphical.target" "destino gráfico"
  fichero "$O" "/etc/bc/sway/keyboard.conf" >"$T/kb.conf"
  tiene "$T/kb.conf" "xkb_layout es" "teclado de sway"
  no_tiene "$O" "secreta" "sin contraseñas en la salida"
  if [[ -e "$T/log" ]]; then no_tiene "$T/log" "secreta" "sin contraseñas en el registro"; fi
done

echo "== general"
if grep -qi labwc "$HERE/bc-install" "$HERE"/lang/*.sh; then mal "sin referencias a labwc"; else ok "sin referencias a labwc"; fi
if diff <(grep -o '^[A-Z_0-9]*=' "$HERE/lang/es_ES.sh" | sort) <(grep -o '^[A-Z_0-9]*=' "$HERE/lang/en.sh" | sort) >/dev/null; then ok "lang/es_ES.sh y lang/en.sh con las mismas claves"; else mal "lang/es_ES.sh y lang/en.sh con las mismas claves"; fi
usadas="$(grep -o '\$[SP]_[A-Z0-9_]*' "$HERE/bc-install" | tr -d '$' | sort -u)"
for v in $usadas; do grep -q "^$v=" "$HERE/lang/es_ES.sh" || mal "cadena $v sin definir en lang/es_ES.sh"; done
instalar "$T/en.out" --lang en --locale en_US.UTF-8
tiene "$T/en.out" "title   BC OS (safe mode, no animation)" "título del modo seguro en inglés con --lang en"
tiene "$T/en.out" "lang=en_US" "lang= según el idioma elegido"

echo
if ((fallos)); then echo "RESULTADO: $fallos fallo(s)"; [[ -n "${BC_TEST_VERBOSE:-}" ]] && cat "$T"/*.out; exit 1; fi
echo "RESULTADO: todo correcto"
