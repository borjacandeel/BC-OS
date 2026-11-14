#!/usr/bin/env python3
"""Cliente mínimo del monitor QEMU: ejecuta órdenes (p. ej. 'sendkey ret', 'screendump a.ppm')."""
import socket, sys, time

def mon(cmds, sock="mon.sock", wait=0.4):
    s = socket.socket(socket.AF_UNIX)
    s.connect(sock)
    time.sleep(0.3)
    for c in cmds:
        s.send((c + "\n").encode())
        time.sleep(wait)
    s.close()

def type_text(text, sock="mon.sock"):
    keys = {" ": "spc", ".": "dot", "-": "minus", "/": "slash", "_": "shift-minus", "\n": "ret"}
    mon(["sendkey " + keys.get(ch, ch) for ch in text], sock, 0.15)

if __name__ == "__main__":
    mon(sys.argv[1:])
