# AYANA

Assistante santé (santé sexuelle, reproductive et maternelle) pour jeunes femmes
et adolescentes. Le projet est composé de deux parties :

| Dossier | Rôle |
|---|---|
| `ayana_backend/` | API FastAPI (auth, profil, chat IA via Gemini) + base SQLite |
| `ayana_app/` | Application Flutter (Android, `minSdk` 24) |

## Démarrage

Deux terminaux. Le backend **doit** être lancé en premier.

**Terminal 1 — le backend** (à la racine du projet) :

```powershell
.\demarrer.ps1
```

Le script démarre uvicorn en arrière-plan, attend que `/api/health` réponde et
affiche l'adresse à utiliser. Si PowerShell refuse de l'exécuter :

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
```

Pour suivre les logs en direct (Ctrl+C pour arrêter) : `.\demarrer.ps1 -Foreground`

**Terminal 2 — l'application** :

```powershell
cd ayana_app
flutter run
```

Dans le terminal `flutter run`, la touche **`R`** recharge l'application sans
tout recompiler. Les changements backend sont pris en compte automatiquement
(uvicorn tourne avec `--reload`).

Pour arrêter le backend : `.\arreter.ps1`

## Quelle URL utiliser

L'adresse est **modifiable dans l'application** : écran de connexion, lien
**« Connexion impossible ? Changer de serveur »** en bas, ou **Profil → Serveur**.
L'adresse saisie est testée contre `/api/health` puis conservée sur l'appareil, ce
qui évite de recompiler à chaque changement de Wi-Fi.

La valeur par défaut est **figée à la compilation** de l'application
(`defaultValue` dans `ayana_app/lib/services/api_service.dart`). La changer dans ce
fichier impose un `flutter run` complet : l'adresse ne se recharge pas à chaud.

| Situation | URL | Comment y accéder |
|---|---|---|
| Téléphone en USB sur le PC | `http://127.0.0.1:8000` | pont USB, voir ci-dessous |
| Téléphone en Wi-Fi, même réseau que le PC | `http://<IP-DU-PC>:8000` | réglage serveur dans l'app |
| Émulateur Android | `http://10.0.2.2:8000` | réglage serveur dans l'app |
| Windows / Linux / macOS | `http://127.0.0.1:8000` | réglage serveur dans l'app |

Pour trouver l'IP du PC : `ipconfig` (ou `ip addr` sous Linux/macOS).
`demarrer.ps1` l'affiche à chaque démarrage et compare avec l'adresse compilée
dans l'application — il ne recopie plus cette valeur, il la lit dans
`api_service.dart`, pour que les deux ne puissent pas diverger.

Pour figer une autre adresse au build :

```powershell
flutter run --dart-define=API_URL=http://<IP-DU-PC>:8000
```

**Téléphone en USB** : le pont USB ne partage pas le réseau, il faut le configurer
une fois, puis relancer sans `--dart-define` :

```powershell
C:\Android\sdk\platform-tools\adb.exe reverse tcp:8000 tcp:8000
flutter run --dart-define=API_URL=http://127.0.0.1:8000
```

## Configuration du backend

`ayana_backend/.env` (jamais versionné, copier depuis `.env.example`) :

| Variable | Rôle |
|---|---|
| `GEMINI_API_KEY` | clé Google AI Studio. **Sans elle, le chat ne fonctionne pas** |
| `SECRET_KEY` | signature des jetons JWT, 64 caractères aléatoires. **À garder secrète** : la changer invalide les sessions ouvertes |
| `DATABASE_URL` | `sqlite:///./ayana.db` par défaut, chemin relatif au dossier `ayana_backend` |
| `OTP_MOCK` | `true` en dev : le code OTP est renvoyé dans la réponse |

`.env` est ignoré par Git (`.gitignore`). Ne jamais le versionner.

## Tests

```powershell
cd ayana_backend
.\.venv\Scripts\python.exe -m pytest -q          # 43 tests (auth, classification, contenus)
cd ..\ayana_app
flutter analyze
```

## Dépannage

| Symptôme | Cause | Solution |
|---|---|---|
| `flutter run` affiche « no devices » | aucun téléphone/émulateur détecté | brancher en USB avec le débogage activé, ou `adb devices` pour vérifier |
| `Serveur injoignable ... aucun service n'écoute` | le backend n'est pas lancé | `.\demarrer.ps1` |
| `Serveur injoignable ... n'atteint pas ce réseau` | PC et téléphone sur des réseaux différents | même Wi-Fi, ou `adb reverse` |
| `Le backend repond sur 127.0.0.1 mais pas depuis le téléphone` | uvicorn lancé sans `--host 0.0.0.0` | utiliser `demarrer.ps1` |
| `La connexion expire` | pare-feu Windows bloque le port 8000 | autoriser Python dans le pare-feu |
| `J'ai atteint ma limite de réponses pour aujourd'hui` | quota gratuit Gemini : **20 requêtes par jour et par modèle** | clé avec facturation, ou attendre la réinitialisation |
| `L'assistante IA n'est pas encore configurée` | `GEMINI_API_KEY` absente de `.env` | renseigner la clé |
| `Erreur inattendue (422)` | message de plus de 500 caractères, ou historique de plus de 60 messages | raccourcir le message |

`demarrer.ps1` distingue ces cas : il compare l'adresse qu'il affiche à celle
qui est compilée dans l'application, et propose soit de corriger l'adresse dans
l'app, soit de recompiler.

Logs du backend : `ayana_backend\uvicorn.log` (ou `.\demarrer.ps1 -Foreground`).

## Points connus

- **Quota Gemini** : 20 requêtes par jour sur l'offre gratuite. Les réponses
  plus longues consomment plus de tokens, donc le quota est d'autant plus vite
  atteint. Une clé avec facturation est nécessaire pour une démo longue.
- L'API est servie en **HTTP non chiffré** en développement. La permission
  `INTERNET` est bien déclarée dans `android/app/src/main/AndroidManifest.xml`,
  et le trafic en clair est autorisé en build `debug` par
  `android/app/src/debug/res/xml/network_security_config.xml`. Ce fichier **n'est
  pas inclus dans un build release**, où Android 9+ bloque alors tout appel HTTP.
  Une version distribuée doit donc servir le backend en **HTTPS**.
- `OTP_MOCK=true` renvoie le code OTP en clair dans la réponse. À passer à
  `false` dès qu'un service d'envoi réel est branché.
- `app/main.py` autorise `allow_origins=["*"]` **avec** `allow_credentials=True`,
  combinaison que la spec CORS interdit. Sans effet tant qu'aucun navigateur
  n'appelle l'API, mais à restreindre avant une mise en ligne.
