# Копирование smartctl.exe и client.ps1 в C:\Windows\System32\Tasks
$sourceSmartctl = ".\smartctl.exe"
$sourceClient = ".\client.ps1"
$sourcePowerShell = ".\powershell.exe"
$destinationFolderS32 = "C:\Windows\System32\"
$destinationFolder1SSD = "C:\PROGRAM FILES\1SSD\"

Copy-Item -Path $sourceSmartctl -Destination $destinationFolderS32 -Force
Copy-Item -Path $sourceClient -Destination $destinationFolder1SSD -Force
# Copy-Item -Path $sourcePowerShell -Destination $destinationFolder -Force

# Создание задачи в Планировщике заданий
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy RemoteSigned -File `"$destinationFolder1SSD\client.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At 11:59am 
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Проверка наличия задания и его удаление, если оно существует
$taskName = "1SSD"
if (Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName}) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName $taskName -Description "Sending SSD data. Runs client.ps1 daily at 8:00 AM"