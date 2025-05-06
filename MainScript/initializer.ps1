clear
# Function to get the local timezone offset in +/-HH:mm format
function Get-TimeZoneOffset {
    # Get the base UTC offset for the local time zone
    $offset = [System.TimeZoneInfo]::Local.BaseUtcOffset
    # Determine the sign (+ or -)
    $sign = if ($offset.TotalMinutes -ge 0) { "+" } else { "-" }
    # Format the offset string (e.g., +05:30), ensuring two digits for hours/minutes
    # Using -f format operator: {index:format}
    # [Math]::Abs ensures hours/minutes are positive for formatting
    "{0}{1:00}:{2:00}" -f $sign, [Math]::Abs($offset.Hours), [Math]::Abs($offset.Minutes)
}

# Function to ask for user input with a specific color
function Ask-Colored {
    param (
        # The text prompt to display to the user
        [Parameter(Mandatory = $true)][string]$promptText,
        # The color for the prompt text. Default is Magenta
        [ConsoleColor]$color = "Magenta"
    )
    # Write the prompt text in the specified color, without adding a newline
    # Using "`n" for a newline before the prompt for better spacing
    Write-Host "`n>> $($promptText): " -ForegroundColor $color -NoNewline
    # Read the user's input from the console and return it
    return Read-Host
}


# --- Script Header ---
Write-Host ""
Write-Host "+======================================+" -ForegroundColor Yellow
Write-Host "|      🚀 NEW PROJECT INITIALIZER      |" -ForegroundColor Yellow
Write-Host "+======================================+" -ForegroundColor Yellow
Write-Host ""

# --- User Input ---
# Use the Ask-Colored function to get project details from the user
# Ensure no trailing invisible characters exist on these lines
do {
    try {
        $projectName = Ask-Colored -promptText "Enter project name (e.g., CoolCar)"
        if ([string]::IsNullOrWhiteSpace($projectName) -or $projectName -match '[\\/:*?"<>|]') {
            throw "Project name cannot be empty or contain invalid characters (\ / : * ? "" < > |)."
        }
        $valid = $true
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)

# GET LOCATION
do {
    try {
        $locationCode = Ask-Colored -promptText "Enter location code (e.g., EARTH) [default: EARTH]"
        if ([string]::IsNullOrWhiteSpace($locationCode)) {
            $locationCode = "EARTH"
        }
        $valid = $true
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)

# Get DATE
do {
    try {
        $startDateInput = Ask-Colored -promptText "Enter start date (YYYY-MM-DD) or leave blank for today"
        if (-not [string]::IsNullOrWhiteSpace($startDateInput)) {
            $customDate = Get-Date $startDateInput -ErrorAction Stop # Validate date format
        }
        $valid = $true
    } catch {
        Write-Host "[!] Error: Invalid date format. Use YYYY-MM-DD." -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)

# --- Process Dates and Time ---
$currentTime = Get-Date
$offset = Get-TimeZoneOffset

# FORMAT DATE-TIME-LOCATION
if ($customDate) {
    $projectStarted = "$($customDate.ToString("yyyy-MM-dd"))T$($currentTime.ToString("HH:mm:ss"))$offset@$locationCode"
    $startDateForFolder = $customDate.ToString("yyyyMMdd")
} else {
    $projectStarted = "$($currentTime.ToString("yyyy-MM-ddTHH:mm:ss"))$offset@$locationCode"
    $startDateForFolder = $currentTime.ToString("yyyyMMdd")
    Write-Host "`nUsing current date as start date." -ForegroundColor Green
}

# GET STATUS
$validStatuses = @("WIP", "Beta", "C", "R")
do {
    try {
        $status = Ask-Colored -promptText "Enter project status (WIP, Beta, C, R) [default: WIP]"
        $status = $status.ToUpper()
        
        if ([string]::IsNullOrWhiteSpace($status)) {
            $status = "WIP"
            Write-Host "Using Default Status WIP" -ForegroundColor Green
            $valid = $true
        } elseif ($status -notin $validStatuses) {
            throw "Invalid status. Choose from WIP, Beta, C, R."
        } else {
            $valid = $true
        }
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)

#GET VERSION
do {
    try {
        $version = Ask-Colored -promptText "Enter version (e.g., 1.0 or v1.2) [default: v1.0]"

        if ([string]::IsNullOrWhiteSpace($version)) {
            $version = "v1.0"
            Write-Host "Using Default Version 1.0" -ForegroundColor Green
            $valid = $true
        } else {
            # Remove leading 'v' and validate format
            $cleanVersion = $version -replace "^v", ""

            if ($cleanVersion -notmatch "^\d+\.\d+$") {
                throw "Invalid version format. Use MAJOR.MINOR (e.g., 1.0)."
            }

            $version = "v$cleanVersion"
            $valid = $true
        }
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)

# GET DESCRIPTION
do {
    try {
        $description = Ask-Colored -promptText "Enter a short description"
        if ([string]::IsNullOrWhiteSpace($description)) {
            throw "Description cannot be empty."
        }
        $valid = $true
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        $valid = $false
    }
} while (-not $valid)


# --- Create Folder Structure ---
# Generate a folder-friendly name (slug) by removing spaces
$projectSlug = $projectName -replace '\s+', ''
# Construct the final folder name: Date-Slug-Status
$folderName = "$startDateForFolder-$projectSlug-$status"

Write-Host "`nCreating folder structure..." -ForegroundColor Gray

# Create the main project directory and subdirectories
# -ItemType Directory specifies folder creation
# -Force prevents errors if folders already exist (overwrites implicitly handled by New-Item)
# | Out-Null suppresses the output object from New-Item for a cleaner console
New-Item -Path $folderName -ItemType Directory -Force | Out-Null
New-Item -Path "$folderName/assets" -ItemType Directory -Force | Out-Null
New-Item -Path "$folderName/audio" -ItemType Directory -Force | Out-Null
New-Item -Path "$folderName/visuals" -ItemType Directory -Force | Out-Null

# --- Create git-info.md File ---
# Define the content for the git-info.md file using a PowerShell here-string.
# The opening @" MUST be at the end of the line.
# The closing "@ MUST be at the START of a new line. NO LEADING/TRAILING SPACES on this line.
$gitInfo = @"
# 📁 Project: $projectName
# 📅 Project Started: $projectStarted
# 📦 Project Released: TBD
# 🚦 Status: $status
# 🔖 Version: $version

---

## 📝 Project Summary
$description

---

## 🔁 Change Log

### 🟡 Revision 1 – $($startDateForFolder.Substring(0,4))-$($startDateForFolder.Substring(4,2))-$($startDateForFolder.Substring(6,2))
**Status:** $status
**Changes:**
- Project created
- Folder initialized
"@

# Construct the full path for the git-info.md file using Join-Path for reliability
$gitInfoPath = Join-Path -Path $folderName -ChildPath "git-info.md"
# Write the content stored in $gitInfo to the specified file path
Set-Content -Path $gitInfoPath -Value $gitInfo

# --- Success Message ---
# Inform the user that the process completed successfully
Write-Host "`n🎉 Successfully created project folder: " -ForegroundColor Green -NoNewline
Write-Host "$folderName" -ForegroundColor White # Display folder name in default color for contrast
Write-Host "📄 git-info.md has been initialized." -ForegroundColor Green
Write-Host "" # Add a final blank line for spacing
