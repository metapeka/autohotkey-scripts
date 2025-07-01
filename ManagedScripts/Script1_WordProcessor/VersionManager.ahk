#Requires AutoHotkey v2.0
; VersionManager.ahk - Менеджер версий
; Кодировка: UTF-8 with BOM
; Версия: 2.0.0
; Дата создания: 2025-01-07
; Последнее изменение: 2025-01-07 - Добавлено автоматическое чтение версий из файлов

class VersionManager {
    static VERSION := "2.0.0"
    
    ; Ожидаемые версии (для проверки обновлений)
    static EXPECTED_VERSIONS := Map(
        "Main.ahk", "1.0.2",
        "ConfigManager.ahk", "1.0.1",
        "FileManager.ahk", "1.0.0",
        "HotkeyManager.ahk", "1.0.1",
        "Logger.ahk", "1.0.0",
        "UIHelper.ahk", "1.0.1",
        "WordProcessor.ahk", "1.0.0",
        "VersionManager.ahk", "2.0.0"
    )
    
    ; История изменений
    static CHANGELOG := Map(
        "Main.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия",
            "1.0.1 (2025-01-07): Добавлена поддержка версионирования",
            "1.0.2 (2025-01-07): Улучшено логирование ошибок инициализации"
        ],
        "ConfigManager.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия",
            "1.0.1 (2025-01-07): Добавлена поддержка логгера для валидации"
        ],
        "FileManager.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия"
        ],
        "HotkeyManager.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия",
            "1.0.1 (2025-01-07): Добавлено логирование ошибки некорректного ввода"
        ],
        "Logger.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия"
        ],
        "UIHelper.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия",
            "1.0.1 (2025-01-07): Добавлена поддержка логгера"
        ],
        "WordProcessor.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия"
        ],
        "VersionManager.ahk", [
            "1.0.0 (2025-01-07): Первоначальная версия",
            "2.0.0 (2025-01-07): Добавлено автоматическое чтение версий из файлов"
        ]
    )
    
    ; Извлечь версию из файла
    static ExtractVersionFromFile(FilePath) {
        try {
            if (!FileExist(FilePath))
                return "Файл не найден"
            
            FileObj := FileOpen(FilePath, "r", "UTF-8")
            if (!FileObj)
                return "Ошибка чтения"
            
            ; Читаем первые 10 строк файла
            Loop 10 {
                Line := FileObj.ReadLine()
                if (FileObj.AtEOF)
                    break
                    
                ; Ищем строку с версией
                if (RegExMatch(Line, "i);\s*Версия:\s*([0-9]+\.[0-9]+\.[0-9]+)", &Match)) {
                    FileObj.Close()
                    return Match[1]
                }
            }
            
            FileObj.Close()
            return "Версия не указана"
            
        } catch as e {
            return "Ошибка: " . e.Message
        }
    }
    
    ; Извлечь дату последнего изменения из файла
    static ExtractLastModifiedFromFile(FilePath) {
        try {
            if (!FileExist(FilePath))
                return "Файл не найден"
            
            FileObj := FileOpen(FilePath, "r", "UTF-8")
            if (!FileObj)
                return "Ошибка чтения"
            
            ; Читаем первые 10 строк файла
            Loop 10 {
                Line := FileObj.ReadLine()
                if (FileObj.AtEOF)
                    break
                    
                ; Ищем строку с последним изменением
                if (RegExMatch(Line, "i);\s*Последнее изменение:\s*(.+)$", &Match)) {
                    FileObj.Close()
                    return Trim(Match[1])
                }
            }
            
            FileObj.Close()
            return "Не указано"
            
        } catch as e {
            return "Ошибка: " . e.Message
        }
    }
    
    ; Получить актуальную версию модуля из файла
    static GetActualModuleVersion(ModuleName) {
        return this.ExtractVersionFromFile(ModuleName)
    }
    
    ; Проверить соответствие версий
    static CheckVersionConsistency() {
        Inconsistencies := []
        
        for ModuleName, ExpectedVersion in this.EXPECTED_VERSIONS {
            ActualVersion := this.ExtractVersionFromFile(ModuleName)
            
            if (ActualVersion != ExpectedVersion && 
                ActualVersion != "Файл не найден" && 
                ActualVersion != "Версия не указана" &&
                !InStr(ActualVersion, "Ошибка")) {
                
                Inconsistencies.Push({
                    Module: ModuleName,
                    Expected: ExpectedVersion,
                    Actual: ActualVersion
                })
            }
        }
        
        return Inconsistencies
    }
    
    ; Получить полную информацию о версиях с проверкой
    static GetAllModulesInfo() {
        Info := "=== ИНФОРМАЦИЯ О ВЕРСИЯХ МОДУЛЕЙ ===`n`n"
        
        ; Проверяем несоответствия
        Inconsistencies := this.CheckVersionConsistency()
        if (Inconsistencies.Length > 0) {
            Info .= "⚠️ ВНИМАНИЕ: Обнаружены несоответствия версий!`n"
            for Item in Inconsistencies {
                Info .= "   " . Item.Module . ": ожидается " . Item.Expected 
                     . ", фактически " . Item.Actual . "`n"
            }
            Info .= "`n"
        }
        
        ; Информация о каждом модуле
        for ModuleName, ExpectedVersion in this.EXPECTED_VERSIONS {
            ActualVersion := this.ExtractVersionFromFile(ModuleName)
            LastModified := this.ExtractLastModifiedFromFile(ModuleName)
            
            Info .= ModuleName . "`n"
            Info .= "  Ожидаемая версия: " . ExpectedVersion . "`n"
            Info .= "  Версия в файле: " . ActualVersion . "`n"
            
            ; Отмечаем несоответствие
            if (ActualVersion != ExpectedVersion && 
                ActualVersion != "Файл не найден" && 
                ActualVersion != "Версия не указана") {
                Info .= "  ⚠️ НЕСООТВЕТСТВИЕ ВЕРСИЙ!`n"
            }
            
            Info .= "  Последнее изменение: " . LastModified . "`n"
            
            ; Добавляем историю изменений
            if (this.CHANGELOG.Has(ModuleName)) {
                Changes := this.CHANGELOG[ModuleName]
                if (Changes.Length > 0) {
                    Info .= "  История:`n"
                    for Change in Changes {
                        Info .= "    - " . Change . "`n"
                    }
                }
            }
            Info .= "`n"
        }
        
        return Info
    }
    
    ; Сохранить информацию о версиях в файл
    static SaveVersionInfo(FileName := "version_info.txt") {
        FileMan := FileManager()
        Content := this.GetAllModulesInfo()
        Content .= "`nПроверка выполнена: " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`n"
        
        ; Добавляем рекомендации
        Inconsistencies := this.CheckVersionConsistency()
        if (Inconsistencies.Length > 0) {
            Content .= "`n=== РЕКОМЕНДАЦИИ ===`n"
            Content .= "1. Обновите версии в VersionManager.ahk для соответствия файлам`n"
            Content .= "2. Или обновите версии в заголовках файлов`n"
            Content .= "3. Не забудьте обновить CHANGELOG`n"
        }
        
        return FileMan.WriteFileUTF8BOM(FileName, Content)
    }
    
    ; Автоматическое обновление версии в файле (вспомогательная функция)
    static UpdateVersionInFile(FilePath, NewVersion, ChangeDescription := "") {
        try {
            if (!FileExist(FilePath))
                return false
            
            ; Читаем файл
            FileContent := FileRead(FilePath, "UTF-8")
            
            ; Обновляем версию
            FileContent := RegExReplace(FileContent, 
                "m)^(;\s*Версия:\s*)[0-9]+\.[0-9]+\.[0-9]+", 
                "$1" . NewVersion)
            
            ; Обновляем дату последнего изменения
            Today := FormatTime(A_Now, "yyyy-MM-dd")
            if (ChangeDescription != "") {
                NewLastModified := Today . " - " . ChangeDescription
            } else {
                NewLastModified := Today
            }
            
            FileContent := RegExReplace(FileContent,
                "m)^(;\s*Последнее изменение:\s*).*$",
                "$1" . NewLastModified)
            
            ; Записываем обратно
            FileObj := FileOpen(FilePath, "w", "UTF-8")
            FileObj.Write(FileContent)
            FileObj.Close()
            
            return true
            
        } catch as e {
            return false
        }
    }
    
    ; Проверить наличие всех модулей
    static CheckModulesExistence() {
        MissingModules := []
        
        for ModuleName, Version in this.EXPECTED_VERSIONS {
            if (!FileExist(ModuleName)) {
                MissingModules.Push(ModuleName)
            }
        }
        
        return MissingModules
    }
    
    ; Создать шаблон заголовка для нового модуля
    static CreateModuleHeader(ModuleName, Description, Version := "1.0.0") {
        Today := FormatTime(A_Now, "yyyy-MM-dd")
        
        Header := "#Requires AutoHotkey v2.0`n"
        Header .= "; " . ModuleName . " - " . Description . "`n"
        Header .= "; Кодировка: UTF-8 with BOM`n"
        Header .= "; Версия: " . Version . "`n"
        Header .= "; Дата создания: " . Today . "`n"
        Header .= "; Последнее изменение: " . Today . "`n`n"
        
        return Header
    }
}