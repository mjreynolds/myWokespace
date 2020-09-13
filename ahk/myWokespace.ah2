; Globals
DesktopCount := 2 ; Windows starts with 2 desktops at boot
CurrentDesktop := 1 ; Desktop count is 1-indexed (Microsoft numbers them this way)

; This function examines the registry to build an accurate list of the current virtual desktops and which one we're currently on.
; Current desktop UUID appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\1\VirtualDesktops
; List of desktops appears to be in HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops

mapDesktopsFromRegistry() {
    global CurrentDesktop, DesktopCount
    
    ; Get the current desktop UUID. Length should be 32 always, but there's no guarantee this couldn't change in a later Windows release so we check.
    IdLength := 32
    SessionId := getSessionId()
    if (SessionId) {
        regPath := Format("HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\{1}\VirtualDesktops", SessionId)
        CurrentDesktopId := RegRead(regPath, "CurrentVirtualDesktop")
        if (CurrentDesktopId) {
            IdLength := StrLen(CurrentDesktopId)
        }
    }
    
    ; Get a list of the UUIDs for all virtual desktops on the system
    regPath := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops"
    DesktopList := RegRead(regPath, "VirtualDesktopIDs")
    if (DesktopList) {
        DesktopListLength := StrLen(DesktopList)
        ; Figure out how many virtual desktops there are
        DesktopCount := DesktopListLength / IdLength
    }
    else {
        DesktopCount := 1
    }
    ; Parse the REG_DATA string that stores the array of UUID's for virtual desktops in the registry.
    i := 0
    while (CurrentDesktopId and i < DesktopCount) {
        StartPos := (i * IdLength) + 1
        DesktopIter := SubStr(DesktopList, StartPos, IdLength)
        OutputDebug Format("The iterator is pointing at {1} and count is {2}.", [DesktopIter, i])
        ; Break out if we find a match in the list. If we didn't find anything, keep the
        ; old guess and pray we're still correct :-D.
        if (DesktopIter = CurrentDesktopId) {
            CurrentDesktop := i + 1
            OutputDebug Format("Current desktop number is {1} with an ID of {2}.", [CurrentDesktop, DesktopIter])
            break
        }
        i++
    }
}

; This functions finds out ID of current session.
getSessionId() {
    ProcessId := DllCall("GetCurrentProcessId", "UInt")
    if !ProcessId {
        OutputDebug "Error getting current process id: " . A_LastError
        return
    }
    OutputDebug "Current Process Id: " . ProcessId
    try {
        SessionId := 0
        SessionId := DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
    } catch e {
        OutputDebug "An exception was thrown" e
    }
    if !SessionId {
        OutputDebug "Error getting session id: " . A_LastError
        return
    }
    OutputDebug "Current Session Id: " . SessionId
    return SessionId
}

; This function lists all open windows
listWindows() {
    win_ids := WinGetList()
    for win_id in win_ids {
        ;id := windows%A_Index%
        win_title := WinGetTitle(win_id)
        win_path := WinGetProcessPath(win_id)
        OutputDebug Format("Title: {1}`n", win_title)
        OutputDebug Format("Path: {1}`n", win_path)
    }
}

; This function switches to the desktop number provided.
switchDesktopByNumber(targetDesktop) {
    global CurrentDesktop, DesktopCount
    
    ; Re-generate the list of desktops and where we fit in that. We do this because
    ; the user may have switched desktops via some other means than the script.
    mapDesktopsFromRegistry()
    
    ; Don't attempt to switch to an invalid desktop
    if (targetDesktop > DesktopCount || targetDesktop < 1) {
        OutputDebug Format("[invalid] target: {1} current: {2}", [targetDesktop, CurrentDesktop])
        return
    }

    ; Go right until we reach the desktop we want
    while(CurrentDesktop < targetDesktop) {
        Send "^#{Right}"
        CurrentDesktop++
        OutputDebug Format("[right] target: {1} current: {2}", [targetDesktop, CurrentDesktop])
    }

    ; Go left until we reach the desktop we want
    while(CurrentDesktop > targetDesktop) {
        Send "^#{Left}"
        CurrentDesktop--
        OutputDebug Format("[left] target: {1} current: {2}", [targetDesktop, CurrentDesktop])
    }
}

; Main
mapDesktopsFromRegistry()
;OutputDebug "[loading] desktops: ".DesktopCount." current: ".CurrentDesktop

; Loop through all Desktops
i := 1
while (i <= DesktopCount) {
    switchDesktopByNumber(i)
    listWindows()
    OutputDebug i
    ;OutputDebug "[loading] desktops: ".DesktopCount." current: ".CurrentDesktop
    i++
}