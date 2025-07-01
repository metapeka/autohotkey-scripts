#Requires AutoHotkey v2.0
; Main.ahk - Главный файл приложения для обработки слов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

; Включаем строгий режим
#Warn All, StdOut

; Подключаем основные модули
#Include "VersionManager.ahk"
#Include "ConfigManager.ahk"
#Include "FileManager.ahk"
#Include "Logger.ahk"
#Include "UIHelper.ahk"
#Include "WordProcessor.ahk"
#Include "HotkeyManager.ahk"

; Подключаем модули для IPC
#Include "IPC\JSONHelper.ahk"
#Include "IPC\IPCProtocol.ahk"
#Include "IPC\CommandDefinitions.ahk"
#Include "IPC\IPCListener.ahk"
#Include "IPC\CommandHandler.ahk"
#Include "IPC\StatusReporter.ahk"
#Include "IPC\IPCConfig.ahk"

; Глобальные переменные для хранения объектов
global versionManager := ""
global configManager := ""
global fileManager := ""
global logger := ""
global ui := ""
global wordProcessor := ""
global hotkeyManager := ""

; Глобальные переменные для IPC
global ipcConfig := ""
global commandHandler := ""
global statusReporter := ""
global ipcListener := ""

; Функция для логирования критических ошибок на ранних этапах
LogCriticalError(ErrorMessage) {
    try {
        FileAppend("[" . A_Now . "] КРИТИЧЕСКАЯ ОШИБКА: " . ErrorMessage . "`n", "critical_errors.log", "UTF-8")
    } catch {
        ; Ничего не делаем, если не удалось записать в файл
    }
    
    MsgBox("Критическая ошибка: " . ErrorMessage, "Ошибка", 16)
    ExitApp
}

; Инициализация приложения
InitializeApp() {
    ; Инициализируем менеджер версий
    try {
        versionManager := VersionManager("Word Processor", "1.0.0", "2025-01-07")
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать менеджер версий: " . e.Message)
        return false
    }
    
    ; Инициализируем менеджер конфигурации
    try {
        configManager := ConfigManager("settings.ini")
        configManager.LoadConfig()
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать менеджер конфигурации: " . e.Message)
        return false
    }
    
    ; Инициализируем менеджер файлов
    try {
        fileManager := FileManager()
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать менеджер файлов: " . e.Message)
        return false
    }
    
    ; Инициализируем логгер
    try {
        logger := LoggerModule(fileManager, configManager)
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать логгер: " . e.Message)
        return false
    }
    
    ; Устанавливаем логгер для менеджера конфигурации
    configManager.SetLogger(logger)
    
    ; Инициализируем UI
    try {
        ui := UIHelper()
        ui.SetLogger(logger)
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать UI: " . e.Message)
        return false
    }
    
    ; Инициализируем процессор слов
    try {
        wordProcessor := WordProcessor(configManager, fileManager, logger, ui)
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать процессор слов: " . e.Message)
        return false
    }
    
    ; Инициализируем менеджер горячих клавиш
    try {
        hotkeyManager := HotkeyManager(wordProcessor, ui, logger)
        hotkeyManager.InitializeHotkeys()
    } catch Error as e {
        LogCriticalError("Не удалось инициализировать менеджер горячих клавиш: " . e.Message)
        return false
    }
    
    ; Проверяем наличие всех необходимых модулей
    if (!versionManager || !configManager || !fileManager || !logger || !ui || !wordProcessor || !hotkeyManager) {
        LogCriticalError("Не все модули были успешно инициализированы")
        return false
    }
    
    ; Проверяем согласованность версий модулей
    if (!versionManager.CheckModuleVersions()) {
        LogCriticalError("Обнаружено несоответствие версий модулей")
        return false
    }
    
    ; Сохраняем информацию о версии
    versionManager.SaveVersionInfo()
    
    ; Логируем успешную инициализацию
    logger.Log("Приложение успешно инициализировано")
    
    ; Инициализируем IPC, если необходимо
    InitializeIPC()
    
    return true
}

; Инициализация IPC
InitializeIPC() {
    ; Инициализируем конфигурацию IPC
    try {
        ipcConfig := IPCConfig("ipc_settings.ini", logger)
        ipcConfig.LoadConfig()
    } catch Error as e {
        logger.LogError("Не удалось инициализировать конфигурацию IPC: " . e.Message)
        return false
    }
    
    ; Если IPC отключен, выходим
    if (!ipcConfig.IPCEnabled) {
        logger.Log("IPC отключен в настройках")
        return true
    }
    
    ; Инициализируем обработчик команд
    try {
        commandHandler := CommandHandler(wordProcessor, logger)
    } catch Error as e {
        logger.LogError("Не удалось инициализировать обработчик команд: " . e.Message)
        return false
    }
    
    ; Инициализируем репортер статуса
    try {
        statusReporter := StatusReporter(ipcConfig.MainControllerName, logger)
        statusReporter.SetReportInterval(ipcConfig.StatusReportInterval)
        statusReporter.EnableReporting()
    } catch Error as e {
        logger.LogError("Не удалось инициализировать репортер статуса: " . e.Message)
        return false
    }
    
    ; Устанавливаем репортер статуса для обработчика команд
    commandHandler._statusReporter := statusReporter
    
    ; Инициализируем слушатель IPC
    try {
        ipcListener := IPCListener(commandHandler, logger)
        ipcListener.StartListening()
    } catch Error as e {
        logger.LogError("Не удалось инициализировать слушатель IPC: " . e.Message)
        return false
    }
    
    logger.Log("IPC успешно инициализирован")
    return true
}

; Обработчик выхода из приложения
OnExit(*) {
    ; Останавливаем компоненты IPC, если они активны
    if (ipcListener && ipcListener.IsListening()) {
        ipcListener.StopListening()
    }
    
    if (statusReporter) {
        statusReporter.DisableReporting()
    }
    
    ; Логируем выход из приложения
    if (logger) {
        logger.Log("Приложение завершает работу")
    }
}

; Инициализируем приложение
if (!InitializeApp()) {
    ExitApp
}

; Показываем сообщение о запуске
ui.ShowTrayTip("Приложение запущено", "Используйте F1 для начала обработки слов, F2 для восстановления файлов, F3 для справки, Escape для выхода")

; Устанавливаем обработчик выхода
OnExit(OnExit)

; Запускаем бесконечный цикл для поддержания скрипта активным
Loop {
    Sleep(1000)
}