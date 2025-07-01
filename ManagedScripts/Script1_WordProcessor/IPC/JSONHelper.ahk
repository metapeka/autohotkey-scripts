#Requires AutoHotkey v2.0
; JSONHelper.ahk - Вспомогательный класс для работы с JSON
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class JSONHelper {
    ; Преобразование объекта в JSON-строку
    static ObjectToJSON(Obj) {
        return this._ObjectToJSON(Obj)
    }
    
    ; Преобразование JSON-строки в объект
    static JSONToObject(JSONStr) {
        return this._JSONToObject(JSONStr)
    }
    
    ; Внутренний метод для преобразования объекта в JSON
    static _ObjectToJSON(Obj, Level := 1) {
        if !IsObject(Obj)
            return this._EscapeStr(Obj)
        
        IsArray := Obj.HasOwnProp("Length")
        Out := IsArray ? "[" : "{"
        
        Comma := ""
        for Key, Val in Obj {
            if (IsArray) {
                ; Для массивов ключи не выводим
                Out .= Comma . this._ObjectToJSON(Val, Level + 1)
            } else {
                ; Для объектов выводим ключи
                Out .= Comma . "`"" . this._EscapeStr(Key) . "`":" . this._ObjectToJSON(Val, Level + 1)
            }
            Comma := ","
        }
        
        Out .= IsArray ? "]" : "}"
        return Out
    }
    
    ; Внутренний метод для преобразования JSON в объект
    static _JSONToObject(JSONStr) {
        ; Удаляем пробелы в начале и конце
        JSONStr := Trim(JSONStr)
        
        ; Проверяем первый символ для определения типа
        FirstChar := SubStr(JSONStr, 1, 1)
        
        if (FirstChar = "{") {
            ; Объект
            return this._ParseObject(JSONStr)
        } else if (FirstChar = "[") {
            ; Массив
            return this._ParseArray(JSONStr)
        } else if (FirstChar = "`"") {
            ; Строка
            return this._ParseString(JSONStr)
        } else if JSONStr is number {
            ; Число
            return Number(JSONStr)
        } else if (JSONStr = "true") {
            ; Булево true
            return true
        } else if (JSONStr = "false") {
            ; Булево false
            return false
        } else if (JSONStr = "null") {
            ; Null
            return ""
        } else {
            ; Неизвестный тип
            return ""
        }
    }
    
    ; Разбор объекта
    static _ParseObject(JSONStr) {
        ; Удаляем фигурные скобки
        JSONStr := SubStr(JSONStr, 2, StrLen(JSONStr) - 2)
        
        Result := Map()
        
        ; Если строка пустая, возвращаем пустой объект
        if (JSONStr = "")
            return Result
        
        ; Разбираем пары ключ-значение
        Pos := 1
        while (Pos <= StrLen(JSONStr)) {
            ; Пропускаем пробелы
            while (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r")
                Pos++
            
            ; Проверяем, что ключ начинается с кавычки
            if (SubStr(JSONStr, Pos, 1) != "`"") {
                ; Ошибка формата
                return Map()
            }
            
            ; Извлекаем ключ
            KeyStart := Pos + 1
            Pos := InStr(JSONStr, "`"", false, Pos + 1)
            Key := SubStr(JSONStr, KeyStart, Pos - KeyStart)
            Pos++
            
            ; Пропускаем пробелы до двоеточия
            while (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r")
                Pos++
            
            ; Проверяем наличие двоеточия
            if (SubStr(JSONStr, Pos, 1) != ":") {
                ; Ошибка формата
                return Map()
            }
            Pos++
            
            ; Пропускаем пробелы после двоеточия
            while (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r")
                Pos++
            
            ; Определяем тип значения
            ValueChar := SubStr(JSONStr, Pos, 1)
            
            if (ValueChar = "{") {
                ; Вложенный объект
                BraceCount := 1
                ValueStart := Pos
                
                while (BraceCount > 0 && Pos < StrLen(JSONStr)) {
                    Pos++
                    CurChar := SubStr(JSONStr, Pos, 1)
                    
                    if (CurChar = "{")
                        BraceCount++
                    else if (CurChar = "}")
                        BraceCount--
                }
                
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseObject(ValueStr)
                Pos++
            } else if (ValueChar = "[") {
                ; Массив
                BracketCount := 1
                ValueStart := Pos
                
                while (BracketCount > 0 && Pos < StrLen(JSONStr)) {
                    Pos++
                    CurChar := SubStr(JSONStr, Pos, 1)
                    
                    if (CurChar = "[")
                        BracketCount++
                    else if (CurChar = "]")
                        BracketCount--
                }
                
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseArray(ValueStr)
                Pos++
            } else if (ValueChar = "`"") {
                ; Строка
                ValueStart := Pos
                Pos := InStr(JSONStr, "`"", false, Pos + 1)
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseString(ValueStr)
                Pos++
            } else {
                ; Число, булево или null
                ValueStart := Pos
                
                while (Pos <= StrLen(JSONStr) && SubStr(JSONStr, Pos, 1) != "," && SubStr(JSONStr, Pos, 1) != "}") {
                    Pos++
                }
                
                ValueStr := Trim(SubStr(JSONStr, ValueStart, Pos - ValueStart))
                
                if ValueStr is number {
                    Value := Number(ValueStr)
                } else if (ValueStr = "true") {
                    Value := true
                } else if (ValueStr = "false") {
                    Value := false
                } else if (ValueStr = "null") {
                    Value := ""
                } else {
                    Value := ValueStr
                }
            }
            
            ; Добавляем пару ключ-значение в результат
            Result[Key] := Value
            
            ; Пропускаем пробелы после значения
            while (Pos <= StrLen(JSONStr) && (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r"))
                Pos++
            
            ; Проверяем наличие запятой или конца объекта
            if (Pos > StrLen(JSONStr) || SubStr(JSONStr, Pos, 1) = "}") {
                break
            } else if (SubStr(JSONStr, Pos, 1) = ",") {
                Pos++
            } else {
                ; Ошибка формата
                return Map()
            }
        }
        
        return Result
    }
    
    ; Разбор массива
    static _ParseArray(JSONStr) {
        ; Удаляем квадратные скобки
        JSONStr := SubStr(JSONStr, 2, StrLen(JSONStr) - 2)
        
        Result := []
        
        ; Если строка пустая, возвращаем пустой массив
        if (JSONStr = "")
            return Result
        
        ; Разбираем элементы массива
        Pos := 1
        while (Pos <= StrLen(JSONStr)) {
            ; Пропускаем пробелы
            while (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r")
                Pos++
            
            ; Определяем тип элемента
            ValueChar := SubStr(JSONStr, Pos, 1)
            
            if (ValueChar = "{") {
                ; Объект
                BraceCount := 1
                ValueStart := Pos
                
                while (BraceCount > 0 && Pos < StrLen(JSONStr)) {
                    Pos++
                    CurChar := SubStr(JSONStr, Pos, 1)
                    
                    if (CurChar = "{")
                        BraceCount++
                    else if (CurChar = "}")
                        BraceCount--
                }
                
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseObject(ValueStr)
                Pos++
            } else if (ValueChar = "[") {
                ; Вложенный массив
                BracketCount := 1
                ValueStart := Pos
                
                while (BracketCount > 0 && Pos < StrLen(JSONStr)) {
                    Pos++
                    CurChar := SubStr(JSONStr, Pos, 1)
                    
                    if (CurChar = "[")
                        BracketCount++
                    else if (CurChar = "]")
                        BracketCount--
                }
                
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseArray(ValueStr)
                Pos++
            } else if (ValueChar = "`"") {
                ; Строка
                ValueStart := Pos
                Pos := InStr(JSONStr, "`"", false, Pos + 1)
                ValueStr := SubStr(JSONStr, ValueStart, Pos - ValueStart + 1)
                Value := this._ParseString(ValueStr)
                Pos++
            } else {
                ; Число, булево или null
                ValueStart := Pos
                
                while (Pos <= StrLen(JSONStr) && SubStr(JSONStr, Pos, 1) != "," && SubStr(JSONStr, Pos, 1) != "]") {
                    Pos++
                }
                
                ValueStr := Trim(SubStr(JSONStr, ValueStart, Pos - ValueStart))
                
                if ValueStr is number {
                    Value := Number(ValueStr)
                } else if (ValueStr = "true") {
                    Value := true
                } else if (ValueStr = "false") {
                    Value := false
                } else if (ValueStr = "null") {
                    Value := ""
                } else {
                    Value := ValueStr
                }
            }
            
            ; Добавляем элемент в результат
            Result.Push(Value)
            
            ; Пропускаем пробелы после элемента
            while (Pos <= StrLen(JSONStr) && (SubStr(JSONStr, Pos, 1) = " " || SubStr(JSONStr, Pos, 1) = "`t" || SubStr(JSONStr, Pos, 1) = "`n" || SubStr(JSONStr, Pos, 1) = "`r"))
                Pos++
            
            ; Проверяем наличие запятой или конца массива
            if (Pos > StrLen(JSONStr) || SubStr(JSONStr, Pos, 1) = "]") {
                break
            } else if (SubStr(JSONStr, Pos, 1) = ",") {
                Pos++
            } else {
                ; Ошибка формата
                return []
            }
        }
        
        return Result
    }
    
    ; Разбор строки
    static _ParseString(JSONStr) {
        ; Удаляем кавычки
        JSONStr := SubStr(JSONStr, 2, StrLen(JSONStr) - 2)
        
        ; Заменяем экранированные символы
        JSONStr := StrReplace(JSONStr, "\\", "\")
        JSONStr := StrReplace(JSONStr, "\\\"", "`"")
        JSONStr := StrReplace(JSONStr, "\\n", "`n")
        JSONStr := StrReplace(JSONStr, "\\r", "`r")
        JSONStr := StrReplace(JSONStr, "\\t", "`t")
        
        return JSONStr
    }
    
    ; Экранирование строки для JSON
    static _EscapeStr(Str) {
        if !IsSet(Str) || (Str = "")
            return "\"\""
        
        if (IsObject(Str))
            return this._ObjectToJSON(Str)
        
        if (Str is Number)
            return Str
        
        if (Str is String) {
            ; Экранируем специальные символы
            Str := StrReplace(Str, "\", "\\")
            Str := StrReplace(Str, "`"", "\\`"")
            Str := StrReplace(Str, "`n", "\\n")
            Str := StrReplace(Str, "`r", "\\r")
            Str := StrReplace(Str, "`t", "\\t")
            
            return "`"" . Str . "`""
        }
        
        if (Str is Integer || Str is Float)
            return Str
        
        if (Str = true)
            return "true"
        
        if (Str = false)
            return "false"
        
        return "null"
    }
}