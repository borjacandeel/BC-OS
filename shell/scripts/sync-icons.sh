#!/usr/bin/env bash
# Copia el pack de iconos generado (icons/dist/svg) a los recursos del shell.
set -euo pipefail
cd "$(dirname "$0")/.."
rm -f assets/icons/*.svg
cp ../icons/dist/svg/*.svg assets/icons/
echo "Iconos sincronizados: $(ls assets/icons | wc -l)"
