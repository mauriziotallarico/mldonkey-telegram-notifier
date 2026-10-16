# 📢 mldonkey-telegram-notifier

Notifiche Telegram automatiche quando MLDonkey completa un download.

## ✨ Funzionalità

- 🎉 **Notifica Telegram** con nome file, dimensione, durata download, rete
- 🎬 **Riconoscimento automatico** film e serie TV (guessit)
- 🔍 **Ricerca IMDB** automatica con link diretto
- 🖼️ **Poster** del film/serie inviato come foto Telegram
- 🎯 **TMDb** (opzionale) per metadata in italiano, rating e poster HD
- 🗒️ **Sottotitoli ITA** scaricati automaticamente (subliminal)
- 📝 **Log** dettagliato su file
- 🔄 **Fallback** automatico: se HTML Telegram fallisce, riprova in plain text

## 📦 Dipendenze

```bash
# Già presenti su Raspberry Pi OS
apt install python3 curl jq

# Python packages
pip3 install guessit subliminal babelfish
```

## 🚀 Installazione

1. **Copia i file** nella stessa directory:
   ```bash
   cp mldonkey-notify.sh /path/to/scripts/
   cp mldonkey-notify.conf.example /path/to/scripts/mldonkey-notify.conf
   chmod +x /path/to/scripts/mldonkey-notify.sh
   ```

2. **Configura** `mldonkey-notify.conf`:
   ```bash
   TELEGRAM_BOT_TOKEN="il_tuo_bot_token"
   TELEGRAM_CHAT_ID="il_tuo_chat_id"
   MLDONKEY_INCOMING="/media/hdd/mldonkey/incoming/files"
   ```

3. **Configura MLDonkey** — nel telnet/web UI di mldonkey:
   ```
   set file_completed_cmd "/path/to/scripts/mldonkey-notify.sh"
   ```
   Oppure in `downloads.ini`:
   ```
   file_completed_cmd = "/path/to/scripts/mldonkey-notify.sh"
   ```

## 📱 Esempio notifica

**Film con poster:**
> 🎉 **Download completato!**
>
> 📁 `Dune.Part.Two.2024.2160p.WEB-DL.DDP5.1.x265.mkv`
> 📦 1.44 GB ⏱ 2h 0m 🌐 ed2k
>
> 🎬 **Dune** (2024) — 2160p
> 🔗 IMDB
> 🗒 Sottotitoli ITA: ✅ scaricati

**Serie TV:**
> 📺 **Breaking Bad** S1E1 — 1080p

**File generico:**
> 📁 `ubuntu-24.04-desktop-amd64.iso`
> 📦 4.38 GB ⏱ 15m 🌐 ed2k

## ⚙️ Opzioni config

| Parametro | Default | Descrizione |
|-----------|---------|-------------|
| `TELEGRAM_BOT_TOKEN` | — | Token del bot Telegram (obbligatorio) |
| `TELEGRAM_CHAT_ID` | — | Chat ID destinazione (obbligatorio) |
| `MLDONKEY_INCOMING` | — | Path directory incoming mldonkey |
| `TMDB_API_KEY` | vuoto | API key TMDb (opzionale, gratis) |
| `SUBTITLE_LANG` | `it` | Lingua sottotitoli |
| `SUBTITLE_ENABLED` | `true` | Abilita download sottotitoli |
| `MEDIA_LOOKUP` | `true` | Cerca info IMDB/TMDb per video |
| `SEND_POSTER` | `true` | Invia poster come foto |
| `LOG_FILE` | — | Path file di log |

## 🏗️ Architettura

```
mldonkey (file_completed_cmd)
  └→ mldonkey-notify.sh
       ├── mldonkey-notify.conf (config esterna)
       ├── guessit (parsing nome file)
       ├── IMDB Suggest API (lookup gratuito)
       ├── TMDb API (opzionale, poster HD + metadata IT)
       ├── subliminal (sottotitoli)
       └── Telegram Bot API (notifica + foto)
```

## 📄 Licenza

MIT
