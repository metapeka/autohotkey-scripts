#Requires AutoHotkey v2.0
; IPCProtocol.ahk - Класс для обмена данными между скриптами через IPC
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

#Include "JSONHelper.ahk"

class IPCProtocol {
    static WM_COPYDATA := 0x004A
    static PROTOCOL_VERSION := "1.0"
    static MAX_DATA_SIZE := 8192 ; Максимальный размер данных в байтах
    
    ; Отправка данных в другое окно
    static SendData(TargetHwnd, Command, Payload := "", ResponseType := "") {
        if (!TargetHwnd || !WinExist("ahk_id " TargetHwnd)) {
            return false
        }
        
        ; Создаем структуру сообщения
        Message := Map()
        Message["protocol_version"] := this.PROTOCOL_VERSION
        Message["timestamp"] := A_Now
        Message["command"] := Command
        Message["source_hwnd"] := WinExist("A")
        Message["source_script"] := A_ScriptName
        
        ; Добавляем полезную нагрузку, если она есть
        if (Payload != "") {
            Message["payload"] := Payload
        }
        
        ; Добавляем тип ответа, если он указан
        if (ResponseType != "") {
            Message["response_type"] := ResponseType
        }
        
        ; Преобразуем сообщение в JSON
        try {
            JSONStr := JSONHelper.ObjectToJSON(Message)
        } catch Error as e {
            return false
        }
        
        ; Проверяем размер данных
        if (StrLen(JSONStr) > this.MAX_DATA_SIZE) {
            return false
        }
        
        ; Отправляем данные через WM_COPYDATA
        CDS := Buffer(3*A_PtrSize)
        NumPut("Ptr", 1, CDS, 0) ; dwData = 1 (идентификатор нашего протокола)
        NumPut("UInt", StrLen(JSONStr) * 2, CDS, A_PtrSize) ; cbData = размер строки в байтах
        NumPut("Ptr", StrPtr(JSONStr), CDS, 2*A_PtrSize) ; lpData = указатель на строку
        
        result := DllCall("SendMessage", "Ptr", TargetHwnd, "UInt", this.WM_COPYDATA, "Ptr", WinExist("A"), "Ptr", CDS, "Ptr")
        return result != 0
    }
    
    ; Обработка полученных данных
    static ProcessReceivedData(wParam, lParam) {
        ; Проверяем, что данные пришли от нашего протокола
        if (NumGet(lParam, 0, "Ptr") != 1) {
            return false
        }
        
        ; Получаем размер данных и указатель на данные
        DataSize := NumGet(lParam, A_PtrSize, "UInt")
        DataPtr := NumGet(lParam, 2*A_PtrSize, "Ptr")
        
        ; Проверяем размер данных
        if (DataSize > this.MAX_DATA_SIZE * 2) { ; *2 для учета Unicode
            return false
        }
        
        ; Преобразуем указатель в строку
        JSONStr := StrGet(DataPtr, "UTF-16")
        
        ; Преобразуем JSON в объект
        try {
            Message := JSONHelper.JSONToObject(JSONStr)
        } catch Error as e {
            return false
        }
        
        ; Проверяем версию протокола
        if (!Message.Has("protocol_version") || Message["protocol_version"] != this.PROTOCOL_VERSION) {
            return false
        }
        
        ; Проверяем наличие обязательных полей
        if (!Message.Has("command") || !Message.Has("source_hwnd") || !Message.Has("source_script")) {
            return false
        }
        
        return Message
    }
    
    ; Отправка ответа на полученное сообщение
    static SendResponse(SourceMessage, ResponseType, Payload := "") {
        if (!SourceMessage.Has("source_hwnd") || !WinExist("ahk_id " SourceMessage["source_hwnd"])) {
            return false
        }
        
        ; Создаем структуру ответа
        Response := Map()
        Response["protocol_version"] := this.PROTOCOL_VERSION
        Response["timestamp"] := A_Now
        Response["response_to"] := SourceMessage["command"]
        Response["response_type"] := ResponseType
        Response["source_hwnd"] := WinExist("A")
        Response["source_script"] := A_ScriptName
        
        ; Добавляем полезную нагрузку, если она есть
        if (Payload != "") {
            Response["payload"] := Payload
        }
        
        ; Преобразуем ответ в JSON
        try {
            JSONStr := JSONHelper.ObjectToJSON(Response)
        } catch Error as e {
            return false
        }
        
        ; Проверяем размер данных
        if (StrLen(JSONStr) > this.MAX_DATA_SIZE) {
            return false
        }
        
        ; Отправляем данные через WM_COPYDATA
        CDS := Buffer(3*A_PtrSize)
        NumPut("Ptr", 1, CDS, 0) ; dwData = 1 (идентификатор нашего протокола)
        NumPut("UInt", StrLen(JSONStr) * 2, CDS, A_PtrSize) ; cbData = размер строки в байтах
        NumPut("Ptr", StrPtr(JSONStr), CDS, 2*A_PtrSize) ; lpData = указатель на строку
        
        result := DllCall("SendMessage", "Ptr", SourceMessage["source_hwnd"], "UInt", this.WM_COPYDATA, "Ptr", WinExist("A"), "Ptr", CDS, "Ptr")
        return result != 0
    }
    
    ; Поиск окна по имени скрипта
    static FindWindowByScriptName(ScriptName) {
        DetectHiddenWindows(true)
        try {
            hwnd := WinExist("ahk_class AutoHotkey ahk_exe AutoHotkey.exe")
            while (hwnd) {
                winTitle := WinGetTitle("ahk_id " hwnd)
                if (InStr(winTitle, ScriptName)) {
                    return hwnd
                }
                hwnd := WinExist("ahk_class AutoHotkey ahk_exe AutoHotkey.exe", , hwnd)
            }
        } finally {
            DetectHiddenWindows(false)
        }
        return 0
    }
}