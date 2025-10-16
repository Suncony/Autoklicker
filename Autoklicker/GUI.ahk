#Requires AutoHotkey v2.0

version := "v1.03"
title := "Autoklicker " version

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

button_width := "w70"
button_height := "r2"
button_spacing := "y+5"

SetButton := MacroGUI.Add("Button", button_width " " button_height " " button_spacing, "SET")
SetButton.OnEvent("Click", showSetGUI)

DeleteButton := MacroGUI.Add("Button", button_width " " button_height " " button_spacing, "DELETE")
DeleteButton.OnEvent("Click", showDeleteGUI)

SaveButton := MacroGUI.Add("Button", button_width " " button_height " " button_spacing, "SAVE")
SaveButton.OnEvent("Click", GUISaveKeys)

HelpButton := MacroGUI.Add("Button", button_width " " button_height " " button_spacing, "MANUAL")
HelpButton.OnEvent("Click", showHelpGUI)

MacroGUI.Add("Text", "ys", "Bound hotkey(s):")
KeyList := MacroGUI.Add("ListBox", "w200 r7 ReadOnly VScroll")
updateKeyList()

AutoklickerMode := MacroGUI.Add("Checkbox", "xp+40 y+20", "Autoklicker mode")
AutoklickerMode.Value := manager.autoklicker
AutoklickerMode.OnEvent("Click", toggleAutoklicker)

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

    AddConfirmButton := SetGUI.Add("Button", "Default xs y+10 w50", "Done")
    AddConfirmButton.OnEvent("Click", setEnteredKey)

    SetGUI.Show()

    setEnteredKey(*) {

        Value := SetGUI.Submit(false)
        name := Value.KeyName
        interval := Value.KeyInterval
        delay := Value.KeyDelay

        try 
            manager.setKey(name, interval, delay)
        catch as err {
            MsgBox(err.Message, title)
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

    DeleteConfirmButton := DeleteGUI.Add("Button", "Default xs y+10 w50", "Done")
    DeleteConfirmButton.OnEvent("Click", deleteEnteredKey)

    DeleteAllButton := DeleteGUI.Add("Button", "x+40 w80", "Delete all")
    DeleteAllButton.OnEvent("Click", deleteAllKeys)

    DeleteGUI.Show()

    deleteEnteredKey(*) {

        Value := DeleteGUI.Submit(false)
        name := Value.KeyName

        try 
            manager.deleteKey(name)
        catch as err {
            MsgBox(err.Message, title)
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

GUISaveKeys(*) {
    manager.saveKeys()
    MsgBox("Hotkeys saved", title)
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