#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; ══════════════════════════════════════════════════════════════
;  COTIZADOR MAEVA → SISHOTEL  v1.0
;  Hotkey principal : Ctrl+Shift+F
;  Hotkey calibrar  : Ctrl+Shift+C  (muestra coordenadas del mouse)
;
;  FLUJO DE USO:
;  1. Genera la cotización en el cotizador (browser)
;  2. Ve al tab "Datos del cliente" → clic "📤 Enviar a SisHotel"
;  3. En SisHotel: clic "Nueva Reserv." → elige fecha → Enter
;     (el sistema genera el folio automático, queda en Datos Personales)
;  4. Presiona Ctrl+Shift+F — el script llena todo
;  5. Revisa y haz clic en "Guardar"
; ══════════════════════════════════════════════════════════════

WIN_TITLE   := "Sistema Hotelero SisHotel"
WIN_DIALOG  := "Nuevo Tipo de Habitacion"

; ── HOTKEY CALIBRACIÓN: muestra coordenadas del mouse ──────
^+c::
  MouseGetPos, mx, my
  WinGetPos, wx, wy,,, A
  MsgBox, 0, Coordenadas, Mouse en pantalla: X=%mx% Y=%my%`n`nVentana activa en: X=%wx% Y=%wy%`nOffset desde ventana: X=%mx-wx% Y=%my-wy%
return

; ── HOTKEY PRINCIPAL ────────────────────────────────────────
^+f::

  ; Verificar que hay payload del cotizador en clipboard
  clip := Clipboard
  if !InStr(clip, "SHCLI|") {
    MsgBox, 48, Sin datos, Primero haz clic en "Enviar a SisHotel" en el cotizador.
    return
  }

  ; Parsear líneas del payload
  cliLine  := ""
  roomLines := []
  Loop, Parse, clip, `n, `r
  {
    if InStr(A_LoopField, "SHCLI|")
      cliLine := A_LoopField
    else if InStr(A_LoopField, "SHROOM|")
      roomLines.Push(A_LoopField)
  }

  if (!cliLine || roomLines.MaxIndex() < 1) {
    MsgBox, 48, Error, Datos incompletos. Vuelve a copiar desde el cotizador.
    return
  }

  ; Parsear datos del cliente
  ; SHCLI|nombre|tel|email|ciudad|estado|pais|origen_seg|tar_pub
  cli     := StrSplit(cliLine, "|")
  nombre  := cli[2]
  tel     := cli[3]
  email   := cli[4]
  ciudad  := cli[5]
  estado  := cli[6]
  pais    := cli[7]
  origen  := cli[8]
  tarPub  := cli[9]

  ; Confirmar antes de llenar
  habCount := roomLines.MaxIndex()
  MsgBox, 36, ¿Llenar SisHotel?, Nombre  : %nombre%`nTeléfono: %tel%`nCiudad  : %ciudad%`nOrigen  : %origen%`nHabitac.: %habCount%`n`n¿Continuar?
  IfMsgBox No
    return

  ; Activar ventana de SisHotel
  WinActivate, %WIN_TITLE%
  WinWaitActive, %WIN_TITLE%,,4
  if ErrorLevel {
    MsgBox, 48, Error, No se encontró la ventana de SisHotel abierta.
    return
  }
  Sleep, 400

  ; Obtener posición de la ventana del formulario de reserva
  ; (puede ser diferente a la ventana principal en MDI)
  WinGetPos, wX, wY, wW, wH, %WIN_TITLE%

  ; ══════════════════════════════════════
  ; TAB 1 — DATOS PERSONALES
  ; ══════════════════════════════════════
  ; Clic en la pestaña "Datos Personales" (ya debería estar activa)
  ; Si necesitas ajustar: usa Ctrl+Shift+C para ver coordenadas
  Click, % wX+215, % wY+322   ; ← AJUSTAR si es necesario
  Sleep, 300

  ; Campo NOMBRE — primer campo del form
  Click, % wX+295, % wY+365   ; ← AJUSTAR
  Sleep, 150
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %nombre%
  Sleep, 100

  ; Navegar con Tab hasta llegar a los campos que llenamos
  ; Orden aprox en Datos Personales:
  ; Nombre → Dirección → Colonia → País → Estado → Ciudad → C.P. → Teléfono → Email
  Send, {Tab}                  ; → Dirección (skip)
  Send, {Tab}                  ; → Colonia   (skip)
  Send, {Tab}                  ; → País      (skip, default México)
  Send, {Tab}                  ; → Estado    (skip)
  Send, {Tab}                  ; → Ciudad
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %ciudad%
  Send, {Tab}                  ; → C.P.      (skip)
  Send, {Tab}                  ; → Teléfono
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %tel%
  Send, {Tab}                  ; → Email
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %email%
  Sleep, 200

  ; ══════════════════════════════════════
  ; TAB 2 — DATOS DE RESERV.
  ; ══════════════════════════════════════
  Click, % wX+357, % wY+322   ; ← AJUSTAR: tab "Datos de Reserv."
  Sleep, 400

  ; Comentario de la Reservación (TAR PUB)
  Click, % wX+698, % wY+500   ; ← AJUSTAR: campo "Comentario de la Reservación"
  Sleep, 150
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %tarPub%
  Sleep, 200

  ; ══════════════════════════════════════
  ; TAB 3 — HABITACIONES
  ; ══════════════════════════════════════
  Click, % wX+440, % wY+322   ; ← AJUSTAR: tab "Habitaciones"
  Sleep, 400

  ; Loop por cada habitación
  Loop, % roomLines.MaxIndex()
  {
    roomLine := roomLines[A_Index]
    ; SHROOM|clase|llegada|salida|noches|adultos|n25|n612|n1317|extra|tarifa|importe
    room     := StrSplit(roomLine, "|")
    r_clase  := room[2]
    r_ll     := room[3]   ; DD/MM/YYYY
    r_sal    := room[4]   ; DD/MM/YYYY
    r_noches := room[5]
    r_adult  := room[6]
    r_n25    := room[7]
    r_n612   := room[8]
    r_n1317  := room[9]
    r_extra  := room[10]
    r_tarifa := room[11]
    r_imp    := room[12]

    ; Clic en botón "Nuevo"
    Click, % wX+253, % wY+400   ; ← AJUSTAR: botón Nuevo
    Sleep, 900

    ; Esperar sub-diálogo
    WinWaitActive, %WIN_DIALOG%,,4
    if ErrorLevel {
      MsgBox, 48, Error, No abrió "Nuevo Tipo de Habitación". Verifica que estés en la pestaña Habitaciones.
      return
    }
    WinGetPos, dX, dY,,, %WIN_DIALOG%
    Sleep, 200

    ; CLASE (dropdown)
    Click, % dX+180, % dY+65    ; ← AJUSTAR: dropdown Clase
    Sleep, 400
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_clase%
    Sleep, 300
    Send, {Enter}
    Sleep, 400

    ; NOCHES (spinner — Tab desde Clase suele llegar aquí después de F.Llegada/F.Salida)
    Click, % dX+260, % dY+98    ; ← AJUSTAR: spinner Noches
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_noches%
    Send, {Tab}
    Sleep, 300   ; esperar recálculo de F.Salida

    ; ADULTOS
    Click, % dX+100, % dY+138   ; ← AJUSTAR: spinner Adultos
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_adult%
    Send, {Tab}
    Sleep, 100

    ; NIÑOS 2-5
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_n25%
    Send, {Tab}

    ; NIÑOS 6-12
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_n612%
    Send, {Tab}

    ; 13-17
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_n1317%
    Send, {Tab}

    ; EXTRA
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_extra%
    Sleep, 100

    ; TARIFA (dropdown)
    Click, % dX+180, % dY+200   ; ← AJUSTAR: dropdown Tarifa
    Sleep, 400
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_tarifa%
    Sleep, 300
    Send, {Enter}
    Sleep, 500

    ; IMPORTE
    Click, % dX+180, % dY+230   ; ← AJUSTAR: campo Importe
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_imp%
    Send, {Tab}
    Sleep, 200

    ; Botón ACEPTAR
    Click, % dX+120, % dY+510   ; ← AJUSTAR: botón Aceptar
    Sleep, 900

    ; Regresar foco a ventana principal
    WinActivate, %WIN_TITLE%
    WinWaitActive, %WIN_TITLE%,,3
    Sleep, 400
  }

  ; ══════════════════════════════════════
  ; TAB 6 — DATOS ADICIONALES
  ; ══════════════════════════════════════
  WinGetPos, wX, wY,,, %WIN_TITLE%
  Click, % wX+712, % wY+322    ; ← AJUSTAR: tab "Datos Adicionales"
  Sleep, 400

  ; ORIGEN SEG. (dropdown)
  Click, % wX+470, % wY+397    ; ← AJUSTAR: dropdown ORIGEN SEG.
  Sleep, 400
  Send, {Ctrl Down}a{Ctrl Up}
  Send, %origen%
  Sleep, 300
  Send, {Enter}
  Sleep, 200

  ; ¡Listo!
  MsgBox, 64, ✅ Listo, Datos cargados en SisHotel.`n`nRevisa y haz clic en "Guardar".

return
