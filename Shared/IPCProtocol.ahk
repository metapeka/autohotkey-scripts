#Requires AutoHotkey v2.0
; IPCProtocol.ahk - Протокол обмена между скриптами
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

class IPCProtocol {
    ; Константы протокола
    static WM_COPYDATA := 0x4A
    static MARKER_COMMAND := 0x4950  ; 'IP' - команда
    static MARKER_STATUS := 0x5354   ; 'ST' - статус
    static MARKER_RESPONSE := 0x5253 ; 'RS' - ответ
    
    ; Отправка команды по PID процесса
    static SendCommand(TargetPID, Command) {
        ; Находим окна процесса
        Windows := WinGetList("ahk_pid " . TargetPID)
        
        for Hwnd in Windows {
            ; Проверяем, что это окно IPC
            Title := WinGetTitle("ahk_id " . Hwnd)
            if (InStr(Title, "_IPC_Window")) {
                return this.SendData(Hwnd, Command, this.MARKER_COMMAND)
            }
        }
        
        return {Success: false, Error: "IPC окно не найдено"}
    }
    
    ; Отправка данных через WM_COPYDATA
    static SendData(TargetHwnd, Data, Marker) {
        try {
            ; Преобразуем в JSON
            JsonData := this.ObjectToJson(Data)
            
            ; Создаем структуру COPYDATASTRUCT
            StringSize := StrLen(JsonData) * 2 + 2
            CopyDataStruct := Buffer(A_PtrSize * 3)
            
            ; dwData = маркер типа сообщения
            NumPut("Ptr", Marker, CopyDataStruct, 0)
            
            ; cbData = размер данных
            NumPut("UInt", StringSize, CopyDataStruct, A_PtrSize)
            
            ; lpData = указатель на данные
            NumPut("Ptr", StrPtr(JsonData), CopyDataStruct, A_PtrSize * 2)
            
            ; Отправляем сообщение
            Result := SendMessage(this.WM_COPYDATA, 0, CopyDataStruct, , "ahk_id " . TargetHwnd)
            
            return {Success: true, Result: Result}
            
        } catch as e {
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Получение данных из WM_COPYDATA
    static ReceiveData(lParam) {
        try {
            ; Извлекаем данные из структуры
            dwData := NumGet(lParam, 0, "Ptr")
            cbData := NumGet(lParam, A_PtrSize, "UInt")
            StringAddress := NumGet(lParam, A_PtrSize * 2, "Ptr")
            
            ; Получаем строку
            JsonData := StrGet(StringAddress, cbData / 2, "UTF-16")
            
            ; Парсим JSON
            Data := this.JsonToObject(JsonData)
            
            return {
                Success: true,
                Marker: dwData,
                Data: Data
            }
            
        } catch as e {
            return {Success: false, Error: e.Message}
        }
    }
    
    ; Преобразование объекта в JSON
    static ObjectToJson(obj) {
        return JSON.Stringify(obj)
    }
    
    ; Преобразование JSON в объект
    static JsonToObject(jsonStr) {
        return JSON.Parse(jsonStr)
    }
    
    ; Создание IPC окна для приема сообщений
    static CreateIPCWindow(WindowName, MessageHandler) {
        IPCWindow := Gui()
        IPCWindow.Title := WindowName . "_IPC_Window"
        IPCWindow.Show("Hide")
        
        ; Регистрируем обработчик
        OnMessage(this.WM_COPYDATA, MessageHandler)
        
        return IPCWindow
    }
}