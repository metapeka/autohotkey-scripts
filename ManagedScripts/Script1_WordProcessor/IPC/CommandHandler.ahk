#Requires AutoHotkey v2.0
; CommandHandler.ahk - Класс для обработки IPC команд
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

#Include "IPCProtocol.ahk"
#Include "CommandDefinitions.ahk"

class CommandHandler {
    ; Приватные свойства
    _wordProcessor := ""
    _logger := ""
    _statusReporter := ""
    
    ; Конструктор
    __New(WordProcessor, Logger := "", StatusReporter := "") {
        this._wordProcessor := WordProcessor
        this._logger := Logger
        this._statusReporter := StatusReporter
    }
    
    ; Обработка полученной команды
    HandleCommand(Message) {
        ; Проверяем, что сообщение содержит команду
        if (!Message.Has("command")) {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Сообщение не содержит команду")
            }
            return false
        }
        
        ; Получаем команду из сообщения
        Command := Message["command"]
        
        ; Проверяем, что команда валидна
        if (!CommandDefinitions.IsValidCommand(Command)) {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Неизвестная команда: " . Command)
            }
            return false
        }
        
        ; Логируем полученную команду
        if (this._logger) {
            this._logger.Log("CommandHandler: Обработка команды: " . Command)
        }
        
        ; Обрабатываем команду в зависимости от её типа
        result := false
        
        switch Command {
            case CommandDefinitions.Commands.SHUTDOWN:
                result := this._HandleShutdown(Message)
            case CommandDefinitions.Commands.GET_STATUS:
                result := this._HandleGetStatus(Message)
            case CommandDefinitions.Commands.START_PROCESSING:
                result := this._HandleStartProcessing(Message)
            case CommandDefinitions.Commands.STOP_PROCESSING:
                result := this._HandleStopProcessing(Message)
            case CommandDefinitions.Commands.RESTORE_FILES:
                result := this._HandleRestoreFiles(Message)
            case CommandDefinitions.Commands.GET_STATS:
                result := this._HandleGetStats(Message)
            default:
                if (this._logger) {
                    this._logger.LogError("CommandHandler: Команда не реализована: " . Command)
                }
                return false
        }
        
        return result
    }
    
    ; Обработка команды SHUTDOWN
    _HandleShutdown(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды SHUTDOWN")
        }
        
        ; Отправляем ответ об успешном выполнении
        IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS)
        
        ; Завершаем скрипт с небольшой задержкой
        SetTimer(() => ExitApp(), -1000)
        
        return true
    }
    
    ; Обработка команды GET_STATUS
    _HandleGetStatus(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды GET_STATUS")
        }
        
        ; Получаем текущий статус
        Status := this._statusReporter ? this._statusReporter.GetCurrentStatus() : CommandDefinitions.Statuses.UNKNOWN
        
        ; Создаем полезную нагрузку с информацией о статусе
        Payload := Map()
        Payload["status"] := Status
        Payload["timestamp"] := A_Now
        
        ; Отправляем ответ с информацией о статусе
        IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS, Payload)
        
        return true
    }
    
    ; Обработка команды START_PROCESSING
    _HandleStartProcessing(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды START_PROCESSING")
        }
        
        ; Проверяем, что процессор слов доступен
        if (!this._wordProcessor) {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Процессор слов не инициализирован")
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := "Процессор слов не инициализирован"
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
        
        ; Запускаем обработку слов
        try {
            this._wordProcessor.ProcessWords()
            
            ; Отправляем ответ об успешном выполнении
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS)
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Ошибка при запуске обработки слов: " . e.Message)
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := e.Message
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
    }
    
    ; Обработка команды STOP_PROCESSING
    _HandleStopProcessing(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды STOP_PROCESSING")
        }
        
        ; Проверяем, что процессор слов доступен
        if (!this._wordProcessor) {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Процессор слов не инициализирован")
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := "Процессор слов не инициализирован"
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
        
        ; Останавливаем обработку слов
        try {
            ; Здесь должен быть метод для остановки обработки
            ; Пока просто отправляем успешный ответ
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS)
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Ошибка при остановке обработки слов: " . e.Message)
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := e.Message
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
    }
    
    ; Обработка команды RESTORE_FILES
    _HandleRestoreFiles(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды RESTORE_FILES")
        }
        
        ; Проверяем, что процессор слов доступен
        if (!this._wordProcessor) {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Процессор слов не инициализирован")
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := "Процессор слов не инициализирован"
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
        
        ; Восстанавливаем файлы
        try {
            this._wordProcessor.RestoreFiles()
            
            ; Отправляем ответ об успешном выполнении
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS)
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("CommandHandler: Ошибка при восстановлении файлов: " . e.Message)
            }
            
            ; Отправляем ответ об ошибке
            ErrorPayload := Map()
            ErrorPayload["error"] := e.Message
            IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.ERROR, ErrorPayload)
            
            return false
        }
    }
    
    ; Обработка команды GET_STATS
    _HandleGetStats(Message) {
        if (this._logger) {
            this._logger.Log("CommandHandler: Выполнение команды GET_STATS")
        }
        
        ; Создаем полезную нагрузку с информацией о статистике
        ; В реальном приложении здесь должна быть логика получения статистики
        Payload := Map()
        Payload["processed_words"] := 0
        Payload["total_words"] := 0
        Payload["start_time"] := ""
        Payload["elapsed_time"] := 0
        
        ; Отправляем ответ с информацией о статистике
        IPCProtocol.SendResponse(Message, CommandDefinitions.ResponseTypes.SUCCESS, Payload)
        
        return true
    }
}