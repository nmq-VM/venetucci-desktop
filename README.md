# Venetucci Control — Versión de escritorio (Tauri)

App de escritorio para Windows y Mac que envuelve la app web nueva (con login, roles,
offline y sincronización). Corre en la **bandeja del sistema**, arranca con el equipo y
sincroniza sola cuando hay internet.

> La app web actual sigue funcionando aparte, sin tocar. Esto es un proyecto separado.

---

## Qué hace la versión de escritorio

- Misma app (`frontend/index.html`), pero como programa nativo.
- Al **cerrar la ventana** se esconde en la bandeja (no se cierra) → el proceso sigue
  vivo y la sincronización (cola offline + chequeo cada 30s) sigue corriendo.
- **Arranca con el sistema** (autostart).
- Ícono en la bandeja con "Abrir Venetucci" y "Salir".

No cubre el caso "PC apagada" — eso es imposible para cualquier app. Pero con la app en
bandeja + autostart, mientras la PC esté encendida sincroniza sola.

---

## 1) Instalar prerequisitos (una sola vez)

### Windows
1. **Rust**: https://www.rust-lang.org/tools/install (instalá `rustup`).
2. **Microsoft C++ Build Tools**: https://visualstudio.microsoft.com/visual-cpp-build-tools/
   (marcá "Desarrollo para escritorio con C++").
3. **WebView2**: viene con Windows 10/11. Si no, instalá el runtime de Microsoft.
4. **Node.js** (opcional, solo si usás la CLI por npm): https://nodejs.org

### Mac
1. **Rust**: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`
2. **Xcode Command Line Tools**: `xcode-select --install`

### CLI de Tauri (en las dos plataformas)
```
cargo install tauri-cli --version "^2"
```

---

## 2) Generar los íconos

Tauri necesita íconos en varios formatos. Desde la carpeta `src-tauri`, usando tu PNG
(por ejemplo el `icon-512.png` que ya tenés):
```
cargo tauri icon /ruta/a/icon-512.png
```
Esto crea `src-tauri/icons/` con todos los tamaños (.png, .ico, .icns).

---

## 3) Probar en desarrollo
Desde la carpeta raíz del proyecto (donde está `src-tauri`):
```
cargo tauri dev
```
Se abre la app. Probá: login, cargar una inspección, cerrar la ventana (debe irse a la
bandeja), reabrir desde la bandeja.

---

## 4) Compilar los instaladores
```
cargo tauri build
```
Los instaladores quedan en:
- **Windows**: `src-tauri/target/release/bundle/` → `.msi` y/o `.exe` (NSIS)
- **Mac**: `src-tauri/target/release/bundle/` → `.dmg` y `.app`

> Importante: el instalador de Windows se compila en Windows, y el de Mac en Mac.
> No se puede compilar el .dmg desde Windows ni viceversa. Necesitás cada sistema
> (o una Mac + una PC) para generar los dos instaladores.

---

## 5) Distribuir a las 5 máquinas (sin firmar, sin pagar los USD 99)

- **Windows**: al abrir el instalador salta SmartScreen → *Más información → Ejecutar de
  todas formas*. Una sola vez por máquina.
- **Mac**: click derecho sobre la app → *Abrir* → *Abrir* (o Ajustes del Sistema →
  Privacidad y seguridad → *Abrir igualmente*). Una sola vez por máquina.

Pasá el instalador por un canal confiable (no un link público editable). Opcional:
compartí un checksum (`shasum -a 256 archivo` en Mac / `Get-FileHash` en Windows) para
verificar que es el que vos compilaste.

---

## Estructura del proyecto
```
venetucci-desktop/
├─ frontend/
│  └─ index.html          # la app nueva (login + roles + offline + sync)
└─ src-tauri/
   ├─ Cargo.toml          # dependencias Rust (tauri 2 + autostart)
   ├─ build.rs
   ├─ tauri.conf.json     # config de la app (ventana, bundle, íconos)
   ├─ capabilities/
   │  └─ default.json     # permisos (ventana + autostart)
   ├─ icons/              # se genera con `cargo tauri icon`
   └─ src/
      └─ main.rs          # bandeja + cerrar-a-bandeja + autostart
```

---

## Notas / cosas a saber

- **Actualizar la app**: cuando cambies el `index.html`, reemplazás `frontend/index.html`,
  recompilás y repartís el instalador nuevo. (Más adelante se puede agregar auto-update,
  pero eso sí requiere firma.)
- **Service worker (sw.js)**: en la versión de escritorio no hace falta el modo PWA. Si el
  `index.html` intenta registrar `sw.js` y no está, falla silencioso, no rompe nada. Si
  querés, se puede sacar ese registro para la build de escritorio.
- **Supabase**: la app se conecta igual a tu proyecto. Asegurate de haber corrido el
  `supabase_setup.sql` (RLS + roles) antes de que la usen.
- **Versiones**: Tauri evoluciona. Si algo de `main.rs` no compila por un cambio de API,
  revisá la doc oficial en https://tauri.app (sección tray-icon y plugin autostart). El
  scaffold apunta a Tauri 2.x.
- No pude compilar esto por vos (requiere el toolchain en tu máquina), así que probá
  primero con `cargo tauri dev` antes de compilar los instaladores.
