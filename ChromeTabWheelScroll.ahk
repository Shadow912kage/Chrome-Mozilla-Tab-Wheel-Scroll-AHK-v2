; Mouse Wheel Tab Scroll 4 Chrome & Mozilla - v3.0
; -------------------------------
; Scroll though Chrome & Mozilla tabs with your mouse wheel when hovering over the tab bar.
; If the window is inactive when starting to scroll, it will be activated.
; -------------------------------
; Copyright(c) 2023 Shadow912kage@gmail.com (MURASE, Takashi)
; Released under the MIT license
; http://www.opensource.org/licenses/mit-license.php

;; Based on a script made by someone(Xsoft?) on the internet
;; Convert to AHK2.0 to fix it and add some hotkeys. Shadow912kage@gmail.com

;;; My indentation coding style is two spaces.

; AutoHotKey 2.0 configuration
#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.
#SingleInstance force ; Determines whether a script is allowed to run again when it is already running.
#UseHook False ; Using the keyboard hook is usually preferred for hotkeys - but here we only need the mouse hook.
InstallMouseHook
A_MaxHotkeysPerInterval := 1000 ; Avoids warning messages for high speed wheel users.
SendMode "Input" ; Recommended for new scripts due to its superior speed and reliability.

TraySetIcon "wheel.png" ; Icon source from https://icooon-mono.com/
A_IconTip := "Mousewheel tab scroll for Chrome &&& Mozilla v3.0"
;; Why can't I display the character '&'... NEED twice '&' escape
;;; [v2.0.2] can't display the character '&' on the 'A_IconTip' - AutoHotkey Community
;;;  https://www.autohotkey.com/boards/viewtopic.php?f=86&t=116067
;;;  c++ - How to display an ampersand in a Windows system tray prompt? - Stack Overflow
;;;  https://stackoverflow.com/questions/10276225/how-to-display-an-ampersand-in-a-windows-system-tray-prompt

; Target window classes
GroupAdd "TargetApp", "ahk_class Chrome_WidgetWin_1" ; Google Chrome and MS Edge, etc...
GroupAdd "TargetApp", "ahk_class MozillaWindowClass" ; Mozilla Firefox and Thunderbird, etc...
; Hotkeys
#HotIf WinActive("ahk_group TargetApp")
; This script configuration
DCIT := 500 ; Double Click Interval Time[msec]

; Sub functions
GetChromeVer(id)
{
	PrcName := WinGetProcessName(id) 
	PrcPath := WinGetProcessPath(id)
	PrcRoot := RegExReplace(PrcPath, PrcName "$", "")
	Loop Files, PrcRoot "*", "D"
	{
		If RegExMatch(A_LoopFileName, "\d+(\.\d+)*", &match)
			Return match[0]
	}
	Return ""
}
GetMozillaVer(id)
{
	PrcName := WinGetProcessName(id) 
	PrcPath := WinGetProcessPath(id)
	AppPath := RegExReplace(PrcPath, PrcName "$", "application.ini")
	Return IniRead(AppPath, "App", "Version", "")
}
GetTabbarRange(id)
{ ; NOTICE! Doesn't distinguish between window and fullscreen mode.
	ChrmProc := "chrome.exe"
	ChrmMapKey := "Chrome"
	ChrmTabRange := Object()
	ChrmTabRange.Top := 0
	ChrmTabRange.Btm := 45
	EdgeProc := "msedge.exe"
	EdgeMapKey := "MSEdge"
	EdgeTabRange := Object()
	EdgeTabRange.Top := 0
	EdgeTabRange.Btm := 40
	FxProc := "firefox.exe"
	FxMapKey := "Fx"
	FxTabRange := Object()
	FxTabRange.Top := 0
	FxTabRange.Btm := 48
	TBProc := "thunderbird.exe"
	TB102MapKey := "TB102" ; Before Supernova
	TB102TabRange := Object()
	TB102TabRange.Top := 0
	TB102TabRange.Btm := 48
	TB115MapKey := "TB115" ; After Supernova
	TB115TabRange := Object()
	TB115TabRange.Top := 39
	TB115TabRange.Btm := 69
	TabRange :=
		Map(ChrmMapKey, ChrmTabRange, EdgeMapKey, EdgeTabRange, FxMapKey, FxTabRange, TB102MapKey, TB102TabRange, TB115MapKey, TB115TabRange)

	PrcName := WinGetProcessName(id) 
	Version := ""
	MapKey := ""
	Switch(PrcName)
	{
		Case ChrmProc:
			Version := GetChromeVer(id)
			MapKey := ChrmMapKey
		Case EdgeProc:
			Version := GetChromeVer(id)
			MapKey := EdgeMapKey
		Case FxProc:
			Version := GetMozillaVer(id)
			MapKey := FxMapKey
		Case TBProc:
			Version := GetMozillaVer(id)
			TB115 := ">=115.0"
			If VerCompare(Version, TB115)
				MapKey := TB115MapKey
			Else
				MapKey := TB102MapKey
	}
	If MapKey
		Return TabRange[MapKey]
	Return ""
}
OnTabbar(ypos, id)
{
	If !(TabbarRange := GetTabbarRange(id))
		Return False
	If (TabbarRange.Top <= ypos) && (ypos <= TabbarRange.Btm)
		Return True
	Return False
}
OnTabpage(ypos, id)
{
	If !(TabbarRange := GetTabbarRange(id))
		Return False
	If TabbarRange.Btm < ypos
		Return True
	Return False
}

;; Tab wheel scroll on the tab bar
WheelUp::
WheelDown::
{
  MouseGetPos , &ypos, &id
	If OnTabbar(ypos, id)
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
  MouseGetPos , &ypos, &id
	If OnTabpage(ypos, id)
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
  MouseGetPos , &ypos, &id
	If OnTabpage(ypos, id)
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
  MouseGetPos , &ypos, &id
	If OnTabpage(ypos, id)
  {
	If A_ThisHotkey = "~LButton & WheelUp"
	  Send "{WheelLeft}"
	Else
	  Send "{WheelRight}"
  }
}
*/
#HotIf ; ***** End of WinActive("ahk_group TargetApp") block *****