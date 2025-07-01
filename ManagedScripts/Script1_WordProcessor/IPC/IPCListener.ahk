#Requires AutoHotkey v2.0
; IPCListener.ahk - Слушатель IPC для WordProcessor
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "..\..\Shared\IPCProtocol.ahk"
#Include "..\..\Shared\CommandDefinitions.ahk"
#Include "..\..\Shared\JSONHelper.ahk"
#Include "IPCConfig.ahk"

class IPCListener {
    __New(CommandHandler) {
        this.CommandHandler := CommandHandler
        this.IPCWindowHwnd := 0
        this.CommandQueue := []
        this.IsRunning := false
        this.Logger := global.Logger
        
        ; Инициализация
        this.Initialize()
    }
    
    ; Инициализация слушателя
    Initialize() {
        if (!IPCConfig.ENABLE_IPC) {
            this.Log("IPC отключен в настройках")
            return
        }
        
        ; Создаем окно для IPC
        this.IPCWindowHwnd := IPCProtocol.CreateIPCWindow("WordProcessor_IPC_Window", ObjBindMethod(this, "OnMessage"))
        
        if (!this.IPCWindowHwnd) {
            this.Log("Ошибка создания IPC окна", "ERROR")
            return
        }
        
        this.IsRunning := true
        this.Log("IPC слушатель запущен")
    }
    
    ; Обработчик входящих сообщений
    OnMessage(wParam, lParam, msg, hwnd) {
        ; Получаем данные
        data := IPCProtocol.ReceiveData(lParam)
        
        if (!data) {
            return 0
        }
        
        ; Обрабатываем в зависимости от типа сообщения
        if (data.marker = IPCProtocol.MARKER_COMMAND) {
            ; Это команда
            this.ProcessCommand(data.data, wParam)
        }
        
        return 1
    }
    
    ; Обработка команды
    ProcessCommand(Command, SenderHwnd) {
        if (!Command || !IsObject(Command)) {
            this.Log("Получена некорректная команда", "ERROR")
            return false
        }
        
        ; Логируем команду
        if (IPCConfig.ENABLE_COMMAND_LOG) {
            this.Log("Получена команда: " Command.command " (ID: " Command.id ")", "INFO")
        }
        
        ; Проверяем отправителя
        if (IPCConfig.VALIDATE_SENDER && Command.sender) {
            if (!this.ValidateSender(Command.sender)) {
                this.Log("Отклонена команда от неавторизованного отправителя: " Command.sender, "WARNING")
                this.SendResponse(SenderHwnd, Command.id, "ERROR", "Unauthorized sender")
                return false
            }
        }
        
        ; Проверяем валидность команды
        if (!CommandValidator.ValidateCommand(Command)) {
            this.Log("Получена некорректная команда: " JSON.Stringify(Command), "ERROR")
            this.SendResponse(SenderHwnd, Command.id, "ERROR", "Invalid command format")
            return false
        }
        
        ; Добавляем в очередь и выполняем
        if (this.CommandQueue.Length >= IPCConfig.MAX_COMMAND_QUEUE) {
            this.Log("Очередь команд переполнена", "WARNING")
            this.SendResponse(SenderHwnd, Command.id, "ERROR", "Command queue full")
            return false
        }
        
        ; Добавляем информацию об отправителе
        Command.senderHwnd := SenderHwnd
        
        ; Выполняем команду
        result := this.CommandHandler.ExecuteCommand(Command)
        
        ; Отправляем ответ
        this.SendResponse(SenderHwnd, Command.id, result.status, result.data)
        
        return true
    }
    
    ; Отправка ответа
    SendResponse(TargetHwnd, CommandId, Status, Data := "") {
        if (!TargetHwnd) {
            return false
        }
        
        ; Формируем ответ
        response := ResponseBuilder.BuildResponse(CommandId, Status, Data)
        
        ; Отправляем через IPC
        return IPCProtocol.SendData(TargetHwnd, response, IPCProtocol.MARKER_RESPONSE)
    }
    
    ; Отправка текущего статуса
    SendCurrentStatus(TargetHwnd) {
        if (!TargetHwnd || !this.CommandHandler) {
            return false
        }
        
        ; Получаем текущий статус
        status := this.CommandHandler.GetCurrentStatus()
        
        ; Отправляем через IPC
        return IPCProtocol.SendData(TargetHwnd, status, IPCProtocol.MARKER_STATUS)
    }
    
    ; Проверка отправителя
    ValidateSender(SenderName) {
        if (!IPCConfig.VALIDATE_SENDER) {
            return true
        }
        
        ; Проверяем, есть ли отправитель в списке разрешенных
        for sender in IPCConfig.ALLOWED_SENDERS {
            if (sender = SenderName) {
                return true
            }
        }
        
        return false
    }
    
    ; Остановка слушателя
    Stop() {
        this.IsRunning := false
        this.Log("IPC слушатель остановлен")
    }
    
    ; Логирование
    Log(Message, Level := "INFO") {
        if (this.Logger) {
            this.Logger.Log("[IPC] " Message, Level)
        }
    }
}