#Requires -Version 7.0
[CmdletBinding()]
param(
    [string]$GodotPath = 'godot'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Capture both streams asynchronously so a full error pipe cannot stall Godot.
function Invoke-GodotCheck {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$Phase,
        [int]$TimeoutSeconds
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $Executable
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Could not start Godot for $Phase."
        }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill($true)
            if (-not $process.WaitForExit(5000)) {
                throw "Godot $Phase exceeded its time limit and could not be stopped."
            }
            throw "Godot $Phase exceeded its $TimeoutSeconds second limit."
        }
        if (-not $stdoutTask.Wait(5000) -or -not $stderrTask.Wait(5000)) {
            throw "Godot $Phase exited, but its output streams did not close."
        }
        $stdout = $stdoutTask.GetAwaiter().GetResult()
        $stderr = $stderrTask.GetAwaiter().GetResult()
        $output = $stdout + [Environment]::NewLine + $stderr
        if (-not [string]::IsNullOrWhiteSpace($output)) {
            Write-Host $output.Trim()
        }
        if ($process.ExitCode -ne 0) {
            throw "Godot $Phase failed with exit code $($process.ExitCode)."
        }
        if ($output -match '(?im)^\s*(?:SCRIPT ERROR|ERROR):') {
            throw "Godot reported an error during $Phase."
        }
        return $output
    }
    finally {
        $process.Dispose()
    }
}

try {
    $projectRoot = Split-Path -Parent $PSScriptRoot
    $pinnedVersion = (Get-Content -LiteralPath (Join-Path $projectRoot '.godot-version') -Raw).Trim()
    if ($pinnedVersion -notmatch '^\d+\.\d+\.\d+$') {
        throw '.godot-version must contain one exact major.minor.patch version.'
    }
    $engineCommand = Get-Command -Name $GodotPath -CommandType Application -ErrorAction Stop | Select-Object -First 1
    $enginePath = $engineCommand.Source
    $versionOutput = Invoke-GodotCheck -Executable $enginePath -Arguments @('--version') -Phase 'version check' -TimeoutSeconds 10
    $versionPattern = '(?m)^' + [regex]::Escape($pinnedVersion) + '\.stable(?:\.|\s|$)'
    if ($versionOutput -notmatch $versionPattern) {
        throw "Use Godot $pinnedVersion stable standard. The selected executable reports: $($versionOutput.Trim())"
    }
    if ($versionOutput -match '(?i)mono|dotnet' -or [System.IO.Path]::GetFileName($enginePath) -match '(?i)mono|dotnet') {
        throw 'Use the standard Godot executable, not the .NET/Mono build.'
    }

    Write-Host "Importing project with Godot $pinnedVersion..."
    $null = Invoke-GodotCheck -Executable $enginePath -Arguments @('--headless', '--path', $projectRoot, '--editor', '--import') -Phase 'import' -TimeoutSeconds 180
    Write-Host 'Loading the configured main scene...'
    $smokeOutput = Invoke-GodotCheck -Executable $enginePath -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/smoke/project_smoke.gd') -Phase 'smoke check' -TimeoutSeconds 60
    if ($smokeOutput -notmatch '(?m)^PROJECT_SMOKE_OK\s*$') {
        throw 'The smoke check exited without the PROJECT_SMOKE_OK success marker.'
    }
    Write-Host 'Checking title screen interactions...'
    $titleOutput = Invoke-GodotCheck -Executable $enginePath -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/ui/title_screen_test.gd') -Phase 'title screen interactions' -TimeoutSeconds 60
    if ($titleOutput -notmatch '(?m)^TITLE_SCREEN_TEST_OK\s*$') {
        throw 'The title screen check exited without the TITLE_SCREEN_TEST_OK success marker.'
    }
    $quitOutput = Invoke-GodotCheck -Executable $enginePath -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/ui/title_screen_test.gd', '--', '--quit-check') -Phase 'desktop Quit' -TimeoutSeconds 30
    if ($quitOutput -notmatch '(?m)^TITLE_SCREEN_QUIT_REQUESTED\s*$') {
        throw 'The Quit check exited without exercising the Quit button.'
    }
    Write-Host 'Title screen interactions and Quit passed.'
    Write-Host 'Checking player movement, collisions, and camera...'
    $movementOutput = Invoke-GodotCheck -Executable $enginePath -Arguments @('--headless', '--path', $projectRoot, '--script', 'res://tests/movement/player_movement_test.gd') -Phase 'player movement' -TimeoutSeconds 60
    if ($movementOutput -notmatch '(?m)^PLAYER_MOVEMENT_TEST_OK(?:\s|$)') {
        throw 'The movement check exited without the PLAYER_MOVEMENT_TEST_OK success marker.'
    }
    Write-Host 'Player movement, collisions, and camera passed.'
    Write-Host 'Project import and startup passed.'
    exit 0
}
catch {
    [Console]::Error.WriteLine("Project check failed: $($_.Exception.Message)")
    exit 1
}
