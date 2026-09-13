# Guía de Configuración: Despliegue a Apple TestFlight con GitHub Actions

Esta guía explica paso a paso cómo conectar este repositorio con tu cuenta de Apple Developer para que GitHub Actions compile y suba automáticamente la app a **TestFlight**, permitiéndote instalarla y probarla directamente en tu iPhone.

---

## 1. Requisitos Previos
1. Una cuenta activa en el **Apple Developer Program** (https://developer.apple.com).
2. La app registrada en **App Store Connect** (https://appstoreconnect.apple.com) con el Bundle Identifier: `com.julietasleiman.splitwallet`.
3. La aplicación **TestFlight** instalada en tu iPhone desde el App Store oficial.

---

## 2. Generar la Clave de API de App Store Connect
1. En App Store Connect, dirígete a **Users and Access (Usuarios y Accesos)** > pestaña **Integrations (Integraciones)**.
2. En la sección **App Store Connect API**, haz clic en el botón `+` (Generate API Key).
3. Asigna un nombre (ej. `GitHub-Actions-CI`) y rol **App Manager** o **Admin**.
4. Descarga el archivo de clave privada (`.p8`). *Nota: Apple solo permite descargarlo una única vez.*
5. Toma nota de:
   - **Key ID** (ej: `2X9R4HX793`)
   - **Issuer ID** (ej: `69a6de70-abcd-47e3-e053-5b8c7c11a4d1`)
   - El contenido del archivo `.p8`.

---

## 3. Configurar los Secretos en tu Repositorio de GitHub
En tu repositorio de GitHub (`https://github.com/JulietaSleiman/APP`), ve a:
👉 **Settings** > **Secrets and variables** > **Actions** > botón **New repository secret**.

Agrega los siguientes secretos:

| Nombre del Secreto | Descripción |
|---|---|
| `APP_STORE_CONNECT_KEY_ID` | El ID de la clave generada en el paso anterior (ej. `2X9R4HX793`). |
| `APP_STORE_CONNECT_ISSUER_ID` | El Issuer ID de App Store Connect. |
| `APP_STORE_CONNECT_PRIVATE_KEY` | El contenido completo del archivo `AuthKey_XXXX.p8` (incluyendo `-----BEGIN PRIVATE KEY-----`). |
| `APPLE_DISTRIBUTION_CERTIFICATE_P12_BASE64` | Tu certificado de distribución (.p12) convertido a Base64. |
| `APPLE_CERTIFICATE_PASSWORD` | La contraseña con la que exportaste tu certificado `.p12`. |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Tu perfil de aprovisionamiento de App Store (`.mobileprovision`) en Base64. |

*(Cómo convertir un archivo a Base64 en Windows PowerShell:)*
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ruta\a\tu\archivo.p12")) | Set-Clipboard
```

---

## 4. Cómo Probar la App en tu iPhone
1. Cada vez que hagas `git push` a la rama `main`, la GitHub Action se ejecutará automáticamente en una Mac de GitHub:
   - Correrá toda la suite de pruebas unitarias (`xcodebuild test`).
   - Compilará el archivo `.ipa`.
   - Lo enviará a App Store Connect.
2. En unos minutos recibirás una notificación de Apple por correo y en la app **TestFlight** en tu iPhone indicando que la versión 1.0.0 (Build 1) está disponible para instalar.
3. Abres TestFlight, tocas **Instalar** y ¡listo! Tienes SplitWallet nativo corriendo en tu iPhone personal.
