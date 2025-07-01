#Requires AutoHotkey v2.0
; GUI_Manager.ahk - Менеджер интерфейса
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class GUIManager {
    __New(ProcessMan, CmdSender, StatusMon) {
        this.ProcessMan := ProcessMan
        this.CmdSender := CmdSender
        this.StatusMon := StatusMon
        this.MainGui := {}
        this.Controls := Map()
        this.ScriptConfigs := this.LoadScriptConfigs()
    }
    
    CreateMainWindow() {
        ; Создаем главное окно
        this.MainGui := Gui("+Resize", "AutoHotkey Script Controller")
        this.MainGui.SetFont("s10", "Segoe UI")
        
        ; Заголовок
        this.MainGui.Add("Text", "Section w600 Center", "🎮 Центр управления скриптами")
        this.MainGui.SetFont("s9")
        
        ; Tabs для разных скриптов
        Tab := this.MainGui.Add("Tab3", "w600 h400", ["WordProcessor", "Другие скрипты", "Настройки"])
        
        ; === Tab 1: WordProcessor ===
        Tab.UseTab(1)
        
        ; Статус скрипта
        this.MainGui.Add("GroupBox", "w580 h80 Section", "📊 Статус")
        StatusText := this.MainGui.Add("Text", "xs+10 ys+25 w200", "Статус: Остановлен")
        ProcessInfo := this.MainGui.Add("Text", "xs+10 ys+45 w400", "PID: -")
        this.Controls["WordProc_Status"] := StatusText
        this.Controls["WordProc_ProcessInfo"] := ProcessInfo
        
        ; Управление
        this.MainGui.Add("GroupBox", "xs w580 h120", "🎯 Управление")
        
        ; Кнопки управления
        BtnStart := this.MainGui.Add("Button", "xs+10 yp+30 w120 h35", "▶️ Запустить")
        BtnStart.OnEvent("Click", (*) => this.StartWordProcessor())
        
        BtnStop := this.MainGui.Add("Button", "x+10 w120 h35", "⏹️ Остановить")
        BtnStop.OnEvent("Click", (*) => this.StopWordProcessor())
        BtnStop.Enabled := false
        this.Controls["WordProc_BtnStop"] := BtnStop
        
        BtnPause := this.MainGui.Add("Button", "x+10 w120 h35", "⏸️ Пауза")
        BtnPause.OnEvent("Click", (*) => this.PauseResumeWordProcessor())
        BtnPause.Enabled := false
        this.Controls["WordProc_BtnPause"] := BtnPause
        
        ; Команды
        this.MainGui.Add("Text", "xs+10 y+20", "Количество циклов:")
        EditLoops := this.MainGui.Add("Edit", "x+10 w60 Number", "10")
        this.Controls["WordProc_Loops"] := EditLoops
        
        BtnProcess := this.MainGui.Add("Button", "x+20 w150 h25", "🔄 Начать обработку")
        BtnProcess.OnEvent("Click", (*) => this.StartProcessing())
        BtnProcess.Enabled := false
        this.Controls["WordProc_BtnProcess"] := BtnProcess
        
        BtnRestore := this.MainGui.Add("Button", "x+10 w150 h25", "♻️ Восстановить файлы")
        BtnRestore.OnEvent("Click", (*) => this.RestoreFiles())
        BtnRestore.Enabled := false
        this.Controls["WordProc_BtnRestore"] := BtnRestore
        
        ; Статистика
        this.MainGui.Add("GroupBox", "xs w580 h100", "📈 Статистика")
        StatsText := this.MainGui.Add("Text", "xs+10 yp+25 w560 h60", "Ожидание данных...")
        this.Controls["WordProc_Stats"] := StatsText
        
        ; === Tab 2: Другие скрипты ===
        Tab.UseTab(2)
        this.MainGui.Add("Text", "w580 Center", "Здесь будут другие управляемые скрипты")
        
        ; === Tab 3: Настройки ===
        Tab.UseTab(3)
        this.MainGui.Add("Text", "Section", "Путь к скриптам:")
        PathEdit := this.MainGui.Add("Edit", "xs w400 ReadOnly", A_ScriptDir . "\ManagedScripts")
        this.MainGui.Add("Button", "x+5 w50", "...").OnEvent("Click", (*) => this.SelectScriptsPath())
        
        this.MainGui.Add("CheckBox", "xs y+20", "Автозапуск скриптов при старте")
        this.MainGui.Add("CheckBox", "xs y+10", "Сворачивать в трей")
        this.MainGui.Add("CheckBox", "xs y+10", "Логировать все команды")
        
        ; Конец табов
        Tab.UseTab()
        
        ; Кнопки внизу
        this.MainGui.Add("Button", "w100 h30", "Обновить").OnEvent("Click", (*) => this.RefreshStatus())
        this.MainGui.Add("Button", "x+10 w100 h30", "Логи").OnEvent("Click", (*) => this.ShowLogs())
        this.MainGui.Add("Button", "x+280 w100 h30", "Выход").OnEvent("Click", (*) => ExitApp())
        
        ; События окна
        this.MainGui.OnEvent("Close", (*) => ExitApp())
        
        ; Обновляем статус
        this.RefreshStatus()
        
        ; Таймер обновления статуса
        SetTimer(() => this.UpdateStatusDisplay(), 1000)
        
        return this.MainGui
    }
    
    ; Запуск WordProcessor
    StartWordProcessor() {
        ScriptPath := A_ScriptDir . "\..\ManagedScripts\Script1_WordProcessor\Main.ahk"
        
        ; Проверяем абсолютный путь
        if (!FileExist(ScriptPath)) {
            ; Пробуем альтернативный путь
            ScriptPath := A_ScriptDir . "\..\..\ManagedScripts\Script1_WordProcessor\Main.ahk"
            
            if (!FileExist(ScriptPath)) {
                MsgBox("Скрипт не найден:`n" . ScriptPath . "`n`nТекущая папка:`n" . A_ScriptDir, "Ошибка", 16)
                return
            }
        }
        
        Result := this.ProcessMan.StartScript("WordProcessor", ScriptPath)
        
        if (Result.Success) {
            this.Controls["WordProc_Status"].Text := "Статус: ✅ Запущен"
            this.Controls["WordProc_ProcessInfo"].Text := "PID: " . Result.PID
            this.Controls["WordProc_BtnStop"].Enabled := true
            this.Controls["WordProc_BtnPause"].Enabled := true
            this.Controls["WordProc_BtnProcess"].Enabled := true
            this.Controls["WordProc_BtnRestore"].Enabled := true
            
            ; Ждем инициализации скрипта
            Sleep(1000)
            
            ; Запрашиваем статус
            this.CmdSender.SendCommand("WordProcessor", {
                command: "GET_STATUS"
            })
        } else {
            MsgBox("Не удалось запустить скрипт: " . Result.Error, "Ошибка", 16)
        }
    }
    
    ; Остановка WordProcessor
    StopWordProcessor() {
        Result := this.ProcessMan.StopScript("WordProcessor")
        
        if (Result.Success) {
            this.Controls["WordProc_Status"].Text := "Статус: ⏹️ Остановлен"
            this.Controls["WordProc_ProcessInfo"].Text := "PID: -"
            this.Controls["WordProc_BtnStop"].Enabled := false
            this.Controls["WordProc_BtnPause"].Enabled := false
            this.Controls["WordProc_BtnProcess"].Enabled := false
            this.Controls["WordProc_BtnRestore"].Enabled := false
            this.Controls["WordProc_Stats"].Text := "Скрипт остановлен"
        }
    }
    
    ; Пауза/возобновление
    PauseResumeWordProcessor() {
        this.CmdSender.SendCommand("WordProcessor", {
            command: "PAUSE_RESUME"
        })
        
        ; Обновляем текст кнопки
        CurrentText := this.Controls["WordProc_BtnPause"].Text
        if (InStr(CurrentText, "Пауза")) {
            this.Controls["WordProc_BtnPause"].Text := "▶️ Продолжить"
        } else {
            this.Controls["WordProc_BtnPause"].Text := "⏸️ Пауза"
        }
    }
    
    ; Начать обработку
    StartProcessing() {
        LoopCount := this.Controls["WordProc_Loops"].Text
        
        if (!IsInteger(LoopCount) || LoopCount < 1) {
            MsgBox("Введите корректное число циклов", "Ошибка", 16)
            return
        }
        
        this.CmdSender.SendCommand("WordProcessor", {
            command: "START_PROCESSING",
            params: {
                loopCount: Integer(LoopCount)
            }
        })
    }
    
    ; Восстановить файлы
    RestoreFiles() {
        Result := MsgBox("Восстановить words.txt из used_words.txt?", "Подтверждение", 4)
        
        if (Result = "Yes") {
            this.CmdSender.SendCommand("WordProcessor", {
                command: "RESTORE_FILES"
            })
        }
    }
    
    ; Обновить статус
    RefreshStatus() {
        ; Проверяем все скрипты
        Scripts := this.ProcessMan.GetRunningScripts()
        
        for ScriptName, Info in Scripts {
            if (ScriptName = "WordProcessor") {
                this.CmdSender.SendCommand("WordProcessor", {
                    command: "GET_STATUS"
                })
                
                this.CmdSender.SendCommand("WordProcessor", {
                    command: "GET_STATS"
                })
            }
        }
    }
    
    ; Обновление отображения статуса
    UpdateStatusDisplay() {
        ; Получаем последние статусы из StatusMonitor
        Status := this.StatusMon.GetLatestStatus("WordProcessor")
        
        if (Status) {
            if (Status.HasProp("stats")) {
                StatsText := "📊 Обработано слов: " . Status.stats.wordsProcessed . "`n"
                StatsText .= "⏱️ Время работы: " . Status.stats.runTime . " сек`n"
                StatsText .= "📝 Осталось слов: " . Status.stats.wordsRemaining
                
                this.Controls["WordProc_Stats"].Text := StatsText
            }
            
            if (Status.HasProp("state")) {
                StateText := "Статус: "
                Switch Status.state {
                    Case "running": StateText .= "✅ Работает"
                    Case "paused": StateText .= "⏸️ Пауза"
                    Case "processing": StateText .= "🔄 Обработка..."
                    Default: StateText .= "⏹️ Остановлен"
                }
                this.Controls["WordProc_Status"].Text := StateText
            }
        }
    }
    
    ; Показать логи
    ShowLogs() {
        LogPath := A_ScriptDir . "\Logs\main_controller.log"
        if (FileExist(LogPath)) {
            Run("notepad.exe " . LogPath)
        } else {
            MsgBox("Файл логов не найден", "Информация", 64)
        }
    }
    
    ; Выбор пути к скриптам
    SelectScriptsPath() {
        SelectedFolder := DirSelect(, 3, "Выберите папку со скриптами")
        if (SelectedFolder) {
            ; Сохраняем новый путь
            IniWrite(SelectedFolder, "settings.ini", "Paths", "ScriptsFolder")
        }
    }
    
    ; Загрузка конфигураций скриптов
    LoadScriptConfigs() {
        ; Здесь можно загрузить конфигурации различных скриптов
        return Map(
            "WordProcessor", {
                name: "Word Processor",
                path: "Script1_WordProcessor\Main.ahk",
                description: "Обработка слов из файла"
            }
        )
    }
    
    ; Сохранение настроек
    SaveSettings() {
        ; Сохраняем позицию окна и настройки
        if (this.MainGui) {
            this.MainGui.GetPos(&X, &Y, &W, &H)
            IniWrite(X, "settings.ini", "Window", "X")
            IniWrite(Y, "settings.ini", "Window", "Y")
            IniWrite(W, "settings.ini", "Window", "Width")
            IniWrite(H, "settings.ini", "Window", "Height")
        }
    }
}