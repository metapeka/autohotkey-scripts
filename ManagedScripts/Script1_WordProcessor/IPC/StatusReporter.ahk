#Requires AutoHotkey v2.0
; StatusReporter.ahk - Отправитель статусов для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class StatusReporter {
    __New(ScriptName := "WordProcessor") {
        this.ScriptName := ScriptName
        this.MainControllerHwnd := 0
        this.ReportingEnabled := true
        this.ReportInterval := 5000  ; 5 секунд
        
        ; Запускаем поиск главного контроллера
        this.FindMainController()
        
        ; Запускаем периодическую отправку статуса
        SetTimer(ObjBindMethod(this, "SendPeriodicStatus"), this.ReportInterval)
    }
    
    ; Поиск окна главного контроллера
    FindMainController() {
        try {
            ; Ищем окно приемника статусов
            this.MainControllerHwnd := WinExist("MainController_Status_Receiver ahk_class AutoHotkey")
            
            if (this.MainControllerHwnd) {
                return true
            }
        } catch {
            ; Игнорируем ошибки
        }
        
        return false
    }
    
    ; Отправка статуса главному контроллеру
    SendStatus(Status) {
        if (!this.ReportingEnabled) {
            return false
        }
        
        ; Если не нашли контроллер, пытаемся найти снова
        if (!this.MainControllerHwnd) {
            this.FindMainController()
        }
        
        if (!this.MainControllerHwnd) {
            return false
        }
        
        ; Добавляем имя скрипта
        Status.script := this.ScriptName
        Status.timestamp := A_Now
        
        ; Отправляем через IPC
        return this.SendStatusTo(this.MainControllerHwnd, Status)
    }
    
    ; Отправка статуса конкретному окну
    SendStatusTo(TargetHwnd, Status) {
        try {
            return IPCProtocol.SendData(TargetHwnd, Status, IPCProtocol.MARKER_STATUS)
        } catch {
            return false
        }
    }
    
    ; Периодическая отправка статуса
    SendPeriodicStatus() {
        if (!this.ReportingEnabled) {
            return
        }
        
        ; Получаем текущий статус от CommandHandler
        if (IsObject(global.CommandHandler)) {
            Status := global.CommandHandler.GetCurrentStatus()
            this.SendStatus(Status)
        }
    }
    
    ; Включить/выключить отправку статусов
    EnableReporting(Enable := true) {
        this.ReportingEnabled := Enable
    }
    
    ; Установить интервал отправки
    SetReportInterval(IntervalMs) {
        this.ReportInterval := IntervalMs
        SetTimer(ObjBindMethod(this, "SendPeriodicStatus"), IntervalMs)
    }
    
    ; Отправка события
    SendEvent(EventType, EventData := {}) {
        Event := {
            type: "event",
            eventType: EventType,
            data: EventData,
            script: this.ScriptName,
            timestamp: A_Now
        }
        
        return this.SendStatus(Event)
    }
    
    ; Отправка ошибки
    SendError(ErrorMessage, ErrorDetails := {}) {
        ErrorStatus := {
            type: "error",
            error: ErrorMessage,
            details: ErrorDetails,
            script: this.ScriptName,
            timestamp: A_Now
        }
        
        return this.SendStatus(ErrorStatus)
    }
    
    ; Отправка прогресса
    SendProgress(Current, Total, Message := "") {
        Progress := {
            type: "progress",
            current: Current,
            total: Total,
            percent: Round((Current / Total) * 100),
            message: Message,
            script: this.ScriptName,
            timestamp: A_Now
        }
        
        return this.SendStatus(Progress)
    }
}