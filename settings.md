Settings for various systems in localdev.md

# CMDER
## WSL Console
CMDer settings to start a new WSL console. [Source](https://shesgottadevelopit.com/2018/12/05/wsl-cmder-context-menu/)
Task Parameters
```
-icon "%USERPROFILE%\AppData\Local\lxss\bash.ico"
```
Start Console
```
set "PATH=%ConEmuBaseDirShort%\wsl;%PATH%" & %windir%\system32\wsl.exe -new_console'
```

![CMDER settings for a new Windows Subsystem for Linux WSL console](https://github.com/justintungonline/debezium-tests/blob/main/images/CMDer%20WSL%20Console%20settings%20Screenshot%202020-11-19%20160323.png)
