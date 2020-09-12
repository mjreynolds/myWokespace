; WinGet all the existing programs
; loop all those programs
; WinGetPos all those positions and size
; IniRead/Write those values
; WinMove to move and resize the programs

; Virtual Desktop

; To create a new virtual windows :
; send #^d

; to move between virtual windows:
; send #^{right}
; send #^{left}

; Dllcall() and https://docs.microsoft.com/de-de/windows/win32/api/shobjidl_core/nn-shobjidl_core-ivirtualdesktopmanager

; IVirtualDesktopManager::GetWindowDesktopId	Gets the identifier for the virtual desktop hosting the provided top-level window.
; IVirtualDesktopManager::IsWindowOnCurrentVirtualDesktop	Indicates whether the provided window is on the currently active virtual desktop.
; IVirtualDesktopManager::MoveWindowToDesktop	Moves a window to the specified virtual desktop.

DetectHiddenWindows, On

WinGet windows, List

Loop %windows%
{
	id := windows%A_Index%
    WinGetTitle wt, ahk_id %id%   
	OutputDebug, %A_Now%: %wt%
}

WinGet, id, list,,
count:=
Loop, %id%
  {
  window := id%A_Index%
  WinGetTitle, title, ahk_id %window%
  window%A_Index%=%title%
  count++
  }
Loop, %count%
  {
  show:=window%A_index%
  OutputDebug, Window%A_index% is:`n`n%show%
  }
