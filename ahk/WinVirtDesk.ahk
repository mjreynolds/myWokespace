; By /u/yet_another_usr - WTFPL
; Credits:
;	* Tariq Porter for gdip.ahk (x64 support by Rseding91) & code to draw numbers in the tray (mods to the latter for 64-bit by me, Tahoma variant by Kudos)
;	* NickoTin & Grabacr07 for reversing the internal virtual desktop API

#NoEnv
SetBatchLines -1
ListLines Off
#NoTrayIcon
#KeyHistory 0
#SingleInstance force
#Persistent
SendMode Input
SetWorkingDir %A_ScriptDir%
#Include myWokespace/ahk/gdip_all.ahk

main(), return

main()
{
	OnExit, cleanup

	static IVirtualDesktopNotificationService, dwCookie, pToken := Gdip_Startup()
	static ImmersiveShell	:= ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}")
	global ppDesktopManager := ComObjQuery(ImmersiveShell, "{C5E0CDCA-7B6E-41B2-9FC4-D93975CC467B}", "{AF8DA486-95BB-4460-B3B7-6E7A6B2962B5}")

	if (!pToken)
		ExitApp

	SetTrayNumber(GetCurrentDesktopNumber())
	OnMessage(DllCall("RegisterWindowMessage", Str, "TaskbarCreated"), "WM_TASKBARCREATED")

	IVirtualDesktopNotification_startMonitoring(ImmersiveShell, IVirtualDesktopNotificationService, dwCookie)
	ObjRelease(ImmersiveShell)
	return

cleanup:
	IVirtualDesktopNotification_removeAndDelete(IVirtualDesktopNotificationService, dwCookie)
	if (ppDesktopManager)
		ObjRelease(ppDesktopManager)
	if (pToken)
		Gdip_Shutdown(pToken)
	ExitApp
}

GetCurrentDesktopNumber(pDesktop:=0)
{
	retval := -1
	if (!pDesktop)
		pDesktop := GetCurrentDesktop()
	else
		ObjAddRef(pDesktop)

	if (pDesktop) {
		if (GetDesktopGUID(pDesktop, currentDesktopGuid))
			retval := searchDesktops(&currentDesktopGuid)
		ObjRelease(pDesktop)
	}
	return retval
}

WM_TASKBARCREATED()
{
	Menu, Tray, NoIcon
	Reload
}

IVirtualDesktopNotification_CurrentVirtualDesktopChanged(this_, pDesktopOld, pDesktopNew)
{
	if (pDesktopNew)
		SetTrayNumber(GetCurrentDesktopNumber(pDesktopNew))
	return 0
}

; --- Desktop utility functions ---

GetCurrentDesktop()
{
	global ppDesktopManager
	return DllCall(vTable(ppDesktopManager, 6), "Ptr", ppDesktopManager, "Ptr*", pDesktop) == 0 ? pDesktop : 0 ; IVirtualDesktopManagerInternal::GetCurrentDesktop
}

GetDesktopGUID(pDesktop, ByRef outGUID)
{
	VarSetCapacity(outGUID, 16, 0)
	return DllCall(vTable(pDesktop, 4), "Ptr", pDesktop, "Ptr", &outGUID) == 0 ; IVirtualDesktop::GetID
}

searchDesktops(pGuid)
{
	global ppDesktopManager
	static IID_IVirtualDesktop
	if !VarSetCapacity(IID_IVirtualDesktop)
		GUIDFromString(IID_IVirtualDesktop, "{FF72FFDD-BE7E-43FC-9C03-AD81681E88E4}")

	DllCall(vTable(ppDesktopManager, 7), "Ptr", ppDesktopManager, "Ptr*", pDesktops) ; IVirtualDesktopManagerInternal::GetDesktops
	if (pDesktops) {
		DllCall(vTable(pDesktops, 3), "Ptr", pDesktops, "UIntP", num) ; IObjectArray::GetCount
		Loop %num%
		{
			DllCall(vTable(pDesktops, 4), "Ptr", pDesktops, "UInt", A_Index - 1, "Ptr", &IID_IVirtualDesktop, "Ptr*", VirtualDesktop) ; IObjectArray::GetAt
			if (VirtualDesktop) {
				if (GetDesktopGUID(VirtualDesktop, Guid)) {
					if (DllCall("ntdll\RtlCompareMemory", "Ptr", pGuid, "Ptr", &Guid, "UInt", 16) == 16) {
						ObjRelease(VirtualDesktop), ObjRelease(pDesktops)
						return A_Index
					}
				}
				ObjRelease(VirtualDesktop)
			}
		}
		ObjRelease(pDesktops)
	}
	return -1
}

;-- Tray funcs --

SetTrayNumber(num, TextColour=0xffffffff, BackgroundColour=0x00ffffff)
{
	static sizeof_NOTIFYICONDATA := A_PtrSize == 8 ? 976 : 444
	static offsetof_uID	   := A_PtrSize * 2
	static offsetof_uFlags := 4 + offsetof_uID
	static offsetof_hIcon  := offsetof_uFlags + 4 + A_PtrSize

	if (num < 0 || num > 99)
		return false
	if !hFamily := Gdip_FontFamilyCreate("Tahoma")
		return false
	Gdip_DeleteFontFamily(hFamily)
	pBitmap := Gdip_CreateBitmap(16, 16), G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_FillRectangle(G, pBrush := Gdip_BrushCreateSolid(BackgroundColour), 0, 0, 16, 16)
	Gdip_DeleteBrush(pBrush)
	pBrush := Gdip_BrushCreateSolid(TextColour)
	Gdip_TextToGraphics(G, num, "x-4 y0 w24 h20 Center r4 s14 Bold c" pBrush, "Tahoma")
	Gdip_DeleteBrush(pBrush)
	hIcon := Gdip_CreateHICONFromBitmap(pBitmap)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap)
	VarSetCapacity(nid, sizeof_NOTIFYICONDATA, 0)
	NumPut(sizeof_NOTIFYICONDATA, nid)
	NumPut(A_ScriptHwnd, nid, A_PtrSize, "Ptr")
	NumPut(1028, nid, offsetof_uID), NumPut(0x2, nid, offsetof_uFlags), NumPut(hIcon, nid, offsetof_hIcon)
	Menu, Tray, Icon
	DllCall("shell32\Shell_NotifyIcon", "UInt", 0x1, "Ptr", &nid)
	DestroyIcon(hIcon)
	return true
}

;-- IVirtualDesktopNotification implementation --

IVirtualDesktopNotification_QueryInterface(this_, riid, ppvObject)
{
	static IID_IUnknown					   := "{00000000-0000-0000-C000-000000000046}"
		 , IID_IVirtualDesktopNotification := "{C179334C-4295-40D3-BEA1-C654D965605A}"

	iid := GUIDToString(riid)
	if (iid = IID_IVirtualDesktopNotification || iid = IID_IUnknown)
	{
		NumPut(this_, ppvObject+0)
		return 0 ;// S_OK
	}

	NumPut(0, ppvObject+0)
	return 0x80004002 ;// E_NOINTERFACE
}

IVirtualDesktopNotification_AddRef(this_) {
	return 1
}

IVirtualDesktopNotification_Release(this_) {
	return 1
}

IVirtualDesktopNotification_VirtualDesktopCreated(this_, pDesktop) {
	return 0
}

IVirtualDesktopNotification_VirtualDesktopDestroyBegin(this_, pDesktopDestroyed, pDesktopFallback) {
	return 0
}

IVirtualDesktopNotification_VirtualDesktopDestroyFailed(this_, pDesktopDestroyed, pDesktopFallback) {
	return 0
}

IVirtualDesktopNotification_VirtualDesktopDestroyed(this_, pDesktopDestroyed, pDesktopFallback) {
	return 0
}

IVirtualDesktopNotification_ViewVirtualDesktopChanged(this_, pView) {
	return 0
}

IVirtualDesktopNotification_Vtbl(clear:=false)
{
	static vtable
	if !VarSetCapacity(vtable) {
		funcs := ["QueryInterface", "AddRef", "Release", "VirtualDesktopCreated"
				 ,"VirtualDesktopDestroyBegin", "VirtualDesktopDestroyFailed", "VirtualDesktopDestroyed"
				 ,"ViewVirtualDesktopChanged", "CurrentVirtualDesktopChanged"]

		VarSetCapacity(vtable, funcs.Length() * A_PtrSize)

		for i, vtEntry in funcs {
			newfunc := "IVirtualDesktopNotification_" . vtEntry
			if (IsFunc(newfunc)) {
				NumPut(RegisterCallback(newfunc, "Fast"), vtable, (i-1) * A_PtrSize)
			} else {
				VarSetCapacity(vtable, 0)
				return 0
			}
		}
	} else {
		if (clear) {
			elements := VarSetCapacity(vtable) / A_PtrSize
			Loop %elements%
				DllCall("GlobalFree", "Ptr", NumGet(vtable, (A_Index - 1) * A_PtrSize), "Ptr")
			VarSetCapacity(vtable, 0)
			return 0
		}
	}
	return &vtable
}

IVirtualDesktopNotification_getInstance(clear:=false)
{
	static client
	if !VarSetCapacity(client) {
		vtable := IVirtualDesktopNotification_Vtbl()
		if (!vtable)
			return 0
		VarSetCapacity(client, A_PtrSize)
		NumPut(vtable, client)
	} else {
		if (clear) {
			IVirtualDesktopNotification_Vtbl(true)
			VarSetCapacity(client, 0)
			return 0
		}
	}
	return &client
}

IVirtualDesktopNotification_startMonitoring(ImmersiveShell, ByRef IVirtualDesktopNotificationService, ByRef pdwCookie)
{
	if (!ImmersiveShell)
		return false

	IVirtualDesktopNotificationService := ComObjQuery(ImmersiveShell, "{a501fdec-4a09-464c-ae4e-1b9c21b84918}", "{0cd45e71-d927-4f15-8b0a-8fef525337bf}")
	if (!IVirtualDesktopNotificationService)
		return false

	; IVirtualDesktopNotificationService::Register
	if (DllCall(vTable(IVirtualDesktopNotificationService, 3), "Ptr", IVirtualDesktopNotificationService, "Ptr", IVirtualDesktopNotification_getInstance(), "UIntP", pdwCookie) != 0) {
		ObjRelease(IVirtualDesktopNotificationService)
		return false
	}
	return true
}

IVirtualDesktopNotification_removeAndDelete(ByRef IVirtualDesktopNotificationService, ByRef dwCookie)
{
	if (IVirtualDesktopNotificationService && dwCookie) {
		; IVirtualDesktopNotificationService::Unregister
		DllCall(vTable(IVirtualDesktopNotificationService, 4), "Ptr", IVirtualDesktopNotificationService, "UInt", dwCookie)
		pdwCookie := 0
		ObjRelease(IVirtualDesktopNotificationService), IVirtualDesktopNotificationService := 0
		IVirtualDesktopNotification_getInstance(true)
	}
}

;-- COM helpers --

vTable(ptr, n) {
return NumGet(NumGet(ptr+0), n*A_PtrSize)
}

GUIDFromString(ByRef GUID, sGUID) ; Converts a string to a binary GUID
{
	VarSetCapacity(GUID, 16, 0)
	DllCall("ole32\CLSIDFromString", "Str", sGUID, "Ptr", &GUID)
}

GUIDToString(pGUID)
{
	VarSetCapacity(string, 78)
	DllCall("ole32\StringFromGUID2", "Ptr", pGUID, "Str", string, "Int", 39)
	return string
}