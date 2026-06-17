# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Proyecto

**Cotizador Club Maeva Miramar** — PWA de un solo archivo HTML para cotización de reservaciones. Usado por agentes de ventas del hotel (Tampico, México). Tarifas 2026, planes Todo Incluido (AI) y Plan Europeo (EP).

## Estructura del archivo

`index.html` es el único archivo de código (6 300+ líneas). Todo está inline: CSS, HTML y JS. No hay build tools, bundlers ni dependencias npm.

```
index.html          ← app completa
manifest.json       ← PWA config (cache key: maeva-v14)
sw.js               ← Service Worker (cache-first, assets estáticos)
icon.svg / logo.png ← íconos
```

## Arquitectura interna de index.html

El archivo se divide en tres bloques secuenciales:

### 1. CSS (líneas ~15–480)
Variables CSS en `:root` definen toda la paleta. Dark mode se aplica vía `body.dark` sobrescribiendo las mismas variables. Breakpoints: 1500px (FABs), 960px, 768px, 600px, 400px.

Paleta de marca:
- `--azul: #00AEEF` / dark: `#4dd4ff`
- `--dorado: #F5A623`
- `--texto: #0D2D3F` / dark: `#e8f4fb`

### 2. HTML (líneas ~480–1155)
Topbar fija + `.container` con sistema de tabs. Las tabs activas se controlan por clase `active` en `.panel` y `.tab`. Modales overlay con `.modal-overlay.active`.

**Tabs:** Cotizar → Comparar opciones → Datos del cliente → Resumen para cliente → Configuración → Historial → Admin

### 3. JavaScript (líneas ~1156–fin)
Organizado por secciones comentadas `// ─── SECCIÓN ───`. Principales:

| Sección | Línea | Qué hace |
|---|---|---|
| Datos de tarifas | ~1160 | Objeto `TARIFAS[]` con temporadas, tipos de hab y precios |
| `initTarifas()` | ~1295 | Carga tarifas desde `localStorage` (admin overrides) o default |
| `calcular()` | ~1640 | Función principal — recalcula todo al cambiar inputs |
| `calcNoche()` | ~1580 | Precio por noche según plan, adultos, menores, descuentos |
| `calcNocheDepto()` | ~1497 | Lógica especial para Departamento Completo (cupo mínimo 6) |
| `clasifMenores()` | ~1361 | Clasifica menores por edad: gratis / tarifa / cargo extra |
| Comparativa | ~2150 | Calcula todas las habitaciones en paralelo para comparar |
| Habitaciones | ~2262 | Array `habitaciones[]` — cotización multi-habitación |
| Resumen | ~2832 | `generarResumen()` — arma el texto copiable para cliente |
| `exportarPDF()` | ~3493 | Genera PDF vía jsPDF (CDN) |
| Historial | ~3955 | CRUD en `localStorage` key `maeva_historial` |
| Dark mode | ~5184 | Toggle + persistencia en `maeva_dark` |
| Admin Panel | ~5992 | Panel protegido con hash SHA-256 |

## localStorage Keys

| Key | Contenido |
|---|---|
| `maeva_tarifas_v1` | Tarifas customizadas por admin (override del default) |
| `maeva_mensajes_v1` | Mensajes promocionales editables |
| `maeva_config` | Config del agente: nombre, datos del hotel, toggles |
| `maeva_historial` | Array de cotizaciones/reservaciones guardadas |
| `maeva_dark` | Preferencia de modo oscuro |

## Admin Panel

- Acceso: tab "Admin" → password hasheado con SHA-256 (`ADMIN_HASH` en línea ~5993)
- Password actual: `Maeva2026`
- Permite: editar tarifas por temporada, activar fin de año, gestionar mensajes promo, ajustes de configuración
- Los cambios se persisten en `maeva_tarifas_v1` (localStorage)

## Reglas al modificar este proyecto

- **No romper el archivo único** — todo debe permanecer en `index.html`
- **No agregar dependencias externas** salvo las ya presentes (Inter font vía Google Fonts, jsPDF vía CDN)
- **Versionar el SW**: al cambiar assets cacheados, incrementar `CACHE = 'maeva-v14'` en `sw.js`
- **Backups**: crear `index.backup-YYYYMMDD-HHMM-descripcion.html` en carpeta `backups/` antes de cambios grandes
- **Dark mode**: cualquier clase nueva necesita su contrapartida `body.dark .clase{}`
- `calcular()` es la función central — se llama en cada cambio de input; mantener su cadena de llamadas intacta

## Tipos de habitación

`ESTANDAR`, `JUNIOR_SUITE`, `JUNIOR_SUITE_KING`, `MASTER_SUITE`, `VILLA`, `EJECUTIVA`, `ESTANDAR_DEPTO`, `JUNIOR_DEPTO`, `DEPARTAMENTO`

`DEPARTAMENTO` tiene lógica separada (`calcNocheDepto`) con cupo mínimo de cotización de 6 personas.

## Cómo probar

Abrir `index.html` directamente en browser (no requiere servidor). Para probar la PWA completa (SW + manifest), servir con un servidor local simple:

```bash
cd "Desktop/Projects Deploys/Cotizador Maeva"
python3 -m http.server 8080
# Abrir http://localhost:8080
```
