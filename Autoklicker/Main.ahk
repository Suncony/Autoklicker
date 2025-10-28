#Requires AutoHotkey v2.0
#UseHook
#NoTrayIcon
SendMode "Event"

#Include "KeysManager.ahk"
manager := KeysManager()

Hotkey("*" manager.reload_key, (*) => Reload())
Hotkey("*" manager.exitapp_key, (*) => ExitApp())
Hotkey("*" manager.toggle_key, (*) => manager.toggleKeyBinds())

manager.loadKeys()
for k in manager.keys
    manager.bindKey(k)

#Include "GUI.ahk"