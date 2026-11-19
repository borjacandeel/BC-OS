#!/bin/bash
# Banco de pruebas de BC Rendering Engine (sin pantalla, backend software de Qt Quick, como una VM sin 3D).
# Uso: render-bench.sh <binario bc-shell> <salida.csv> [repeticiones]
# Mide por escenario: tiempo de arranque hasta la primera captura, CPU (usuario+sistema), memoria máxima y, en las
# ráfagas, el tiempo de render de cada fotograma (media, p95, p99, registro qt.scenegraph.time.renderloop) y los
# fotogramas que no caben en 16,7 ms (60 Hz).
set -u
BIN="$1"; OUT="$2"; N="${3:-3}"
CFG="$(mktemp -d)"; mkdir -p "$CFG/.config/BC-OS" "$CFG/.cache"
printf "[General]\naspecto=dark\nbienvenida=true\n" > "$CFG/.config/BC-OS/bc-shell.conf"
SCR="$(mktemp)"; echo '{"screens":[{"name":"s","x":0,"y":0,"width":1440,"height":900,"logicalDpi":96,"logicalBaseDpi":96,"dpr":1}]}' > "$SCR"
export HOME="$CFG" XDG_CONFIG_HOME="$CFG/.config" XDG_CACHE_HOME="$CFG/.cache" QT_QUICK_BACKEND=software
export QT_QPA_PLATFORM="offscreen:configfile=$SCR"
echo "escenario,rep,arranque_ms,cpu_ms,rss_mb,frames,media_ms,p95_ms,p99_ms,perdidos" > "$OUT"
run() { # escenario rep extra-env...
  local esc="$1" rep="$2"; shift 2
  local d; d="$(mktemp -d)"
  python3 - "$d" "$esc" "$rep" "$BIN" "$@" >> "$OUT" <<'P'
import sys, glob, os, re, subprocess, time, resource
d, esc, rep, binp = sys.argv[1:5]
env = dict(os.environ)
for kv in sys.argv[5:]:
    k, v = kv.split("=", 1); env[k] = v
t0 = time.monotonic()
env["QT_LOGGING_RULES"] = "qt.scenegraph.time.renderloop=true"
r = subprocess.run(["timeout", "120", binp, "--no-splash", "--screenshot", d + "/f.png"], env=env,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, errors="replace")
wall = int((time.monotonic() - t0) * 1000)
ru = resource.getrusage(resource.RUSAGE_CHILDREN)
# Tiempo de cada fotograma pintado (todas las superficies), del registro del render loop de Qt Quick
g = [int(x) for x in re.findall(r"Frame rendered with '\w+' renderloop in (\d+)ms", r.stderr)]
g = [x for x in g if x > 0]
fs = g

def pct(v, p):
    v = sorted(v); return v[min(len(v) - 1, int(round(p / 100 * (len(v) - 1))))] if v else 0
mean = sum(g) / len(g) if g else 0
print(f"{esc},{rep},{wall},{int((ru.ru_utime+ru.ru_stime)*1000)},{ru.ru_maxrss//1024},{len(fs)},{mean:.1f},{pct(g,95)},{pct(g,99)},{sum(1 for x in g if x > 16)}")
P
  rm -rf "$d"
}
for r in $(seq "$N"); do
  rm -rf "$CFG/.cache/bc"
  run arranque-frio "$r"
  run arranque-cache "$r"
  run genio "$r" BC_BURST=genio:40 BC_BURST_MS=16
  run dock "$r" BC_BURST=launcherOpen:40 BC_BURST_MS=16
  run spotlight "$r" BC_BURST=spotlightOpen:40 BC_BURST_MS=16
done
rm -rf "$CFG" "$SCR"
