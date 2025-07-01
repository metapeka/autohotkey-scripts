#Requires AutoHotkey v2.0
; HotkeyManager.ahk - Менеджер горячих клавиш
; Кодировка: UTF-8 with BOM
; Версия: 1.0.1
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07 - Добавлено логирование ошибок

class HotkeyManager {
    __New(Config, WordProc, FileMan, Logger, UI) {
        this.Config := Config
        this.WordProc := WordProc
        this.FileMan := FileMan
        this.Logger := Logger
        this.UI := UI
        this.Paused := false
    }
    
    ; Инициализация горячих клавиш
    Initialize() {
        ; Позволяем клавише '2' работать как обычно при одиночном нажатии
        Hotkey("2", (*) => Send("2"))
        
        ; 2 & F4 - основной функционал
        Hotkey("2 & F4", (*) => this.HandleMainFunction())
        
        ; 2 & F5 - восстановление файлов
        Hotkey("2 & F5", (*) => this.HandleFileRestore())
        
        ; 2 & F12 - пауза/возобновление
        Hotkey("2 & F12", (*) => this.HandlePause())
        
        ; 2 & F1 - информация о версиях
        Hotkey("2 & F1", (*) => this.ShowVersionInfo())
    }
    
    ; Обработчик основной функции (2 & F4)
    HandleMainFunction() {
        try {
            ; Запрашиваем количество повторов
            LoopCount := this.UI.GetNumberInput(
                "Введите число повторов:", 
                "Количество циклов"
            )
            
            if (LoopCount = -1) {
                this.Logger.LogError("Ошибка: Введено некорректное число повторов")
                return
            }
            
            ; Запускаем обработку
            this.WordProc.ProcessWords(LoopCount)
            
        } catch as e {
            this.Logger.LogError("Ошибка в цикле: " . e.Message)
            this.UI.ShowError(e.Message)
        }
    }
    
    ; Обработчик восстановления файлов (2 & F5)
    HandleFileRestore() {
        this.WordProc.RestoreFiles()
    }
    
    ; Обработчик паузы (2 & F12)
    HandlePause() {
        this.Paused := !this.Paused
        
        if (this.Paused) {
            this.UI.ShowTrayTip("Скрипт приостановлен", 
                               "Нажмите 2+F12 для возобновления")
            Pause(1)
        } else {
            this.UI.ShowTrayTip("Скрипт возобновлен", 
                               "Работа продолжается")
            Pause(0)
        }
    }
    
    ; Показать информацию о версиях
    ShowVersionInfo() {
        Info := VersionManager.GetAllModulesInfo()
        this.UI.ShowMessage(Info, "Информация о версиях модулей")
        this.Logger.Log("Просмотрена информация о версиях")
    }
    
    ; Отключение горячих клавиш
    Disable() {
        Hotkey("2", "Off")
        Hotkey("2 & F4", "Off")
        Hotkey("2 & F5", "Off")
        Hotkey("2 & F12", "Off")
        Hotkey("2 & F1", "Off")
    }
    
    ; Включение горячих клавиш
    Enable() {
        Hotkey("2", "On")
        Hotkey("2 & F4", "On")
        Hotkey("2 & F5", "On")
        Hotkey("2 & F12", "On")
        Hotkey("2 & F1", "On")
    }
}