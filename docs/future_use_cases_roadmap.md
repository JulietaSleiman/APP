# SplitWallet — Roadmap de Casos de Uso y Evolución de Producto

Este documento recopila todos los casos de uso identificados para SplitWallet, ordenados por prioridad estratégica y requerimientos de arquitectura.

---

## 1. Modo "Gasto Personal" (Personal Expenses / Solo Tracking)
- **Alcance**: Registro de gastos individuales que no pertenecen a ningún grupo ni se dividen con otras personas.
- **Valor para el usuario**: Permite usar SplitWallet como app unificada de finanzas (compartidas + personales), con presupuestos mensuales y reportes visuales con gráficos (Swift Charts).
- **Complejidad técnica**: Media (Modelos desacoplados, persistencia SwiftData, UI con TabView y Swift Charts).

## 2. Adjuntos de Comprobantes y Fotos de Tickets (Receipt Attachments)
- **Alcance**: Capturar fotos con la cámara o seleccionar de la galería para adjuntar comprobantes físicos a cada gasto.
- **Valor para el usuario**: Transparencia total; cualquier participante puede comprobar los ítems y precios reales del gasto.
- **Complejidad técnica**: Baja-Media (`PhotosUI`, almacenamiento local cifrado de imágenes y subida multipart a backend).

## 3. Exportación a PDF con Formato Editorial (Printable PDF Summary)
- **Alcance**: Generación de documentos PDF vectoriales con diseño estilizado (tablas, desglose de balances, marcas de saldado).
- **Valor para el usuario**: Cierre formal de cuentas al finalizar un contrato de roommate o un viaje en grupo para compartir por WhatsApp o imprimir.
- **Complejidad técnica**: Media (`PDFKit` o renderizado SwiftUI `ImageRenderer`).

## 4. Escaneo Inteligente de Tickets con OCR y División Ítem por Ítem
- **Alcance**: Reconocimiento óptico de caracteres sobre el ticket de un restaurante o supermercado.
- **Valor para el usuario**: Permite que en una cena cada comensal seleccione en pantalla qué consumió exactamente, repartiendo propinas y cargos de servicio automáticamente.
- **Complejidad técnica**: Alta (`VisionKit` / Apple Vision Framework, parseo de texto con regex/LLM local en dispositivo).

## 5. Integración con Medios de Pago Locales (Deep Linking / Alias / QR)
- **Alcance**: Botón directo de "Pagar" que abre aplicaciones de pago locales (Mercado Pago, Alias CBU/CVU bancario, Apple Cash, Bizum) con el monto de la deuda prellenado.
- **Valor para el usuario**: Reduce la fricción de liquidación a cero al conectar el saldo contable con la transferencia de dinero real.
- **Complejidad técnica**: Media (URL Schemes, Universal Links y Portapapeles con feedback).

## 6. Múltiples Pagadores en un Solo Gasto (Co-Payers)
- **Alcance**: Registro de gastos donde más de una persona aportó dinero (ej: una cuenta de $20.000 pagada $12.000 con tarjeta por Juan y $8.000 en efectivo por Male).
- **Valor para el usuario**: Refleja situaciones comunes en la vida real sin necesidad de crear gastos ficticios separados.
- **Complejidad técnica**: Media-Alta (Actualización del modelo de datos a array de pagadores y ajuste en `BalanceCalculator`).

## 7. Widgets de iOS y Live Activities (WidgetKit / Dynamic Island)
- **Alcance**: Widgets de pantalla de inicio y bloqueo para consultar balances sin abrir la app; Live Activity para seguimiento de gastos en tiempo real durante salidas o viajes.
- **Valor para el usuario**: Acceso inmediato a la información financiera crítica en el sistema operativo.
- **Complejidad técnica**: Media (`WidgetKit`, `ActivityKit`).

## 8. Conversión de Divisas en Tiempo Real (Multi-Currency Live FX)
- **Alcance**: Consulta de cotizaciones oficiales/de mercado para unificar balances de gastos en diferentes monedas a una divisa de referencia.
- **Valor para el usuario**: Claridad en viajes internacionales con gastos en USD, EUR y moneda local.
- **Complejidad técnica**: Media (Integración de API de tipos de cambio con cache offline y recálculo determinista).

## 9. Cierre y Archivo de Grupos (Group Settle & Archival)
- **Alcance**: Estado de "Grupo Cerrado" que congela la carga de nuevos gastos una vez que todas las cuentas están en cero.
- **Valor para el usuario**: Mantiene ordenado el historial y previene alteraciones post-cierre de viaje.
- **Complejidad técnica**: Baja (Flags de estado en el grupo y validaciones en UI/Backend).

## 10. Sincronización Offline-First con Resolución de Conflictos (CRDTs)
- **Alcance**: Cola de mutaciones idempotentes y combinación sin pérdida de datos ante ediciones concurrentes sin conexión.
- **Valor para el usuario**: Uso ininterrumpido en aviones, zonas rurales o sin cobertura de datos.
- **Complejidad técnica**: Alta (Mapeo de timestamps lógicos o CRDTs en SwiftData y backend).
