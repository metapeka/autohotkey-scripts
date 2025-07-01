#Requires AutoHotkey v2.0
; IPCConfig.ahk - Конфигурация IPC для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class IPCConfig {
    ; Настройки IPC
    static ENABLE_IPC := true                    ; Включить IPC
    static AUTO_FIND_CONTROLLER := true         ; Автопоиск контроллера
    static STATUS_REPORT_INTERVAL := 5000        ; Интервал отправки статуса (мс)
    static COMMAND_TIMEOUT := 30000              ; Таймаут выполнения команды (мс)
    static MAX_COMMAND_QUEUE := 100              ; Максимальный размер очереди команд
    static ENABLE_COMMAND_LOG := true            ; Логировать команды
    static ENABLE_STATUS_LOG := false            ; Логировать статусы
    
    ; Настройки безопасности
    static VALIDATE_SENDER := true               ; Проверять отправителя
    static ALLOWED_SENDERS := ["MainController"] ; Разрешенные отправители
    static MAX_COMMANDS_PER_MINUTE := 60         ; Лимит команд в минуту
    
    ; Пути
    static IPC_LOG_FILE := "ipc_commands.log"    ; Файл лога команд
    
    ; Загрузка настроек из INI
    static LoadFromINI(IniFile := "ipc_settings.ini") {
        if (!FileExist(IniFile)) {
            this.SaveToINI(IniFile)  ; Создаем файл с настройками по умолчанию
            return
        }
        
        ; Основные настройки
        this.ENABLE_IPC := IniRead(IniFile, "General", "EnableIPC", true)
        this.AUTO_FIND_CONTROLLER := IniRead(IniFile, "General", "AutoFindController", true)
        this.STATUS_REPORT_INTERVAL := IniRead(IniFile, "General", "StatusReportInterval", 5000)
        this.COMMAND_TIMEOUT := IniRead(IniFile, "General", "CommandTimeout", 30000)
        
        ; Настройки логирования
        this.ENABLE_COMMAND_LOG := IniRead(IniFile, "Logging", "EnableCommandLog", true)
        this.ENABLE_STATUS_LOG := IniRead(IniFile, "Logging", "EnableStatusLog", false)
        this.IPC_LOG_FILE := IniRead(IniFile, "Logging", "LogFile", "ipc_commands.log")
        
        ; Настройки безопасности
        this.VALIDATE_SENDER := IniRead(IniFile, "Security", "ValidateSender", true)
        this.MAX_COMMANDS_PER_MINUTE := IniRead(IniFile, "Security", "MaxCommandsPerMinute", 60)
    }
    
    ; Сохранение настроек в INI
    static SaveToINI(IniFile := "ipc_settings.ini") {
        ; Основные настройки
        IniWrite(this.ENABLE_IPC, IniFile, "General", "EnableIPC")
        IniWrite(this.AUTO_FIND_CONTROLLER, IniFile, "General", "AutoFindController")
        IniWrite(this.STATUS_REPORT_INTERVAL, IniFile, "General", "StatusReportInterval")
        IniWrite(this.COMMAND_TIMEOUT, IniFile, "General", "CommandTimeout")
        
        ; Настройки логирования
        IniWrite(this.ENABLE_COMMAND_LOG, IniFile, "Logging", "EnableCommandLog")
        IniWrite(this.ENABLE_STATUS_LOG, IniFile, "Logging", "EnableStatusLog")
        IniWrite(this.IPC_LOG_FILE, IniFile, "Logging", "LogFile")
        
        ; Настройки безопасности
        IniWrite(this.VALIDATE_SENDER, IniFile, "Security", "ValidateSender")
        IniWrite(this.MAX_COMMANDS_PER_MINUTE, IniFile, "Security", "MaxCommandsPerMinute")
    }
}