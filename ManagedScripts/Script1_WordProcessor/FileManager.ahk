#Requires AutoHotkey v2.0
; FileManager.ahk - Менеджер файлов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class FileManager {
    __New() {
        this.WordFile := "words.txt"
        this.UsedWordsFile := "used_words.txt"
    }
    
    ; Запись файла с UTF-8 BOM
    WriteFileUTF8BOM(FileName, Content) {
        try {
            FileObj := FileOpen(FileName, "w", "UTF-8")
            if (FileObj) {
                FileObj.Write(Content)
                FileObj.Close()
                return true
            }
            return false
        } catch {
            return false
        }
    }
    
    ; Чтение файла с UTF-8 BOM
    ReadFileUTF8BOM(FileName) {
        try {
            if !FileExist(FileName)
                return ""
            
            FileObj := FileOpen(FileName, "r", "UTF-8")
            if (FileObj) {
                Content := FileObj.Read()
                FileObj.Close()
                return Content
            }
            return ""
        } catch {
            return ""
        }
    }
    
    ; Добавление в файл с UTF-8 BOM
    AppendFileUTF8BOM(FileName, Content) {
        try {
            ExistingContent := this.ReadFileUTF8BOM(FileName)
            NewContent := ExistingContent . Content
            return this.WriteFileUTF8BOM(FileName, NewContent)
        } catch {
            return false
        }
    }
    
    ; Загрузка массива из файла
    LoadArrayFromFile(FileName) {
        arr := []
        if !FileExist(FileName)
            return arr
            
        Content := this.ReadFileUTF8BOM(FileName)
        for line in StrSplit(Content, "`n", "`r") {
            line := Trim(line)
            if (line != "")
                arr.Push(line)
        }
        return arr
    }
    
    ; Сохранение массива в файл
    SaveArrayToFile(FileName, Array) {
        Content := ""
        for item in Array
            Content .= item "`n"
        return this.WriteFileUTF8BOM(FileName, Content)
    }
    
    ; Перемещение слова из words.txt в used_words.txt
    MoveWordToUsed(Word) {
        return this.AppendFileUTF8BOM(this.UsedWordsFile, Word "`n")
    }
    
    ; Восстановление words.txt из used_words.txt
    RestoreWords() {
        if !FileExist(this.UsedWordsFile)
            return false
            
        UsedWords := this.ReadFileUTF8BOM(this.UsedWordsFile)
        
        if FileExist(this.WordFile) {
            this.AppendFileUTF8BOM(this.WordFile, UsedWords)
        } else {
            this.WriteFileUTF8BOM(this.WordFile, UsedWords)
        }
        
        this.WriteFileUTF8BOM(this.UsedWordsFile, "")
        return true
    }
}