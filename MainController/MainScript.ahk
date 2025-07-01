#Requires AutoHotkey v2.0
; MainScript.ahk - Главный управляющий скрипт
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07

#SingleInstance Force
Persistent

; Загрузка модулей
#Include "..\Shared\JSONHelper.ahk"
#Include "..\Shared\IPCProtocol.ahk"
#Include "..\Shared\CommandDefinitions.ahk"
#Include "GUI_Manager.ahk"
#Include "ProcessManager.ahk"
#Include "CommandSender.ahk"
#Include "StatusMonitor.ahk"

; Глобальные переменные
global GUI_Manager := {}
global ProcessMan := {}
global CmdSender := {}
global StatusMon := {}
global MainWindow := {}

; Инициализация
InitializeMainController()

InitializeMainController() {
    global GUI_Manager, ProcessMan, CmdSender, StatusMon, MainWindow
    
    try {
        ; Создаем основные компоненты
        ProcessMan := ProcessManager()
        CmdSender := CommandSender()
        StatusMon := StatusMonitor()
        
        ; Создаем GUI
        GUI_Manager := GUIManager(ProcessMan, CmdSender, StatusMon)
        MainWindow := GUI_Manager.CreateMainWindow()
        
        ; Запускаем мониторинг статусов
        StatusMon.StartMonitoring()
        
        ; Показываем окно
        MainWindow.Show()
        
    } catch as e {
        MsgBox("Ошибка инициализации главного контроллера: " . e.Message, "Критическая ошибка", 16)
        ExitApp
    }
}

; Обработка закрытия программы
OnExit(ExitHandler)

ExitHandler(*) {
    global ProcessMan, GUI_Manager, StatusMon
    
    ; Останавливаем мониторинг
    if (IsObject(StatusMon) && StatusMon.HasMethod("StopMonitoring")) {
        StatusMon.StopMonitoring()
    }
    
    ; Останавливаем все управляемые скрипты
    if (IsObject(ProcessMan) && ProcessMan.HasMethod("StopAllScripts")) {
        ProcessMan.StopAllScripts()
    }
    
    ; Сохраняем настройки
    if (IsObject(GUI_Manager) && GUI_Manager.HasMethod("SaveSettings")) {
        GUI_Manager.SaveSettings()
    }
    
    ExitApp
}