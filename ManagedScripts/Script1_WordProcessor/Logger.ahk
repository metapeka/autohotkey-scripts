#Requires AutoHotkey v2.0
; Logger.ahk - Модуль логирования
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class LoggerModule {
    __New(FileMan, Config) {
        this.FileMan := FileMan
        this.Config := Config
        
        ; Создаем файлы логов, если они не существуют
        if !FileExist(this.Config.LogFile)
            this.FileMan.WriteFileUTF8BOM(this.Config.LogFile, "")
            
        if !FileExist(this.Config.ErrorLogFile)
            this.FileMan.WriteFileUTF8BOM(this.Config.ErrorLogFile, "")
            
        if !FileExist(this.Config.StatsFile)
            this.FileMan.WriteFileUTF8BOM(this.Config.StatsFile, "")
    }
    
    ; Общее логирование
    Log(Message) {
        try {
            TimeStamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            LogMessage := TimeStamp . " - " . Message . "`n"
            this.FileMan.AppendFileUTF8BOM(this.Config.LogFile, LogMessage)
        } catch as e {
            ; В случае ошибки при логировании, пытаемся записать в файл ошибок
            try {
                TimeStamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
                ErrorMessage := TimeStamp . " - Ошибка логирования: " . e.Message . "`n"
                this.FileMan.AppendFileUTF8BOM(this.Config.ErrorLogFile, ErrorMessage)
            }
        }
    }
    
    ; Логирование ошибок
    LogError(ErrorMessage) {
        try {
            TimeStamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FullErrorMessage := TimeStamp . " - ОШИБКА: " . ErrorMessage . "`n"
            
            ; Записываем в оба лога
            this.FileMan.AppendFileUTF8BOM(this.Config.ErrorLogFile, FullErrorMessage)
            this.FileMan.AppendFileUTF8BOM(this.Config.LogFile, FullErrorMessage)
        } catch {
            ; Если не удалось записать в лог, выводим в консоль
            OutputDebug("Критическая ошибка логирования: " . ErrorMessage)
        }
    }
    
    ; Логирование статистики
    LogStats(StatsMessage) {
        try {
            TimeStamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FullStatsMessage := TimeStamp . " - " . StatsMessage . "`n"
            this.FileMan.AppendFileUTF8BOM(this.Config.StatsFile, FullStatsMessage)
        } catch as e {
            this.LogError("Ошибка при записи статистики: " . e.Message)
        }
    }
    
    ; Логирование отправленного слова
    LogSentWord(Word, Delay) {
        this.Log("Отправлено слово: '" . Word . "' с задержкой " . Delay . " мс")
    }
    
    ; Логирование завершения цикла
    LogCycleComplete(SentCount, TotalTime) {
        StatsMessage := "Цикл завершен. Отправлено слов: " . SentCount . 
                       ", Затрачено времени: " . TotalTime . " сек."
        
        this.Log(StatsMessage)
        this.LogStats(StatsMessage)
    }
    
    ; Логирование действий с файлами
    LogFileAction(ActionMessage) {
        this.Log("Файловая операция: " . ActionMessage)
    }
}