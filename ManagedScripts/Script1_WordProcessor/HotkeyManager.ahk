#Requires AutoHotkey v2.0
; HotkeyManager.ahk - Менеджер горячих клавиш
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class HotkeyManager {
    __New(WordProc, UI, Logger) {
        this.WordProc := WordProc
        this.UI := UI
        this.Logger := Logger
        this.HotkeysEnabled := false
    }
    
    ; Инициализация горячих клавиш
    Initialize() {
        try {
            ; Регистрируем горячие клавиши
            this.RegisterHotkeys()
            
            ; Включаем горячие клавиши
            this.EnableHotkeys()
            
            this.Logger.Log("Горячие клавиши инициализированы")
            return true
        } catch as e {
            this.Logger.LogError("Ошибка при инициализации горячих клавиш: " . e.Message)
            return false
        }
    }
    
    ; Регистрация горячих клавиш
    RegisterHotkeys() {
        ; F1 - Запуск обработки слов
        HotIfWinNotActive("ahk_class ConsoleWindowClass")
        Hotkey("F1", this.StartProcessingHandler.Bind(this))
        
        ; F2 - Восстановление файлов
        Hotkey("F2", this.RestoreFilesHandler.Bind(this))
        
        ; F3 - Показать справку
        Hotkey("F3", this.ShowHelpHandler.Bind(this))
        
        ; Escape - Выход из приложения
        Hotkey("Escape", this.ExitAppHandler.Bind(this))
        
        HotIf()
    }
    
    ; Включение горячих клавиш
    EnableHotkeys() {
        if (!this.HotkeysEnabled) {
            HotIfWinNotActive("ahk_class ConsoleWindowClass")
            Hotkey("F1", "On")
            Hotkey("F2", "On")
            Hotkey("F3", "On")
            Hotkey("Escape", "On")
            HotIf()
            
            this.HotkeysEnabled := true
            this.Logger.Log("Горячие клавиши включены")
        }
    }
    
    ; Отключение горячих клавиш
    DisableHotkeys() {
        if (this.HotkeysEnabled) {
            HotIfWinNotActive("ahk_class ConsoleWindowClass")
            Hotkey("F1", "Off")
            Hotkey("F2", "Off")
            Hotkey("F3", "Off")
            Hotkey("Escape", "Off")
            HotIf()
            
            this.HotkeysEnabled := false
            this.Logger.Log("Горячие клавиши отключены")
        }
    }
    
    ; Обработчик F1 - Запуск обработки слов
    StartProcessingHandler(ThisHotkey) {
        try {
            this.Logger.Log("Нажата клавиша F1 - Запуск обработки слов")
            
            ; Запрашиваем количество слов для обработки
            LoopCount := this.UI.GetNumberInput("Введите количество слов для обработки:", 10)
            
            if (LoopCount > 0) {
                ; Отключаем горячие клавиши на время обработки
                this.DisableHotkeys()
                
                ; Запускаем обработку
                this.WordProc.ProcessWords(LoopCount)
                
                ; Включаем горячие клавиши после завершения
                this.EnableHotkeys()
            }
        } catch as e {
            this.Logger.LogError("Ошибка при обработке F1: " . e.Message)
            this.UI.ShowError("Ошибка при запуске обработки: " . e.Message)
            this.EnableHotkeys()
        }
    }
    
    ; Обработчик F2 - Восстановление файлов
    RestoreFilesHandler(ThisHotkey) {
        try {
            this.Logger.Log("Нажата клавиша F2 - Восстановление файлов")
            
            ; Запрашиваем подтверждение
            if (this.UI.ConfirmAction("Восстановить файл words.txt из used_words.txt?`n`nЭто действие очистит used_words.txt!")) {
                ; Отключаем горячие клавиши на время операции
                this.DisableHotkeys()
                
                ; Восстанавливаем файлы
                this.WordProc.RestoreFiles()
                
                ; Включаем горячие клавиши после завершения
                this.EnableHotkeys()
            }
        } catch as e {
            this.Logger.LogError("Ошибка при обработке F2: " . e.Message)
            this.UI.ShowError("Ошибка при восстановлении файлов: " . e.Message)
            this.EnableHotkeys()
        }
    }
    
    ; Обработчик F3 - Показать справку
    ShowHelpHandler(ThisHotkey) {
        try {
            this.Logger.Log("Нажата клавиша F3 - Показать справку")
            
            HelpText := "Процессор слов - Справка`n`n" .
                       "F1 - Запуск обработки слов`n" .
                       "F2 - Восстановление файлов`n" .
                       "F3 - Показать эту справку`n" .
                       "Escape - Выход из приложения`n`n" .
                       "Программа читает слова из файла words.txt, `n" .
                       "отправляет их в активное окно и перемещает `n" .
                       "в файл used_words.txt.`n`n" .
                       "Версия: 1.0.0"
            
            this.UI.ShowMessage(HelpText)
        } catch as e {
            this.Logger.LogError("Ошибка при обработке F3: " . e.Message)
            this.UI.ShowError("Ошибка при показе справки: " . e.Message)
        }
    }
    
    ; Обработчик Escape - Выход из приложения
    ExitAppHandler(ThisHotkey) {
        try {
            this.Logger.Log("Нажата клавиша Escape - Выход из приложения")
            
            ; Запрашиваем подтверждение
            if (this.UI.ConfirmAction("Вы уверены, что хотите выйти из приложения?")) {
                this.Logger.Log("Выход из приложения подтвержден пользователем")
                ExitApp()
            }
        } catch as e {
            this.Logger.LogError("Ошибка при обработке Escape: " . e.Message)
            this.UI.ShowError("Ошибка при выходе из приложения: " . e.Message)
        }
    }
}