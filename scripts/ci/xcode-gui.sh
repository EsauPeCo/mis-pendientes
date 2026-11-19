#!/usr/bin/env bash
# Abre el proyecto en Xcode (interfaz gráfica del runner) y toma capturas de pantalla:
#   1. proyecto abierto  2. compilación para el simulador  3. compilación para "Any iOS Device"
#   4. pestaña Signing & Capabilities (si la accesibilidad lo permite)
set -uo pipefail
RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
X="${X:-$RAIZ/evidencia/xcode}"; D="${D:-$RAIZ/evidencia/diagnostico}"
mkdir -p "$X" "$D"
cd "$RAIZ"

foto() { sleep "${2:-2}"; screencapture -x "$X/$1.png" && echo "captura Xcode $1"; }

system_profiler SPDisplaysDataType > "$D/pantalla.txt" 2>&1
open -a Xcode MisPendientes.xcodeproj
sleep 40

osascript > "$D/xcode-1-abrir.txt" 2>&1 <<'OSA'
tell application "Finder" to set pantalla to bounds of window of desktop
tell application "Xcode"
  activate
  repeat 90 times
    try
      if loaded of active workspace document then exit repeat
    end try
    delay 1
  end repeat
  set bounds of front window to {0, 25, item 3 of pantalla, item 4 of pantalla}
  set ws to active workspace document
  set salida to "pantalla: " & (item 3 of pantalla) & "x" & (item 4 of pantalla) & linefeed
  repeat with d in run destinations of ws
    set salida to salida & (name of d) & " | " & (platform of d) & linefeed
  end repeat
  return salida
end tell
OSA
foto 01-proyecto 3

# Mostrar el editor del proyecto (General) seleccionando la raíz en el navegador
osascript > "$D/xcode-2-navegador.txt" 2>&1 <<'OSA'
tell application "System Events" to tell process "Xcode"
  set frontmost to true
  keystroke "1" using command down
  delay 1
  set salida to ""
  try
    set filas to rows of outline 1 of scroll area 1 of group 1 of splitter group 1 of group 1 of window 1
    set salida to "filas: " & (count of filas)
    select item 1 of filas
  on error e
    set salida to salida & "sin outline: " & e
  end try
  return salida
end tell
OSA
foto 02-editor-proyecto 3

# Compilar para el simulador
osascript > "$D/xcode-3-simulador.txt" 2>&1 <<'OSA'
tell application "Xcode"
  set ws to active workspace document
  try
    set active run destination of ws to (first run destination of ws whose name contains "Pro Max")
  end try
  set r to build ws
  repeat 600 times
    if completed of r then exit repeat
    delay 1
  end repeat
  return "estado: " & (status of r) & " errores: " & (count of build errors of r)
end tell
OSA
foto 03-compilacion-simulador 3

# Compilar para un dispositivo real: aquí aparece el error de firma (sin equipo de desarrollo)
osascript > "$D/xcode-4-dispositivo.txt" 2>&1 <<'OSA'
tell application "Xcode"
  set ws to active workspace document
  try
    set active run destination of ws to (first run destination of ws whose name contains "Any iOS Device")
  end try
  set r to build ws
  repeat 600 times
    if completed of r then exit repeat
    delay 1
  end repeat
  set salida to "estado: " & (status of r) & linefeed
  repeat with e in build errors of r
    set salida to salida & (message of e) & linefeed
  end repeat
  return salida
end tell
OSA
osascript -e 'tell application "System Events" to tell process "Xcode" to keystroke "5" using command down' >/dev/null 2>&1
foto 04-error-firma 3

# Intentar abrir la pestaña Signing & Capabilities mediante accesibilidad
osascript > "$D/xcode-5-firma.txt" 2>&1 <<'OSA'
with timeout of 240 seconds
  tell application "System Events" to tell process "Xcode"
    set frontmost to true
    keystroke "1" using command down
    delay 1
    set todo to entire contents of window 1
    set salida to "elementos: " & (count of todo) & linefeed
    set hecho to false
    repeat with el in todo
      try
        set n to ""
        try
          set n to name of el
        end try
        if n is missing value then set n to ""
        set t to ""
        try
          set t to title of el
        end try
        if t is missing value then set t to ""
        if (n contains "Signing") or (t contains "Signing") then
          set salida to salida & (class of el as text) & " | " & n & " | " & t & linefeed
          if not hecho then
            try
              click el
              set hecho to true
            end try
          end if
        end if
      end try
    end repeat
    return salida & "clic: " & hecho
  end tell
end timeout
OSA
foto 05-signing 3
cat "$D"/xcode-*.txt
