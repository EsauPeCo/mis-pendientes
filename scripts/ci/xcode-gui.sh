#!/usr/bin/env bash
# Abre el proyecto en Xcode (interfaz gráfica del runner) y toma capturas de pantalla.
# Sin AppleScript: en el runner, enviar eventos a Xcode abre un permiso de automatización que
# nadie puede aceptar y el script se queda esperando. Solo se usan `open` y `screencapture`,
# y cada paso tiene un límite de tiempo.
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
X="${X:-$RAIZ/evidencia/xcode}"; D="${D:-$RAIZ/evidencia/diagnostico}"
mkdir -p "$X" "$D"
cd "$RAIZ"

# Ejecuta un comando con límite de segundos (macOS no trae `timeout`)
limite() { local s="$1"; shift; "$@" & local pid=$!; ( sleep "$s"; kill -9 "$pid" 2>/dev/null ) & local vigia=$!
           wait "$pid" 2>/dev/null; kill "$vigia" 2>/dev/null; }
foto() { limite 20 screencapture -x "$X/$1.png" && echo "captura Xcode $1"; }

XCODE_APP="$(xcode-select -p | sed 's|/Contents/Developer$||')"
echo "Xcode: $XCODE_APP" > "$D/xcode-0-app.txt"
limite 30 open -a "$XCODE_APP" MisPendientes.xcodeproj >> "$D/xcode-0-app.txt" 2>&1
for n in 1 2 3 4; do sleep 30; foto "0$n-proyecto"; done
# Abrir también el archivo principal de la lista en el mismo proyecto
limite 30 open -a "$XCODE_APP" MisPendientes/Vistas/ListaTareasView.swift
sleep 30; foto 05-codigo
pgrep -fl Xcode >> "$D/xcode-0-app.txt" 2>&1
true
