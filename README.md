# AutoHotkey Project

This repository contains an AutoHotkey project with a main controller and managed scripts architecture.

## Project Structure

### MainController
The main controller manages and coordinates the execution of scripts:
- `MainScript.ahk` - The primary controller script
- `GUI_Manager.ahk` - Handles GUI operations
- `ProcessManager.ahk` - Manages script processes
- `StatusMonitor.ahk` - Monitors script status
- `CommandSender.ahk` - Handles command sending between scripts

### ManagedScripts
Contains individual scripts that are managed by the main controller:
- `Script1_WordProcessor` - A word processing script with various components

### Shared
Contains shared code used by both the controller and managed scripts:
- `CommandDefinitions.ahk` - Defines commands used for inter-script communication
- `IPCProtocol.ahk` - Implements inter-process communication protocol
- `JSONHelper.ahk` - Provides JSON handling utilities

## Getting Started

1. Run `MainController\MainScript.ahk` to start the main controller
2. The controller will manage the execution of scripts in the `ManagedScripts` directory

## Testing

Various test scripts are available in the root directory:
- `TestLauncher.ahk`
- `TestMainIPC.ahk`
- `TestSetup.ahk`
- `TestDiagnosticLauncher.ahk`