#Requires AutoHotkey v2.0
; CommandDefinitions.ahk - Определения команд для всех скриптов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class Commands {
    ; === Общие команды для всех скриптов ===
    static SHUTDOWN := "SHUTDOWN"           ; Завершение работы
    static GET_STATUS := "GET_STATUS"       ; Получить статус
    static GET_INFO := "GET_INFO"           ; Получить информацию
    static PING := "PING"                   ; Проверка связи
    
    ; === Команды для WordProcessor ===
    static START_PROCESSING := "START_PROCESSING"   ; Начать обработку
    static STOP_PROCESSING := "STOP_PROCESSING"     ; Остановить обработку
    static PAUSE_RESUME := "PAUSE_RESUME"           ; Пауза/возобновление
    static RESTORE_FILES := "RESTORE_FILES"         ; Восстановить файлы
    static GET_STATS := "GET_STATS"                 ; Получить статистику
    
    ; === Статусы ответов ===
    static STATUS_SUCCESS := "SUCCESS"      ; Успешно
    static STATUS_ERROR := "ERROR"          ; Ошибка
    static STATUS_UNKNOWN := "UNKNOWN"      ; Неизвестно
    
    ; === Состояния скриптов ===
    static STATE_IDLE := "idle"                 ; Ожидание
    static STATE_RUNNING := "running"           ; Работает
    static STATE_PAUSED := "paused"             ; Пауза
    static STATE_PROCESSING := "processing"     ; Обработка
    static STATE_ERROR := "error"               ; Ошибка
}

; Валидация команд
class CommandValidator {
    ; Проверка валидности команды
    static IsValidCommand(Command) {
        ; Проверяем обязательные поля
        if (!Command.HasProp("commandId") || !Command.HasProp("command")) {
            return {Valid: false, Error: "Отсутствуют обязательные поля"}
        }
        
        ; Проверяем известность команды
        if (!this.IsKnownCommand(Command.command)) {
            return {Valid: false, Error: "Неизвестная команда: " . Command.command}
        }
        
        ; Проверяем параметры команды
        return this.ValidateParams(Command)
    }
    
    ; Проверка известности команды
    static IsKnownCommand(CommandName) {
        switch CommandName {
            case Commands.SHUTDOWN, Commands.GET_STATUS, Commands.GET_INFO, Commands.PING,
                 Commands.START_PROCESSING, Commands.STOP_PROCESSING, Commands.PAUSE_RESUME,
                 Commands.RESTORE_FILES, Commands.GET_STATS:
                return true
            default:
                return false
        }
    }
    
    ; Проверка параметров команды
    static ValidateParams(Command) {
        switch Command.command {
            case Commands.START_PROCESSING:
                ; Требуется loopCount
                if (!Command.HasProp("params") || !Command.params.HasProp("loopCount")) {
                    return {Valid: false, Error: "Отсутствует параметр loopCount"}
                }
                
                if (!IsInteger(Command.params.loopCount) || Command.params.loopCount < 1) {
                    return {Valid: false, Error: "loopCount должен быть целым числом > 0"}
                }
                
                return {Valid: true}
                
            case Commands.SHUTDOWN, Commands.GET_STATUS, Commands.GET_INFO, Commands.PING,
                 Commands.STOP_PROCESSING, Commands.PAUSE_RESUME, Commands.RESTORE_FILES,
                 Commands.GET_STATS:
                ; Для этих команд параметры не требуются
                return {Valid: true}
                
            default:
                return {Valid: false, Error: "Неизвестная команда: " . Command.command}
        }
    }
}

; Построитель ответов
class ResponseBuilder {
    ; Создание успешного ответа
    static CreateSuccessResponse(CommandId, Data := "") {
        Response := {
            commandId: CommandId,
            status: Commands.STATUS_SUCCESS
        }
        
        if (Data) {
            Response.data := Data
        }
        
        return Response
    }
    
    ; Создание ответа с ошибкой
    static CreateErrorResponse(CommandId, ErrorMessage) {
        return {
            commandId: CommandId,
            status: Commands.STATUS_ERROR,
            error: ErrorMessage
        }
    }
    
    ; Создание ответа со статусом
    static CreateStatusResponse(CommandId, State, Stats := "") {
        Response := {
            commandId: CommandId,
            status: Commands.STATUS_SUCCESS,
            state: State
        }
        
        if (Stats) {
            Response.stats := Stats
        }
        
        return Response
    }
}