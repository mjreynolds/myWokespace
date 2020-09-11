# pyWokespace

The goal of this project is to create utility scripts and/or application
that helps a user save and restore all application windows.  This means
storing each window name, exec, size and location on the desktop to file 
and being able to read the file and reopen and position all the application
windows.

First features may simply be python or powershell scripts that can save 
or load window layout locations to/from file.

## Future features:

Running the utility at startup and loading the last used layout and sitting in the system tray.  

Switching layouts if windows is idle and at certain schedules - work layout
from 5am to 6pm, entertainment mode from 6pm to 5am.

Switch layouts with hot key or popup up displaying layout settings file picker from hot key.

Be able to leverage windows 10 virtual desktops.

## Microsoft PowerToys

Make sure to download and install PowerToys which includes a FanzyZones utility to level up the
window snapping possibilities.

[PowerToys](https://github.com/microsoft/PowerToys)

## Possible python libraries

[Python-UIAutomation-for-Windows](https://github.com/yinkaisheng/Python-UIAutomation-for-Windows)

[pywinauto](https://github.com/pywinauto/pywinauto)

[pyautogui](https://github.com/asweigart/pyautogui)

## Other automatino tools

[AutoHotkey](https://www.autohotkey.com/)