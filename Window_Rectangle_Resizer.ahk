#Requires AutoHotkey v2.0
#SingleInstance Force
CoordMode "Mouse", "Screen"

; ============================================================
; HOTKEY
; Press CTRL + ALT + R to draw a rectangle and resize active window
; ============================================================

^!r::
{
    targetWindow := WinExist("A")

    if !targetWindow {
        MsgBox "No active window found."
        return
    }

    rect := DrawScreenRectangle()

    if !rect {
        return
    }

    ; Optional: small delay so the overlay is fully gone
    Sleep 100

    ; Restore window first if minimized/maximized
    WinRestore "ahk_id " targetWindow
    Sleep 100

    ; Move and resize the active window to the drawn rectangle
    WinMove rect.x, rect.y, rect.w, rect.h, "ahk_id " targetWindow
}

; ============================================================
; FUNCTION: Draw rectangle over all monitors
; Returns object: {x, y, w, h}
; ============================================================

DrawScreenRectangle()
{
    ; Get total virtual screen area across all monitors
    virtualX := SysGet(76) ; SM_XVIRTUALSCREEN
    virtualY := SysGet(77) ; SM_YVIRTUALSCREEN
    virtualW := SysGet(78) ; SM_CXVIRTUALSCREEN
    virtualH := SysGet(79) ; SM_CYVIRTUALSCREEN

    ; Create transparent overlay GUI
    overlay := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
    overlay.BackColor := "000000"
    overlay.Show("x" virtualX " y" virtualY " w" virtualW " h" virtualH)

    ; Make overlay semi-transparent
    WinSetTransparent 60, overlay.Hwnd

    ; Create rectangle GUI border
    box := Gui("+AlwaysOnTop -Caption +ToolWindow")
    box.BackColor := "00AAFF"

    ; Wait for left mouse down
    KeyWait "LButton", "D"

    MouseGetPos &startX, &startY

    ; Show initial tiny rectangle
    box.Show("x" startX " y" startY " w1 h1")
    WinSetTransparent 120, box.Hwnd

    ; Track drag
    while GetKeyState("LButton", "P") {
        MouseGetPos &currentX, &currentY

        x := Min(startX, currentX)
        y := Min(startY, currentY)
        w := Abs(currentX - startX)
        h := Abs(currentY - startY)

        if (w < 1)
            w := 1
        if (h < 1)
            h := 1

        box.Move(x, y, w, h)

        Sleep 10
    }

    ; Final mouse position
    MouseGetPos &endX, &endY

    finalX := Min(startX, endX)
    finalY := Min(startY, endY)
    finalW := Abs(endX - startX)
    finalH := Abs(endY - startY)

    ; Destroy overlay and rectangle box
    box.Destroy()
    overlay.Destroy()

    ; Ignore tiny accidental clicks
    if (finalW < 25 || finalH < 25) {
        return false
    }

    return {
        x: finalX,
        y: finalY,
        w: finalW,
        h: finalH
    }
}