param([string]$Godot = 'godot')

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engine = (Get-Command $Godot -ErrorAction Stop).Source
$logDirectory = Join-Path $projectRoot '.godot'
New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null

function Invoke-GodotCheck {
    param([string]$Name, [string[]]$EngineArguments)

    $logFile = Join-Path $logDirectory "$Name.log"
    $arguments = @('--headless', '--path', ('"{0}"' -f $projectRoot),
        '--log-file', ('"{0}"' -f $logFile)) + $EngineArguments
    $process = Start-Process -FilePath $engine -ArgumentList $arguments `
        -WindowStyle Hidden -Wait -PassThru
    $output = Get-Content -LiteralPath $logFile -Raw
    Write-Output $output
    if ($process.ExitCode -ne 0 -or $output -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
        throw "$Name failed (exit $($process.ExitCode)). See $logFile"
    }
}

Invoke-GodotCheck -Name 'import-check' -EngineArguments @('--editor', '--import')
foreach ($tickRate in @(60, 120)) {
    Invoke-GodotCheck -Name "test-$tickRate" -EngineArguments @(
        '--fixed-fps', "$tickRate", '--script', 'res://tests/player_movement_test.gd',
        '--', "--ticks=$tickRate")
}
Invoke-GodotCheck -Name 'scene-check' -EngineArguments @('--quit-after', '120')
Write-Output 'Import, movement integration checks, and main scene startup passed.'
