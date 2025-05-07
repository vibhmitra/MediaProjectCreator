function Get-GitInfoPath {
	clear
    while ($true) {
        if (Test-Path ".\git-info.md") {
            Write-Host "✅ git-info.md file found!" -ForegroundColor Green
            return ".\git-info.md"
        }

        Write-Host "git-info.md not found in current directory. Enter full path or folder containing it:" -ForegroundColor Yellow
        $path = Read-Host

        if (Test-Path $path) {
            if ((Get-Item $path).PSIsContainer) {
                $filePath = Join-Path $path "git-info.md"
            } else {
                $filePath = $path
            }

            if (Test-Path $filePath) {
                Write-Host "✅ git-info.md file found!" -ForegroundColor Green
                return $filePath
            }
        }

        Write-Host "❌ No valid git-info.md file found at specified path. Try again." -ForegroundColor Red
    }
}


function Read-Log {
    param($filePath)
    Write-Host "`n📖 Reading git-info.md:" -ForegroundColor Cyan
    Get-Content $filePath | Out-Host
}

function Get-CurrentStatus {
    param($filePath)

    $logLines = Get-Content $filePath
    $reversedLines = [System.Collections.Generic.List[string]]::new()
    $logLines | ForEach-Object { $reversedLines.Insert(0, $_) }

    foreach ($line in $reversedLines) {
        if ($line -match "\*\*Status:\*\*\s*(.+)") {
            return $matches[1].Trim()
        }
    }

    return "WIP"
}

function Add-LogEntry {
    param($filePath)

    $currentTime = Get-Date
    $offset = ([System.TimeZoneInfo]::Local).BaseUtcOffset.ToString("hh\:mm")
    if ($offset -notmatch "^[+-]") {
        $offset = "+" + $offset
    }

    $locationCode = Read-Host "Enter location code (default = EARTH)"
    if ([string]::IsNullOrWhiteSpace($locationCode)) {
        $locationCode = "EARTH"
    }

    $logTime = "$($currentTime.ToString("yyyy-MM-ddTHH:mm:ss"))$offset@$locationCode"

    $validStatuses = @("WIP", "Beta", "C", "R")
    $status = Read-Host "Enter status [WIP, Beta, C, R] (leave empty to use last)"
    $status = $status.ToUpper()
    if ([string]::IsNullOrWhiteSpace($status)) {
        $status = Get-CurrentStatus -filePath $filePath
        Write-Host "Using previous status: $status"
    } elseif ($status -notin $validStatuses) {
        Write-Host "❌ Invalid status. Allowed: WIP, Beta, C, R" -ForegroundColor Red
        return
    }

    $changes = Read-Host "List changes (comma-separated)"
    $changeList = $changes -split "," | ForEach-Object { ($_).Trim() } | Where-Object { $_ -ne "" }

    Write-Host "`n✅ Please confirm the following entry:" -ForegroundColor Yellow
    Write-Host "Time: $logTime"
    Write-Host "Status: $status"
    Write-Host "Changes:"
    $changeList | ForEach-Object { Write-Host "- $_" }

    $confirm = Read-Host "Do you want to save this entry? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "❌ Entry discarded." -ForegroundColor Red
        return
    }

    $logNumber = ((Get-Content $filePath | Select-String "### 🟡 Revision " | Measure-Object).Count + 1)

    Add-Content -Path $filePath -Value "`n### 🟡 Revision $logNumber – $logTime"
    Add-Content -Path $filePath -Value "**Status:** $status"
    Add-Content -Path $filePath -Value "**Changes:**"
    foreach ($change in $changeList) {
        Add-Content -Path $filePath -Value "- $change"
    }

    Write-Host "✅ Entry added successfully!" -ForegroundColor Green
}

# Main loop
$gitInfoPath = Get-GitInfoPath

while ($true) {
    Write-Host "`nPlease select an option:" -ForegroundColor Cyan
    Write-Host "1. Read 'git-info.md'"
    Write-Host "2. Add Entry to 'git-info.md'"
    Write-Host "3. Exit"

    $choice = Read-Host "Enter your choice (1/2/3)"

    switch ($choice) {
        "1" { Read-Log -filePath $gitInfoPath }
        "2" { Add-LogEntry -filePath $gitInfoPath }
        "3" { Write-Host "👋 Exiting..."; exit }
        default { Write-Host "❌ Invalid choice. Please select 1, 2, or 3." -ForegroundColor Red }
    }
}
# End of script