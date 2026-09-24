param([string]$Godot = 'godot')

$ErrorActionPreference = 'Stop'
$tacticsRoot = Split-Path -Parent $PSScriptRoot
$engine = (Get-Command $Godot -ErrorAction Stop).Source
$logs = Join-Path $tacticsRoot '.godot'
New-Item -ItemType Directory -Force -Path $logs | Out-Null

function Invoke-TacticsCheck {
    param([string]$Name, [string[]]$EngineArguments)
    $logFile = Join-Path $logs "$Name.log"
    $arguments = @('--headless', '--path', ('"{0}"' -f $tacticsRoot),
        '--log-file', ('"{0}"' -f $logFile)) + $EngineArguments
    $process = Start-Process -FilePath $engine -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru
    $output = Get-Content -LiteralPath $logFile -Raw
    if ($process.ExitCode -ne 0 -or $output -match '(?m)^(SCRIPT ERROR:|ERROR:)') {
        Write-Output $output
        throw "$Name failed (exit $($process.ExitCode)). See $logFile"
    }
    $summary = ($output -split "`n" | Where-Object { $_ -match 'RESULT:|Navigation:' }) -join "`n"
    Write-Output "$Name passed. $summary"
}

Invoke-TacticsCheck 'import' @('--editor', '--import')
Invoke-TacticsCheck 'navigation' @('--script', 'res://tests/navigation_test.gd')
foreach ($ticks in @(60, 120)) {
    Invoke-TacticsCheck "commands-$ticks" @('--fixed-fps', "$ticks", '--script',
        'res://tests/command_test.gd', '--', "--ticks=$ticks")
    Invoke-TacticsCheck "combat-$ticks" @('--fixed-fps', "$ticks", '--script',
        'res://tests/combat_test.gd', '--', "--ticks=$ticks")
    Invoke-TacticsCheck "encounter-input-$ticks" @('--fixed-fps', "$ticks", '--script',
        'res://tests/encounter_input_test.gd', '--', "--ticks=$ticks")
    Invoke-TacticsCheck "directional-combat-$ticks" @('--fixed-fps', "$ticks", '--script',
        'res://tests/directional_combat_test.gd', '--', "--ticks=$ticks")
    Invoke-TacticsCheck "cover-input-$ticks" @('--fixed-fps', "$ticks", '--script',
        'res://tests/cover_input_test.gd', '--', "--ticks=$ticks")
}
Invoke-TacticsCheck 'encounter-startup' @('--quit-after', '120')
