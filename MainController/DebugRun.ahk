#Requires AutoHotkey v2.0
; DebugRun.ahk - Скрипт для тестирования запуска скриптов
; Кодировка: UTF-8 with BOM
; Версия: 1.0.0

; Создаем GUI для отображения результатов
DebugGui := Gui("+Resize", "Тестирование запуска скриптов")
DebugGui.SetFont("s10", "Segoe UI")
DebugGui.Add("Text", "w500", "Тестирование различных способов запуска скриптов AutoHotkey")
ResultsEdit := DebugGui.Add("Edit", "r20 w500 ReadOnly", "")

; Проверяем наличие Main.ahk
ScriptPath := A_ScriptDir . "\..\ManagedScripts\Script1_WordProcessor\Main.ahk"
AppendResult("Проверка наличия файла: " . ScriptPath)

if (FileExist(ScriptPath)) {
    AppendResult("✅ Файл найден")
} else {
    ; Пробуем альтернативный путь
    ScriptPath := A_ScriptDir . "\ManagedScripts\Script1_WordProcessor\Main.ahk"
    AppendResult("Проверка альтернативного пути: " . ScriptPath)
    
    if (FileExist(ScriptPath)) {
        AppendResult("✅ Файл найден по альтернативному пути")
    } else {
        AppendResult("❌ Файл не найден")
        ScriptPath := ""
    }
}

; Если файл найден, пробуем разные способы запуска
if (ScriptPath) {
    ; Способ 1: Простой Run
    AppendResult("`nСпособ 1: Простой Run()")
    try {
        RunResult := Run(ScriptPath)
        AppendResult("✅ Запуск успешен: " . RunResult)
    } catch Error as e {
        AppendResult("❌ Ошибка: " . e.Message)
    }
    
    ; Способ 2: Run с параметром /IPC
    AppendResult("`nСпособ 2: Run() с параметром /IPC")
    try {
        RunResult := Run(ScriptPath . " /IPC")
        AppendResult("✅ Запуск успешен: " . RunResult)
    } catch Error as e {
        AppendResult("❌ Ошибка: " . e.Message)
    }
    
    ; Способ 3: Run через ComSpec
    AppendResult("`nСпособ 3: Run() через ComSpec")
    try {
        RunResult := Run(ComSpec . " /c " . ScriptPath)
        AppendResult("✅ Запуск успешен: " . RunResult)
    } catch Error as e {
        AppendResult("❌ Ошибка: " . e.Message)
    }
}

; Сохраняем результаты в файл
SaveResults()

; Показываем GUI
DebugGui.Show()

; Функция для добавления результата в Edit контрол
AppendResult(text) {
    global ResultsEdit
    CurrentText := ResultsEdit.Value
    ResultsEdit.Value := CurrentText . (CurrentText ? "`n" : "") . text
}

; Функция для сохранения результатов в файл
SaveResults() {
    global ResultsEdit
    FileOpen(A_ScriptDir . "\run_debug.txt", "w", "UTF-8").Write(ResultsEdit.Value).Close()
}