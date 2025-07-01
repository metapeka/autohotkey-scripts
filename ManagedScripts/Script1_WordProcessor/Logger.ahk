#Requires AutoHotkey v2.0
; Logger.ahk - Модуль логирования
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class LoggerModule {
    __New(Config) {
        this.Config := Config
        this.FileMan := FileManager()
    }
    
    ; Основное логирование
    Log(Message) {
        FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        LogEntry := "[" . FormattedTime . "]: " . Message . "`n"
        this.FileMan.AppendFileUTF8BOM(this.Config.LogFile, LogEntry)
    }
    
    ; Логирование ошибок
    LogError(ErrorMessage) {
        FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        ErrorEntry := "[" . FormattedTime . "]: " . ErrorMessage . "`n"
        this.FileMan.AppendFileUTF8BOM(this.Config.ErrorLogFile, ErrorEntry)
    }
    
    ; Логирование статистики
    LogStats(Message) {
        FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        StatsEntry := "[" . FormattedTime . "]: " . Message . "`n"
        try {
            this.FileMan.AppendFileUTF8BOM(this.Config.StatsFile, StatsEntry)
        } catch as e {
            this.LogError("Ошибка записи в файл статистики " . this.Config.StatsFile . ": " . e.Message)
        }
    }
    
    ; Логирование отправленного слова
    LogSentWord(Word, Delay) {
        Message := "delay: " . Delay . " ms, send: " . Word
        this.Log(Message)
    }
    
    ; Логирование завершения цикла
    LogCycleComplete(SentCount, TotalTime) {
        Message := "Цикл завершен, отправлено " . SentCount . " строк, общее время " . TotalTime . " секунд"
        this.Log(Message)
        this.LogStats("Отправлено " . SentCount . " строк, общее время " . TotalTime . " секунд")
    }
    
    ; Логирование действий с файлами
    LogFileAction(Action) {
        this.Log(Action)
    }
}