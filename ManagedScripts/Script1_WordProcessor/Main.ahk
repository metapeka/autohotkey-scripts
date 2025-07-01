#Requires AutoHotkey v2.0
; Main.ahk - Главный модуль
; Кодировка: UTF-8 with BOM
; Версия: 1.1.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07 - Добавлена поддержка IPC

#SingleInstance Force
Persistent

; Функция для записи критических ошибок до инициализации Logger
LogCriticalError(ErrorMessage) {
    try {
        ErrorFile := "errors.log"
        FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        ErrorEntry := "[" . FormattedTime . "]: " . ErrorMessage . "`n"
        
        FileAppend(ErrorEntry, ErrorFile, "UTF-8")
    } catch {
        ; Игнорируем ошибки записи
    }
}

; Загрузка модулей с обработкой ошибок
try {
    #Include "VersionManager.ahk"
} catch as e {
    LogCriticalError("Не удалось загрузить VersionManager.ahk: " . e.Message)
    MsgBox("Критическая ошибка: Не удалось загрузить VersionManager.ahk", "Ошибка", 16)
    ExitApp
}

try {
    #Include "ConfigManager.ahk"
    #Include "FileManager.ahk"
    #Include "Logger.ahk"
    #Include "UIHelper.ahk"
    #Include "WordProcessor.ahk"
    #Include "HotkeyManager.ahk"
} catch as e {
    LogCriticalError("Не удалось загрузить модули: " . e.Message)
    MsgBox("Критическая ошибка: Не удалось загрузить необходимые модули", "Ошибка", 16)
    ExitApp
}

; Загрузка модулей IPC (всегда загружаем, но используем по условию)
#Include "..\..\Shared\JSONHelper.ahk"
#Include "..\..\Shared\IPCProtocol.ahk"
#Include "..\..\Shared\CommandDefinitions.ahk"
#Include "IPC\IPCListener.ahk"
#Include "IPC\CommandHandler.ahk"
#Include "IPC\StatusReporter.ahk"
#Include "IPC\IPCConfig.ahk"

; Глобальные переменные
global Config := {}
global FileMan := {}
global Logger := {}
global UI := {}
global WordProc := {}
global HotkeyMan := {}

; IPC компоненты
global IPCListener := {}
global CommandHandler := {}
global StatusReporter := {}
global UseIPC := false

; Инициализация приложения
InitializeApp()

InitializeApp() {
    global Config, FileMan, Logger, UI, WordProc, HotkeyMan
    global IPCListener, CommandHandler, StatusReporter, UseIPC
    
    try {
        ; Проверяем режим запуска
        UseIPC := (A_Args.Length > 0 && A_Args[1] = "/IPC")
        
        ; Инициализация модулей
        Config := ConfigManager()
        FileMan := FileManager()
        Logger := LoggerModule(Config)
        
        ; Передаем логгер в модули, которым он нужен
        Config.SetLogger(Logger)
        Config.ValidateSettings()  ; Повторная валидация с логированием
        
        UI := UIHelper()
        UI.SetLogger(Logger)  ; Передаем логгер в UI
        WordProc := WordProcessor(Config, FileMan, Logger, UI)
        HotkeyMan := HotkeyManager(Config, WordProc, FileMan, Logger, UI)
        
        ; Логирование запуска
        Logger.Log("Приложение запущено" . (UseIPC ? " в режиме IPC" : ""))
        
        ; Инициализация IPC если нужно
        if (UseIPC) {
            InitializeIPC()
        }
        
        ; Проверка наличия модулей
        MissingModules := VersionManager.CheckModulesExistence()
        if (MissingModules.Length > 0) {
            Logger.LogError("Отсутствуют модули: " . MissingModules.Join(", "))
        }
        
        ; Проверка версий модулей
        VersionCheck := VersionManager.CheckVersionConsistency()
        if (VersionCheck.Length > 0) {
            Logger.LogError("Обнаружены несоответствия версий в " . VersionCheck.Length . " модулях")
        }
        
        ; Сохранение информации о версиях
        VersionManager.SaveVersionInfo()
        
        ; Инициализация горячих клавиш
        HotkeyMan.Initialize()
        
    } catch as e {
        ; Пытаемся залогировать ошибку, если Logger уже создан
        if (IsObject(Logger) && Logger.HasMethod("LogError")) {
            Logger.LogError("Ошибка инициализации: " . e.Message . " в строке " . e.Line)
        } else {
            ; Если Logger не создан, пишем в файл напрямую
            try {
                ErrorFile := "errors.log"
                FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
                ErrorEntry := "[" . FormattedTime . "]: Критическая ошибка инициализации: " . e.Message . " в строке " . e.Line . "`n"
                
                ; Пытаемся записать напрямую
                if (FileExist(ErrorFile)) {
                    FileAppend(ErrorEntry, ErrorFile, "UTF-8")
                } else {
                    FileAppend(ErrorEntry, ErrorFile, "UTF-8")
                }
            } catch {
                ; Если и это не удалось, просто показываем сообщение
            }
        }
        
        MsgBox("Ошибка инициализации: " . e.Message . "`nСтрока: " . e.Line, "Критическая ошибка", 16)
        ExitApp
    }
}

; Инициализация IPC компонентов
InitializeIPC() {
    global IPCListener, CommandHandler, StatusReporter, UseIPC
    global Config, FileMan, Logger, UI, WordProc
    
    try {
        ; Загружаем конфигурацию IPC
        IPCConfig.LoadFromINI()
        
        if (!IPCConfig.ENABLE_IPC) {
            Logger.Log("IPC отключен в настройках")
            return
        }
        
        ; Создаем компоненты IPC
        CommandHandler := CommandHandler(WordProc, FileMan, Logger, Config, UI)
        StatusReporter := StatusReporter("WordProcessor")
        IPCListener := IPCListener("WordProcessor")
        
        ; Инициализируем слушатель
        IPCListener.Initialize(CommandHandler, StatusReporter)
        
        Logger.Log("IPC компоненты инициализированы")
        
    } catch as e {
        Logger.LogError("Ошибка инициализации IPC: " . e.Message)
        ; Продолжаем работу без IPC
        UseIPC := false
    }
}

; Обработка закрытия программы
OnExit(ExitHandler)

ExitHandler(*) {
    global IPCListener, StatusReporter, UseIPC
    
    ; Останавливаем IPC если активен
    if (UseIPC) {
        if (IsObject(IPCListener)) {
            IPCListener.Stop()
        }
        
        if (IsObject(StatusReporter)) {
            StatusReporter.EnableReporting(false)
        }
    }
    
    ExitApp
}