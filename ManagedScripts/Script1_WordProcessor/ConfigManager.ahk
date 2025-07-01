#Requires AutoHotkey v2.0
; ConfigManager.ahk - Менеджер конфигурации
; Кодировка: UTF-8 with BOM
; Версия: 1.0.1
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07 - Добавлена поддержка логгера

class ConfigManager {
    __New() {
        this.SettingsFile := "settings.ini"
        this.Logger := {}  ; Будет установлен после инициализации
        this.LoadSettings()
    }
    
    ; Установка логгера
    SetLogger(Logger) {
        this.Logger := Logger
    }
    
    LoadSettings() {
        ; Создание файла настроек с значениями по умолчанию, если он отсутствует
        if !FileExist(this.SettingsFile) {
            this.CreateDefaultSettings()
        }
        
        ; Загрузка настроек
        this.MinDelay := IniRead(this.SettingsFile, "Delays", "MinDelay", 1000)
        this.MaxDelay := IniRead(this.SettingsFile, "Delays", "MaxDelay", 1500)
        this.LogFile := IniRead(this.SettingsFile, "Settings", "LogFile", "TwitchChatLog.txt")
        this.ErrorLogFile := IniRead(this.SettingsFile, "Settings", "ErrorLogFile", "errors.log")
        this.StatsFile := IniRead(this.SettingsFile, "Settings", "StatsFile", "stats.txt")
        
        ; Валидация настроек
        this.ValidateSettings()
    }
    
    CreateDefaultSettings() {
        IniWrite(1000, this.SettingsFile, "Delays", "MinDelay")
        IniWrite(1500, this.SettingsFile, "Delays", "MaxDelay")
        IniWrite("TwitchChatLog.txt", this.SettingsFile, "Settings", "LogFile")
        IniWrite("errors.log", this.SettingsFile, "Settings", "ErrorLogFile")
        IniWrite("stats.txt", this.SettingsFile, "Settings", "StatsFile")
    }
    
    ValidateSettings() {
        ; Валидация задержек
        if (!IsInteger(this.MinDelay) || !IsInteger(this.MaxDelay) || 
            this.MinDelay < 1 || this.MaxDelay < 1 || this.MinDelay > this.MaxDelay) {
            this.MinDelay := 1000
            this.MaxDelay := 1500
            IniWrite(this.MinDelay, this.SettingsFile, "Delays", "MinDelay")
            IniWrite(this.MaxDelay, this.SettingsFile, "Delays", "MaxDelay")
            
            ; Логируем ошибку, если логгер доступен
            if (IsObject(this.Logger) && this.Logger.HasMethod("LogError")) {
                this.Logger.LogError("Ошибка: Некорректные значения задержек, использованы значения по умолчанию")
            }
        }
        
        ; Валидация имени файла статистики
        if (this.StatsFile = "" || !RegExMatch(this.StatsFile, "^[\w\-]+\.txt$")) {
            oldStatsFile := this.StatsFile
            this.StatsFile := "stats.txt"
            IniWrite(this.StatsFile, this.SettingsFile, "Settings", "StatsFile")
            
            ; Логируем предупреждение, если логгер доступен
            if (IsObject(this.Logger) && this.Logger.HasMethod("LogError")) {
                this.Logger.LogError("Предупреждение: Некорректное имя файла статистики '" . oldStatsFile . "', используется по умолчанию: stats.txt")
            }
        }
    }
    
    SaveSetting(Section, Key, Value) {
        IniWrite(Value, this.SettingsFile, Section, Key)
        this.LoadSettings() ; Перезагрузка настроек
    }
    
    GetRandomDelay() {
        return Random(this.MinDelay, this.MaxDelay)
    }
}