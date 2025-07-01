/**
 * StatusReporter.ahk
 * Класс для отправки периодических отчетов о статусе приложения через IPC
 * 
 * @version 1.0.0
 * @date 2025-01-07
 */

#Requires AutoHotkey v2.0

class StatusReporter {
    ; Приватные свойства
    _wordProcessor := ""
    _logger := ""
    _ipcProtocol := ""
    _commandDefs := ""
    _mainControllerName := ""
    _reportInterval := 5000 ; Интервал отправки статуса по умолчанию (мс)
    _isReporting := false
    _timer := ""
    
    /**
     * Конструктор класса StatusReporter
     * @param {WordProcessor} wordProcessor - Объект WordProcessor для получения статуса
     * @param {Logger} logger - Объект Logger для логирования
     * @param {IPCProtocol} ipcProtocol - Объект IPCProtocol для отправки сообщений
     * @param {CommandDefinitions} commandDefs - Объект CommandDefinitions для получения команд и статусов
     * @param {String} mainControllerName - Имя главного контроллера для отправки статуса
     * @param {Integer} reportInterval - Интервал отправки статуса (мс)
     */
    __New(wordProcessor, logger, ipcProtocol, commandDefs, mainControllerName, reportInterval := 5000) {
        this._wordProcessor := wordProcessor
        this._logger := logger
        this._ipcProtocol := ipcProtocol
        this._commandDefs := commandDefs
        this._mainControllerName := mainControllerName
        this._reportInterval := reportInterval
        
        ; Создаем таймер для периодической отправки статуса
        this._timer := ObjBindMethod(this, "_SendStatusReport")
    }
    
    /**
     * Начать отправку периодических отчетов о статусе
     */
    StartReporting() {
        if (this._isReporting) {
            return
        }
        
        this._isReporting := true
        this._logger.Log("Начата периодическая отправка статуса с интервалом " this._reportInterval " мс")
        
        ; Запускаем таймер для периодической отправки статуса
        SetTimer(this._timer, this._reportInterval)
        
        ; Отправляем первый отчет о статусе немедленно
        this._SendStatusReport()
    }
    
    /**
     * Остановить отправку периодических отчетов о статусе
     */
    StopReporting() {
        if (!this._isReporting) {
            return
        }
        
        this._isReporting := false
        this._logger.Log("Остановлена периодическая отправка статуса")
        
        ; Останавливаем таймер
        SetTimer(this._timer, 0)
    }
    
    /**
     * Проверить, отправляются ли периодические отчеты о статусе
     * @return {Boolean} true, если отчеты отправляются, иначе false
     */
    IsReporting() {
        return this._isReporting
    }
    
    /**
     * Установить интервал отправки отчетов о статусе
     * @param {Integer} interval - Интервал отправки статуса (мс)
     */
    SetReportInterval(interval) {
        this._reportInterval := interval
        
        ; Если отчеты уже отправляются, обновляем интервал таймера
        if (this._isReporting) {
            SetTimer(this._timer, this._reportInterval)
            this._logger.Log("Обновлен интервал отправки статуса: " this._reportInterval " мс")
        }
    }
    
    /**
     * Получить текущий интервал отправки отчетов о статусе
     * @return {Integer} Интервал отправки статуса (мс)
     */
    GetReportInterval() {
        return this._reportInterval
    }
    
    /**
     * Отправить отчет о статусе немедленно
     */
    SendStatusNow() {
        this._SendStatusReport()
    }
    
    /**
     * Приватный метод для отправки отчета о статусе
     */
    _SendStatusReport() {
        ; Получаем текущий статус от WordProcessor
        currentStatus := this._wordProcessor.GetStatus()
        
        ; Преобразуем статус в строку из CommandDefinitions
        statusStr := ""
        switch (currentStatus) {
            case 0:
                statusStr := this._commandDefs.GetStatus("IDLE")
            case 1:
                statusStr := this._commandDefs.GetStatus("PROCESSING")
            case 2:
                statusStr := this._commandDefs.GetStatus("PAUSED")
            case 3:
                statusStr := this._commandDefs.GetStatus("ERROR")
            default:
                statusStr := this._commandDefs.GetStatus("UNKNOWN")
        }
        
        ; Получаем статистику от WordProcessor
        stats := this._wordProcessor.GetStatistics()
        
        ; Создаем объект данных для отправки
        data := {
            "command": this._commandDefs.GetCommand("STATUS_REPORT"),
            "status": statusStr,
            "statistics": stats
        }
        
        ; Отправляем данные через IPCProtocol
        result := this._ipcProtocol.SendData(this._mainControllerName, data)
        
        ; Логируем результат отправки
        if (result) {
            this._logger.Log("Отправлен отчет о статусе: " statusStr)
        } else {
            this._logger.LogError("Не удалось отправить отчет о статусе: " statusStr)
        }
        
        return result
    }
}