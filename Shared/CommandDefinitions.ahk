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
    static RELOAD_CONFIG := "RELOAD_CONFIG"         ; Перезагрузить конфигурацию
    static SET_DELAY := "SET_DELAY"                 ; Установить задержку
    
    ; === Статусы ответов ===
    static STATUS_SUCCESS := "SUCCESS"
    static STATUS_ERROR := "ERROR"
    static STATUS_PROCESSING := "PROCESSING"
    static STATUS_UNKNOWN := "UNKNOWN"
    
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
        if (!Command.HasProp("id") || !Command.HasProp("command")) {
            return false
        }
        
        ; Проверяем, что команда известна
        KnownCommands := [
            Commands.SHUTDOWN,
            Commands.GET_STATUS,
            Commands.GET_INFO,
            Commands.PING,
            Commands.START_PROCESSING,
            Commands.STOP_PROCESSING,
            Commands.PAUSE_RESUME,
            Commands.RESTORE_FILES,
            Commands.GET_STATS,
            Commands.RELOAD_CONFIG,
            Commands.SET_DELAY
        ]
        
        for KnownCmd in KnownCommands {
            if (Command.command = KnownCmd) {
                return true
            }
        }
        
        return false
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
                
            case Commands.SET_DELAY:
                ; Требуются minDelay и maxDelay
                if (!Command.HasProp("params") || 
                    !Command.params.HasProp("minDelay") || 
                    !Command.params.HasProp("maxDelay")) {
                    return {Valid: false, Error: "Отсутствуют параметры задержки"}
                }
        }
        
        return {Valid: true}
    }
}

; Создание стандартных ответов
class ResponseBuilder {
    ; Успешный ответ
    static Success(CommandId, Message := "", Data := {}) {
        Response := {
            id: CommandId,
            status: Commands.STATUS_SUCCESS,
            timestamp: A_Now
        }
        
        if (Message != "") {
            Response.message := Message
        }
        
        if (Type(Data) = "Object" && ObjOwnPropCount(Data) > 0) {
            Response.data := Data
        }
        
        return Response
    }
    
    ; Ответ с ошибкой
    static Error(CommandId, ErrorMessage) {
        return {
            id: CommandId,
            status: Commands.STATUS_ERROR,
            error: ErrorMessage,
            timestamp: A_Now
        }
    }
    
    ; Ответ "в процессе"
    static Processing(CommandId, Message := "") {
        Response := {
            id: CommandId,
            status: Commands.STATUS_PROCESSING,
            timestamp: A_Now
        }
        
        if (Message != "") {
            Response.message := Message
        }
        
        return Response
    }
}