; https://www.autohotkey.com/boards/viewtopic.php?t=12388&p=64256

hWnd := WinExist("Untitled - Notepad")
MsgBox % "IsWindowOnCurrentVirtualDesktop: " IsWindowOnCurrentVirtualDesktop(hWnd)
ExitApp

;Indicates whether the provided window is on the currently active virtual desktop.
IsWindowOnCurrentVirtualDesktop(hWnd) {
	;IVirtualDesktopManager interface
	;Exposes methods that enable an application to interact with groups of windows that form virtual workspaces.
	;https://msdn.microsoft.com/en-us/library/windows/desktop/mt186440(v=vs.85).aspx
	CLSID := "{aa509086-5ca9-4c25-8f95-589d3c07b48a}" ;search VirtualDesktopManager clsid
	IID := "{a5cd92ff-29be-454c-8d04-d82879fb3f1b}" ;search IID_IVirtualDesktopManager
	IVirtualDesktopManager := ComObjCreate(CLSID, IID)
	
	;IVirtualDesktopManager::IsWindowOnCurrentVirtualDesktop method
	;Indicates whether the provided window is on the currently active virtual desktop.
	;https://msdn.microsoft.com/en-us/library/windows/desktop/mt186442(v=vs.85).aspx
	Error := DllCall(NumGet(NumGet(IVirtualDesktopManager+0), 3*A_PtrSize), "Ptr", IVirtualDesktopManager, "Ptr", hWnd, "IntP", onCurrentDesktop)

	;free IVirtualDesktopManager
	ObjRelease(IVirtualDesktopManager)
	
	;return
	if !(Error=0) ;S_OK
		return false, ErrorLevel := true
	return onCurrentDesktop, ErrorLevel := false
}