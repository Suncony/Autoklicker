#Requires AutoHotkey v2.0
#UseHook
#NoTrayIcon
SendMode "Event"
SetKeyDelay 0, 1
SetMouseDelay 0

#Include "KeysManager.ahk"
manager := KeysManager()

Hotkey("*" manager.reload_key, (*) => Reload())
Hotkey("*" manager.exitapp_key, (*) => ExitApp())
Hotkey("*" manager.toggle_key, (*) => manager.toggleKeyBinds())

manager.loadKeys()
for k in manager.keys
    manager.bindKey(k)

#Include "GUI.ahk"