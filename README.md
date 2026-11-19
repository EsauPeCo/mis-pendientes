# MisPendientes

Lista de tareas para iPhone hecha en SwiftUI (iOS 17 o posterior). Proyecto del Reto 5 del módulo
*Despliegue de aplicaciones web y móviles* (UVEG): preparación, empaquetado, firma y publicación simulada en la App Store.

- Bundle ID: `io.github.esaupeco.mispendientes`, versión 1.0 (compilación 1), solo iPhone.
- Los datos se guardan en un JSON local con protección de datos; sin red, cuentas ni analítica.
- `PrivacyInfo.xcprivacy` declara que no hay rastreo ni datos recopilados.
- `ITSAppUsesNonExemptEncryption = NO` en `Info.plist` (la app no usa cifrado propio).

## Compilar

```sh
brew install xcodegen
xcodegen generate          # crea MisPendientes.xcodeproj a partir de project.yml
open MisPendientes.xcodeproj
```

Para distribuir hay que asignar un equipo del Apple Developer Program en *Signing & Capabilities*.

## Evidencia automática

`.github/workflows/evidencia.yml` corre en un runner macOS con Xcode 26: compila, ejecuta las pruebas,
archiva, firma el `.ipa` con una identidad **autofirmada y un perfil simulado** (no hay membresía de pago),
toma las capturas de la tienda en el simulador de 6.9" y graba el recorrido para la vista previa.

## Sitio

`docs/` se publica en GitHub Pages: política de privacidad y página de soporte.
