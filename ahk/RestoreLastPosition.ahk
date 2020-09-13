
; Automatically Restore Previous Window Size/Pos

; To make this script run when windows starts, make sure RegistryAdd.ahk is in the same directory as this script, run this script, and it will be added to the registry. Then delete RegistryAdd.ahk
; #Include *i RegistryAdd.ahk

; To easily remove the previously added registry entry, make sure RegistryRemove.ahk is in the same directory as this script, run this script, and it will be removed from the registry. Then delete RegistryRemove.ahk
; #Include *i RegistryRemove.ahk

#NoTrayIcon

#SingleInstance Force
#Persistent
#NoEnv
SetWinDelay, 50
Process, Priority, , Normal

MatchList := ""

; Build the MatchList
WinGet, id, list,,, Program Manager
Loop, %id%
{
    this_id := id%A_Index%
	if (MatchList = "")
	MatchList := this_id
	else
	MatchList := MatchList . "," . this_id 
}

;Filter - only programs listed here have their size and position automatically managed,otherwise without this filter wierd malfunctions occur with dialog boxes being resized to their parent program and such...
Filter = xulrunner.exe,firefox.exe,notepad.exe,chrome.exe,notepad++.exe
Title_Filter =		;add every new title on a new line
(
Automatically Restore Last Window Position For Each Process - AutoHotkey Community - Mozilla Firefox
)

; ExclusionList		--- use this as alternative to filter above,i.e this will exclude applications below from automated resize/relocate
ExclusionList = ShellExperienceHost.exe,SearchUI.exe,notepad++.exe,cpuz.exe,gpu-z.0.3.3.exe


; The main program loop, which manages window positions/sizes and saves their last known configuration to an ini file in the script directory.
Loop,
{
Title_Filter_reInit:		;a patch to allow terminating further checks when a filtered title is active within a filtered application

	Sleep, 350
	WinGet, active_id, ID, A
	if active_id not in %MatchList% ; Then this is a new window ID! So, check if it has a configuration saved.
	{
		MatchList := MatchList . "," . active_id ; This window ID is not new anymore!
		WinGet, active_ProcessName, ProcessName, A
		WinGetClass, active_Class, A
		IniRead, savedSizePos, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%
		; MsgBox, debug marker 1  %pClass%
		if (savedSizePos != "ERROR" AND active_Class != "MultitaskingViewFrame" AND active_class != "Shell_TrayWnd" ) ; Then a saved configuration exists, size/move the window!
		{
			StringSplit OutputArray, savedSizePos,`,
			if (active_ProcessName = "explorer.exe" AND active_Class != "CabinetWClass")
			{
				
			}
			else
			{
			;Last minute check to make sure Active windows matches specified classname
			WinGetClass, active_Class, A
			IniRead, pClass, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%_pClass
			if ( pClass = active_Class )
				{
				if ( active_Class != #32770 )	;filter open/save dialog boxes
					{
					WinMove, A,, OutputArray1, OutputArray2, OutputArray3, OutputArray4
					; MsgBox, debug marker 0 %pClass% v %active_Class%
					}
				}
			}
		}
		else ; No saved configuration exists, save the current window size/pos as a configuration instead!
		{
			WinGetPos X, Y, Width, Height, A
			WinGet, active_ProcessName, ProcessName, A
			WinGetClass, active_Class, A
			If (X != "" AND Y != "" AND Width != "" AND Height != "" AND Width > 0 AND Height > 0 AND active_Class != "MultitaskingViewFrame" AND active_class != "Shell_TrayWnd")
			{
				if (active_ProcessName = "explorer.exe" AND active_Class != "CabinetWClass")
				{
					
				}
				else if active_ProcessName not in %ExclusionList%
				{
				if active_ProcessName in %Filter%																					;TWEAK to only add specific programs to windowConfiguration
					{
					;Title_Filter patch
					WinGetActiveTitle, this_activeTitle
					IfInString, Title_Filter, this_activeTitle	;if active window is filtered by title, return to beginning of loop until active window is unfiltered
						Goto, Title_Filter_reInit
											
					
					WinGetClass, active_Class, A
					IniRead, pClass, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%_pClass
					;To PREVENT SIZE OF DIALOG BOX BEING ASSIGNED AS SIZE AND LOCATION OF MAIN PROCESS WINDOW
					if ( pClass = active_Class OR pClass = "ERROR" )		;if process has not yet been assigned class value or if active window matches process class write!.
						{
						IniWrite %X%`,%Y%`,%Width%`,%Height%, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%
						}
					WinGetClass, exePrimaryClass, ahk_exe %active_ProcessName%
					if ( pClass = "ERROR" )		;to make sure the class tied to an exe is only written when the window is first detected,so it's position can be updated but not it's class name.
						{
						; MsgBox, debug marker 2  %ExEpClass%  - %exePrimaryClass%
						IniWrite %exePrimaryClass%, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%_pClass
						}
					}
				}
			}
		}
	}
	else ; Save/overwrite the active window size and position to a file with a link to the processname, for later use.
	{
		WinGetPos X, Y, Width, Height, A
		WinGet, active_ProcessName, ProcessName, A
		WinGetClass, active_Class, A
		If (X != "" AND Y != "" AND Width != "" AND Height != "" AND Width > 0 AND Height > 0 AND active_Class != "MultitaskingViewFrame" AND active_class != "Shell_TrayWnd")
		{
			if (active_ProcessName = "explorer.exe" AND active_Class != "CabinetWClass")
			{
				
			}
			else if active_ProcessName not in %ExclusionList%
			{
			if active_ProcessName in %Filter%																					;TWEAK to only add specific programs to windowConfiguration
				{
				;Title_Filter patch
				WinGetActiveTitle, this_activeTitle
				IfInString, Title_Filter, this_activeTitle	;if active window is filtered by title, return to beginning of loop until active window is unfiltered
					Goto, Title_Filter_reInit

				
				WinGetClass, active_Class, A
				IniRead, pClass, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%_pClass
				;To PREVENT SIZE OF DIALOG BOX BEING ASSIGNED AS SIZE AND LOCATION OF MAIN PROCESS WINDOW
				if ( pClass = active_Class OR pClass = "ERROR" )		;if process has not yet been assigned class value or if active window matches process class write!.
					{
					IniWrite %X%`,%Y%`,%Width%`,%Height%, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%
					}
				WinGetClass, exePrimaryClass, ahk_exe %active_ProcessName%
				if ( pClass = "ERROR" )		;to make sure the class tied to an exe is only written when the window is first detected,so it's position can be updated but not it's class name.
					{
					; MsgBox, debug marker 3  %ExEpClass%  - %exePrimaryClass%
					IniWrite %exePrimaryClass%, %A_ScriptDir%\WindowSizePosLog.ini, Process Names, %active_ProcessName%_pClass
					}
				}
			}
		}
	}
}
Return

