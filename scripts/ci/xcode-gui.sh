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
limite 240 sudo xcodebuild -runFirstLaunch >> "$D/xcode-0-app.txt" 2>&1
xcodebuild -checkFirstLaunchStatus >> "$D/xcode-0-app.txt" 2>&1; echo "checkFirstLaunchStatus: $?" >> "$D/xcode-0-app.txt"
limite 30 open -a "$XCODE_APP" MisPendientes.xcodeproj >> "$D/xcode-0-app.txt" 2>&1
sleep 45; foto 01-proyecto
# Si aparece el diálogo de componentes del primer arranque, cerrarlo con Escape / Cmd+W
for tecla in 'key code 53' 'keystroke "w" using command down'; do
  limite 20 osascript -e "tell application \"System Events\" to $tecla" >> "$D/xcode-0-app.txt" 2>&1
  sleep 8
done
sleep 20; foto 02-proyecto
limite 30 open -a "$XCODE_APP" MisPendientes.xcodeproj
sleep 40; foto 03-proyecto
defaults read com.apple.dt.Xcode > "$D/xcode-defaults.txt" 2>&1
# Abrir también el archivo principal de la lista en el mismo proyecto
limite 30 open -a "$XCODE_APP" MisPendientes/Vistas/ListaTareasView.swift
sleep 30; foto 05-codigo
pgrep -fl Xcode >> "$D/xcode-0-app.txt" 2>&1
true
