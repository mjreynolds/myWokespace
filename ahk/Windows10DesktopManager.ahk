#SingleInstance
 /*
  * the next 10 lines setup the hotkeys for the script. 
  */
globalDesktopManager := new JPGIncDesktopManagerClass()
globalDesktopManager.setGoToDesktop("Capslock")
    .setMoveWindowToDesktop("+#")
    .afterGoToDesktop("turnCapslockOff")
    .afterMoveWindowToDesktop("turnCapslockOff")
    .setGoToNextDesktop("Capslock & w")
    .setGoToPreviousDesktop("Capslock & q")
    .setMoveWindowToNextDesktop("Capslock & s")
    .setMoveWindowToPreviousDesktop("Capslock & a")
	;~ .setCloseDesktop("Capslock & x")
	;~ .setNewDesktop("Capslock & n")

return

#c::ExitApp

debugger(message) 
{
	;~ ToolTip, % message
	;~ sleep 100
	return
}
turnCapslockOff()
{
	;if the capslock key is down then set the capslock state to on so that
	;when the user lets go it will change the state to off
	if(GetKeyState("Capslock", "P"))
	{
		SetCapsLockState, On
	} else
	{
		SetCapsLockState , Off
	}
	return
}

/*
 * If we send the keystrokes too quickly you sometimes get a flickering of the screen
 */
send(toSend)
{
	oldDelay := A_KeyDelay
	SetKeyDelay, 30
	
	send, % toSend
	
	SetKeyDelay, % oldDelay
	return 
}

closeMultitaskingViewFrame()
{
	IfWinActive, ahk_class MultitaskingViewFrame
	{
		send("#{tab}")
	}
	return 
}

	
openMultitaskingViewFrame()
{
	IfWinNotActive, ahk_class MultitaskingViewFrame
	{
		send("#{tab}")
		WinWaitActive, ahk_class MultitaskingViewFrame
	}
	return
}


callFunction(possibleFunction)
{
	if(IsFunc(possibleFunction)) 
	{
		%possibleFunction%()
	} else if(IsObject(possibleFunction))
	{
		possibleFunction.Call()
	} else if(IsLabel(possibleFunction))
	{
		gosub, % possibleFunction
	}
	return
}

getDesktopNumberFromHotkey(keyCombo)
{
	number := RegExReplace(keyCombo, "[^\d]", "")
	return number == 0 ? 10 : number
}

getIndexFromArray(searchFor, array) 
{
	loop, % array.MaxIndex()
	{
		if(array[A_index] == searchFor) 
		{
			return A_index
		}
	}
	return -1
}
/* 
 * this function is used when a hotkey combo is pressed. It directs the program to the appropriate function in the appropriate class
 */ 
JPGIncDesktopManagerCallback(desktopManager, functionName, keyCombo)
{
	desktopManager[functionName](getDesktopNumberFromHotkey(keyCombo))
	return
}

class JPGIncHotkeyManager
{
	_notAnAutohotkeyModKeyRegex := "[^#!^+<>*~$]"

	__new() 
	{
		return this
	}

	setupNumberedHotkey(callbackClass, callbackFunctionName, hotkeyKey)
	{
		if(this._doesHotkeyRequireCustomHotkeySyntax(hotkeyKey))
		{
			hotkeyKey .= " & "
		}
		Loop, 10
		{
			this.setupHotkey(callbackClass, callbackFunctionName, hotkeyKey (A_Index - 1))
		}
		return this
	}
	
	setupHotkey(callbackClass, callbackFunctionName, hotkeyKey)
	{
		;~ debugger("Setting up callback: " callbackFunctionName " as " hotkeyKey)
		callback := Func("JPGIncDesktopManagerCallback").Bind(callbackClass, callbackFunctionName, hotkeyKey)
		Hotkey, % hotkeyKey, % callback, On
		return this
	}
	
	/*
	 * If the modifier key used is only a modifier symbol then we don't need to do anything (https://autohotkey.com/docs/Hotkeys.htm#Symbols)
	 * but if it contains any other characters then it means that the hotkey is a combination hotkey then we need to add " & " 
	 */
	_doesHotkeyRequireCustomHotkeySyntax(key)
	{
		return RegExMatch(key, this._notAnAutohotkeyModKeyRegex)
	}
}
;taken from optimist__prime https://autohotkey.com/boards/viewtopic.php?t=9224
class MonitorMapperClass
{
	; This part figures out how many times we need to hit Tab to get to the
	; monitor with the window we are trying to send to another desktop.	
	getRequiredTabCount(hwnd)
	{
		activemonitor := this.getWindowsMonitorNumber(hwnd)
		
		SysGet, monitorcount, MonitorCount
		SysGet, primarymonitor, MonitorPrimary
	 
		If (activemonitor > primarymonitor)
		{
			tabCount := activemonitor - primarymonitor
		}
		else If (activemonitor < primarymonitor)
		{
			tabCount := monitorcount - primarymonitor + activemonitor
		}
		else
		{
			tabCount := 0
		}
		tabCount *= 2	
		
		return tabCount
	}
	
	/*
	 * This function returns the monitor number of the window with the given hwnd
	 */
	getWindowsMonitorNumber(hwnd)
	{
		WinGetPos, x, y, width, height, % "Ahk_id" hwnd
		debugger("Window Position/Size:`nX: " X "`nY: " Y "`nWidth: " width "`nHeight: " height)	
		SysGet, monitorcount, MonitorCount
		SysGet, primarymonitor, MonitorPrimary	
		debugger("Monitor Count: " MonitorCount)	
		Loop %monitorcount%
		{
			SysGet, mon, Monitor, %a_index%
			debugger("Primary Monitor: " primarymonitor "`nDistance between monitor #" a_index "'s right border and Primary monitor's left border (Left < 0, Right > 0):`n" monRight "px")	
			If (x < monRight - width / 2 || monitorcount = a_index)
			{
				return %a_index%
			}
		}
	}
}

class VirtualDesktopManagerClass
{
	__new()
	{	
		debugger("creating th vdm")
		;https://msdn.microsoft.com/en-us/library/windows/desktop/mt186440(v=vs.85).aspx
		CLSID := "{aa509086-5ca9-4c25-8f95-589d3c07b48a}" ;search VirtualDesktopManager clsid
		IID := "{a5cd92ff-29be-454c-8d04-d82879fb3f1b}" ;search IID_IVirtualDesktopManager
		this.iVirtualDesktopManager := ComObjCreate(CLSID, IID)
		
		this.isWindowOnCurrentVirtualDesktopAddress := NumGet(NumGet(this.iVirtualDesktopManager+0), 3*A_PtrSize)
		this.getWindowDesktopIdAddress := NumGet(NumGet(this.iVirtualDesktopManager+0), 4*A_PtrSize)
		this.moveWindowToDesktopAddress := NumGet(NumGet(this.iVirtualDesktopManager+0), 5*A_PtrSize)
		
		return this
	}
	
	getWindowDesktopId(hWnd, tryAgain := true) 
	{
		desktopId := ""
		VarSetCapacity(desktopID, 16, 0)
		;IVirtualDesktopManager::GetWindowDesktopId  method
		;https://msdn.microsoft.com/en-us/library/windows/desktop/mt186441(v=vs.85).aspx
 
		Error := DllCall(this.getWindowDesktopIdAddress, "Ptr", this.iVirtualDesktopManager, "Ptr", hWnd, "Ptr", &desktopID)	
		if(Error != 0) {
			if(tryAgain) 
			{
				return this.getWindowDesktopId(hwnd, false)
			}
			msgbox % "error in getWindowDesktopId " Error
			clipboard := error
		}
 
		return &desktopID
	}
	
	getDesktopGuid(hwnd)
	{
		debugger("getting the guid")
		return this._guidToStr(this.getWindowDesktopId(hwnd))
	}
	; https://github.com/cocobelgica/AutoHotkey-Util/blob/master/Guid.ahk#L36
	_guidToStr(ByRef VarOrAddress)
	{
		;~ debugger(&VarOrAddress " address")
		pGuid := IsByRef(VarOrAddress) ? &VarOrAddress : VarOrAddress
		VarSetCapacity(sGuid, 78) ; (38 + 1) * 2
		if !DllCall("ole32\StringFromGUID2", "Ptr", pGuid, "Ptr", &sGuid, "Int", 39)
			throw Exception("Invalid GUID", -1, Format("<at {1:p}>", pGuid))
		return StrGet(&sGuid, "UTF-16")
	}
	
	
	isDesktopCurrentlyActive(hWnd) 
	{
		;IVirtualDesktopManager::IsWindowOnCurrentVirtualDesktop method
		;Indicates whether the provided window is on the currently active virtual desktop.
		;https://msdn.microsoft.com/en-us/library/windows/desktop/mt186442(v=vs.85).aspx
		Error := DllCall(this.isWindowOnCurrentVirtualDesktopAddress, "Ptr", this.iVirtualDesktopManager, "Ptr", hWnd, "IntP", onCurrentDesktop)
		if(Error != 0) {
			msgbox % "error in isDesktopCurrentlyActive " Error
			clipboard := error
		}

		return onCurrentDesktop
	}
	
	moveWindowToDesktop(hWnd, ByRef desktopId)
	{
		Error := DllCall(this.moveWindowToDesktopAddress, "Ptr", this.iVirtualDesktopManager, "Ptr", activeHwnd, "Ptr", &desktopId)
		if(Error != 0) {
			msgbox % "error in moveWindowToDesktop " Error "but no error?"
			clipboard := error
		}
		return this
	}
	
	getCurrentDesktop(hWnd) 
	{
		desktopId := ""
		VarSetCapacity(desktopID, 16, 0)

		Error := DllCall(this.getCurrentDesktopAddress, "Ptr", this.iVirtualDesktopManagerInternal, "Ptr", &desktopID)	
		if(Error != 0) {
			msgbox % "error in getWindowDesktopId " Error
			clipboard := error
		}

		return &desktopID
	}
}
class DesktopMapperClass
{	
	desktopIds := []
	
	__new(virtualDesktopManager)
	{
		this._setupGui()
		this.virtualDesktopManager := virtualDesktopManager
		return this
	}
	
	/*
	 * Populates the desktopIds array with the current virtual deskops according to the registry key
	 */
	mapVirtualDesktops() 
	{
		regIdLength := 32
		RegRead, DesktopList, HKEY_CURRENT_USER, SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
	
		this.desktopIds := []
		while, true
		{
			desktopId := SubStr(DesktopList, ((A_index-1) * regIdLength) + 1, regIdLength)
			if(desktopId) 
			{
				this.desktopIds.Insert(this._idFromReg(desktopId))
			} else
			{
				break
			}
		}
		debugger("there are " this.desktopIds.MaxIndex() " things")
		return this
	}
	
	/*
	 * Gets the desktop id of the current desktop
	 */
	getCurrentDesktopId()
	{
		hwnd := this.hwnd
		Gui %hwnd%:show, NA ;show but don't activate
		winwait, % "Ahk_id " hwnd
		
		guid := this.virtualDesktopManager.getDesktopGuid(hwnd)

		Gui %hwnd%:hide 
		;if you don't wait until it closes (and sleep a little) then the desktop the gui is on can get focus
		WinWaitClose,  % "Ahk_id " hwnd
		sleep 50 

		return this._idFromGuid(guid)
	}
	
	getNumberOfDesktops() 
	{
		this.mapVirtualDesktops()
		return this.desktopIds.maxIndex()
	}
	
	/*
	 * returns the number of the current desktop
	 */
	getDesktopNumber()
	{
		this.mapVirtualDesktops()
		currentDesktop := this.getCurrentDesktopId()
		
		return this._indexOfId(currentDesktop)
	}
	
	/*
	 * takes an ID from the registry and extracts the last 16 characters (which matches the last 16 characters of the GUID)
	 */
	_idFromReg(regString) 
	{
		return SubStr(regString, 17)
	}
	
	/*
	 * takes an ID from microsofts IVirtualDesktopManager and extracts the last 16 characters (which matches the last 16 characters of the ID from the registry)
	 */
	_idFromGuid(guidString)
	{
		return SubStr(RegExReplace(guidString, "[-{}]"), 17)
	}

	_indexOfId(guid) 
	{
		loop, % this.desktopIds.MaxIndex()
		{
			debugger("looking for `n" guid "`n" this.desktopIds[A_index])
			if(this.desktopIds[A_index] == guid) 
			{
				debugger("Found it! desktop is " A_Index)
				return A_Index
			}
		}
		return -1
	}

	_setupGui()
	{
		Gui, new
		Gui, show
		Gui, +HwndMyGuiHwnd
		this.hwnd := MyGuiHwnd
		Gui, hide
		return this
	}
}
class JPGIncWindowMoverClass
{
	moveActiveWindowToDesktopFunctionName := "moveActiveWindowToDesktop"
	moveToNextFunctionName := "moveActiveWindowToNextDesktop"
	moveToPreviousFunctionName := "moveActiveWindowToPreviousDesktop"
	_postMoveWindowFunctionName := ""
	
	__new()
	{
		this.desktopMapper := new DesktopMapperClass(new VirtualDesktopManagerClass())
		this.monitorMapper := new MonitorMapperClass()
		return this
	}
	
	doPostMoveWindow() 
	{
		callFunction(this._postMoveWindowFunctionName)
		return this
	}
	
	moveActiveWindowToDesktop(targetDesktop, follow := false)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		if(currentDesktop == targetDesktop) 
		{
			return this
		}
		numberOfTabsNeededToSelectActiveMonitor := this.monitorMapper.getRequiredTabCount(WinActive("A"))
		numberOfDownsNeededToSelectDesktop := this.getNumberOfDownsNeededToSelectDesktop(targetDesktop, currentDesktop)
		
		openMultitaskingViewFrame()
		send("{tab " numberOfTabsNeededToSelectActiveMonitor "}")
		send("{Appskey}m{Down " numberOfDownsNeededToSelectDesktop "}{Enter}")
		closeMultitaskingViewFrame()
		this.doPostMoveWindow()
		
		return	this
	}
	
	moveActiveWindowToNextDesktop(follow := false)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		return this.moveActiveWindowToDesktop(currentDesktop + 1, follow)
	}
	
	moveActiveWindowToPreviousDesktop(follow := false)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		if(currentDesktop == 1) 
		{
			return this
		}
		return this.moveActiveWindowToDesktop(currentDesktop - 1, follow)
	}	
	
	getNumberOfDownsNeededToSelectDesktop(targetDesktop, currentDesktop)
	{
		; This part figures out how many times we need to push down within the context menu to get the desktop we want.	
		if (targetDesktop > currentDesktop)
		{
			targetDesktop -= 2
		}
		else
		{
			targetdesktop--
		}
		return targetDesktop
	}
}
class JPGIncDesktopChangerClass
{
	goToDesktopCallbackFunctionName := "goToDesktop"
	nextDesktopFunctionName := "goToNextDesktop"
	PreviousDesktopFunctionName := "goToPreviousDesktop"
	_postGoToDesktopFunctionName := ""
	
	__new() 
	{
		this.desktopMapper := new DesktopMapperClass(new VirtualDesktopManagerClass())
		return this
	}

	goToNextDesktop(keyCombo := "")
	{
		send("^#{right}")
		return this.doPostGoToDesktop()
	}
	
	goToPreviousDesktop(keyCombo := "")
	{
		send("^#{left}")
		return this.doPostGoToDesktop()
	}
	
	/*
	 *	swap to the given virtual desktop number
	 */
	goToDesktop(newDesktopNumber) 
	{
		debugger("in go to desktop changing to " newDesktopNumber)
		this._makeDesktopsIfRequired(newDesktopNumber)
			._goToDesktop(newDesktopNumber)
		closeMultitaskingViewFrame()
		this.doPostGoToDesktop()
		return this
	}
	
	_makeDesktopsIfRequired(minimumNumberOfDesktops)
	{
		currentNumberOfDesktops := this.desktopMapper.getNumberOfDesktops()
		loop, % minimumNumberOfDesktops - currentNumberOfDesktops
		{
			send("#^d")
		}
		
		return this
	}

	_goToDesktop(newDesktopNumber)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		direction := currentDesktop - newDesktopNumber
		distance := Abs(direction)
		debugger("distance to move is " distance "`ndirectin" direction)
		if(direction < 0)
		{
			debugger("Sending right! " distance "times")
			send("^#{right " distance "}")
		} else
		{
			send("^#{left " distance "}")
		}
		return this
	}
	
	doPostGoToDesktop() 
	{
		this._activateTopMostWindow()
		callFunction(this.postGoToDesktopFunctionName)
		return this
	}
	
	_activateTopMostWindow()
	{
		If(WinActive("ahk_exe explorer.exe"))
		{
			send !{tab}
		}
		return this
	}
}

class JPGIncDesktopManagerClass
{	
	__new()
	{
		this._desktopChanger := new JPGIncDesktopChangerClass()
		this._windowMover := new JPGIncWindowMoverClass()
		this.hotkeyManager := new JPGIncHotkeyManager()
		
		this._setupDefaultHotkeys()
		return this
	}
	
	/*
	 * Public API to setup virtual desktop hotkeys and callbacks
	 */
	setGoToDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupNumberedHotkey(this._desktopChanger, this._desktopChanger.goToDesktopCallbackFunctionName, hotkeyKey)
		return this
	}
	setMoveWindowToDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupNumberedHotkey(this._windowMover, this._windowMover.moveActiveWindowToDesktopFunctionName, hotkeyKey)
		return this
	}
	
	setGoToNextDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this._desktopChanger, this._desktopChanger.nextDesktopFunctionName, hotkeyKey)
		return this
	}
	
	setGoToPreviousDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this._desktopChanger, this._desktopChanger.PreviousDesktopFunctionName, hotkeyKey)
		return this
	}
	
	setMoveWindowToNextDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this._windowMover, this._windowMover.moveToNextFunctionName, hotkeyKey)
		return this
	}
	
	setMoveWindowToPreviousDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this._windowMover, this._windowMover.moveToPreviousFunctionName, hotkeyKey)
		return this
	}
	
	setCloseDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this, "closeDesktop", hotkeyKey)
		return this
	}
	
	setNewDesktop(hotkeyKey)
	{
		this.hotkeyManager.setupHotkey(this, "newDesktop", hotkeyKey)
		return this
	}
	
	afterGoToDesktop(functionLabelOrClassWithCallMethodName)
	{
		this._desktopChanger.postGoToDesktopFunctionName := functionLabelOrClassWithCallMethodName
		return this
	}
	
	afterMoveWindowToDesktop(functionLabelOrClassWithCallMethodName)
	{
		this._windowMover.postMoveWindowFunctionName := functionLabelOrClassWithCallMethodName
		return this
	}
	
	/*
	 * end public api
	 */
	
	newDesktop(hotkeyCombo := "")
	{
		send("^#d")
		return this
	}
	
	closeDesktop(hotkeyCombo := "")
	{
		send("^#{f4}")
		return this
	}
	
	_setupDefaultHotkeys()
	{
		Hotkey, IfWinActive, ahk_class MultitaskingViewFrame
		this.hotkeyManager.setupNumberedHotkey(this._desktopChanger, this._desktopChanger.goToDesktopCallbackFunctionName, "")
		Hotkey, If
		return this
	}
}