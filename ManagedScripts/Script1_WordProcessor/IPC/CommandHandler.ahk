#Requires AutoHotkey v2.0
; CommandHandler.ahk - Обработчик команд для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "..\..\Shared\CommandDefinitions.ahk"

class CommandHandler {
    static STATE_IDLE := "idle"
    static STATE_PROCESSING := "processing"
    static STATE_PAUSED := "paused"
    
    __New(WordProc, FileManager, Logger, Config, UI) {
        this.WordProc := WordProc
        this.FileManager := FileManager
        this.Logger := Logger
        this.Config := Config
        this.UI := UI
        
        this.CurrentState := this.STATE_IDLE
        this.StartTime := 0
        this.ProcessedWords := 0
        this.TotalWords := 0
        this.LastError := ""
    }
    
    ; Выполнение команды
    ExecuteCommand(Command) {
        if (!Command || !Command.command) {
            return {status: "ERROR", data: "Invalid command"}
        }
        
        this.Logger.Log("Выполнение команды: " Command.command, "INFO")
        
        ; Обработка команды в зависимости от типа
        switch Command.command {
            case CMD.SHUTDOWN:
                return this.HandleShutdown(Command)
                
            case CMD.GET_STATUS:
                return this.HandleGetStatus(Command)
                
            case CMD.START_PROCESSING:
                return this.HandleStartProcessing(Command)
                
            case CMD.STOP_PROCESSING:
                return this.HandleStopProcessing(Command)
                
            case CMD.PAUSE_RESUME:
                return this.HandlePauseResume(Command)
                
            case CMD.RESTORE_FILES:
                return this.HandleRestoreFiles(Command)
                
            case CMD.GET_STATS:
                return this.HandleGetStats(Command)
                
            case CMD.RELOAD_CONFIG:
                return this.HandleReloadConfig(Command)
                
            case CMD.SET_DELAY:
                return this.HandleSetDelay(Command)
                
            default:
                this.Logger.Log("Неизвестная команда: " Command.command, "WARNING")
                return {status: "ERROR", data: "Unknown command"}
        }
    }
    
    ; Обработка команды SHUTDOWN
    HandleShutdown(Command) {
        this.Logger.Log("Получена команда завершения работы", "INFO")
        
        ; Останавливаем обработку, если она запущена
        if (this.CurrentState != this.STATE_IDLE) {
            this.WordProc.StopProcessing()
        }
        
        ; Запускаем таймер для завершения скрипта
        SetTimer(() => ExitApp(), -1000)
        
        return {status: "OK", data: "Shutting down"}
    }
    
    ; Обработка команды GET_STATUS
    HandleGetStatus(Command) {
        status := this.GetCurrentStatus()
        return {status: "OK", data: status}
    }
    
    ; Обработка команды START_PROCESSING
    HandleStartProcessing(Command) {
        if (this.CurrentState = this.STATE_PROCESSING) {
            return {status: "ERROR", data: "Already processing"}
        }
        
        ; Получаем параметры из команды
        params := Command.params ? Command.params : {}
        
        ; Запускаем обработку
        result := this.WordProc.StartProcessing(params)
        
        if (result) {
            this.CurrentState := this.STATE_PROCESSING
            this.StartTime := A_TickCount
            this.ProcessedWords := 0
            this.LastError := ""
            
            ; Обновляем UI
            if (this.UI) {
                this.UI.UpdateStatus("Обработка запущена")
            }
            
            return {status: "OK", data: "Processing started"}
        } else {
            this.LastError := "Failed to start processing"
            return {status: "ERROR", data: this.LastError}
        }
    }
    
    ; Обработка команды STOP_PROCESSING
    HandleStopProcessing(Command) {
        if (this.CurrentState = this.STATE_IDLE) {
            return {status: "ERROR", data: "Not processing"}
        }
        
        ; Останавливаем обработку
        result := this.WordProc.StopProcessing()
        
        if (result) {
            this.CurrentState := this.STATE_IDLE
            
            ; Обновляем UI
            if (this.UI) {
                this.UI.UpdateStatus("Обработка остановлена")
            }
            
            return {status: "OK", data: "Processing stopped"}
        } else {
            this.LastError := "Failed to stop processing"
            return {status: "ERROR", data: this.LastError}
        }
    }
    
    ; Обработка команды PAUSE_RESUME
    HandlePauseResume(Command) {
        if (this.CurrentState = this.STATE_IDLE) {
            return {status: "ERROR", data: "Not processing"}
        }
        
        if (this.CurrentState = this.STATE_PROCESSING) {
            ; Ставим на паузу
            result := this.WordProc.PauseProcessing()
            
            if (result) {
                this.CurrentState := this.STATE_PAUSED
                
                ; Обновляем UI
                if (this.UI) {
                    this.UI.UpdateStatus("Обработка приостановлена")
                }
                
                return {status: "OK", data: "Processing paused"}
            } else {
                this.LastError := "Failed to pause processing"
                return {status: "ERROR", data: this.LastError}
            }
        } else if (this.CurrentState = this.STATE_PAUSED) {
            ; Возобновляем
            result := this.WordProc.ResumeProcessing()
            
            if (result) {
                this.CurrentState := this.STATE_PROCESSING
                
                ; Обновляем UI
                if (this.UI) {
                    this.UI.UpdateStatus("Обработка возобновлена")
                }
                
                return {status: "OK", data: "Processing resumed"}
            } else {
                this.LastError := "Failed to resume processing"
                return {status: "ERROR", data: this.LastError}
            }
        }
    }
    
    ; Обработка команды RESTORE_FILES
    HandleRestoreFiles(Command) {
        if (this.CurrentState != this.STATE_IDLE) {
            return {status: "ERROR", data: "Cannot restore files while processing"}
        }
        
        ; Восстанавливаем файлы
        result := this.FileManager.RestoreBackups()
        
        if (result) {
            ; Обновляем UI
            if (this.UI) {
                this.UI.UpdateStatus("Файлы восстановлены")
            }
            
            return {status: "OK", data: "Files restored"}
        } else {
            this.LastError := "Failed to restore files"
            return {status: "ERROR", data: this.LastError}
        }
    }
    
    ; Обработка команды GET_STATS
    HandleGetStats(Command) {
        stats := {
            state: this.CurrentState,
            processed_words: this.ProcessedWords,
            total_words: this.TotalWords,
            elapsed_time: this.StartTime ? A_TickCount - this.StartTime : 0,
            last_error: this.LastError
        }
        
        return {status: "OK", data: stats}
    }
    
    ; Обработка команды RELOAD_CONFIG
    HandleReloadConfig(Command) {
        if (this.CurrentState != this.STATE_IDLE) {
            return {status: "ERROR", data: "Cannot reload config while processing"}
        }
        
        ; Перезагружаем конфигурацию
        result := this.Config.Reload()
        
        if (result) {
            ; Обновляем UI
            if (this.UI) {
                this.UI.UpdateStatus("Конфигурация перезагружена")
            }
            
            return {status: "OK", data: "Config reloaded"}
        } else {
            this.LastError := "Failed to reload config"
            return {status: "ERROR", data: this.LastError}
        }
    }
    
    ; Обработка команды SET_DELAY
    HandleSetDelay(Command) {
        if (!Command.params || !Command.params.HasOwnProp("delay")) {
            return {status: "ERROR", data: "Missing delay parameter"}
        }
        
        delay := Command.params.delay
        
        ; Устанавливаем задержку
        this.WordProc.SetDelay(delay)
        
        ; Обновляем UI
        if (this.UI) {
            this.UI.UpdateStatus("Задержка установлена: " delay " мс")
        }
        
        return {status: "OK", data: "Delay set to " delay}
    }
    
    ; Получение текущего статуса
    GetCurrentStatus() {
        status := {
            script: "WordProcessor",
            state: this.CurrentState,
            processed_words: this.ProcessedWords,
            total_words: this.TotalWords,
            elapsed_time: this.StartTime ? A_TickCount - this.StartTime : 0,
            last_error: this.LastError,
            timestamp: A_Now
        }
        
        return status
    }
    
    ; Обновление статистики обработки
    UpdateProcessingStats(ProcessedWords, TotalWords) {
        this.ProcessedWords := ProcessedWords
        this.TotalWords := TotalWords
    }
    
    ; Установка ошибки
    SetError(ErrorMessage) {
        this.LastError := ErrorMessage
        this.Logger.Log("Ошибка: " ErrorMessage, "ERROR")
    }
}