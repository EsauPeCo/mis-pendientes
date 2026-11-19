#!/usr/bin/env bash
# Genera la evidencia del Reto 5 en un runner macOS de GitHub Actions.
# Cada captura de terminal se guarda como .txt: la 1.ª línea es el comando, el resto su salida real.
# Requisitos: Xcode 26, xcodegen. Uso: bash scripts/ci/evidencia.sh
set -uo pipefail

RAIZ="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$RAIZ"
export EV="$RAIZ/evidencia"
export T="$EV/terminal" S="$EV/simulador" X="$EV/xcode" B="$EV/binarios" D="$EV/diagnostico"
mkdir -p "$T" "$S" "$X" "$B" "$D" build/firma
export DD="$RAIZ/build/DD"
export BUNDLE=io.github.esaupeco.mispendientes
export TEAM=ESAUSIM001            # Team ID simulado: no hay membresía del Apple Developer Program
export NOMBRE_CERT="Distribucion simulada: Jose Esau Perez Coronel ($TEAM)"
export KC="$RAIZ/build/firma/reto5.keychain-db" KCPASS=reto5
export APP="build/MisPendientes.xcarchive/Products/Applications/MisPendientes.app"

cap() {
  local nombre="$1" comando="$2"
  { printf '%s\n' "$comando"; bash -c "$comando" 2>&1; } > "$T/$nombre.txt"
  echo "::group::$nombre"; cat "$T/$nombre.txt"; echo "::endgroup::"
}

# ---------- 1. Preparación del proyecto ----------
cap 01-entorno "sw_vers | head -2; xcodebuild -version; xcrun --sdk iphoneos --show-sdk-version; xcodegen --version"
cap 02-generar-proyecto "xcodegen generate --spec project.yml"
cap 03-identidad "xcodebuild -showBuildSettings -project MisPendientes.xcodeproj -target MisPendientes -configuration Release 2>/dev/null \\
  | grep -E ' (PRODUCT_BUNDLE_IDENTIFIER|MARKETING_VERSION|CURRENT_PROJECT_VERSION|IPHONEOS_DEPLOYMENT_TARGET|TARGETED_DEVICE_FAMILY|CODE_SIGN_STYLE|DEVELOPMENT_TEAM|SDK_VERSION) ='"

# Simulador para compilar, probar y capturar (6.9 pulgadas: 1320 x 2868 px)
TIPO=$(xcrun simctl list devicetypes | grep -oE 'iPhone 17 Pro Max|iPhone 16 Pro Max' | head -1)
UDID=$(xcrun simctl create "Captura Reto 5" "$TIPO")
export UDID TIPO
echo "Simulador: $TIPO $UDID"
xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl spawn "$UDID" defaults write -g AppleLanguages -array es-MX
xcrun simctl spawn "$UDID" defaults write -g AppleLocale -string es_MX
xcrun simctl shutdown "$UDID"; xcrun simctl boot "$UDID"; xcrun simctl bootstatus "$UDID" -b >/dev/null

cap 04-compilacion "xcodebuild build -scheme MisPendientes -destination \"id=\$UDID\" -derivedDataPath build/DD > build/compilacion.log 2>&1
grep -E '^\\*\\* BUILD' build/compilacion.log
echo \"Errores: \$(grep -c ' error: ' build/compilacion.log)   Advertencias: \$(grep -c ' warning: ' build/compilacion.log)\""

cap 05-pruebas "xcodebuild test -scheme MisPendientes -destination \"id=\$UDID\" -derivedDataPath build/DD \\
  -only-testing:MisPendientesTests 2>&1 | grep -E \"Test Case .*(passed|failed)|Executed|\\*\\* TEST\" | sed -E 's/^Test Case .-\\[MisPendientesTests\\.//; s/\\]. / /'"

# ---------- 2. Empaquetado y firmado ----------
cap 06-archivo-sin-equipo "xcodebuild archive -scheme MisPendientes -destination 'generic/platform=iOS' \\
  -archivePath build/intento.xcarchive 2>&1 | grep -E 'error:|ARCHIVE' | sed 's|^.*/MisPendientes.xcodeproj: ||' | sort -u"

cap 07-archivo "xcodebuild archive -scheme MisPendientes -destination 'generic/platform=iOS' \\
  -archivePath build/MisPendientes.xcarchive CODE_SIGNING_ALLOWED=NO > build/archivo.log 2>&1; grep -E '^\\*\\* ARCHIVE' build/archivo.log
ls build/MisPendientes.xcarchive/Products/Applications/
plutil -p build/MisPendientes.xcarchive/Info.plist | grep -E 'Name|CFBundle|Architectures|arm64|SigningIdentity' | sed 's/^ *//'
lipo -info $APP/MisPendientes"

cat > build/ExportOptions.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>destination</key><string>export</string>
  <key>signingStyle</key><string>automatic</string>
</dict></plist>
EOF
cap 08-exportar-app-store "xcodebuild -exportArchive -archivePath build/MisPendientes.xcarchive \\
  -exportOptionsPlist build/ExportOptions.plist -exportPath build/export 2>&1 | grep -E 'error|EXPORT' | sort -u"

# Identidad de firma autofirmada (sustituye al certificado Apple Distribution, que emite Apple)
cd build/firma
cat > cert.cnf <<EOF
[req]
distinguished_name = dn
prompt = no
[dn]
CN = $NOMBRE_CERT
OU = $TEAM
O = Jose Esau Perez Coronel
C = MX
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -keyout distribucion.key -out distribucion.crt -days 365 \
  -config cert.cnf -extensions ext 2>/dev/null
/usr/bin/openssl pkcs12 -export -inkey distribucion.key -in distribucion.crt -out distribucion.p12 -passout pass:$KCPASS
security create-keychain -p "$KCPASS" "$KC"
security set-keychain-settings -lut 3600 "$KC"
security unlock-keychain -p "$KCPASS" "$KC"
security import distribucion.p12 -k "$KC" -P "$KCPASS" -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security set-key-partition-list -S apple-tool:,apple: -s -k "$KCPASS" "$KC" >/dev/null
security list-keychains -d user -s "$KC" $(security list-keychains -d user | tr -d '"')
cd "$RAIZ"

cap 09-certificado "openssl x509 -in build/firma/distribucion.crt -noout -subject -issuer -dates -ext extendedKeyUsage
security find-identity -p codesigning \$KC"

# Perfil de aprovisionamiento de App Store simulado (el real lo firma Apple)
CREADO=$(date -u +%Y-%m-%dT%H:%M:%SZ); VENCE=$(date -u -v+1y +%Y-%m-%dT%H:%M:%SZ)
CERT_DER=$(/usr/bin/openssl x509 -in build/firma/distribucion.crt -outform DER | base64)
cat > build/firma/perfil.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>AppIDName</key><string>MisPendientes</string>
  <key>ApplicationIdentifierPrefix</key><array><string>$TEAM</string></array>
  <key>CreationDate</key><date>$CREADO</date>
  <key>DeveloperCertificates</key><array><data>$CERT_DER</data></array>
  <key>Entitlements</key><dict>
    <key>application-identifier</key><string>$TEAM.$BUNDLE</string>
    <key>beta-reports-active</key><true/>
    <key>com.apple.developer.team-identifier</key><string>$TEAM</string>
    <key>get-task-allow</key><false/>
    <key>keychain-access-groups</key><array><string>$TEAM.*</string></array>
  </dict>
  <key>ExpirationDate</key><date>$VENCE</date>
  <key>IsXcodeManaged</key><false/>
  <key>Name</key><string>MisPendientes App Store (simulado)</string>
  <key>Platform</key><array><string>iOS</string></array>
  <key>TeamIdentifier</key><array><string>$TEAM</string></array>
  <key>TeamName</key><string>Jose Esau Perez Coronel</string>
  <key>TimeToLive</key><integer>365</integer>
  <key>UUID</key><string>$(uuidgen)</string>
  <key>Version</key><integer>1</integer>
</dict></plist>
EOF
/usr/bin/openssl smime -sign -binary -nodetach -outform der -in build/firma/perfil.plist \
  -signer build/firma/distribucion.crt -inkey build/firma/distribucion.key -out build/firma/embedded.mobileprovision

cap 10-perfil "security cms -D -i build/firma/embedded.mobileprovision > build/firma/perfil-decodificado.plist
plutil -p build/firma/perfil-decodificado.plist | grep -vE 'DeveloperCertificates|=> \\{length|^ *0 => \\{|^  \\]' | head -30"

cap 11-firma "/usr/libexec/PlistBuddy -x -c 'Print :Entitlements' build/firma/perfil-decodificado.plist > build/firma/derechos.plist
cp build/firma/embedded.mobileprovision $APP/embedded.mobileprovision
IDENTIDAD=\$(security find-identity -p codesigning \$KC | awk '/1\\)/{print \$2; exit}')
codesign --force --sign \$IDENTIDAD --keychain \$KC \\
  --entitlements build/firma/derechos.plist --generate-entitlement-der $APP
codesign --verify --strict --verbose=2 $APP
codesign -dvv $APP 2>&1 | grep -E '^(Identifier|Format|Authority|TeamIdentifier|Signed Time|Sealed Resources)'
codesign -d --entitlements - --xml $APP 2>/dev/null | plutil -p -"

cap 12-ipa "mkdir -p build/ipa/Payload && cp -R $APP build/ipa/Payload/
(cd build/ipa && zip -qry ../../evidencia/binarios/MisPendientes-1.0-1.ipa Payload)
unzip -l evidencia/binarios/MisPendientes-1.0-1.ipa | grep -E 'MisPendientes\$|Info.plist\$|embedded|_CodeSignature/CodeResources|Assets.car|AppIcon|PrivacyInfo|files\$'
shasum -a 256 evidencia/binarios/MisPendientes-1.0-1.ipa"

cap 13-info-plist "plutil -p $APP/Info.plist | grep -E 'CFBundleIdentifier|CFBundleShortVersionString|CFBundleVersion|MinimumOSVersion|UIDeviceFamily|ITSAppUsesNonExemptEncryption|DTPlatformVersion|DTXcode\"|DTSDKName|LSApplicationCategoryType' | sed 's/^ *//'
plutil -p $APP/PrivacyInfo.xcprivacy | sed 's/^ *//'"

# ---------- 3. Capturas en el simulador ----------
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$UDID" "$DD/Build/Products/Debug-iphonesimulator/MisPendientes.app"

foto() {
  xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
  xcrun simctl launch "$UDID" "$BUNDLE" -demo YES -pantalla "$2" >/dev/null
  sleep 5
  xcrun simctl io "$UDID" screenshot --type=png "$S/$1.png" >/dev/null 2>&1 && echo "captura $1"
}
foto 1-lista lista
foto 2-nueva nueva
foto 3-editar editar
foto 4-completadas completadas
foto 5-privacidad privacidad
xcrun simctl ui "$UDID" appearance dark
foto 6-lista-oscuro lista
xcrun simctl ui "$UDID" appearance light

# Video del recorrido (vista previa de la tienda)
xcrun simctl terminate "$UDID" "$BUNDLE" 2>/dev/null
xcrun simctl io "$UDID" recordVideo --codec=h264 --force "$S/recorrido.mp4" > "$D/video.log" 2>&1 &
REC=$!
sleep 3
cap 14-prueba-ui "xcodebuild test -scheme MisPendientes -destination \"id=\$UDID\" -derivedDataPath build/DD \\
  -only-testing:MisPendientesUITests -parallel-testing-enabled NO 2>&1 | grep -E \"Test Case .*(passed|failed)|Executed|\\*\\* TEST|error\""
sleep 2
kill -INT "$REC"; wait "$REC" 2>/dev/null
cap 15-identidad-instalada "xcrun simctl listapps \$UDID | grep -A12 '\"$BUNDLE\"' | grep -E 'CFBundle(DisplayName|Identifier|ShortVersionString|Version)' | sed 's/^ *//'"

# ---------- 4. Xcode con interfaz gráfica ----------
bash scripts/ci/xcode-gui.sh || echo "No se pudieron tomar las capturas de Xcode"

cp build/compilacion.log build/archivo.log "$D/" 2>/dev/null
xcrun simctl list devices "$UDID" > "$D/simulador.txt" 2>&1
echo "Listo. Evidencia en $EV"
