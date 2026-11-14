#!/usr/bin/env python3
"""Servidor greetd falso para pruebas: usuario bc / contraseña bcos."""
import json, os, socket, struct, sys

def recv(c):
    h = c.recv(4)
    if len(h) < 4:
        return None
    n = struct.unpack("=I", h)[0]
    b = b""
    while len(b) < n:
        b += c.recv(n - len(b))
    return json.loads(b)

def send(c, o):
    b = json.dumps(o).encode()
    c.sendall(struct.pack("=I", len(b)) + b)

path = sys.argv[1]
if os.path.exists(path):
    os.unlink(path)
s = socket.socket(socket.AF_UNIX)
s.bind(path)
s.listen(4)
open(path + ".ready", "w").close()
c, _ = s.accept()
user = None
while True:
    m = recv(c)
    if m is None:
        break
    t = m["type"]
    if t == "create_session":
        user = m["username"]
        send(c, {"type": "auth_message", "auth_message_type": "secret", "auth_message": "Password: "})
    elif t == "post_auth_message_response":
        if user == "bc" and m.get("response") == "bcos":
            send(c, {"type": "success"})
        else:
            send(c, {"type": "error", "error_type": "auth_error", "description": "Authentication failed"})
    elif t == "start_session":
        assert m["cmd"][0] == "bc-session", m
        send(c, {"type": "success"})
    elif t == "cancel_session":
        send(c, {"type": "success"})
