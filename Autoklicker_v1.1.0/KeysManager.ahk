#Requires AutoHotkey v2.0

class Key {
    __New(name, interval, delay) {
        this.name := name
        this.interval := interval
        this.delay := delay
    }
}

class KeysManager {

    __New() {
        this.keys := []
        this.toggle := false

        this.toggle_key := IniRead("settings.ini", "KEYBINDS", "toggle_key")
        this.reload_key := IniRead("settings.ini", "KEYBINDS", "reload_key")
        this.exitapp_key := IniRead("settings.ini", "KEYBINDS", "exitapp_key")
        this.autoklicker := IniRead("settings.ini", "SETTINGS", "autoklicker")
    }

    isValidHotKey(name) {
        return !!GetKeyVK(name)
    }

    saveKeys() {
        file := FileOpen("keys.txt", "w")
        for k in this.keys {
            save_string := Format("{},{},{}", k.name, k.interval, k.delay)
            file.WriteLine(save_string)
        }
        file.Close()
    }

    loadKeys() {
        file := FileOpen("keys.txt", "rw")
        while !file.AtEOF {
            line := file.ReadLine()
            parts := StrSplit(line, ",")
            k := Key(StrLower(parts[1]), Integer(parts[2]), Integer(parts[3]))
            this.keys.Push(k)
        }
        file.Close()
    }
    
    setKey(name, interval, delay) {

        if !this.isValidHotKey(name)
            throw ValueError("Invalid key name")
        if name == this.toggle_key or name == this.reload_key or name == this.exitapp_key
            throw ValueError("Unable to bind preset hotkeys")
        if !IsInteger(interval) or !IsInteger(delay) or interval <= 0 or delay <= 0
            throw TypeError("Interval/Delay must be a positive integer")

        for k in this.keys {
            if k.name == StrLower(name) {
                k.interval := Integer(interval)
                k.delay := Integer(delay)
                return
            }
        }

        k := Key(StrLower(name), Integer(interval), Integer(delay))
        this.keys.Push(k)
        this.bindKey(k)
    }

    bindKey(k) {

        sendKey() {
            if !this.toggle
                SetTimer , 0
            Send "{Blind}{" k.name "}"
        }
        
        delayedTimer() {
            sendKey()
            SetTimer sendKey, k.interval
        }

        if this.autoklicker {
            if this.toggle
                HotKey("*" k.name, autoKey.Bind(k), "On")
            else
                Hotkey("*" k.name, autoKey.Bind(k), "Off")
        } else {
            if this.toggle
                HotKey("*" k.name, semiKey.Bind(k), "On")
            else
                Hotkey("*" k.name, semiKey.Bind(k), "Off")
        }

        semiKey(k, *) {
            sendKey()
            SetTimer delayedTimer, -k.delay
            KeyWait k.name
            SetTimer delayedTimer, 0
            SetTimer sendKey, 0
        }

        autoKey(k, *) {
            static toggle := false
            toggle := !toggle
            if toggle
                SetTimer delayedTimer, -k.delay
            else {
                SetTimer delayedTimer, 0
                SetTimer sendKey, 0
            }
        }
    }

    deleteKey(name) {
        for k in this.keys {
            if k.name == StrLower(name) {
                Hotkey("*" name, "Off")
                this.keys.RemoveAt(A_Index)
                return
            }
        }
        throw TargetError("Nonexistent hotkey")
    }

    deleteAllKeys() {
        for k in this.keys {
            Hotkey("*" k.name, "Off")
        }
        this.keys := []
    }

    toggleKeyBindsOn() {
        this.toggle := true
        for k in this.keys
            Hotkey("*" k.name, "On")
    }

    toggleKeyBindsOff() {
        this.toggle := false
        for k in this.keys
            Hotkey("*" k.name, "Off")
    }

    toggleKeyBinds() {
        if this.toggle {
            this.toggleKeyBindsOff()
            ToolTip "OFF"
        } else {
            this.toggleKeyBindsOn()
            ToolTip "ON"
        }
        SetTimer () => ToolTip(), -1000
    }

    checkDuplicatePresetKeys(preset_arr) {
        seen := Map()
        for k in preset_arr {
            if seen.Has(k)
                throw Error("Duplicate preset keys")
            seen[k] := true
        }
    }

    bindPresetKey(type, name) {

        if !this.isValidHotKey(name)
            throw ValueError(Format("Invalid {} key name", type))
        for k in this.keys {
            if name == k.name
                throw Error("Unable to bind already bound keys")
        }

        if type == "toggle" {
            Hotkey("*" this.toggle_key, "Off")
            this.toggle_key := name
            Hotkey("*" this.toggle_key, (*) => this.toggleKeyBinds(), "On")
        } else if type == "reload" {
            Hotkey("*" this.reload_key, "Off")
            this.reload_key := name
            Hotkey("*" this.reload_key, (*) => Reload(), "On")
        } else if type == "exitapp" {
            Hotkey("*" this.exitapp_key, "Off")
            this.exitapp_key := name
            Hotkey("*" this.exitapp_key, (*) => ExitApp(), "On")
        }
    }
}