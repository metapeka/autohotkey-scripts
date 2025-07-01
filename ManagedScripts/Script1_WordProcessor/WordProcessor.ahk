#Requires AutoHotkey v2.0
; WordProcessor.ahk - Процессор слов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class WordProcessor {
    __New(Config, FileMan, Logger, UI) {
        this.Config := Config
        this.FileMan := FileMan
        this.Logger := Logger
        this.UI := UI
        this.WordsArray := []
    }
    
    ; Основной процесс обработки слов
    ProcessWords(LoopCount) {
        try {
            ; Загружаем массив слов
            this.WordsArray := this.FileMan.LoadArrayFromFile(this.FileMan.WordFile)
            
            if (this.WordsArray.Length = 0) {
                this.Logger.LogError("Не удалось загрузить слова из файла " . this.FileMan.WordFile)
                this.UI.ShowError("Не удалось загрузить слова из файла " . this.FileMan.WordFile)
                return false
            }
            
            ; Создаем used_words.txt, если он отсутствует
            if !FileExist(this.FileMan.UsedWordsFile)
                this.FileMan.WriteFileUTF8BOM(this.FileMan.UsedWordsFile, "")
            
            ; Запускаем основной цикл
            return this.RunMainLoop(LoopCount)
            
        } catch as e {
            this.Logger.LogError("Ошибка в ProcessWords: " . e.Message)
            this.UI.ShowError(e.Message)
            return false
        }
    }
    
    ; Основной цикл обработки
    RunMainLoop(LoopCount) {
        SentCount := 0
        StartTime := A_TickCount
        
        Loop LoopCount {
            if (this.WordsArray.Length = 0) {
                this.UI.ShowMessage("Все слова использованы!")
                this.FileMan.WriteFileUTF8BOM(this.FileMan.WordFile, "")
                break
            }
            
            ; Выбираем и отправляем слово
            if (this.ProcessSingleWord()) {
                SentCount++
            }
        }
        
        ; Логируем статистику
        this.LogStatistics(SentCount, StartTime)
        
        ; Показываем результаты
        this.UI.ShowCompletionStats(SentCount, this.Config.LogFile)
        
        return true
    }
    
    ; Обработка одного слова
    ProcessSingleWord() {
        try {
            ; Выбираем случайное слово
            rand := Random(1, this.WordsArray.Length)
            Word := this.WordsArray[rand]
            
            ; Генерируем задержку
            Delay := this.Config.GetRandomDelay()
            
            ; Отправляем слово
            Send(Word)
            Sleep(Delay)
            Send("{Enter}")
            Sleep(1000)
            
            ; Логируем отправку
            this.Logger.LogSentWord(Word, Delay)
            
            ; Записываем использованное слово
            this.FileMan.MoveWordToUsed(Word)
            
            ; Удаляем слово из массива
            this.WordsArray.RemoveAt(rand)
            
            ; Обновляем words.txt
            this.UpdateWordsFile()
            
            return true
            
        } catch as e {
            this.Logger.LogError("Ошибка при обработке слова: " . e.Message)
            return false
        }
    }
    
    ; Обновление файла слов
    UpdateWordsFile() {
        if (this.WordsArray.Length > 0) {
            this.FileMan.SaveArrayToFile(this.FileMan.WordFile, this.WordsArray)
        } else {
            this.FileMan.WriteFileUTF8BOM(this.FileMan.WordFile, "")
        }
    }
    
    ; Логирование статистики
    LogStatistics(SentCount, StartTime) {
        TotalTime := Round((A_TickCount - StartTime) / 1000.0, 1)
        this.Logger.LogCycleComplete(SentCount, TotalTime)
    }
    
    ; Восстановление файлов
    RestoreFiles() {
        try {
            if (this.FileMan.RestoreWords()) {
                this.Logger.LogFileAction("Восстановлен файл " . this.FileMan.WordFile . 
                                         ", очищен " . this.FileMan.UsedWordsFile)
                this.UI.ShowTrayTip("Файлы обновлены", 
                                   "words.txt восстановлен, used_words.txt очищен")
                return true
            } else {
                this.Logger.LogError("Файл used_words.txt не существует")
                this.UI.ShowError("Файл used_words.txt не существует!")
                return false
            }
        } catch as e {
            this.Logger.LogError("Ошибка при восстановлении: " . e.Message)
            this.UI.ShowError("Ошибка при восстановлении: " . e.Message)
            return false
        }
    }
}