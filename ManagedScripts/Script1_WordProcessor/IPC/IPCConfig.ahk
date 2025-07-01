#Requires AutoHotkey v2.0
; IPCConfig.ahk - Класс для управления настройками IPC
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class IPCConfig {
    ; Публичные свойства
    IPCEnabled := false
    MainControllerName := "MainController.ahk"
    StatusReportInterval := 5000 ; Интервал отправки статуса в миллисекундах
    
    ; Приватные свойства
    _configPath := "ipc_settings.ini"
    _logger := ""
    
    ; Конструктор
    __New(ConfigPath := "", Logger := "") {
        if (ConfigPath != "") {
            this._configPath := ConfigPath
        }
        
        this._logger := Logger
    }
    
    ; Загрузка настроек из файла
    LoadConfig() {
        ; Проверяем существование файла конфигурации
        if (!FileExist(this._configPath)) {
            ; Если файл не существует, создаем его с настройками по умолчанию
            this._CreateDefaultConfig()
            
            if (this._logger) {
                this._logger.Log("IPCConfig: Создан файл конфигурации с настройками по умолчанию")
            }
            
            return true
        }
        
        ; Загружаем настройки из файла
        try {
            this.IPCEnabled := this._ReadBoolSetting("General", "IPCEnabled", false)
            this.MainControllerName := this._ReadStringSetting("General", "MainControllerName", "MainController.ahk")
            this.StatusReportInterval := this._ReadIntSetting("General", "StatusReportInterval", 5000)
            
            if (this._logger) {
                this._logger.Log("IPCConfig: Настройки IPC загружены успешно")
            }
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при загрузке настроек: " . e.Message)
            }
            
            ; В случае ошибки создаем файл с настройками по умолчанию
            this._CreateDefaultConfig()
            
            return false
        }
    }
    
    ; Сохранение настроек в файл
    SaveConfig() {
        try {
            ; Сохраняем настройки в файл
            IniWrite(this.IPCEnabled ? 1 : 0, this._configPath, "General", "IPCEnabled")
            IniWrite(this.MainControllerName, this._configPath, "General", "MainControllerName")
            IniWrite(this.StatusReportInterval, this._configPath, "General", "StatusReportInterval")
            
            if (this._logger) {
                this._logger.Log("IPCConfig: Настройки IPC сохранены успешно")
            }
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при сохранении настроек: " . e.Message)
            }
            
            return false
        }
    }
    
    ; Создание файла с настройками по умолчанию
    _CreateDefaultConfig() {
        try {
            ; Создаем файл с настройками по умолчанию
            IniWrite(this.IPCEnabled ? 1 : 0, this._configPath, "General", "IPCEnabled")
            IniWrite(this.MainControllerName, this._configPath, "General", "MainControllerName")
            IniWrite(this.StatusReportInterval, this._configPath, "General", "StatusReportInterval")
            
            return true
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при создании файла конфигурации: " . e.Message)
            }
            
            return false
        }
    }
    
    ; Чтение строкового значения из файла настроек
    _ReadStringSetting(Section, Key, DefaultValue) {
        try {
            Value := IniRead(this._configPath, Section, Key, DefaultValue)
            return Value
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при чтении настройки " . Section . "/" . Key . ": " . e.Message)
            }
            
            return DefaultValue
        }
    }
    
    ; Чтение целочисленного значения из файла настроек
    _ReadIntSetting(Section, Key, DefaultValue) {
        try {
            Value := IniRead(this._configPath, Section, Key, DefaultValue)
            return Integer(Value)
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при чтении настройки " . Section . "/" . Key . ": " . e.Message)
            }
            
            return DefaultValue
        }
    }
    
    ; Чтение логического значения из файла настроек
    _ReadBoolSetting(Section, Key, DefaultValue) {
        try {
            Value := IniRead(this._configPath, Section, Key, DefaultValue ? 1 : 0)
            return Value = 1
        } catch Error as e {
            if (this._logger) {
                this._logger.LogError("IPCConfig: Ошибка при чтении настройки " . Section . "/" . Key . ": " . e.Message)
            }
            
            return DefaultValue
        }
    }
}