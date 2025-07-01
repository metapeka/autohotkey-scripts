#Requires AutoHotkey v2.0
; IPCListener.ahk - Класс для прослушивания и обработки IPC сообщений
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

#Include "IPCProtocol.ahk"

class IPCListener {
    ; Приватные свойства
    _isListening := false
    _commandHandler := ""
    _logger := ""
    
    ; Конструктор
    __New(CommandHandler, Logger := "") {
        this._commandHandler := CommandHandler
        this._logger := Logger
    }
    
    ; Начать прослушивание IPC сообщений
    StartListening() {
        if (this._isListening) {
            return true
        }
        
        ; Регистрируем обработчик WM_COPYDATA
        OnMessage(IPCProtocol.WM_COPYDATA, ObjBindMethod(this, "_OnCopyData"))
        this._isListening := true
        
        if (this._logger) {
            this._logger.Log("IPCListener: Начато прослушивание IPC сообщений")
        }
        
        return true
    }
    
    ; Остановить прослушивание IPC сообщений
    StopListening() {
        if (!this._isListening) {
            return true
        }
        
        ; Удаляем обработчик WM_COPYDATA
        OnMessage(IPCProtocol.WM_COPYDATA, ObjBindMethod(this, "_OnCopyData"), 0)
        this._isListening := false
        
        if (this._logger) {
            this._logger.Log("IPCListener: Остановлено прослушивание IPC сообщений")
        }
        
        return true
    }
    
    ; Проверка, активно ли прослушивание
    IsListening() {
        return this._isListening
    }
    
    ; Обработчик WM_COPYDATA
    _OnCopyData(wParam, lParam, msg, hwnd) {
        ; Обрабатываем полученные данные
        Message := IPCProtocol.ProcessReceivedData(wParam, lParam)
        
        ; Если данные некорректны, игнорируем сообщение
        if (!Message) {
            if (this._logger) {
                this._logger.LogError("IPCListener: Получены некорректные данные")
            }
            return false
        }
        
        ; Логируем полученное сообщение
        if (this._logger) {
            this._logger.Log("IPCListener: Получено сообщение: " . Message["command"] . " от " . Message["source_script"])
        }
        
        ; Если есть обработчик команд, передаем сообщение ему
        if (this._commandHandler) {
            try {
                result := this._commandHandler.HandleCommand(Message)
                return result
            } catch Error as e {
                if (this._logger) {
                    this._logger.LogError("IPCListener: Ошибка при обработке команды: " . e.Message)
                }
                return false
            }
        }
        
        return true
    }
}