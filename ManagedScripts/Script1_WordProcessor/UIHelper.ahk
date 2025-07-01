#Requires AutoHotkey v2.0
; UIHelper.ahk - Помощник интерфейса
; Кодировка: UTF-8 with BOM
; Версия: 1.0.1
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07 - Добавлена поддержка логгера

class UIHelper {
    __New() {
        ; Инициализация
        this.Logger := {}  ; Будет установлен после инициализации
    }
    
    ; Установка логгера
    SetLogger(Logger) {
        this.Logger := Logger
    }
    
    ; Показать сообщение
    ShowMessage(Message, Title := "Информация") {
        MsgBox(Message, Title)
    }
    
    ; Показать ошибку
    ShowError(ErrorMessage) {
        MsgBox("Ошибка: " . ErrorMessage, "Ошибка", 16)
    }
    
    ; Запросить число
    GetNumberInput(Prompt, Title, Default := "") {
        try {
            Result := InputBox(Prompt, Title, "W300 H150", Default)
            if (Result.Result = "Cancel")
                return -1
                
            Value := Result.Value
            if (!IsInteger(Value) || Value < 1) {
                this.ShowError("Введите целое число больше 0!")
                return -1
            }
            return Integer(Value)
        } catch {
            return -1
        }
    }
    
    ; Показать уведомление в трее
    ShowTrayTip(Title, Text, Icon := 1) {
        TrayTip(Text, Title, Icon)
    }
    
    ; Показать статистику завершения
    ShowCompletionStats(SentCount, LogFile) {
        Message := "Цикл завершен! Отправлено " . SentCount . " строк.`nЛог сохранен в " . LogFile
        this.ShowMessage(Message, "Завершено")
    }
    
    ; Показать предупреждение
    ShowWarning(Message) {
        MsgBox(Message, "Предупреждение", 48)
    }
    
    ; Подтверждение действия
    ConfirmAction(Message) {
        Result := MsgBox(Message, "Подтверждение", 4)
        return (Result = "Yes")
    }
}