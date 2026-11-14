#!/usr/bin/env bash
# Uso: greeter_protocol.sh <bc-greeter> <fake_greetd.py> <usuario:clave> <código_esperado>
set -u
G="$1"; SRV="$2"; CRED="$3"; WANT="$4"
D="$(mktemp -d)"; SOCK="$D/greetd.sock"
python3 -I "$SRV" "$SOCK" & P=$!
for _ in $(seq 50); do [ -e "$SOCK.ready" ] && break; sleep 0.1; done
GREETD_SOCK="$SOCK" BC_GREETER_DIR="$D" QT_QPA_PLATFORM=offscreen QT_QUICK_BACKEND=software \
  "$G" --test-login "$CRED" --size 1280x800 >/dev/null 2>&1
RC=$?
kill $P 2>/dev/null; rm -rf "$D"
[ "$RC" = "$WANT" ] || { echo "esperado $WANT, obtenido $RC"; exit 1; }
