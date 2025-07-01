#Requires AutoHotkey v2.0
; ProcessManager.ahk - Менеджер процессов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class ProcessManager {
    __New() {
        this.RunningScripts := Map()
        this.Logger := this.CreateLogger()
    }
    
    CreateLogger() {
        ; Простой логгер для процессов
        return {
            Log: (msg) => this.WriteLog(msg),
            Error: (msg) => this.WriteLog("[ERROR] " . msg)
        }
    }
    
    WriteLog(Message) {
        LogFile := A_ScriptDir . "\Logs\main_controller.log"
        
        ; Создаем папку если не существует
        LogDir := A_ScriptDir . "\Logs"
        if (!DirExist(LogDir)) {
            DirCreate(LogDir)
        }
        
        FormattedTime := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        LogEntry := "[" . FormattedTime . "] " . Message . "`n"
        
        try {
            FileAppend(LogEntry, LogFile, "UTF-8")
        } catch {
            ; Игнорируем ошибки записи
        }
    }
    
    ; Запуск скрипта
    StartScript(ScriptName, ScriptPath) {
        try {
            ; Проверяем, не запущен ли уже
            if (this.RunningScripts.Has(ScriptName)) {
                Info := this.RunningScripts[ScriptName]
                if (ProcessExist(Info.PID)) {
                    return {Success: false, Error: "Скрипт уже запущен"}
                }
            }
            
            ; Запускаем скрипт с параметром IPC
            RunCmd := '"' . A_AhkPath . '" "' . ScriptPath . '" /IPC'
            
            try {
                ; В AutoHotkey v2 Run возвращает PID
                PID := Run(RunCmd)
                
                ; Даем время на инициализацию
                Sleep(500)
                
            } catch as e {
                throw Error("Не удалось запустить процесс: " . e.Message)
            }
            
            ; Сохраняем информацию
            this.RunningScripts[ScriptName] := {
                PID: PID,
                Path: ScriptPath,
                StartTime: A_Now,
                Status: "running"
            }
            
            this.Logger.Log("Запущен скрипт " . ScriptName . " (PID: " . PID . ")")
            
            return {Success: true, PID: PID}
            
        } catch as e {
            this.WriteLog("[ERROR] Ошибка запуска " . ScriptName . ": " . e.Message)
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Остановка скрипта
    StopScript(ScriptName) {
        try {
            if (!this.RunningScripts.Has(ScriptName)) {
                return {Success: false, Error: "Скрипт не запущен"}
            }
            
            Info := this.RunningScripts[ScriptName]
            
            ; Сначала пытаемся отправить команду завершения
            if (ProcessExist(Info.PID)) {
                ; Отправляем команду мягкого завершения через IPC
                IPCProtocol.SendCommand(Info.PID, {command: "SHUTDOWN"})
                
                ; Ждем завершения
                Loop 30 {  ; 3 секунды
                    Sleep(100)
                    if (!ProcessExist(Info.PID)) {
                        break
                    }
                }
                
                ; Если не завершился, принудительно
                if (ProcessExist(Info.PID)) {
                    ProcessClose(Info.PID)
                }
            }
            
            this.RunningScripts.Delete(ScriptName)
            this.Logger.Log("Остановлен скрипт " . ScriptName)
            
            return {Success: true}
            
        } catch as e {
            this.WriteLog("[ERROR] Ошибка остановки " . ScriptName . ": " . e.Message)
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Остановка всех скриптов
    StopAllScripts() {
        for ScriptName, Info in this.RunningScripts {
            this.StopScript(ScriptName)
        }
    }
    
    ; Получить список запущенных скриптов
    GetRunningScripts() {
        Running := Map()
        
        ; Проверяем, какие скрипты действительно запущены
        for ScriptName, Info in this.RunningScripts {
            if (ProcessExist(Info.PID)) {
                Running[ScriptName] := Info
            } else {
                ; Удаляем из списка, если процесс не существует
                this.RunningScripts.Delete(ScriptName)
            }
        }
        
        return Running
    }
    
    ; Проверка статуса скрипта
    IsScriptRunning(ScriptName) {
        if (this.RunningScripts.Has(ScriptName)) {
            Info := this.RunningScripts[ScriptName]
            return ProcessExist(Info.PID)
        }
        return false
    }
    
    ; Получить информацию о скрипте
    GetScriptInfo(ScriptName) {
        if (this.RunningScripts.Has(ScriptName)) {
            return this.RunningScripts[ScriptName]
        }
        return {}
    }
}