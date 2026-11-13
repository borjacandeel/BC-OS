#!/usr/bin/env bash
# Prepara una COPIA de la imagen live (raíz montada en <dir>) para la prueba automática del instalador en QEMU.
# Uso: prepare-live.sh <raíz-live> <plain|encrypt>
set -euo pipefail
L="${1:?raíz live}"; MODE="${2:?plain|encrypt}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

rm -rf "$L/usr/lib/bc-install"; mkdir -p "$L/usr/lib/bc-install"
cp -a "$HERE/bc-install" "$HERE/lang" "$L/usr/lib/bc-install/"
ln -sf /usr/lib/bc-install/bc-install "$L/usr/bin/bc-install"

printf 'bcos-prueba\n' >"$L/root/pw.txt"; printf 'clave-luks-prueba\n' >"$L/root/luks.txt"; chmod 600 "$L"/root/*.txt
printf '%s\n' "$MODE" >"$L/etc/bc-test-mode"

cat >"$L/usr/local/bin/bc-test-run" <<'E'
#!/bin/bash
mode="$(cat /etc/bc-test-mode)"
args=(--auto --disk /dev/vdb --user borja --password-file /root/pw.txt --hostname bcosprueba)
[[ "$mode" == encrypt ]] && args+=(--encrypt --luks-passphrase-file /root/luks.txt)
echo "BCTEST-START $mode"
bc-install "${args[@]}"; rc=$?
echo "BCTEST-END rc=$rc"
[[ $rc -ne 0 ]] && tail -n 40 /var/log/bc-install.log
systemctl poweroff
E
chmod +x "$L/usr/local/bin/bc-test-run"

cat >"$L/etc/systemd/system/bc-install-test.service" <<'E'
[Unit]
Description=Prueba automatica del instalador de BC OS
After=multi-user.target
ConditionPathExists=/dev/vdb
[Service]
Type=oneshot
ExecStart=/usr/local/bin/bc-test-run
StandardOutput=journal+console
StandardError=journal+console
[Install]
WantedBy=multi-user.target
E
mkdir -p "$L/etc/systemd/system/multi-user.target.wants"
ln -sf /etc/systemd/system/bc-install-test.service "$L/etc/systemd/system/multi-user.target.wants/bc-install-test.service"
echo "Live preparado ($MODE)"
