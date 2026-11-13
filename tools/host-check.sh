#!/usr/bin/env bash
# BC OS — diagnóstico del host de desarrollo (pensado para macOS Apple Silicon).
# Solo lectura. No modifica nada. Pega la salida completa en una issue o en el chat.
set -u

linea() { printf '\n== %s ==\n' "$1"; }
cmd()   { command -v "$1" >/dev/null 2>&1; }

linea "Sistema"
uname -a
echo "Arquitectura: $(uname -m)"
if [[ "$(uname -s)" == "Darwin" ]]; then
  sw_vers 2>/dev/null
  echo "Chip: $(sysctl -n machdep.cpu.brand_string 2>/dev/null)"
  echo "Núcleos CPU: $(sysctl -n hw.ncpu 2>/dev/null)"
  mem=$(sysctl -n hw.memsize 2>/dev/null); [[ -n "${mem:-}" ]] && echo "RAM: $((mem/1024/1024/1024)) GiB"
  echo "Rosetta/translated: $(sysctl -n sysctl.proc_translated 2>/dev/null || echo n/d)"
  echo "Soporte Hypervisor.framework: $(sysctl -n kern.hv_support 2>/dev/null || echo n/d)"
else
  echo "Aviso: no es macOS; el resultado es orientativo."
  cmd nproc && echo "Núcleos CPU: $(nproc)"
  cmd free && free -h | sed -n '2p'
fi

linea "Disco libre (directorio actual)"
df -h . | tail -n 2

linea "VirtualBox"
if cmd VBoxManage; then
  echo "VBoxManage: $(VBoxManage --version)"
  VBoxManage list systemproperties 2>/dev/null | grep -Ei 'version|default machine|supported|firmware' | head -n 20
  echo "--- Tipos de SO invitado ARM64 ---"
  VBoxManage list ostypes 2>/dev/null | grep -Ei 'arm|aarch64' | head -n 20 || true
  echo "--- VMs existentes ---"
  VBoxManage list vms 2>/dev/null
else
  echo "VBoxManage no encontrado (¿VirtualBox instalado? ¿en el PATH?)."
  [[ -d /Applications/VirtualBox.app ]] && echo "Existe /Applications/VirtualBox.app" && \
    defaults read /Applications/VirtualBox.app/Contents/Info CFBundleShortVersionString 2>/dev/null
fi

linea "Alternativas de virtualización"
for c in qemu-system-aarch64 qemu-img utmctl; do
  if cmd "$c"; then echo "$c: $(command -v $c)"; else echo "$c: no instalado"; fi
done
cmd qemu-system-aarch64 && qemu-system-aarch64 --version | head -n 1 && \
  (qemu-system-aarch64 -accel help 2>/dev/null | tr '\n' ' '; echo)
[[ -d /Applications/UTM.app ]] && echo "UTM instalado"

linea "Compiladores y herramientas"
for c in clang gcc git make cmake ninja python3 cargo rustc rustup node qmake6 docker brew xcode-select; do
  if cmd "$c"; then
    v=$("$c" --version 2>&1 | head -n 1)
    printf '%-14s %s\n' "$c" "${v:-ok}"
  else
    printf '%-14s no instalado\n' "$c"
  fi
done
cmd xcode-select && echo "Xcode CLT: $(xcode-select -p 2>/dev/null || echo no)"
cmd rustup && rustup target list --installed 2>/dev/null

linea "Gráficos"
if [[ "$(uname -s)" == "Darwin" ]]; then
  system_profiler SPDisplaysDataType 2>/dev/null | grep -Ei 'chipset|metal|cores|resolution|refresh' | head -n 10
fi

linea "Fin"
echo "Pega esta salida completa. No contiene contraseñas ni claves."
