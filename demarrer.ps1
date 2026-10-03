<#
.SYNOPSIS
    Démarre le backend AYANA (FastAPI + uvicorn) et vérifie qu'il répond.

.DESCRIPTION
    Le piège principal de ce projet est que uvicorn écoute par défaut sur
    127.0.0.1 : le backend répond alors sur le PC mais reste injoignable depuis
    le téléphone, ce qui donne l'impression d'un problème d'URL. Ce script
    impose --host 0.0.0.0, attend la réponse de /api/health, puis affiche
    l'adresse à utiliser dans l'application.

.PARAMETER Foreground
    Lance uvicorn au premier plan (logs en direct, Ctrl+C pour arrêter).
    Par défaut il est lancé en arrière-plan et journalisé dans
    ayana_backend\uvicorn.log.

.PARAMETER Port
    Port d'écoute du backend. 8000 par défaut.

.EXAMPLE
    .\demarrer.ps1
    .\demarrer.ps1 -Foreground
#>
[CmdletBinding()]
param(
    [switch]$Foreground,
    [int]$Port = 8000
)

$ErrorActionPreference = 'Stop'

$racine = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $racine 'ayana_backend'
$python = Join-Path $backend '.venv\Scripts\python.exe'
$fichierPid = Join-Path $backend 'uvicorn.pid'
$log = Join-Path $backend 'uvicorn.log'

function Write-Titre([string]$texte) {
    Write-Host ''
    Write-Host "== $texte" -ForegroundColor Cyan
}

function Get-IpLocale {
    # Ignore le loopback et l'APIPA (169.254.x.x = pas de DHCP), ainsi que les
    # adaptateurs virtuels, non joignables depuis un téléphone.
    $candidats = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notlike '127.*' -and
            $_.IPAddress -notlike '169.254.*'
        }
    foreach ($ip in $candidats) {
        $nom = $null
        try { $nom = (Get-NetAdapter -InterfaceIndex $ip.InterfaceIndex).Name } catch { }
        if ($nom -and $nom -match 'vEthernet|Hyper-V|Loopback|VirtualBox|VMware') {
            continue
        }
        return $ip.IPAddress
    }
    return $null
}

function Test-Backend([int]$p) {
    try {
        $r = Invoke-RestMethod -Uri "http://127.0.0.1:$p/api/health" -TimeoutSec 2
        return ($r.status -eq 'ok')
    } catch {
        return $false
    }
}

# --- Vérification de l'environnement -------------------------------------

if (-not (Test-Path -LiteralPath $python)) {
    Write-Host "Le virtualenv est introuvable : $python" -ForegroundColor Red
    Write-Host 'Crée-le avec :' -ForegroundColor Yellow
    Write-Host '  python -m venv ayana_backend\.venv' -ForegroundColor Yellow
    Write-Host '  ayana_backend\.venv\Scripts\pip.exe install -r ayana_backend\requirements.txt' -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $backend '.env'))) {
    Write-Host 'Avertissement : aucun fichier .env dans ayana_backend.' -ForegroundColor Yellow
    Write-Host 'Sans GEMINI_API_KEY, le chat répondra que l''assistante n''est pas configurée.' -ForegroundColor Yellow
    Write-Host 'Copie .env.example en .env et renseigne la clé :' -ForegroundColor Yellow
    Write-Host '  Copy-Item ayana_backend\.env.example ayana_backend\.env' -ForegroundColor Yellow
}

# --- Un backend tourne-t-il déjà ? ---------------------------------------

if (Test-Backend $Port) {
    Write-Host "Le backend répond déjà sur le port $Port : rien à faire." -ForegroundColor Green
    $ip = Get-IpLocale
    if ($ip) { Write-Host "URL à utiliser : http://${ip}:$Port" -ForegroundColor Green }
    exit 0
}

$occupant = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
if ($occupant) {
    Write-Host "Le port $Port est occupé par le processus $($occupant[0].OwningProcess)," -ForegroundColor Yellow
    Write-Host "mais /api/health ne répond pas. Arrête-le avec .\arreter.ps1" -ForegroundColor Yellow
    exit 1
}

# --- Démarrage ------------------------------------------------------------

$arguments = @(
    '-m', 'uvicorn', 'app.main:app',
    '--host', '0.0.0.0',
    '--port', $Port,
    '--reload'
)

if ($Foreground) {
    Write-Titre 'Démarrage du backend au premier plan (Ctrl+C pour arrêter)'
    Push-Location $backend
    try {
        & $python @arguments
    } finally {
        Pop-Location
    }
    exit 0
}

Write-Host 'Démarrage du backend en arrière-plan...'
# uvicorn --reload supervise un processus fils : tuer le fils seul le ferait
# redémarrer. On note donc le PID du parent pour arrêter toute l'arborescence.
$commande = "& '$python' $($arguments -join ' ') *>&1 | Out-File -FilePath '$log' -Encoding utf8"
$proc = Start-Process -FilePath 'powershell.exe' `
    -ArgumentList '-NoProfile', '-Command', $commande `
    -WorkingDirectory $backend `
    -WindowStyle Hidden `
    -PassThru

Set-Content -LiteralPath $fichierPid -Value $proc.Id -Encoding ASCII

# --- Attente de la réponse ------------------------------------------------

for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    if ($proc.HasExited) { break }
    if (Test-Backend $Port) { break }
}

if (-not (Test-Backend $Port)) {
    Write-Host ''
    Write-Host "Le backend n'a pas démarré." -ForegroundColor Red
    Write-Host "Journal : $log" -ForegroundColor Yellow
    if (Test-Path -LiteralPath $log) {
        Write-Host '--- 30 dernières lignes ---' -ForegroundColor Yellow
        Get-Content -LiteralPath $log -Tail 30 | ForEach-Object { Write-Host "  $_" }
    }
    Write-Host 'Pour lancer au premier plan et voir les erreurs : .\demarrer.ps1 -Foreground' -ForegroundColor Yellow
    exit 1
}

function Get-UrlParDefaut {
    # L'adresse compilée dans l'application est lue dans le source plutôt que
    # recopiée ici : une valeur en dur dans les deux fichiers finit toujours par
    # diverger, et le message affiché enverrait alors vers une recompilation
    # inutile puisque l'application pointe déjà sur une autre adresse.
    $source = Join-Path $racine 'ayana_app\lib\services\api_service.dart'
    if (-not (Test-Path -LiteralPath $source)) { return $null }
    $contenu = Get-Content -LiteralPath $source -Raw
    $m = [regex]::Match(
        $contenu,
        "'API_URL',\s*\r?\n\s*defaultValue:\s*'([^']+)'")
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

# --- Succès : afficher quoi taper dans l'app ------------------------------

$ip = Get-IpLocale

Write-Titre 'Backend démarré'
Write-Host "  Sonde      : http://127.0.0.1:$Port/api/health" -ForegroundColor Green
Write-Host "  Journal    : $log" -ForegroundColor Green
Write-Host "  Arrêt      : .\arreter.ps1" -ForegroundColor Green

if ($ip) {
    Write-Host ''
    Write-Host 'Depuis le téléphone, utilise :' -ForegroundColor Cyan
    Write-Host "  http://${ip}:$Port" -ForegroundColor White
    Write-Host ''
    # L'adresse ci-dessus est figée au build, mais l'application permet de la
    # corriger à chaud (Profil → Serveur, ou « Changer de serveur » sur l'écran
    # de connexion) : cette solution est donc proposée en premier.
    $urlParDefaut = Get-UrlParDefaut
    if (("http://${ip}:$Port") -eq $urlParDefaut) {
        Write-Host 'L''application utilise déjà cette adresse : appuie sur R dans' -ForegroundColor DarkGray
        Write-Host 'le terminal flutter run, sans recompiler.' -ForegroundColor DarkGray
    } else {
        if ($urlParDefaut) {
            Write-Host "L'application est compilée pour $urlParDefaut. Deux options :" -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  1) Sans recompiler : dans l''application, touche' -ForegroundColor White
            Write-Host '     « Connexion impossible ? Changer de serveur » (écran de' -ForegroundColor White
            Write-Host '     connexion, en bas) ou Profil → Serveur, puis saisir :' -ForegroundColor White
        } else {
            Write-Host 'Adresse attendue par l''application introuvable dans ' -ForegroundColor Yellow
            Write-Host 'ayana_app\lib\services\api_service.dart. Deux options :' -ForegroundColor Yellow
            Write-Host ''
            Write-Host '  1) Sans recompiler : dans l''application, Profil → Serveur,' -ForegroundColor White
            Write-Host '     puis saisir l''adresse ci-dessus.' -ForegroundColor White
        }
        Write-Host "     http://${ip}:$Port" -ForegroundColor White
        Write-Host ''
        Write-Host '  2) Avec recompilation (remplace la valeur par défaut) :' -ForegroundColor White
        Write-Host "     flutter run --dart-define=API_URL=http://${ip}:$Port" -ForegroundColor White
    }
} else {
    Write-Host ''
    Write-Host 'Aucune adresse locale détectée : le backend n''est joignable que' -ForegroundColor Yellow
    Write-Host 'depuis le PC. Vérifie ta connexion réseau.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Dans le terminal flutter run, appuie sur R pour recharger l''app.' -ForegroundColor DarkGray
