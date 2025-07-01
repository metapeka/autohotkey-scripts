#Requires AutoHotkey v2.0
; JSONHelper.ahk - Вспомогательные функции для работы с JSON
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

; Класс для работы с JSON
class JSON {
    ; Преобразование объекта в строку JSON
    static Stringify(obj, pretty := false) {
        this.esc := Map("\\", "\\\\", "\"", "\\\"", "`n", "\\n", "`r", "\\r", "`t", "\\t", "/", "\\/")
        this.depth := 0
        this.pretty := pretty
        this.indent := "    "
        
        return this.Walk(obj)
    }
    
    ; Преобразование строки JSON в объект
    static Parse(json_string) {
        return this.ParseValue(&json_string)
    }
    
    ; Внутренний метод для обхода объекта
    static Walk(obj) {
        if (!IsObject(obj)) {
            if (IsNumber(obj)) {
                return obj
            } else if (obj == true) {
                return "true"
            } else if (obj == false) {
                return "false"
            } else if (obj == "") {
                return "\"\""
            } else if (obj == "null") {
                return "null"
            } else {
                return "\"" . this.Escape(obj) . "\""
            }
        } else if (obj is Array) {
            return this.WalkArray(obj)
        } else {
            return this.WalkObject(obj)
        }
    }
    
    ; Обход массива
    static WalkArray(arr) {
        this.depth++
        items := []
        
        for item in arr {
            items.Push(this.Walk(item))
        }
        
        this.depth--
        
        if (this.pretty) {
            return "[" . "`n" . this.indent.Repeat(this.depth) . items.Join(",`n" . this.indent.Repeat(this.depth)) . "`n" . this.indent.Repeat(this.depth - 1) . "]"
        } else {
            return "[" . items.Join(",") . "]"
        }
    }
    
    ; Обход объекта
    static WalkObject(obj) {
        this.depth++
        items := []
        
        for key, value in obj.OwnProps() {
            items.Push("\"" . this.Escape(key) . "\": " . this.Walk(value))
        }
        
        this.depth--
        
        if (this.pretty) {
            return "{" . "`n" . this.indent.Repeat(this.depth) . items.Join(",`n" . this.indent.Repeat(this.depth)) . "`n" . this.indent.Repeat(this.depth - 1) . "}"
        } else {
            return "{" . items.Join(",") . "}"
        }
    }
    
    ; Экранирование специальных символов
    static Escape(str) {
        for search, replace in this.esc {
            str := StrReplace(str, search, replace)
        }
        return str
    }
    
    ; Парсинг значения JSON
    static ParseValue(&json_string) {
        ; Пропускаем пробелы
        json_string := LTrim(json_string)
        
        if (json_string == "") {
            return ""
        }
        
        ; Определяем тип значения
        first_char := SubStr(json_string, 1, 1)
        
        if (first_char == "{") {
            return this.ParseObject(&json_string)
        } else if (first_char == "[") {
            return this.ParseArray(&json_string)
        } else if (first_char == "\"") {
            return this.ParseString(&json_string)
        } else if (first_char == "-" || IsDigit(first_char)) {
            return this.ParseNumber(&json_string)
        } else if (SubStr(json_string, 1, 4) == "true") {
            json_string := SubStr(json_string, 5)
            return true
        } else if (SubStr(json_string, 1, 5) == "false") {
            json_string := SubStr(json_string, 6)
            return false
        } else if (SubStr(json_string, 1, 4) == "null") {
            json_string := SubStr(json_string, 5)
            return "null"
        } else {
            throw Error("Неверный формат JSON: " . json_string)
        }
    }
    
    ; Парсинг объекта JSON
    static ParseObject(&json_string) {
        ; Пропускаем открывающую скобку
        json_string := SubStr(json_string, 2)
        
        obj := {}
        
        ; Пропускаем пробелы
        json_string := LTrim(json_string)
        
        ; Проверяем на пустой объект
        if (SubStr(json_string, 1, 1) == "}") {
            json_string := SubStr(json_string, 2)
            return obj
        }
        
        while (true) {
            ; Пропускаем пробелы
            json_string := LTrim(json_string)
            
            ; Ожидаем строку в качестве ключа
            if (SubStr(json_string, 1, 1) != "\"") {
                throw Error("Ожидается строка в качестве ключа: " . json_string)
            }
            
            ; Получаем ключ
            key := this.ParseString(&json_string)
            
            ; Пропускаем пробелы
            json_string := LTrim(json_string)
            
            ; Ожидаем двоеточие
            if (SubStr(json_string, 1, 1) != ":") {
                throw Error("Ожидается двоеточие: " . json_string)
            }
            
            ; Пропускаем двоеточие
            json_string := SubStr(json_string, 2)
            
            ; Получаем значение
            value := this.ParseValue(&json_string)
            
            ; Добавляем пару ключ-значение в объект
            obj.%key% := value
            
            ; Пропускаем пробелы
            json_string := LTrim(json_string)
            
            ; Проверяем на конец объекта или запятую
            if (SubStr(json_string, 1, 1) == "}") {
                json_string := SubStr(json_string, 2)
                return obj
            } else if (SubStr(json_string, 1, 1) == ",") {
                json_string := SubStr(json_string, 2)
            } else {
                throw Error("Ожидается запятая или закрывающая скобка: " . json_string)
            }
        }
    }
    
    ; Парсинг массива JSON
    static ParseArray(&json_string) {
        ; Пропускаем открывающую скобку
        json_string := SubStr(json_string, 2)
        
        arr := []
        
        ; Пропускаем пробелы
        json_string := LTrim(json_string)
        
        ; Проверяем на пустой массив
        if (SubStr(json_string, 1, 1) == "]") {
            json_string := SubStr(json_string, 2)
            return arr
        }
        
        while (true) {
            ; Получаем значение
            value := this.ParseValue(&json_string)
            
            ; Добавляем значение в массив
            arr.Push(value)
            
            ; Пропускаем пробелы
            json_string := LTrim(json_string)
            
            ; Проверяем на конец массива или запятую
            if (SubStr(json_string, 1, 1) == "]") {
                json_string := SubStr(json_string, 2)
                return arr
            } else if (SubStr(json_string, 1, 1) == ",") {
                json_string := SubStr(json_string, 2)
            } else {
                throw Error("Ожидается запятая или закрывающая скобка: " . json_string)
            }
        }
    }
    
    ; Парсинг строки JSON
    static ParseString(&json_string) {
        ; Пропускаем открывающую кавычку
        json_string := SubStr(json_string, 2)
        
        str := ""
        pos := 1
        
        while (pos <= StrLen(json_string)) {
            char := SubStr(json_string, pos, 1)
            
            if (char == "\"") {
                ; Закрывающая кавычка
                json_string := SubStr(json_string, pos + 1)
                return str
            } else if (char == "\\") {
                ; Экранированный символ
                next_char := SubStr(json_string, pos + 1, 1)
                
                if (next_char == "\"" || next_char == "\\") {
                    str .= next_char
                } else if (next_char == "n") {
                    str .= "`n"
                } else if (next_char == "r") {
                    str .= "`r"
                } else if (next_char == "t") {
                    str .= "`t"
                } else {
                    str .= next_char
                }
                
                pos += 2
            } else {
                ; Обычный символ
                str .= char
                pos++
            }
        }
        
        throw Error("Незакрытая строка: " . json_string)
    }
    
    ; Парсинг числа JSON
    static ParseNumber(&json_string) {
        num_str := ""
        pos := 1
        
        while (pos <= StrLen(json_string)) {
            char := SubStr(json_string, pos, 1)
            
            if (char == "-" || char == "+" || char == "." || char == "e" || char == "E" || IsDigit(char)) {
                num_str .= char
                pos++
            } else {
                break
            }
        }
        
        json_string := SubStr(json_string, pos)
        return Number(num_str)
    }
}