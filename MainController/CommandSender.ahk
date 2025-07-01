#Requires AutoHotkey v2.0
; CommandSender.ahk - Модуль отправки команд
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

#Include "../Shared/CommandDefinitions.ahk"
#Include "../Shared/JSONHelper.ahk"

class CommandSender {
    __New(Logger) {
        this.Logger := Logger
        this.CommandCounter := 0
        this.ResponseCallbacks := Map()
        this.DefaultTimeout := 5000 ; 5 секунд таймаут по умолчанию
        
        ; Регистрируем обработчик сообщений для получения ответов
        OnMessage(0x4a, ObjBindMethod(this, "ReceiveResponse"))
    }
    
    ; Генерация уникального ID команды
    GenerateCommandId() {
        this.CommandCounter++
        return "CMD_" . A_TickCount . "_" . this.CommandCounter
    }
    
    ; Поиск окна целевого скрипта
    FindTargetWindow(scriptName) {
        ; Ищем окно по имени скрипта
        targetHwnd := WinExist("ahk_class AutoHotkey ahk_pid " . scriptName)
        
        if (!targetHwnd) {
            ; Пробуем найти по имени класса
            targetHwnd := WinExist(scriptName . " ahk_class AutoHotkey")
        }
        
        return targetHwnd
    }
    
    ; Отправка команды скрипту
    SendCommand(scriptName, commandData, callback := "", timeout := 0) {
        ; Находим окно скрипта
        targetHwnd := this.FindTargetWindow(scriptName)
        
        if (!targetHwnd) {
            this.Logger.LogError("Не удалось найти окно скрипта: " . scriptName)
            return { success: false, error: "Скрипт не найден" }
        }
        
        ; Добавляем ID команды
        commandData.commandId := this.GenerateCommandId()
        
        ; Преобразуем команду в JSON
        jsonCommand := JSON.Stringify(commandData)
        
        ; Логируем отправляемую команду
        this.Logger.LogInfo("Отправка команды: " . jsonCommand . " в скрипт: " . scriptName)
        
        ; Подготавливаем данные для отправки
        size := StrPut(jsonCommand, "UTF-8")
        VarSetStrCapacity(&commandBuffer, size)
        StrPut(jsonCommand, &commandBuffer, size, "UTF-8")
        
        ; Создаем структуру COPYDATASTRUCT
        CDS := Buffer(A_PtrSize * 3, 0)
        NumPut("Ptr", 1, CDS, 0)                ; dwData = 1 (команда)
        NumPut("Ptr", size - 1, CDS, A_PtrSize) ; cbData = размер - 1 (без нулевого символа)
        NumPut("Ptr", StrPtr(commandBuffer), CDS, A_PtrSize * 2) ; lpData = указатель на данные
        
        ; Если есть callback, регистрируем его с таймаутом
        if (IsObject(callback) || IsFunc(callback)) {
            this.ResponseCallbacks[commandData.commandId] := {
                callback: callback,
                timestamp: A_TickCount,
                timeout: timeout ? timeout : this.DefaultTimeout
            }
            
            ; Запускаем таймер для проверки таймаутов
            SetTimer(ObjBindMethod(this, "CheckTimeouts"), 1000)
        }
        
        ; Отправляем сообщение
        result := DllCall("SendMessage", "Ptr", targetHwnd, "UInt", 0x4a, 
                         "Ptr", A_ScriptHwnd, "Ptr", CDS, "Ptr")
        
        return { 
            success: result != 0, 
            commandId: commandData.commandId,
            error: result == 0 ? "Ошибка отправки команды" : ""
        }
    }
    
    ; Обработчик получения ответа
    ReceiveResponse(wParam, lParam, msg, hwnd) {
        ; Получаем данные из COPYDATASTRUCT
        CDS := Buffer(A_PtrSize * 3, lParam)
        dwData := NumGet(CDS, 0, "Ptr")
        cbData := NumGet(CDS, A_PtrSize, "Ptr")
        lpData := NumGet(CDS, A_PtrSize * 2, "Ptr")
        
        ; Проверяем, что это ответ (dwData = 2)
        if (dwData != 2) {
            return 0
        }
        
        ; Получаем строку JSON
        jsonResponse := StrGet(lpData, cbData, "UTF-8")
        
        ; Логируем полученный ответ
        this.Logger.LogInfo("Получен ответ: " . jsonResponse)
        
        ; Парсим JSON
        try {
            response := JSON.Parse(jsonResponse)
            
            ; Проверяем наличие ID команды
            if (response.HasProp("commandId")) {
                commandId := response.commandId
                
                ; Проверяем наличие зарегистрированного callback
                if (this.ResponseCallbacks.Has(commandId)) {
                    callbackInfo := this.ResponseCallbacks[commandId]
                    callback := callbackInfo.callback
                    
                    ; Удаляем callback из списка
                    this.ResponseCallbacks.Delete(commandId)
                    
                    ; Вызываем callback
                    if (IsObject(callback)) {
                        callback.Call(response)
                    } else if (IsFunc(callback)) {
                        %callback%(response)
                    }
                }
            }
        } catch Error as e {
            this.Logger.LogError("Ошибка при обработке ответа: " . e.Message)
        }
        
        return 1 ; Сообщение обработано
    }
    
    ; Проверка таймаутов
    CheckTimeouts() {
        currentTime := A_TickCount
        timeoutCommands := []
        
        ; Проверяем все зарегистрированные callbacks
        for commandId, callbackInfo in this.ResponseCallbacks {
            elapsedTime := currentTime - callbackInfo.timestamp
            
            if (elapsedTime > callbackInfo.timeout) {
                ; Добавляем в список для таймаута
                timeoutCommands.Push(commandId)
                
                ; Вызываем callback с ошибкой таймаута
                callback := callbackInfo.callback
                if (IsObject(callback)) {
                    callback.Call({ status: "error", error: "timeout", commandId: commandId })
                } else if (IsFunc(callback)) {
                    %callback%({ status: "error", error: "timeout", commandId: commandId })
                }
            }
        }
        
        ; Удаляем команды с таймаутом
        for index, commandId in timeoutCommands {
            this.ResponseCallbacks.Delete(commandId)
        }
        
        ; Если больше нет активных callbacks, останавливаем таймер
        if (this.ResponseCallbacks.Count == 0) {
            SetTimer(ObjBindMethod(this, "CheckTimeouts"), 0)
        }
    }
}