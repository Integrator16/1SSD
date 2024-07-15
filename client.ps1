$logFilePath = "c:\users\director\code\ssdv.05\DiskData888.log"
$apiUrl = "http://i.1ssd.ru/temperatures"

# Функция для получения температуры дисков и параметров SMART
function Get-DiskData {
    $diskData = @()
    $smartParameters = @('241', '243', '228', '005', '009', '170', '174', '184', '187', '194', '192', '199', '197')

    # Получение данных о дисках с помощью Get-PhysicalDisk и Get-StorageReliabilityCounter
    $disks = Get-PhysicalDisk | Sort-Object -Property Number
    $index = 0
    foreach ($disk in $disks) {
        $diskName = $disk.DeviceID
        $reliabilityData = Get-StorageReliabilityCounter -PhysicalDisk $disk

        $temperatureCelsius = "-"
        $parameters = @{}

        if ($reliabilityData) {
            $temperatureCelsius = $reliabilityData.Temperature

            # Получение параметров SMART
            $driveLetter = [char](97 + $index) # 'a' начинается с 97 в ASCII
            $drivePath = "/dev/sd$driveLetter"
            Write-Output $drivePath
            $index++ # Увеличиваем счетчик после каждой итерации
            
            foreach ($param in $smartParameters) {
                $output = & .\smartctl.exe -A $drivePath | Select-String "$param"
                $pattern = '(\d+)$'

                if ($output -match $pattern) {
                    $matchedValue = $matches[1]
                    $parameters[$param] = $matchedValue
                } else {
                    $parameters[$param] = "-"
                }
            }
        }

        $diskData += @{
            "disk" = $disk.FriendlyName
            "temperature" = $temperatureCelsius
            "parameters" = $parameters
        }
    }

    return $diskData
}

# Функция для фильтрации данных
function Filter-DiskData {
    param (
        [array]$diskData
    )

    return $diskData | Where-Object {
        $_.disk -ne $null -and
        $_.temperature -ne $null -and 
        $_.parameters -ne $null
    }
}

# Функция для отправки данных на сервер
function Send-DataToServer {
    param (
        [string]$apiUrl,
        [string]$computerName,
        [array]$diskData
    )

    $payload = @{
        computer_name = $computerName
        temperatures = @()
    }

    foreach ($data in $diskData) {
        $tempData = @{
            disk = $data.disk
            temperature = $data.temperature
            parameters = $data.parameters
        }
        $payload.temperatures += $tempData
    }

    $jsonPayload = $payload | ConvertTo-Json -Depth 5
    Write-Output "Отправляемый JSON-пейлоад: $jsonPayload"

    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $jsonPayload -ContentType "application/json"
        Write-Output "Server response: $($response.message)"
    } catch {
        Write-Output "Ошибка при вызове API. Статус код: $($_.Exception.Response.StatusCode.Value__) Сообщение: $($_.Exception.Message)"
    }
}

# Основной цикл
$computerName = $env:COMPUTERNAME

$diskData = Get-DiskData
$filteredDiskData = Filter-DiskData -diskData $diskData
Send-DataToServer -apiUrl $apiUrl -computerName $computerName -diskData $filteredDiskData
Start-Sleep -Seconds 5  # Отправка данных каждые 5 секунд
