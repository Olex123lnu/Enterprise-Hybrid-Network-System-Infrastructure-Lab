@echo off
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -LiteralPath '%~f0' -Encoding UTF8 | Select-Object -Skip 9 | Out-String | iex"
if %errorlevel% neq 0 (
    echo.
    echo [ПОМИЛКА] Скрипт завершився з кодом %errorlevel%.
    pause
)
goto :EOF

# Примусово вмикаємо UTF-8 для виведення в консоль Windows
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- Налаштування MikroTik ---
$RouterIP    = "192.168.2.1"           # IP-адреса вашого MikroTik (або зовнішня IP)
$RouterUser  = "admin"                  # Логін адміністратора
$RouterPass  = ""                      # Залиште порожнім "", щоб скрипт безпечно запитував пароль при запуску
$WgInterface = "wgvpn"                 # Назва інтерфейсу WireGuard на MikroTik

# --- Налаштування VPN-мережі ---
$ServerPubKey   = "y+dauWQI77+xRPngpSl5K0l/bYgL0zHGDXiiQe/OR3g="   # Публічний ключ WireGuard з MikroTik
$ServerEndpoint = "176.105.198.129:51820"   # Локальна IP роутера для тестування зсередини мережі
$ClientSubnet   = "192.168.5."                 # Перші 3 октети вашої VPN-мережі
$ClientDNS      = "192.168.3.100"              # DNS для клієнтів

# --- Шляхи до утиліт та експорту ---
$WgExePath  = "C:\wgtools\wg.exe"      # Шлях до wg.exe
$PlinkPath  = "C:\wgtools\plink.exe"   # Шлях до plink.exe
$OutputDir  = "C:\wgtools"             # Куди зберігати готові файли конфігурації
# -------------------------------------

# Запит пароля, якщо він не прописаний у налаштуваннях
if ([string]::IsNullOrEmpty($RouterPass)) {
    $SecurePass = Read-Host "Введіть пароль від MikroTik (символи приховані)" -AsSecureString
    $RouterPass = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass))
}

# Видаляємо помилково створений порожній файл .conf, якщо він залишився
if (Test-Path "$OutputDir\.conf") { Remove-Item "$OutputDir\.conf" -Force }

# Автоматичний пошук wg.exe у стандартних папках Windows, якщо його немає в C:\wgtools
if (-not (Test-Path $WgExePath)) {
    $DefaultPaths = @(
        "C:\Program Files\WireGuard\wg.exe",
        "C:\Program Files (x86)\WireGuard\wg.exe"
    )
    foreach ($Path in $DefaultPaths) {
        if (Test-Path $Path) {
            $WgExePath = $Path
            break
        }
    }
}

# Якщо утиліту взагалі не знайдено в системі
if (-not (Test-Path $WgExePath)) {
    Write-Host "[ПОМИЛКА] Не знайдено утиліту wg.exe!" -ForegroundColor Red
    Write-Host "Будь ласка, переконайтеся, що WireGuard встановлено на цьому ПК, або скопіюйте файл wg.exe у папку $OutputDir" -ForegroundColor Yellow
    Write-Host "Посилання на офіційний інсталятор: https://www.wireguard.com/install/" -ForegroundColor Cyan
    Write-Host "`nНатисніть Enter для виходу..."
    Read-Host
    exit
}

# Запит імені нового користувача з обов'язковою перевіркою на порожнє та вже існуюче значення
$ClientName = ""
while ([string]::IsNullOrWhiteSpace($ClientName)) {
    $ClientName = Read-Host "`nВведіть ім'я нового клієнта (наприклад, ivan_phone)"
    if ($null -ne $ClientName) { $ClientName = $ClientName.Trim() }
    
    if ([string]::IsNullOrWhiteSpace($ClientName)) {
        Write-Host "Ім'я клієнта не може бути порожнім! Будь ласка, вкажіть назву підключення." -ForegroundColor Yellow
        continue
    }

    # Перевірка на дублювання файлу конфігурації
    $ClientConfigPath = "$OutputDir\$ClientName.conf"
    if (Test-Path $ClientConfigPath) {
        Write-Host "[ПОМИЛКА] Клієнт з ім'ям '$ClientName' вже існує локально!" -ForegroundColor Red
        Write-Host "Будь ласка, оберіть іншу назву для підключення." -ForegroundColor Yellow
        $ClientName = "" # Скидаємо ім'я для повторного запиту
    }
}

if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir | Out-Null }

Write-Host "`nГенерація криптографічних ключів..." -ForegroundColor Cyan
# 1. ГЕНЕРАЦІЯ КЛЮЧІВ КЛІЄНТА
$PrivKey = ""
try {
    $PrivKey = (& $WgExePath genkey).Trim()
} catch {
    # Помилка запуску
}

if ([string]::IsNullOrEmpty($PrivKey)) {
    Write-Host "[ПОМИЛКА] Не вдалося згенерувати приватний ключ за допомогою $WgExePath!" -ForegroundColor Red
    Write-Host "`nНатисніть Enter для виходу..."
    Read-Host
    exit
}

# Генерація публічного ключа через тимчасовий файл (щоб уникнути додавання \r\n та сигнатур BOM)
$PubKey = ""
try {
    $TempPrivFile = "$OutputDir\temp_priv.key"
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes($PrivKey)
    [System.IO.File]::WriteAllBytes($TempPrivFile, $Bytes)
    
    $PubKey = (cmd.exe /c "`"$WgExePath`" pubkey < `"$TempPrivFile`"").Trim()
    
    if (Test-Path $TempPrivFile) { Remove-Item $TempPrivFile -Force }
} catch {
    # Помилка запуску
}

if ([string]::IsNullOrEmpty($PubKey) -or $PubKey -match "Trailing" -or $PubKey -match "error") {
    Write-Host "[ПОМИЛКА] Не вдалося отримати публічний ключ із приватного!" -ForegroundColor Red
    Write-Host "`nНатисніть Enter для виходу..."
    Read-Host
    exit
}

Write-Host "Підключення до MikroTik та пошук вільної IP..." -ForegroundColor Cyan
# 2. АВТОМАТИЧНИЙ ПОШУК ВІЛЬНОЇ IP-АДРЕСИ НА МІКРОТІК (Використовуємо режим detail для уникнення обрізання рядків)
$SshCmd = "/interface/wireguard/peers/print detail where interface=$WgInterface"
$UsedIPsRaw = & $PlinkPath -batch -ssh $RouterUser@$RouterIP -pw $RouterPass $SshCmd 2>&1

# Витягуємо номери IP із результату
if ([string]::IsNullOrEmpty($UsedIPsRaw) -or ($UsedIPsRaw -match "error") -or ($UsedIPsRaw -match "failure")) {
    Write-Host "Попередження: Не вдалося отримати список IP з MikroTik. Можливо, виникла помилка підключення." -ForegroundColor Yellow
    $UsedIPs = @()
} else {
    $UsedIPs = [regex]::Matches($UsedIPsRaw, "$($ClientSubnet.Replace('.','\.'))(\d+)") | ForEach-Object { $_.Groups[1].Value }
}

# Шукаємо першу вільну IP починаючи з .2 повністю автоматично!
$NextIP = 2
while ($UsedIPs -contains [string]$NextIP) { $NextIP++ }
$ClientIP = "$ClientSubnet$NextIP"

Write-Host "Призначено IP-адресу: $ClientIP" -ForegroundColor Green
Write-Host "Додавання користувача на MikroTik..." -ForegroundColor Cyan

# 3. РЕЄСТРАЦІЯ КЛІЄНТА НА MIKROTIK (Через тимчасовий файл команд для збереження лапок)
$TempCmdFile = "$OutputDir\temp_command.txt"
$MikrotikCmd = '/interface/wireguard/peers/add interface="{0}" public-key="{1}" allowed-address="{2}/32" comment="{3}"' -f $WgInterface, $PubKey, $ClientIP, $ClientName

[System.IO.File]::WriteAllText($TempCmdFile, $MikrotikCmd)

$Result = & $PlinkPath -batch -ssh $RouterUser@$RouterIP -pw $RouterPass -m $TempCmdFile 2>&1

if (Test-Path $TempCmdFile) { Remove-Item $TempCmdFile -Force }

# Перевірка на помилки під час виконання команди на MikroTik
if ($Result -match "failure" -or $Result -match "error" -or $Result -match "bad command" -or $Result -match "syntax error") {
    Write-Host "`n[ПОМИЛКА] Не вдалося додати користувача на MikroTik!" -ForegroundColor Red
    Write-Host "Відповідь від роутера: $Result" -ForegroundColor Yellow
} else {
    # 4. СТВОРЕННЯ ГОТОВОГО ФАЙЛУ .CONF ДЛЯ КЛІЄНТА
    $ClientConfig = "[Interface]`r`nPrivateKey = $PrivKey`r`nAddress = $ClientIP/24`r`nDNS = $ClientDNS`r`n`r`n[Peer]`r`nPublicKey = $ServerPubKey`r`nEndpoint = $ServerEndpoint`r`nAllowedIPs = 192.168.5.0/24, 192.168.2.0/24,192.168.4.0/30,192.168.6.0/24,192.168.7.0/24,192.168.8.0/24,192.168.1.0/24,192.168.3.0/24`r`nPersistentKeepalive = 25"

    $ClientConfigPath = "$OutputDir\$ClientName.conf"
    [System.IO.File]::WriteAllText($ClientConfigPath, $ClientConfig)

    Write-Host "`n[УСПІШНО]" -ForegroundColor Green
    Write-Host "1. Клієнта '$ClientName' зареєстровано на MikroTik з IP $ClientIP/32." -ForegroundColor Green
    Write-Host "2. Готовий файл конфігурації створено: $ClientConfigPath" -ForegroundColor Green
}

Write-Host "`nНатисніть Enter для виходу..."
Read-Host