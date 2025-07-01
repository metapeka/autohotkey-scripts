#Requires AutoHotkey v2.0
; JSONHelper.ahk - Простой помощник для работы с JSON
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class JSON {
    ; Преобразование объекта в JSON строку
    static Stringify(obj, indent := "") {
        if (Type(obj) = "String") {
            return '"' . StrReplace(StrReplace(StrReplace(obj, "\\", "\\\\"), '"', '\\"'), "`n", "\\n") . '"'
        }
        else if (Type(obj) = "Integer" || Type(obj) = "Float") {
            return String(obj)
        }
        else if (Type(obj) = "Array") {
            result := "["
            first := true
            for item in obj {
                if (!first) {
                    result .= ","
                }
                first := false
                result .= this.Stringify(item, indent)
            }
            result .= "]"
            return result
        }
        else if (Type(obj) = "Map") {
            result := "{"
            first := true
            for key, value in obj {
                if (!first) {
                    result .= ","
                }
                first := false
                result .= '"' . key . '":' . this.Stringify(value, indent)
            }
            result .= "}"
            return result
        }
        else if (Type(obj) = "Object") {
            result := "{"
            first := true
            for key, value in obj.OwnProps() {
                if (!first) {
                    result .= ","
                }
                first := false
                result .= '"' . key . '":' . this.Stringify(value, indent)
            }
            result .= "}"
            return result
        }
        else {
            return "null"
        }
    }
    
    ; Простой парсер JSON (базовая реализация)
    static Parse(jsonStr) {
        jsonStr := Trim(jsonStr)
        
        ; Объект
        if (SubStr(jsonStr, 1, 1) = "{") {
            return this.ParseObject(jsonStr)
        }
        ; Массив
        else if (SubStr(jsonStr, 1, 1) = "[") {
            return this.ParseArray(jsonStr)
        }
        ; Строка
        else if (SubStr(jsonStr, 1, 1) = '"') {
            return this.ParseString(jsonStr)
        }
        ; Число
        else if (RegExMatch(jsonStr, "^-?\d+(\.\d+)?", &match)) {
            return Number(match[0])
        }
        ; Boolean/null
        else if (jsonStr = "true") {
            return true
        }
        else if (jsonStr = "false") {
            return false
        }
        else if (jsonStr = "null") {
            return ""
        }
        
        return ""
    }
    
    ; Парсинг объекта
    static ParseObject(jsonStr) {
        obj := {}
        jsonStr := SubStr(jsonStr, 2, -1)  ; Убираем {}
        
        if (jsonStr = "") {
            return obj
        }
        
        ; Простой парсер для базовых случаев
        pairs := this.SplitJSON(jsonStr, ",")
        
        for pair in pairs {
            colonPos := InStr(pair, ":")
            if (colonPos > 0) {
                key := Trim(SubStr(pair, 1, colonPos - 1), ' "')
                value := Trim(SubStr(pair, colonPos + 1))
                
                ; Парсим значение
                if (SubStr(value, 1, 1) = '"') {
                    obj.%key% := SubStr(value, 2, -1)
                } else if (IsNumber(value)) {
                    obj.%key% := Number(value)
                } else if (value = "true") {
                    obj.%key% := true
                } else if (value = "false") {
                    obj.%key% := false
                } else if (value = "null") {
                    obj.%key% := ""
                } else if (SubStr(value, 1, 1) = "{") {
                    obj.%key% := this.ParseObject(value)
                } else {
                    obj.%key% := value
                }
            }
        }
        
        return obj
    }
    
    ; Парсинг массива
    static ParseArray(jsonStr) {
        arr := []
        jsonStr := SubStr(jsonStr, 2, -1)  ; Убираем []
        
        if (jsonStr = "") {
            return arr
        }
        
        items := this.SplitJSON(jsonStr, ",")
        
        for item in items {
            item := Trim(item)
            arr.Push(this.Parse(item))
        }
        
        return arr
    }
    
    ; Парсинг строки
    static ParseString(jsonStr) {
        return SubStr(jsonStr, 2, -1)
    }
    
    ; Разделение JSON с учетом вложенности
    static SplitJSON(jsonStr, delimiter) {
        parts := []
        current := ""
        depth := 0
        inString := false
        
        Loop Parse, jsonStr {
            char := A_LoopField
            
            if (!inString && (char = "{" || char = "[")) {
                depth++
            } else if (!inString && (char = "}" || char = "]")) {
                depth--
            } else if (char = '"' && (A_Index = 1 || SubStr(jsonStr, A_Index - 1, 1) != "\\")) {
                inString := !inString
            }
            
            if (!inString && depth = 0 && char = delimiter) {
                parts.Push(current)
                current := ""
            } else {
                current .= char
            }
        }
        
        if (current != "") {
            parts.Push(current)
        }
        
        return parts
    }
}