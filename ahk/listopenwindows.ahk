WinGet windows, List
Loop %windows%
{
	id := windows%A_Index%
    WinGetTitle wt, ahk_id %id%   
	OutputDebug, %A_Now%: %wt%
}
