#Requires AutoHotkey v2.0
#Include "KeysManager.ahk"
#NoTrayIcon
#UseHook
SendMode "Event"

*F7::Reload
*F8::ExitApp

manager := KeysManager()
manager.loadKeys()
for k in manager.keys
    manager.bindKey(k)

*F1:: {
    manager.toggleKeyBinds()
}

#Include "GUI.ahk"