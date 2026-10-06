# 🎬 MLDonkey Telegram Notifier

> 🇬🇧 [Read in English](README.en.md)

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](LICENSE)

Notifiche Telegram automatiche per i download completati da **MLDonkey**, con ricerca IMDB, download sottotitoli italiani, poster e metadata per media center.

---

## ✨ Funzionalità

| Funzionalità | Descrizione |
|---|---|
| 📬 **Notifiche Telegram** | Messaggio automatico ad ogni download completato |
| 🎥 **Ricerca IMDB** | Link IMDB automatico per file video |
| 📺 **Rilevamento Film/Serie** | Distingue automaticamente film da serie TV |
| 💬 **Sottotitoli italiani** | Download automatico via Subliminal, opensubtitles-cli o API diretta |
| 🖼️ **Poster HD** | Download automatico poster dal TMDb |
| 📋 **Metadata NFO** | File NFO compatibili con Kodi, Plex, Jellyfin, Emby |
| 📊 **Dimensioni leggibili** | Conversione automatica bytes → KB/MB/GB |
| 📝 **Logging** | Log completo di tutte le operazioni |

---

## 📂 Struttura del Repository

```
├── mldonkey-telegram-notify.sh   # 🔧 Script principale (versione attuale)
├── SUBLIMINAL_SETUP.md           # 📖 Guida installazione Subliminal
├── TMDB_GUIDE.md                 # 📖 Guida configurazione TMDb
├── _Maurizio/                    # 📦 Script originali (legacy)
│   ├── my_file_completed_cmd.sh  #     Hook originale per MLDonkey
│   ├── telegram-pipe.sh          #     Utility pipe → Telegram
│   ├── README.md                 #     Documentazione originale
│   └── LICENSE                   #     Licenza GPL-3.0
└── README.md                     # ← Questo file
```

---

## ⚡ Quick Start

### 1. Prerequisiti

```bash
sudo apt-get update
sudo apt-get install -y curl jq bc python3 python3-pip
pip3 install subliminal   # Consigliato per sottotitoli
```

### 2. Crea un Bot Telegram

1. Apri Telegram → cerca **@BotFather** → invia `/newbot`
2. Salva il **Bot Token** (formato: `123456789:ABCdefGHI...`)
3. Ottieni il tuo **Chat ID** da **@userinfobot**

### 3. Configura lo Script

Modifica le variabili in testa a `mldonkey-telegram-notify.sh`:

```bash
TELEGRAM_BOT_TOKEN="il-tuo-token"
TELEGRAM_CHAT_ID="il-tuo-chat-id"

# Opzionali (ma consigliati)
TMDB_API_KEY="la-tua-api-key"          # Per poster e metadata
OPENSUBTITLES_USERNAME="username"       # Per sottotitoli migliorati
OPENSUBTITLES_PASSWORD="password"
```

### 4. Configura MLDonkey

Imposta `file_completed_cmd` in uno dei seguenti modi:

**Via `downloads.ini`:**
```ini
file_completed_cmd = "/percorso/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
```

**Via interfaccia web** (http://localhost:4080):
Settings → Options → `file_completed_cmd`

**Via telnet:**
```bash
telnet localhost 4000
set file_completed_cmd "/percorso/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
save
```

### 5. Test

```bash
chmod +x mldonkey-telegram-notify.sh
./mldonkey-telegram-notify.sh "The.Matrix.1999.1080p.BluRay.mkv" "1073741824" "ABC123" "/downloads/The.Matrix.1999.1080p.BluRay.mkv"
```

---

## 📱 Esempio di Notifica

```
🎉 Download completato!

📁 File: The.Matrix.1999.1080p.BluRay.x264.mkv
📊 Dimensione: 8.50 GB
🔑 Hash: ABC123DEF456
📂 Percorso: /home/downloads/The.Matrix.1999.1080p.BluRay.x264.mkv
🕐 Data: 30/01/2026 15:30:45

🎬 Informazioni Video:
🎥 Tipo: Film
🔗 Vedi su IMDB
🖼️ Poster scaricato
📋 Metadata salvati (NFO)
💬 ✅ Sottotitoli italiani scaricati
```

### File generati per ogni video:

```
/downloads/
├── The.Matrix.1999.1080p.BluRay.x264.mkv          # Video
├── The.Matrix.1999.1080p.BluRay.x264.srt           # Sottotitoli IT
├── The.Matrix.1999.1080p.BluRay.x264-poster.jpg    # Poster HD
└── The.Matrix.1999.1080p.BluRay.x264.nfo           # Metadata XML
```

---

## 🔧 Funzionamento Dettagliato

### Rilevamento Video
Estensioni supportate: `.avi`, `.mkv`, `.mp4`, `.mov`, `.wmv`, `.flv`, `.m4v`, `.mpg`, `.mpeg`, `.divx`, `.xvid`, `.webm`, `.ogv`, `.3gp`, `.m2ts`, `.ts`

### Rilevamento Film vs Serie TV
- **Serie TV**: pattern come `S01E01`, `1x01`, `Season`, `Episode`
- **Film**: tutto il resto

### Download Sottotitoli (3 metodi in cascata)
1. **Subliminal** (consigliato) — cerca su più provider automaticamente
2. **opensubtitles-cli** — alternativa via npm
3. **API diretta OpenSubtitles** — fallback con hash del file

### Poster e Metadata (TMDb)
- Cerca film/serie su TMDb con titolo estratto dal filename
- Scarica poster in risoluzione originale (~2000×3000px)
- Genera file NFO in formato XML compatibile con Kodi/Plex/Jellyfin

---

## 📖 Guide Aggiuntive

| Guida | Descrizione |
|---|---|
| [SUBLIMINAL_SETUP.md](SUBLIMINAL_SETUP.md) | Installazione e configurazione Subliminal per sottotitoli |
| [TMDB_GUIDE.md](TMDB_GUIDE.md) | Configurazione TMDb per poster e metadata |

---

## 📦 Script Legacy (`_Maurizio/`)

La cartella `_Maurizio/` contiene gli **script originali** che hanno ispirato questo progetto:

- **`my_file_completed_cmd.sh`** — Hook per `file_completed_cmd` di MLDonkey, con download sottotitoli via [OpenSubtitlesDownload](https://github.com/emericg/OpenSubtitlesDownload)
- **`telegram-pipe.sh`** — Utility per inviare testo a Telegram via pipe (`echo "messaggio" | ./telegram-pipe.sh`)

Questi script sono mantenuti per riferimento storico. Per nuove installazioni, usa `mldonkey-telegram-notify.sh`.

---

## 🔍 Parametri dello Script

Lo script riceve 4 parametri da MLDonkey:

| Parametro | Descrizione |
|---|---|
| `$1` | Nome del file |
| `$2` | Dimensione in bytes |
| `$3` | Hash MD4/ED2K |
| `$4` | Percorso completo del file |

---

## 🐛 Risoluzione Problemi

<details>
<summary><b>La notifica non arriva</b></summary>

1. Verifica token e chat_id
2. Controlla che `curl` sia installato
3. Testa il bot: `curl https://api.telegram.org/bot<TOKEN>/getMe`
4. Controlla il log: `tail -f /var/log/mldonkey-telegram.log`
</details>

<details>
<summary><b>Sottotitoli non trovati</b></summary>

1. Installa Subliminal: `pip3 install subliminal`
2. Verifica che il nome file sia in formato standard (`Film.Anno.Qualità.mkv`)
3. Registrati su OpenSubtitles per limiti più alti
</details>

<details>
<summary><b>Poster/metadata non scaricati</b></summary>

1. Verifica la TMDb API Key
2. Testa: `curl "https://api.themoviedb.org/3/search/movie?api_key=TUA_KEY&query=matrix"`
3. Rate limit: max 40 richieste ogni 10 secondi
</details>

---

## 📄 Licenza

Questo progetto è distribuito sotto licenza [GPL-3.0](LICENSE).

---

## 👤 Autore

**Maurizio Tallarico** — [@mauriziotallarico](https://github.com/mauriziotallarico)

---

*Notifiche intelligenti per i tuoi download 🍿*
