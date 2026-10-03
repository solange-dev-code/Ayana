<#
.SYNOPSIS
    Arrête le backend AYANA lancé par demarrer.ps1.

.DESCRIPTION
    Tue le superviseur uvicorn (enregistré dans ayana_backend\uvicorn.pid)
    ainsi que tout processus encore à l'écoute sur le port, afin qu'aucun
    processus orphelin ne bloque un redémarrage.

.PARAMETER Port
    Port d'écoute à libérer. 8000 par défaut.

.EXAMPLE
    .\arreter.ps1
#>
[CmdletBinding()]
param(
    [int]$Port = 8000
)

$ErrorActionPreference = 'SilentlyContinue'

$racine = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $racine 'ayana_backend'
$fichierPid = Join-Path $backend 'uvicorn.pid'

$arretes = New-Object System.Collections.Generic.List[string]

# 1. Le superviseur et toute son arborescence (uvicorn --reload).
if (Test-Path -LiteralPath $fichierPid) {
    $contenu = (Get-Content -LiteralPath $fichierPid -Raw).Trim()
    if ($contenu -match '^\d+$') {
        # taskkill /T tue toute l'arborescence, sinon le superviseur
        # redémarre le processus fils juste après.
        $resultat = taskkill /PID $contenu /T /F 2>&1
        if ($LASTEXITCODE -eq 0) {
            $arretes.Add("superviseur uvicorn (PID $contenu)")
        }
    }
    Remove-Item -LiteralPath $fichierPid -Force
}

# 2. Tout processus encore à l'écoute sur le port.
$occupants = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
foreach ($connexion in $occupants) {
    $pidProcessus = $connexion.OwningProcess
    if ($pidProcessus -and $pidProcessus -ne $PID) {
        taskkill /PID $pidProcessus /T /F 2>&1 | Out-Null
        $arretes.Add("processus à l'écoute sur le port $Port (PID $pidProcessus)")
    }
}

if ($arretes.Count -eq 0) {
    Write-Host "Aucun backend n'est lancé sur le port $Port." -ForegroundColor Green
    exit 0
}

Write-Host 'Arrêté :' -ForegroundColor Green
foreach ($ligne in $arretes) {
    Write-Host "  $ligne"
}

$restant = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($restant) {
    Write-Host ''
    Write-Host "Le port $Port est encore occupé : ferme le terminal du backend si tu l'avais lancé au premier plan." -ForegroundColor Yellow
} else {
    Write-Host ''
    Write-Host "Le port $Port est libre." -ForegroundColor DarkGray
}
