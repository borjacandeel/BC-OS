#!/usr/bin/env bash
# Construye el tema de iconos MacOS-Like-Dark (Scrimas/MacOS-Like, GPL-3.0, sobre MacTahoe de vinceliuice)
# en el ANFITRIÓN y copia al rootfs solo las carpetas escalables (apps, lugares, tipos de archivo, dispositivos y símbolos).
# Requiere en el anfitrión: git, python3 con Pillow y rsvg-convert. Uso: build-icons-maclike.sh <rootfs>
set -euo pipefail
R="${1:?uso: $0 <rootfs>}"
COMMIT="838dfd392b24d2e5886b6618bee63f84328baa52"
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
git clone -q https://github.com/Scrimas/MacOS-Like "$W/src"
git -C "$W/src" checkout -q "$COMMIT"
( cd "$W/src" && XDG_DATA_HOME="$W/out" XDG_CONFIG_HOME="$W/cfg" ./setup.sh --inherits-dark Qogir,hicolor --inherits-light Qogir,hicolor >"$W/setup.log" 2>&1 ) || { tail -20 "$W/setup.log"; exit 1; }
SRC="$W/out/icons/MacOS-Like-Dark"; DST="$R/usr/share/icons/MacOS-Like-Dark"
rm -rf "$DST"; mkdir -p "$DST"
DIRS="apps/scalable apps/symbolic places/scalable places/symbolic mimes/scalable devices/scalable status/symbolic actions/symbolic categories/symbolic"
for d in $DIRS; do [ -d "$SRC/$d" ] && { mkdir -p "$DST/$d"; cp -a "$SRC/$d/." "$DST/$d/"; }; done
cp "$SRC/COPYING" "$SRC/AUTHORS" "$DST/" 2>/dev/null || true
{
  printf '[Icon Theme]\nName=MacOS-Like-Dark\nComment=MacOS-Like (Scrimas) sobre MacTahoe (vinceliuice), GPL-3.0 — subconjunto escalable de BC OS\nInherits=Qogir,hicolor\nExample=folder\n\nDirectories='
  first=1; for d in $DIRS; do [ -d "$DST/$d" ] || continue; [ $first = 1 ] || printf ','; printf '%s' "$d"; first=0; done; printf '\n'
  for d in $DIRS; do [ -d "$DST/$d" ] || continue
    printf '\n[%s]\nSize=%s\nMinSize=8\nMaxSize=512\nType=Scalable\n' "$d" "$( [ "${d#*/}" = symbolic ] && echo 16 || echo 48 )"; done
} > "$DST/index.theme"
echo "MacOS-Like-Dark instalado en $DST ($(du -sh "$DST" | cut -f1))"
