mkdir "%PROGRAMFILES%\1SSD"
copy .\*.ps1 "%PROGRAMFILES%\1SSD" /y
copy .\*.bat "%PROGRAMFILES%\1SSD" /y
copy .\smartctl.exe "%PROGRAMFILES%\1SSD" /y
powershell -executionpolicy RemoteSigned -file "%PROGRAMFILES%\1SSD\Addtasks.ps1"

pause