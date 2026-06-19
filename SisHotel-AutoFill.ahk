#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; ══════════════════════════════════════════════════════════════
;  COTIZADOR MAEVA → SISHOTEL  v1.1
;  Hotkey principal : Ctrl+Shift+F  — llena el formulario
;  Hotkey calibrar  : Ctrl+Shift+C  — muestra coordenadas del mouse
;
;  FLUJO DE USO:
;  1. Genera cotización en el cotizador (browser)
;  2. Tab "Datos del cliente" → clic "📤 Enviar a SisHotel"
;  3. En SisHotel: clic "Nueva Reserv." → elige fecha → Enter
;  4. Asegúrate de estar en la pestaña "Datos Personales"
;  5. Presiona Ctrl+Shift+F
;  6. Confirma en el cuadro de diálogo → el script llena todo
;  7. Revisa y haz clic en "Guardar"
; ══════════════════════════════════════════════════════════════

WIN_TITLE  := "Sistema Hotelero SisHotel"
WIN_DIALOG := "Nuevo Tipo de Habitacion"

; ─── CALIBRACIÓN: muestra coordenadas del mouse ──────────────
^+c::
  MouseGetPos, mx, my
  WinGetPos, wx, wy,,, A
  offX := mx - wx
  offY := my - wy
  MsgBox, 0, Coordenadas, Pantalla: X=%mx% Y=%my%`nVentana: X=%wx% Y=%wy%`nOffset: X=%offX% Y=%offY%
return

; ─── HELPER: clic con offset desde ventana ───────────────────
Clic(wX, wY, offX, offY) {
  cx := wX + offX
  cy := wY + offY
  MouseClick, Left, %cx%, %cy%
}

; ─── HOTKEY PRINCIPAL ────────────────────────────────────────
^+f::

  ; Verificar payload en clipboard
  clip := Clipboard
  if !InStr(clip, "SHCLI|") {
    MsgBox, 48, Sin datos, Primero haz clic en "Enviar a SisHotel" en el cotizador.
    return
  }

  ; Parsear líneas
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

  ; Parsear cliente
  ; SHCLI|nombre|tel|email|ciudad|estado|pais|origen_seg|tar_pub
  cli    := StrSplit(cliLine, "|")
  nombre := cli[2]
  tel    := cli[3]
  email  := cli[4]
  ciudad := cli[5]
  origen := cli[8]
  tarPub := cli[9]

  ; Confirmar
  habCount := roomLines.MaxIndex()
  MsgBox, 36, ¿Llenar SisHotel?, Nombre: %nombre%`nTel: %tel%`nCiudad: %ciudad%`nOrigen: %origen%`nHabitaciones: %habCount%`n`n¿Continuar?
  IfMsgBox No
    return

  ; Activar SisHotel
  WinActivate, %WIN_TITLE%
  WinWaitActive, %WIN_TITLE%,,4
  if ErrorLevel {
    MsgBox, 48, Error, No se encontró SisHotel abierto.
    return
  }
  Sleep, 400
  WinGetPos, wX, wY, wW, wH, %WIN_TITLE%

  ; ════════════════════════════════
  ; TAB 1 — DATOS PERSONALES
  ; ════════════════════════════════
  ; Clic en pestaña Datos Personales
  cx := wX + 215 & cy := wY + 322
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR con Ctrl+Shift+C
  Sleep, 300

  ; Campo Nombre
  cx := wX + 295 & cy := wY + 365
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR
  Sleep, 150
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %nombre%
  Sleep, 100

  ; Tab: Nombre→Dirección→Colonia→País→Estado→Ciudad→C.P.→Teléfono→Email
  Send, {Tab}    ; Dirección  (skip)
  Send, {Tab}    ; Colonia    (skip)
  Send, {Tab}    ; País       (skip — default México)
  Send, {Tab}    ; Estado     (skip)
  Send, {Tab}    ; Ciudad
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %ciudad%
  Send, {Tab}    ; C.P.       (skip)
  Send, {Tab}    ; Teléfono
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %tel%
  Send, {Tab}    ; Email
  Sleep, 100
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %email%
  Sleep, 200

  ; ════════════════════════════════
  ; TAB 2 — DATOS DE RESERV.
  ; ════════════════════════════════
  cx := wX + 357 & cy := wY + 322
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR: tab Datos de Reserv.
  Sleep, 400

  ; Comentario de la Reservación (TAR PUB)
  cx := wX + 698 & cy := wY + 500
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR: campo Comentario
  Sleep, 150
  Send, {Ctrl Down}a{Ctrl Up}{Delete}
  Send, %tarPub%
  Sleep, 200

  ; ════════════════════════════════
  ; TAB 3 — HABITACIONES
  ; ════════════════════════════════
  cx := wX + 440 & cy := wY + 322
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR: tab Habitaciones
  Sleep, 400

  ; Loop por habitación
  Loop, % roomLines.MaxIndex()
  {
    roomLine := roomLines[A_Index]
    ; SHROOM|clase|llegada|salida|noches|adultos|n25|n612|n1317|extra|tarifa|importe
    room    := StrSplit(roomLine, "|")
    r_clase  := room[2]
    r_noches := room[5]
    r_adult  := room[6]
    r_n25    := room[7]
    r_n612   := room[8]
    r_n1317  := room[9]
    r_extra  := room[10]
    r_tarifa := room[11]
    r_imp    := room[12]

    ; Botón Nuevo
    cx := wX + 253 & cy := wY + 400
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: botón Nuevo
    Sleep, 900

    ; Esperar sub-diálogo
    WinWaitActive, %WIN_DIALOG%,,4
    if ErrorLevel {
      MsgBox, 48, Error, No abrió "Nuevo Tipo de Habitación".`nVerifica que estés en la pestaña Habitaciones.
      return
    }
    WinGetPos, dX, dY,,, %WIN_DIALOG%
    Sleep, 200

    ; CLASE (dropdown)
    cx := dX + 180 & cy := dY + 65
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: dropdown Clase
    Sleep, 400
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_clase%
    Sleep, 300
    Send, {Enter}
    Sleep, 400

    ; NOCHES (spinner)
    cx := dX + 260 & cy := dY + 98
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: spinner Noches
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_noches%
    Send, {Tab}
    Sleep, 300

    ; ADULTOS y NIÑOS (Tab navigation desde Adultos)
    cx := dX + 100 & cy := dY + 138
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: spinner Adultos
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_adult%
    Send, {Tab}
    Sleep, 100
    Send, {Ctrl Down}a{Ctrl Up}        ; 2-5
    Send, %r_n25%
    Send, {Tab}
    Send, {Ctrl Down}a{Ctrl Up}        ; 6-12
    Send, %r_n612%
    Send, {Tab}
    Send, {Ctrl Down}a{Ctrl Up}        ; 13-17
    Send, %r_n1317%
    Send, {Tab}
    Send, {Ctrl Down}a{Ctrl Up}        ; Extra
    Send, %r_extra%
    Sleep, 100

    ; TARIFA (dropdown)
    cx := dX + 180 & cy := dY + 200
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: dropdown Tarifa
    Sleep, 400
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_tarifa%
    Sleep, 300
    Send, {Enter}
    Sleep, 500

    ; IMPORTE
    cx := dX + 180 & cy := dY + 230
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: campo Importe
    Sleep, 150
    Send, {Ctrl Down}a{Ctrl Up}
    Send, %r_imp%
    Send, {Tab}
    Sleep, 200

    ; Botón ACEPTAR
    cx := dX + 120 & cy := dY + 510
    MouseClick, Left, %cx%, %cy%       ; ← AJUSTAR: botón Aceptar
    Sleep, 900

    WinActivate, %WIN_TITLE%
    WinWaitActive, %WIN_TITLE%,,3
    Sleep, 400
  }

  ; ════════════════════════════════
  ; TAB 6 — DATOS ADICIONALES
  ; ════════════════════════════════
  WinGetPos, wX, wY,,, %WIN_TITLE%
  cx := wX + 712 & cy := wY + 322
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR: tab Datos Adicionales
  Sleep, 400

  ; ORIGEN SEG. (dropdown)
  cx := wX + 470 & cy := wY + 397
  MouseClick, Left, %cx%, %cy%         ; ← AJUSTAR: dropdown ORIGEN SEG.
  Sleep, 400
  Send, {Ctrl Down}a{Ctrl Up}
  Send, %origen%
  Sleep, 300
  Send, {Enter}
  Sleep, 200

  MsgBox, 64, Listo, Datos cargados en SisHotel.`nRevisa y haz clic en "Guardar".

return
