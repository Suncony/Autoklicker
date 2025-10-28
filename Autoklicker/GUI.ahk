#Requires AutoHotkey v2.0

version := "v1.1.0"
title := "Autoklicker " version

A_TrayMenu.Delete()
A_TrayMenu.Add("Restore", restore)
restore(*){
    A_IconHidden := true
    MacroGUI.Show()
}
A_TrayMenu.Add("Close", (*) => ExitApp())
A_TrayMenu.Default := "Restore"
A_TrayMenu.ClickCount := 1
TraySetIcon("icon.ico")
A_IconTip := title

MacroGUI := Gui(, title)
MacroGUI.SetFont(, "Consolas")
MacroGUI.OnEvent("Close", (*) => ExitApp())
MacroGUI.OnEvent("Size", minimizeToTray)
minimizeToTray(GuiObj, MinMax, *) {
    if MinMax == -1 {
        A_IconHidden := false
        GuiObj.Hide()
    }
}

Tabs := MacroGUI.Add("Tab3", , ["Hotkeys", "Settings"])

; HOTKEYS TAB
Tabs.UseTab("Hotkeys")

button_width := "w70"
button_height := "r2"
button_spacing := "y+5"

MacroGUI.Add("Text", "Section", "Bound hotkey(s):")
KeyList := MacroGUI.Add("ListBox", "w200 r6 ReadOnly VScroll")
updateKeyList()

SetButton := MacroGUI.Add("Button", "ys yp " button_width " " button_height, "SET KEY")
SetButton.OnEvent("Click", showSetGUI)

DeleteButton := MacroGUI.Add("Button", "y+8 " button_width " " button_height, "DELETE KEY")
DeleteButton.OnEvent("Click", showDeleteGUI)

; SETTINGS TAB
Tabs.UseTab("Settings")

MacroGUI.Add("GroupBox", "w280 r3", "Preset Keys")

MacroGUI.Add("Text", "Section xp+10 yp+18", "Toggle:")
ToggleKeyEdit := MacroGUI.Add("Edit", "w60 ReadOnly", IniRead("settings.ini", "KEYBINDS", "toggle_key"))

MacroGUI.Add("Text", "ys x+39", "Reload:")
ReloadKeyEdit := MacroGUI.Add("Edit", "w60 ReadOnly", IniRead("settings.ini", "KEYBINDS", "reload_key"))

MacroGUI.Add("Text", "ys x+39", "ExitApp:")
ExitAppKeyEdit := MacroGUI.Add("Edit", "w60 ReadOnly", IniRead("settings.ini", "KEYBINDS", "exitapp_key"))

AutoklickerMode := MacroGUI.Add("Checkbox", "Section xm+18 ym+104", "Autoklicker mode")
AutoklickerMode.Value := IniRead("settings.ini", "SETTINGS", "autoklicker")
AutoklickerMode.OnEvent("Click", toggleAutoklicker)

PresetKeysButton := MacroGUI.Add("Button", "w130 r1 yp-5 x+25", "Change preset keys")
PresetKeysButton.OnEvent("Click", showPresetKeysGUI)

; SAVE BUTTON
Tabs.UseTab()

SaveButton := MacroGUI.Add("Button", "w149 r1", "SAVE")
SaveButton.OnEvent("Click", GUISaveSettings)

HelpButton := MacroGUI.Add("Button", "yp x+5 w149 r1", "HOW TO USE")
HelpButton.OnEvent("Click", showHelpGUI)

MacroGUI.Show()

; FUNCTIONS

showSetGUI(*) {

    SetGUI := Gui(, title)
    SetGUI.SetFont(, "Consolas")
    SetGUI.OnEvent("Close", (*) => SetGUI.Destroy())

    SetGUI.Add("Text", "w120", "Enter key name: ")
    SetGUI.Add("Edit", "vKeyName w80 Lowercase Limit")
    SetGUI.Add("Text", "ys w120", "Enter interval: ")
    SetGUI.Add("Edit", "vKeyInterval w80 Limit4", "25")
    SetGUI.Add("Text", "x+0 yp+3", "ms")
    SetGUI.Add("Text", "ys", "Enter delay: ")
    SetGUI.Add("Edit", "vKeyDelay w80 Limit4", "500")
    SetGUI.Add("Text", "x+0 yp+3", "ms")

    SetGUI.Add("Button", "Default xs y+10 w50", "Done").OnEvent("Click", setEnteredKey)

    SetGUI.Show()

    setEnteredKey(*) {

        Value := SetGUI.Submit(false)
        name := Value.KeyName
        interval := Value.KeyInterval
        delay := Value.KeyDelay

        try 
            manager.setKey(name, interval, delay)
        catch as err {
            MsgBox("Error: " err.Message, title)
            return
        }

        updateKeyList()
        SetGUI.Destroy()
    }
}

showDeleteGUI(*) {

    DeleteGUI := Gui(, title)
    DeleteGUI.SetFont(, "Consolas")
    DeleteGUI.OnEvent("Close", (*) => DeleteGUI.Destroy())

    DeleteGUI.Add("Text", "ym+3 r2", "Enter key name: ")
    DeleteGUI.Add("Edit", "vKeyName x+0 yp-2 w80 Limit")

    DeleteGUI.Add("Button", "Default xs y+10 w50", "Done").OnEvent("Click", deleteEnteredKey)

    DeleteGUI.Add("Button", "x+40 w80", "Delete all").OnEvent("Click", deleteAllKeys)

    DeleteGUI.Show()

    deleteEnteredKey(*) {

        Value := DeleteGUI.Submit(false)
        name := Value.KeyName

        try 
            manager.deleteKey(name)
        catch as err {
            MsgBox("Error: " err.Message, title)
            return
        }

        updateKeyList()
        DeleteGUI.Destroy()
    }

    deleteAllKeys(*) {
        manager.deleteAllKeys()
        updateKeyList()
        DeleteGUI.Destroy()
    }
}

showPresetKeysGUI(*) {

    PresetKeysGUI := Gui(, title)
    PresetKeysGUI.SetFont(, "Consolas")
    PresetKeysGUI.OnEvent("Close", (*) => PresetKeysGUI.Destroy())

    PresetKeysGUI.Add("Text", "w80", "Toggle:")
    PresetKeysGUI.Add("Edit", "vToggleKey w60 Lowercase Limit", manager.toggle_key)
    PresetKeysGUI.Add("Text", "ys w80", "Reload:")
    PresetKeysGUI.Add("Edit", "vReloadKey w60 Lowercase Limit", manager.reload_key)
    PresetKeysGUI.Add("Text", "ys w80", "ExitApp: ")
    PresetKeysGUI.Add("Edit", "vExitAppKey w60 Lowercase Limit", manager.exitapp_key)

    PresetKeysGUI.Add("Button", "Default xs y+10 w50", "Apply").OnEvent("Click", applyPresetKeys)

    PresetKeysGUI.Show()

    applyPresetKeys(*) {

        Value := PresetKeysGUI.Submit(false)
        toggle_name := Value.ToggleKey
        reload_name := Value.ReloadKey
        exitapp_name := Value.ExitAppKey
        arr := [toggle_name, reload_name, exitapp_name]

        try {
            manager.checkDuplicatePresetKeys(arr)
            manager.bindPresetKey("toggle", toggle_name)
            manager.bindPresetKey("reload", reload_name)
            manager.bindPresetKey("exitapp", exitapp_name)
        } catch as err {
            MsgBox("Error: " err.Message, title)
            return
        }

        ToggleKeyEdit.Value := toggle_name
        ReloadKeyEdit.Value := reload_name
        ExitAppKeyEdit.Value := exitapp_name

        PresetKeysGUI.Destroy() 
    }
}

GUISaveSettings(*) {
    manager.saveKeys()
    IniWrite(manager.toggle_key, "settings.ini", "KEYBINDS", "toggle_key")
    IniWrite(manager.reload_key, "settings.ini", "KEYBINDS", "reload_key")
    IniWrite(manager.exitapp_key, "settings.ini", "KEYBINDS", "exitapp_key")
    IniWrite(manager.autoklicker, "settings.ini", "SETTINGS", "autoklicker")
    MsgBox("Hotkeys & Settings saved", title)
}

updateKeyList() {
    KeyList.Delete()
    intitial_string := Format("{:-14}{:-13}{}", "Key name", "Interval", "Delay")
    KeyList.Add([intitial_string])
    for k in manager.keys {
        key_string := Format("{:-14}{:-13}{}", k.name, k.interval " ms", k.delay " ms")
        KeyList.Add([key_string])
    }
}

toggleAutoklicker(*) {
    manager.autoklicker := !manager.autoklicker
    manager.toggleKeyBindsOff
    for k in manager.keys
        manager.bindKey(k)
}

showHelpGUI(*) {

    HelpGUI := Gui(, title)
    HelpGUI.SetFont(, "Consolas")
    HelpGUI.OnEvent("Close", (*) => HelpGUI.Destroy())

    HelpGUI.Add(
        "Edit",
        "w330 r20 ReadOnly",
        "F1 to toggle key bindings (default is OFF)`n"
        "F7 to reload Autoklicker`n"
        "F8 to force stop Autoklicker`n"
        "`n"
        '"SET" to bind a hotkey, F1 to turn ON, then click/hold depending on the mode`n'
        "`n"
        "Interval is how fast the keys fire`n"
        "Delay is time before key starts firing`n"
        "`n"
        "Most keys are named the same as on your keyboard`n"
        "Mouse buttons are:`n"
        "- Left: lbutton`n"
        "- Middle: mbutton`n"
        "- Right: rbutton`n"
        "For complicated key names, just give up (visit AHKv2 Help Site)`n"
        "`n"
        "Semi-auto mode (default): Hold to rapid-fire keys, release to stop`n"
        "`n"
        "Autoklicker mode (checkbox): Press to enable rapid-fire, press again to stop`n"
        "`n"
        "For the sake of your PC, don't fire too many keys at once`n"
        "Also not recommended to set interval below 25, unless you really need it`n"
        "In case of emergency, either use:`n"
        "- F1 to toggle off`n"
        "- F7 to reload`n"
        "- F8 to force stop (safest)`n"
        "`n"
        "Program made by Suncony (Blacc Man, da proest man aliv)`n"
        "Icon made by luck (ma wifey)"
    )

    HelpGUI.Show()
}