WinGet, id, List,,, Program Manager
Loop, %id%
{
    this_id := id%A_Index%
    WinActivate, ahk_id %this_id%
    WinGetClass, this_class, ahk_id %this_id%
    WinGetTitle, this_title, ahk_id %this_id%
    OutputDebug, %A_Index% of %id%`nahk_id %this_id%`nahk_class %this_class%`n%this_title%
}

WinGet windows, List
Loop %windows%
{
	id := windows%A_Index%
	WinGet, OutputVar, ProcessPath, WinTitle, WinText, ExcludeTitle, ExcludeText
    WinGetTitle wt, ahk_id %id%   
	WinGet ww, ProcessPath, %wt%
	OutputDebug, %A_Now%: %ww%
	OutputDebug, %A_Now%: %wt%
	WinGet, wmm, MinMax , %wt%
	OutputDebug, %A_Now%: %wmm%
}
