#Requires AutoHotkey v2.0
; UIHelper.ahk - Вспомогательный модуль для пользовательского интерфейса
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07

class UIHelper {
    __New() {
        this.Logger := ""
        this.AppTitle := "Процессор слов"
    }
    
    ; Установка логгера
    SetLogger(Logger) {
        this.Logger := Logger
    }
    
    ; Показать сообщение
    ShowMessage(Message) {
        try {
            MsgBox(Message, this.AppTitle, "OK")
            
            if (this.Logger != "") {
                this.Logger.Log("Показано сообщение: " . Message)
            }
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при показе сообщения: " . e.Message)
            }
        }
    }
    
    ; Показать ошибку
    ShowError(ErrorMessage) {
        try {
            MsgBox(ErrorMessage, this.AppTitle . " - Ошибка", "OK Icon!") 
            
            if (this.Logger != "") {
                this.Logger.LogError("Показана ошибка: " . ErrorMessage)
            }
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при показе ошибки: " . e.Message)
            }
        }
    }
    
    ; Получить числовой ввод
    GetNumberInput(Prompt, Default := 1) {
        try {
            InputValue := InputBox(Prompt, this.AppTitle, "w300 h130", Default)
            
            if (InputValue.Result = "Cancel") {
                if (this.Logger != "") {
                    this.Logger.Log("Пользователь отменил ввод числа")
                }
                return 0
            }
            
            ; Проверяем, что введено число
            if InputValue.Value is integer
            {
                if (this.Logger != "") {
                    this.Logger.Log("Пользователь ввел число: " . InputValue.Value)
                }
                return Integer(InputValue.Value)
            }
            else
            {
                this.ShowError("Пожалуйста, введите целое число!")
                return this.GetNumberInput(Prompt, Default)
            }
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при получении числового ввода: " . e.Message)
            }
            return Default
        }
    }
    
    ; Показать уведомление в трее
    ShowTrayTip(Title, Message, Options := "") {
        try {
            TrayTip(Title, Message, Options)
            
            if (this.Logger != "") {
                this.Logger.Log("Показано уведомление: " . Title . " - " . Message)
            }
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при показе уведомления: " . e.Message)
            }
        }
    }
    
    ; Показать статистику завершения
    ShowCompletionStats(SentCount, LogFile) {
        try {
            Message := "Обработка завершена!`n`n" .
                      "Отправлено слов: " . SentCount . "`n`n" .
                      "Подробности записаны в лог: `n" . LogFile
            
            this.ShowMessage(Message)
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при показе статистики: " . e.Message)
            }
        }
    }
    
    ; Показать предупреждение
    ShowWarning(WarningMessage) {
        try {
            MsgBox(WarningMessage, this.AppTitle . " - Предупреждение", "OK Icon!")
            
            if (this.Logger != "") {
                this.Logger.Log("Показано предупреждение: " . WarningMessage)
            }
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при показе предупреждения: " . e.Message)
            }
        }
    }
    
    ; Подтверждение действия
    ConfirmAction(Question) {
        try {
            Result := MsgBox(Question, this.AppTitle . " - Подтверждение", "YesNo Icon?")
            
            if (this.Logger != "") {
                this.Logger.Log("Запрос подтверждения: " . Question . ", Ответ: " . (Result = "Yes" ? "Да" : "Нет"))
            }
            
            return Result = "Yes"
        } catch as e {
            if (this.Logger != "") {
                this.Logger.LogError("Ошибка при запросе подтверждения: " . e.Message)
            }
            return false
        }
    }
}