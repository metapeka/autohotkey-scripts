#Requires AutoHotkey v2.0
; CommandDefinitions.ahk - Определения команд для IPC
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class CommandDefinitions {
    ; Определения команд
    static CMD_SHUTDOWN := "SHUTDOWN"            ; Завершение работы скрипта
    static CMD_GET_STATUS := "GET_STATUS"        ; Получение текущего статуса
    static CMD_START_PROCESSING := "START_PROCESSING"  ; Запуск обработки слов
    static CMD_STOP_PROCESSING := "STOP_PROCESSING"    ; Остановка обработки
    static CMD_PAUSE_RESUME := "PAUSE_RESUME"    ; Пауза/возобновление обработки
    static CMD_RESTORE_FILES := "RESTORE_FILES"  ; Восстановление файлов
    static CMD_GET_STATS := "GET_STATS"          ; Получение статистики
    static CMD_RELOAD_CONFIG := "RELOAD_CONFIG"  ; Перезагрузка конфигурации
    static CMD_SET_DELAY := "SET_DELAY"          ; Установка задержки
    
    ; Определения статусов
    static STATUS_IDLE := "IDLE"                 ; Простой
    static STATUS_PROCESSING := "PROCESSING"      ; Обработка
    static STATUS_PAUSED := "PAUSED"              ; Пауза
    static STATUS_ERROR := "ERROR"                ; Ошибка
    
    ; Определения типов ответов
    static RESP_SUCCESS := "SUCCESS"              ; Успешное выполнение
    static RESP_ERROR := "ERROR"                  ; Ошибка выполнения
    static RESP_INVALID := "INVALID"              ; Неверная команда
    static RESP_DENIED := "DENIED"                ; Доступ запрещен
    
    ; Получение списка всех команд
    static GetAllCommands() {
        return [
            this.CMD_SHUTDOWN,
            this.CMD_GET_STATUS,
            this.CMD_START_PROCESSING,
            this.CMD_STOP_PROCESSING,
            this.CMD_PAUSE_RESUME,
            this.CMD_RESTORE_FILES,
            this.CMD_GET_STATS,
            this.CMD_RELOAD_CONFIG,
            this.CMD_SET_DELAY
        ]
    }
    
    ; Проверка, является ли строка допустимой командой
    static IsValidCommand(Command) {
        Commands := this.GetAllCommands()
        for Cmd in Commands {
            if (Cmd = Command)
                return true
        }
        return false
    }
    
    ; Получение списка всех статусов
    static GetAllStatuses() {
        return [
            this.STATUS_IDLE,
            this.STATUS_PROCESSING,
            this.STATUS_PAUSED,
            this.STATUS_ERROR
        ]
    }
    
    ; Проверка, является ли строка допустимым статусом
    static IsValidStatus(Status) {
        Statuses := this.GetAllStatuses()
        for Stat in Statuses {
            if (Stat = Status)
                return true
        }
        return false
    }
    
    ; Получение списка всех типов ответов
    static GetAllResponseTypes() {
        return [
            this.RESP_SUCCESS,
            this.RESP_ERROR,
            this.RESP_INVALID,
            this.RESP_DENIED
        ]
    }
    
    ; Проверка, является ли строка допустимым типом ответа
    static IsValidResponseType(ResponseType) {
        ResponseTypes := this.GetAllResponseTypes()
        for RespType in ResponseTypes {
            if (RespType = ResponseType)
                return true
        }
        return false
    }
}