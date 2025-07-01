#Requires AutoHotkey v2.0
; ConfigManager.ahk - Менеджер конфигурации
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class ConfigManager {
    __New() {
        this.ConfigFile := A_ScriptDir . "\settings.ini"
        this.MinDelay := 1000
        this.MaxDelay := 3000
        this.LogFile := A_ScriptDir . "\log.txt"
        this.ErrorLogFile := A_ScriptDir . "\error_log.txt"
        this.StatsFile := A_ScriptDir . "\stats.txt"
        this.Logger := ""
        
        ; Создаем файл конфигурации, если он не существует
        if !FileExist(this.ConfigFile) {
            this.CreateDefaultSettings()
        }
        
        ; Загружаем настройки
        this.LoadSettings()
    }
    
    ; Установка логгера для сообщений об ошибках
    SetLogger(Logger) {
        this.Logger := Logger
    }
    
    ; Создание файла настроек по умолчанию
    CreateDefaultSettings() {
        try {
            IniWrite(this.MinDelay, this.ConfigFile, "Delays", "MinDelay")
            IniWrite(this.MaxDelay, this.ConfigFile, "Delays", "MaxDelay")
            IniWrite(this.LogFile, this.ConfigFile, "Logging", "LogFile")
            IniWrite(this.ErrorLogFile, this.ConfigFile, "Logging", "ErrorLogFile")
            IniWrite(this.StatsFile, this.ConfigFile, "Logging", "StatsFile")
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при создании настроек по умолчанию: " . e.Message)
            }
        }
    }
    
    ; Загрузка настроек из файла
    LoadSettings() {
        try {
            ; Загружаем задержки
            this.MinDelay := this.ReadIniInt("Delays", "MinDelay", 1000)
            this.MaxDelay := this.ReadIniInt("Delays", "MaxDelay", 3000)
            
            ; Проверяем корректность задержек
            if (this.MinDelay < 100) {
                this.MinDelay := 100
                IniWrite(this.MinDelay, this.ConfigFile, "Delays", "MinDelay")
            }
            
            if (this.MaxDelay < this.MinDelay) {
                this.MaxDelay := this.MinDelay + 1000
                IniWrite(this.MaxDelay, this.ConfigFile, "Delays", "MaxDelay")
            }
            
            ; Загружаем пути к файлам логов
            this.LogFile := this.ReadIniString("Logging", "LogFile", A_ScriptDir . "\log.txt")
            this.ErrorLogFile := this.ReadIniString("Logging", "ErrorLogFile", A_ScriptDir . "\error_log.txt")
            this.StatsFile := this.ReadIniString("Logging", "StatsFile", A_ScriptDir . "\stats.txt")
            
            return true
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при загрузке настроек: " . e.Message)
            }
            return false
        }
    }
    
    ; Сохранение настроек в файл
    SaveSettings() {
        try {
            IniWrite(this.MinDelay, this.ConfigFile, "Delays", "MinDelay")
            IniWrite(this.MaxDelay, this.ConfigFile, "Delays", "MaxDelay")
            IniWrite(this.LogFile, this.ConfigFile, "Logging", "LogFile")
            IniWrite(this.ErrorLogFile, this.ConfigFile, "Logging", "ErrorLogFile")
            IniWrite(this.StatsFile, this.ConfigFile, "Logging", "StatsFile")
            return true
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при сохранении настроек: " . e.Message)
            }
            return false
        }
    }
    
    ; Чтение целого числа из INI файла
    ReadIniInt(Section, Key, DefaultValue) {
        try {
            Value := IniRead(this.ConfigFile, Section, Key, DefaultValue)
            return Integer(Value)
        } catch {
            return DefaultValue
        }
    }
    
    ; Чтение строки из INI файла
    ReadIniString(Section, Key, DefaultValue) {
        try {
            return IniRead(this.ConfigFile, Section, Key, DefaultValue)
        } catch {
            return DefaultValue
        }
    }
    
    ; Получение случайной задержки
    GetRandomDelay() {
        return Random(this.MinDelay, this.MaxDelay)
    }
}