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
        ; OutputDebug Format("The iterator is pointing at {1} and count is {2}.`n", [DesktopIter, i]*)
        ; Break out if we find a match in the list. If we didn't find anything, keep the
        ; old guess and pray we're still correct :-D.
        if (DesktopIter = CurrentDesktopId) {
            CurrentDesktop := i + 1
            ; OutputDebug Format("Current desktop number is {1} with an ID of {2}.`n", [CurrentDesktop, DesktopIter]*)
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
    ; OutputDebug "Current Process Id: " . ProcessId
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
    ; OutputDebug "Current Session Id: " . SessionId
    return SessionId
}

; This function lists all open windows
listWindows() {
    win_ids := WinGetList()
    for win_id in win_ids {
        ;id := windows%A_Index%
        win_title := WinGetTitle(win_id)
        win_path := WinGetProcessPath(win_id)
        WinGetClientPos X, Y, W, H, win_id
        win_class := WinGetClass(win_id)
        OutputDebug Format("Title: {1}`n", win_title)
        OutputDebug Format("Path: {1}`n", win_path)
        OutputDebug Format("Class: {1}`n", win_class)
        OutputDebug Format("X: {1}, Y: {2}, Width: {3}, Height: {4}`n", [X, Y, W, H]*)
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
        OutputDebug Format("[invalid] target: {1} current: {2}", [targetDesktop, CurrentDesktop]*)
        return
    }

    ; Go right until we reach the desktop we want
    while(CurrentDesktop < targetDesktop) {
        Send "^#{Right}"
        CurrentDesktop++
        ; OutputDebug Format("[right] target: {1} current: {2}", [targetDesktop, CurrentDesktop]*)
    }

    ; Go left until we reach the desktop we want
    while(CurrentDesktop > targetDesktop) {
        Send "^#{Left}"
        CurrentDesktop--
        ; OutputDebug Format("[left] target: {1} current: {2}", [targetDesktop, CurrentDesktop]*)
    }
}

; Main
mapDesktopsFromRegistry()
;OutputDebug "[loading] desktops: ".DesktopCount." current: ".CurrentDesktop

; Loop through all Desktops
i := 1
while (i <= DesktopCount) {
    switchDesktopByNumber(i)
    OutputDebug Format("===Desktop {2} of {1}===`n", [DesktopCount, i]*)
    listWindows()
    i++
}

/*
Title: MnIT Outlook
Path: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
Class: Chrome_WidgetWin_1
X: -1514, Y: 0, Width: 1513, Height: 1039
Target: "C:\Program Files (x86)\Google\Chrome\Application\chrome_proxy.exe"  --profile-directory=Default --app-id=aaigkeeeimecfcbccjnkpiflcofcamel
Start In: "C:\Program Files (x86)\Google\Chrome\Application"

Title: myWokespace.ah2 - myWokespace - Visual Studio Code
Path: C:\Users\mikro\AppData\Local\Programs\Microsoft VS Code\Code.exe
Class: Chrome_WidgetWin_1
X: -1, Y: -1, Width: 1922, Height: 1042

Title: Chat | Microsoft Teams
Path: C:\Users\mikro\AppData\Local\Microsoft\Teams\current\Teams.exe
Class: Chrome_WidgetWin_1
X: 1920, Y: 0, Width: 1280, Height: 1040

Title: Skype for Business 
Path: C:\Program Files\Microsoft Office\Office16\lync.exe
Class: CommunicatorMainWindowClass
X: -1919, Y: 1, Width: 400, Height: 1038

Title: OutputDebug - Syntax & Usage | AutoHotkey and 5 more pages - Personal 2 - Microsoft​ Edge
Path: C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe
Class: Chrome_WidgetWin_1
X: -31992, Y: -32000, Width: 144, Height: 20
Target: "C:\Program Files (x86)\Microsoft\Edge Dev\Application\msedge.exe" --profile-directory="Profile 2" [or Profile 1 or Default]

Title: Discord
Path: C:\Users\mikro\AppData\Local\Discord\app-0.0.308\Discord.exe
Class: Chrome_WidgetWin_1
X: 2560, Y: 0, Width: 1280, Height: 1040

X: 2560, Y: 0, Width: 1280, Height: 1040
Title: Inbox - Gmail ‎- Mail
Path: C:\Windows\System32\ApplicationFrameHost.exe
Class: ApplicationFrameWindow
X: -1920, Y: -8, Width: 1920, Height: 1048
Target: "C:\Windows\explorer.exe" "shell:AppsFolder\microsoft.windowscommunicationsapps_8wekyb3d8bbwe!microsoft.windowslive.mail"

Title: Cherry Glazerr - Wasted Nun - YouTube
Path: C:\Program Files (x86)\Google\Chrome\Application\chrome.exe
Class: Chrome_WidgetWin_1
X: 1921, Y: 0, Width: 958, Height: 512
Target: ?
*/