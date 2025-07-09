$output = "C:\temp\network_scan.txt"

# יצירת תיקייה אם לא קיימת
if (-not (Test-Path "C:\temp")) {
    New-Item -Path "C:\temp" -ItemType Directory | Out-Null
}

# התחלת הדוח
"==== Network Scan Report ====" | Out-File $output -Encoding utf8
"Scan Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $output -Append
"----------------------------------------`n" | Out-File $output -Append

# שליפת כתובת ה-IP באופן אמין
try {
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object { $_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254*' -and $_.PrefixOrigin -ne 'WellKnown' } |
        Select-Object -First 1 -ExpandProperty IPAddress)
} catch {
    $ipLine = ipconfig | Select-String 'IPv4 Address'
    $localIP = ($ipLine -split ':')[1].Trim() -replace '\(.*\)', ''
}

# חילוץ prefix - שלושת האוקטטים הראשונים
if ($localIP -match '(\d+)\.(\d+)\.(\d+)\.\d+') {
    $prefix = "$($matches[1]).$($matches[2]).$($matches[3])"
} else {
    Write-Host "❌ לא ניתן לאתר כתובת IP תקינה. עצירה." -ForegroundColor Red
    exit
}

"Scanning subnet: $prefix.0/24`n" | Out-File $output -Append
Write-Host "`n🔍 Scanning $prefix.1 to $prefix.254..."

# סריקה עם ping.exe — במקום Test-Connection
1..254 | ForEach-Object {
    $ip = "$prefix.$_"
    $result = ping -n 1 -w 100 $ip | Select-String "Reply from"
    if ($result) {
        "$ip is up" | Tee-Object -FilePath $output -Append
    }
}

"`n==== ARP Table ====`n" | Out-File $output -Append
arp -a >> $output

Write-Host "`n✅ סריקה הסתיימה. הקובץ נמצא כאן:`n$output" -ForegroundColor Green
