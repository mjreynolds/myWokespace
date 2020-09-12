; Source: https://autohotkey.com/board/topic/65340-saving-and-restoring-windows-layout/

#NoEnv
   Delim := "|" ; change this if any of your window names are likely to contain this character
   AHKWinTitle := "WinLayout"
   ExcludeList := "Start" . Delim . "Program Manager" . Delim . AHKWinTitle ; don't want the Start Menu, Desktop or the AHK script window to be included
   
   EnumAddress := RegisterCallback( "EnumWindowsProc", "Fast" )
   DetectHiddenWindows, Off  ; Due to fast-mode, this setting will go into effect for the callback too.

   Gui, Add, Button, gSaveLayout w200, Save Layout
   Gui, Add, Button, gRestoreLayout w200, Restore Layout
   Gui, Show,, %AHKWinTitle%
Return   

SaveLayout:
   Output := ""
   DllCall( "EnumWindows", "UInt", EnumAddress, "UInt", 0 )

   FileSelectFile, SaveFileName, S24, \MyLayout.layout, Please Choose where to save layout file
   If ( ErrorLevel )
   {
      If ( SaveFileName ) ; user didn't cancel
         MsgBox, Error getting save file name!
     
      Return
   }

   FileDelete, %SaveFileName%
   FileAppend, %Output%, %SaveFileName%
   If ( ErrorLevel )
      MsgBox, Error saving file!

Return

RestoreLayout:
   FileSelectFile, OpenFileName, 1,, Please Choose layout file to open
   If ( ErrorLevel )
   {
      If ( OpenFileName ) ; user didn't cancel
         MsgBox, Error getting open file name!
     
      Return
   }

   Send, #m ; minimise all windows to start
   
   FileRead, LayoutFile, %OpenFileName%

   Sort, LayoutFile, F ReverseDirection D  ; Reverses the list

   Loop, parse, LayoutFile, `r, `n
   {
      If ( !A_LoopField )
         Continue

      Loop, parse, A_LoopField, %Delim%
      {
         If ( A_Index = 1 )
            WinTitle := A_LoopField
         Else If ( A_Index = 2 )
            X := A_LoopField
         Else If ( A_Index = 3 )
            Y := A_LoopField
         Else If ( A_Index = 4 )
            Width := A_LoopField
         Else If ( A_Index = 5 )
            Height := A_LoopField
         Else If ( A_Index = 6 )
            SavedMinMax := A_LoopField
      }

      If ( !WinExist( WinTitle ) )
         Continue

      WinRestore, %WinTitle% ; make sure the window is not minimised or maximised to start

      If ( SavedMinMax > 0 ) ; window was maximised so maximise it
         WinMaximize, %WinTitle%
      Else If ( SavedMinMax < 0 ) ; window was minimised so minimise it
         WinMinimize, %WinTitle%
      Else ; window was not minimised or maximised, so just move it to where it was
         WinMove, %WinTitle%,, X, Y, Width, Height

      WinSet, Top,, %WinTitle% ; these 3 lines should result in the current window being made "on top", restoring the z-order as the list is parsed
      WinSet, TopMost, On, %WinTitle%
      WinSet, TopMost, Off, %WinTitle%
   }
Return

ReverseDirection( a1, a2, offset )
{
    return offset  ; Offset is positive if a2 came after a1 in the original list; negative otherwise.
}
   
EnumWindowsProc( hwnd, lParam )
{
   global Output, ExcludeList, Delim
   WinGetTitle, WinTitle, ahk_id %hwnd%

   If ( InStr( ExcludeList, WinTitle ) || WinTitle = "" )
      Return true

   WinGetPos, X, Y, Width, Height, ahk_id %hwnd%
   WinGet, WinMinMaxState, MinMax, ahk_id %hwnd%

   Output .= WinTitle . Delim . X . Delim . Y . Delim . Width . Delim . Height . Delim . WinMinMaxState . "`n"

   Return true  ; continue until all windows have been enumerated (returning false or nothing would tell it to stop)
}

GuiClose:
GuiEscape:
   ExitApp
Return
