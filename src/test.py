from pywinauto import application
from pywinauto import Desktop

windows = Desktop(backend="win32").windows(top_level_only=True, visible_only=False, enabled_only=False)
for w in windows:
    if w.window_text():
        print(w.window_text())
        print(w.rectangle()) 

import win32gui

def winEnumHandler( hwnd, ctx ):
    if win32gui.IsWindowVisible( hwnd ):
        print (hex(hwnd), win32gui.GetWindowText( hwnd ))

win32gui.EnumWindows( winEnumHandler, None )

