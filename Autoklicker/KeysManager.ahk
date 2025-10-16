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
        this.autoklicker := false
    }

    isValidHotKey(name) {
        return !!GetKeyVK(name)
    }

    saveKeys() {
        file := FileOpen("keys.txt", "w")
        for k in this.keys {
            save_string := Format("{}, {}, {}", k.name, k.interval, k.delay)
            file.WriteLine(save_string)
        }
        file.Close()
    }

    loadKeys() {
        file := FileOpen("keys.txt", "rw")
        while !file.AtEOF {
            line := file.ReadLine()
            parts := StrSplit(line, ", ")
            k := Key(StrLower(parts[1]), Integer(parts[2]), Integer(parts[3]))
            this.keys.Push(k)
        }
        file.Close()
    }

    bindKey(k) {

        sendKey() {
            if !this.toggle
                SetTimer , 0
            Send "{Blind}{" k.name " Down}"
            Sleep 0
            Send "{Blind}{" k.name " Up}"
        }
        
        delayedTimer() {
            sendKey()
            SetTimer sendKey, k.interval
        }

        if this.autoklicker {
            if this.toggle
                HotKey("*" k.name, autoKey.Bind(k))
            else
                Hotkey("*" k.name, autoKey.Bind(k), "Off")
        } else {
            if this.toggle
                HotKey("*" k.name, semiKey.Bind(k))
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
            else if !toggle {
                SetTimer delayedTimer, 0
                SetTimer sendKey, 0
            }
        }
    }

    setKey(name, interval, delay) {

        if !this.isValidHotKey(name)
            throw ValueError("Invalid key name")
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
}