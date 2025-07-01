#Requires AutoHotkey v2.0
; FileManager.ahk - Менеджер файлов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class FileManager {
    __New() {
        this.WordFile := A_ScriptDir . "\words.txt"
        this.UsedWordsFile := A_ScriptDir . "\used_words.txt"
    }
    
    ; Запись в файл с кодировкой UTF-8 с BOM
    WriteFileUTF8BOM(FilePath, Content) {
        try {
            FileObj := FileOpen(FilePath, "w", "UTF-8-RAW")
            if !IsObject(FileObj) {
                throw Error("Не удалось открыть файл для записи: " . FilePath)
            }
            
            ; Записываем BOM для UTF-8
            FileObj.WriteUInt(0xBFBBEF, 1)
            
            ; Записываем содержимое
            FileObj.Write(Content)
            FileObj.Close()
            return true
        } catch as e {
            return false
        }
    }
    
    ; Чтение из файла с кодировкой UTF-8 с BOM
    ReadFileUTF8BOM(FilePath) {
        try {
            if !FileExist(FilePath) {
                return ""
            }
            
            FileObj := FileOpen(FilePath, "r", "UTF-8-RAW")
            if !IsObject(FileObj) {
                throw Error("Не удалось открыть файл для чтения: " . FilePath)
            }
            
            ; Пропускаем BOM, если он есть
            if (FileObj.Length >= 3) {
                BOM := FileObj.ReadUInt(1)
                if (BOM = 0xBFBBEF) {
                    ; BOM найден, пропускаем его
                } else {
                    ; BOM не найден, возвращаемся в начало файла
                    FileObj.Pos := 0
                }
            }
            
            ; Читаем содержимое
            Content := FileObj.Read()
            FileObj.Close()
            return Content
        } catch as e {
            return ""
        }
    }
    
    ; Добавление в файл с кодировкой UTF-8 с BOM
    AppendFileUTF8BOM(FilePath, Content) {
        try {
            if !FileExist(FilePath) {
                return this.WriteFileUTF8BOM(FilePath, Content)
            }
            
            ExistingContent := this.ReadFileUTF8BOM(FilePath)
            return this.WriteFileUTF8BOM(FilePath, ExistingContent . Content)
        } catch as e {
            return false
        }
    }
    
    ; Загрузка массива из файла
    LoadArrayFromFile(FilePath) {
        try {
            if !FileExist(FilePath) {
                return []
            }
            
            Content := this.ReadFileUTF8BOM(FilePath)
            if (Content = "") {
                return []
            }
            
            ; Разделяем по строкам и удаляем пустые строки
            Lines := StrSplit(Content, "`n", "`r")
            Result := []
            
            for Line in Lines {
                if (Line != "") {
                    Result.Push(Line)
                }
            }
            
            return Result
        } catch as e {
            return []
        }
    }
    
    ; Сохранение массива в файл
    SaveArrayToFile(FilePath, Array) {
        try {
            Content := ""
            for Item in Array {
                Content .= Item . "`n"
            }
            
            return this.WriteFileUTF8BOM(FilePath, Content)
        } catch as e {
            return false
        }
    }
    
    ; Перемещение слова в used_words.txt
    MoveWordToUsed(Word) {
        try {
            return this.AppendFileUTF8BOM(this.UsedWordsFile, Word . "`n")
        } catch as e {
            return false
        }
    }
    
    ; Восстановление words.txt из used_words.txt
    RestoreWords() {
        try {
            if !FileExist(this.UsedWordsFile) {
                return false
            }
            
            ; Загружаем использованные слова
            UsedWords := this.LoadArrayFromFile(this.UsedWordsFile)
            
            if (UsedWords.Length = 0) {
                return false
            }
            
            ; Сохраняем их в words.txt
            this.SaveArrayToFile(this.WordFile, UsedWords)
            
            ; Очищаем used_words.txt
            this.WriteFileUTF8BOM(this.UsedWordsFile, "")
            
            return true
        } catch as e {
            return false
        }
    }
}