; Mouse Wheel Tab Scroll 4 Chrome & Mozilla
; -------------------------------
; Scroll though Chrome & Mozilla tabs with your mouse wheel when hovering over the tab bar.
; If the Chrome window is inactive when starting to scroll, it will be activated.

;; Based on a script made by someone(Xsoft?) on the internet
;; Translate to AHK2.0 and modify, Add some hotkeys, Shadow912kage@gmail.com

; AutoHotKey 2.0 configuration
#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance force ; Determines whether a script is allowed to run again when it is already running.
#UseHook False ; Using the keyboard hook is usually preferred for hotkeys - but here we only need the mouse hook.
InstallMouseHook
A_MaxHotkeysPerInterval := 1000 ; Avoids warning messages for high speed wheel users.
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.

TraySetIcon "mouse.png" ; Icon source from https://icooon-mono.com/
A_IconTip := "Mousewheel tab scroll for Chrome &&& Mozilla v2.3.0"
;; Why can't I display the character '&'... NEED twice '&' escape
;;; [v2.0.2] can't display the character '&' on the 'A_IconTip' - AutoHotkey Community
;;;  https://www.autohotkey.com/boards/viewtopic.php?f=86&t=116067
;;;  c++ - How to display an ampersand in a Windows system tray prompt? - Stack Overflow
;;;  https://stackoverflow.com/questions/10276225/how-to-display-an-ampersand-in-a-windows-system-tray-prompt

/* DO NOT WORK like an X Mouse, probably due to a Windows update...
SetTimer Xmouse, 100
Xmouse()
{
  MouseGetPos ,, &id
  If !WinActive(id)
    WinActivate "ahk_id " id
}
*/

/* X Mouse
https://elmony.gitlab.io/posts/2020/20200222_userpreferencesmask.html
=====
[HKEY_CURRENT_USER\Control Panel\Desktop]
"ActiveWndTrkTimeout"=dword:00000064
"UserPreferencesMask"=hex:91,00,27,80,10,00,00,00
-----
# UserPreferencesMask = 90,12,07,80,10,00,00,00 の場合で説明
# 先頭1バイト: 0x90
0x90(1001 0000)
Bit00 Active window tracking: 0
Bit01 Menu animation: 0
Bit02 Slide open combo boxes (Combo box animation): 0
Bit03 Smooth-scroll list boxes (List box smooth scrolling): 0 
Bit04 Gradient captions: 1 
Bit05 Keyboard cues): 0
Bit06 Active window tracking Z order: 0
Bit07 Hot tracking: 1
*/

; Registry handling for X Mouse
RegKey := "HKCU\Control Panel\Desktop"
RegValUPrefMask := "UserPreferencesMask"
RegValAWndTrkTout := "ActiveWndTrkTimeout"
XMFlgBitMsk := 0x0100000000000000
OnStartUPMaskStr := 0
OnStartAWTToutStr := 0
GetUPMaskAWTTout(&UPMask, &AWTTout) ; Get registory values of "UserPreferencesMask" and "ActiveWndTrkTimeout"
{
	global RegKey, RegValUPrefMask, RegValAWndTrkTout
	UPMask := RegRead(RegKey, RegValUPrefMask)
	AWTTout := RegRead(RegKey, RegValAWndTrkTout, "")
}
GetXMouseFlag(UPMask) ; Get X Mouse flag
{
	Global XMFlgBitMsk
	Return (XMFlgBitMsk & Integer("0x" UPMask))?True:False
}
SetUPMaskAWTTout(UPMask, AWTTout) ; Set registory values of "UserPreferencesMask" and "ActiveWndTrkTimeout"
{
	global RegKey, RegValUPrefMask, RegValAWndTrkTout
	RegWrite UPMask, "REG_BINARY", RegKey, RegValUPrefMask
	RegWrite AWTTout, "REG_DWORD", RegKey, RegValAWndTrkTout
}
GetUPMask(UPMask, XMFlag) ; Get X Mouse flag
{
	Global XMFlgBitMsk
	If XMFlag
		Return Format("{:X}", XMFlgBitMsk | Integer("0x" UPMask))
	Else
		Return Format("{:X}", ~XMFlgBitMsk & Integer("0x" UPMask))
}

; Get default values from registory.
GetUPMaskAWTTout(&OnStartUPMaskStr, &OnStartAWTToutStr)
DfltXMFlag := GetXMouseFlag(OnStartUPMaskStr)
DfltAWTTout := OnStartAWTToutStr

; X Mouse's menu and dialog
A_TrayMenu.Add() ; Add a separator line to AutoHotKey's menu
A_TrayMenu.Add("X Mouse settings", ConfXMouseFnc) ; Add menu item to AutoHotKey's menu

; X Mouse's Gui object
ConfXMouseGui := Gui("ToolWindow", "X Mouse")
ConfXMouseGui.OnEvent("Close", CnclFncXMouse)
ConfXMEnbCkBx := ConfXMouseGui.Add("CheckBox", "vEnbXMouse", "The Activate and focus the window when the mouse hovers it.")
ConfXMEnbCkBx.Value := DfltXMFlag
ConfXMouseGui.Add("Text", "section xp+16 y+10", "The delay time of active and focus (1-1000) [msec]:")
ConfXMouseGui.Add("Edit")
ConfXMDlyTime := ConfXMouseGui.Add("UpDown", "vDlTXMouse Range1-1000", DfltAWTTout)
ConfXMouseGui.Add("Text", "xm", "If you change the settings, It becomes effective after restarting Windows.")
OkBtnConfXMouse := ConfXMouseGui.Add("Button", "Default w80 section", "Ok")
OkBtnConfXMouse.OnEvent("Click", OkFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Store changed settings")
CnclBtnConfXMouse := ConfXMouseGui.Add("Button", "w80 section xm y+10", "Cancel")
CnclBtnConfXMouse.OnEvent("Click", CnclFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Discard changed settings")
DfltBtnConfXMouse := ConfXMouseGui.Add("Button", "w80 section xm y+10", "Default")
DfltBtnConfXMouse.OnEvent("Click", DfltFncXMouse)
ConfXMouseGui.Add("Text", "ys+5", "Load default (on the start) settings")

SavedXMouse := ConfXMouseGui.Submit() ; Create initial saved Gui object

; X Mouse's callback functions: Ok/Cancel/Default button, Menu item
OkFncXMouse(*)
{
	Global
	SavedXMouse := ConfXMouseGui.Submit()
	SetUPMaskAWTTout(GetUPMask(OnStartUPMaskStr, SavedXMouse.EnbXMouse), SavedXMouse.DlTXMouse)
}
CnclFncXMouse(*)
{
	Global
	ConfXMEnbCkBx.Value := SavedXMouse.EnbXMouse
	ConfXMDlyTime.Value := SavedXMouse.DlTXMouse
	ConfXMouseGui.Submit()
}
DfltFncXMouse(*)
{
	Global
	ConfXMEnbCkBx.Value := DfltXMFlag
	ConfXMDlyTime.Value := DfltAWTTout
}
ConfXMouseFnc(*)
{
	Global
	ConfXMouseGui.Show()
}
; ***** End of X Mouse *****

; Target window classes
GroupAdd "TargetApp", "ahk_class Chrome_WidgetWin_1" ; Google Chrome and MS Edge, etc...
GroupAdd "TargetApp", "ahk_class MozillaWindowClass" ; Mozilla Firefox and Thunderbird, etc...
; Hotkeys
#HotIf WinActive("ahk_group TargetApp")
; This script configuration
WTBH := 45 ; Window Tab Bar's Height, ad hoc value...
DCIT := 500 ; Double Click Interval Time[msec]

;; Tab wheel scroll on the tab bar
WheelUp::
WheelDown::
{
  global WTBH

  MouseGetPos , &ypos, &id
  If ypos < WTBH
  {
    If A_ThisHotkey = "WheelUp"
      Send "^{PgUp}"
    Else
      Send "^{PgDn}"
  }
  Else
  {
    If A_ThisHotkey = "WheelUp"
      Send "{WheelUp}"
    Else
      Send "{WheelDown}"
  }
}

/* ;; Tab wheel scroll with right button on the tab page
~RButton & WheelUp::
~RButton & WheelDown::
{
  global WTBH

  MouseGetPos , &ypos
  If ypos >= WTBH
  {
	If A_ThisHotkey = "~RButton & WheelUp"
	  Send "^{PgUp}"
	Else
	  Send "^{PgDn}"
  }
}
*/

;; Close tab by double right click on the tab page
~RButton::
{
  global WTBH, DCIT

  MouseGetPos , &ypos
  If ypos >= WTBH
  {
    If (A_PriorHotkey != "~RButton" or A_TimeSincePriorHotkey > DCIT)
	{
    ; Case single click or press other button, action
	  KeyWait "RButton"
	  Return
    }
	; Case double click
	Send "^w"
  }
}

/* ;; Remove the comment-out, if your mouse doesn't have a wheel tilt button.
;; Horizontal wheel scroll with left button on the tab page
~LButton & WheelUp::
~LButton & WheelDown::
{
  global WTBH

  MouseGetPos , &ypos
  If ypos >= WTBH
  {
	If A_ThisHotkey = "~LButton & WheelUp"
	  Send "{WheelLeft}"
	Else
	  Send "{WheelRight}"
  }
}
*/
#HotIf ; ***** End of WinActive("ahk_group TargetApp") block *****

; Optional mouse button's hotkeys
CBWT := 0.5 ; Clipboard Waiting Time[sec]
SSQU := "https://www.google.com/search?q=" ; Search Site Query URL
TSQU := "https://translate.google.com/?text=" ; Translate Site Query URL
TSQO := "&sl=en&tl=ja&op=translate" ; Translate Site Query Option
PSQO := "&tbm=isch" ; Picture Search Query Option

ClipSaved := ""
SaveClipBd()
{
  global ClipSaved := ClipboardAll() ; Save the entire clipboard to a variable of your choice.
  A_Clipboard := "" ; Start off empty to allow ClipWait to detect when the text has arrived.
}
RstrClipBd()
{
  global ClipSaved
  A_Clipboard := ClipSaved ; Restore the original clipboard. Note the use of A_Clipboard (not ClipboardAll).
  ClipSaved := "" ; Free the memory in case the clipboard was very large.
}

;; Search selected text, using a clipboard as a temporary
F24::
{
  global CBWT, SSQU

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run SSQU A_Clipboard
  RstrClipBd()
}
;; Tranlate selected text, using a clipboard as a temporary
F23::
{
  global CBWT, TSQU, TSQO

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run TSQU A_Clipboard TSQO
  RstrClipBd()
}
;; Search Picture with selcted text, using a Clipboard as a temporary
F22::
{
  global CBWT, TSQU, PSQO

  SaveClipBd()
  Send "^c"
  If ClipWait(CBWT) ; Wait for the clipboard to contain text.
    Run SSQU A_Clipboard PSQO
  RstrClipBd()
}