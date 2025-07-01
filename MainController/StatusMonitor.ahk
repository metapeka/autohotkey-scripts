#Requires AutoHotkey v2.0
; StatusMonitor.ahk - Монитор статуса скриптов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "../Shared/JSONHelper.ahk"

class StatusMonitor {
    __New(Logger) {
        this.Logger := Logger
        this.ScriptStatuses := Map()
        this.StatusHistory := Map()
        this.IsMonitoring := false
        
        ; Максимальное количество записей истории для каждого скрипта
        this.MaxHistoryEntries := 100
    }
    
    ; Начать мониторинг
    StartMonitoring() {
        if (!this.IsMonitoring) {
            ; Регистрируем обработчик сообщений для получения статусов
            OnMessage(0x4a, ObjBindMethod(this, "ReceiveStatus"))
            this.IsMonitoring := true
            this.Logger.LogInfo("Мониторинг статуса скриптов запущен")
        }
    }
    
    ; Остановить мониторинг
    StopMonitoring() {
        if (this.IsMonitoring) {
            ; Удаляем обработчик сообщений
            OnMessage(0x4a, ObjBindMethod(this, "ReceiveStatus"), 0)
            this.IsMonitoring := false
            this.Logger.LogInfo("Мониторинг статуса скриптов остановлен")
        }
    }
    
    ; Обработчик получения статуса
    ReceiveStatus(wParam, lParam, msg, hwnd) {
        ; Получаем данные из COPYDATASTRUCT
        CDS := Buffer(A_PtrSize * 3, lParam)
        dwData := NumGet(CDS, 0, "Ptr")
        cbData := NumGet(CDS, A_PtrSize, "Ptr")
        lpData := NumGet(CDS, A_PtrSize * 2, "Ptr")
        
        ; Проверяем, что это статус (dwData = 3)
        if (dwData != 3) {
            return 0
        }
        
        ; Получаем строку JSON
        jsonStatus := StrGet(lpData, cbData, "UTF-8")
        
        ; Логируем полученный статус
        this.Logger.LogInfo("Получен статус: " . jsonStatus)
        
        ; Парсим JSON
        try {
            status := JSON.Parse(jsonStatus)
            
            ; Проверяем наличие имени скрипта
            if (status.HasProp("scriptName")) {
                scriptName := status.scriptName
                
                ; Обновляем статус скрипта
                this.UpdateScriptStatus(scriptName, status)
            }
        } catch Error as e {
            this.Logger.LogError("Ошибка при обработке статуса: " . e.Message)
        }
        
        return 1 ; Сообщение обработано
    }
    
    ; Обновление статуса скрипта
    UpdateScriptStatus(scriptName, status) {
        ; Добавляем временную метку
        status.timestamp := A_Now
        
        ; Обновляем текущий статус
        this.ScriptStatuses[scriptName] := status
        
        ; Добавляем в историю
        if (!this.StatusHistory.Has(scriptName)) {
            this.StatusHistory[scriptName] := []
        }
        
        ; Добавляем новую запись в начало массива
        this.StatusHistory[scriptName].InsertAt(1, status)
        
        ; Ограничиваем размер истории
        if (this.StatusHistory[scriptName].Length > this.MaxHistoryEntries) {
            this.StatusHistory[scriptName].Pop()
        }
        
        ; Логируем обновление статуса
        this.Logger.LogInfo("Статус скрипта " . scriptName . " обновлен")
    }
    
    ; Получение последнего статуса скрипта
    GetLatestStatus(scriptName) {
        if (this.ScriptStatuses.Has(scriptName)) {
            return this.ScriptStatuses[scriptName]
        }
        return ""
    }
    
    ; Получение истории статусов скрипта
    GetStatusHistory(scriptName, count := 0) {
        if (!this.StatusHistory.Has(scriptName)) {
            return []
        }
        
        if (count > 0 && count < this.StatusHistory[scriptName].Length) {
            return this.StatusHistory[scriptName].Slice(1, count)
        }
        
        return this.StatusHistory[scriptName]
    }
    
    ; Очистка истории статусов скрипта
    ClearStatusHistory(scriptName) {
        if (this.StatusHistory.Has(scriptName)) {
            this.StatusHistory[scriptName] := []
            this.Logger.LogInfo("История статусов скрипта " . scriptName . " очищена")
        }
    }
    
    ; Очистка всей истории статусов
    ClearAllStatusHistory() {
        for scriptName in this.StatusHistory {
            this.StatusHistory[scriptName] := []
        }
        this.Logger.LogInfo("Вся история статусов очищена")
    }
    
    ; Получение списка всех скриптов с известным статусом
    GetMonitoredScripts() {
        scripts := []
        for scriptName in this.ScriptStatuses {
            scripts.Push(scriptName)
        }
        return scripts
    }
    
    ; Экспорт истории статусов в JSON
    ExportStatusHistory(scriptName, filePath) {
        if (!this.StatusHistory.Has(scriptName)) {
            return { success: false, error: "История статусов для скрипта не найдена" }
        }
        
        try {
            jsonHistory := JSON.Stringify(this.StatusHistory[scriptName])
            FileOpen(filePath, "w", "UTF-8").Write(jsonHistory).Close()
            return { success: true }
        } catch Error as e {
            return { success: false, error: e.Message }
        }
    }
}