# 🎬 MLDonkey Telegram Notifier

> 🇮🇹 [Leggi in Italiano](README.md)

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL%203.0-blue.svg)](LICENSE)

Automatic Telegram notifications for completed **MLDonkey** downloads, with IMDB lookup, Italian subtitle download, poster art, and media center metadata.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📬 **Telegram Notifications** | Automatic message for every completed download |
| 🎥 **IMDB Lookup** | Automatic IMDB link for video files |
| 📺 **Movie/TV Detection** | Automatically distinguishes movies from TV series |
| 💬 **Italian Subtitles** | Auto-download via Subliminal, opensubtitles-cli, or direct API |
| 🖼️ **HD Posters** | Automatic poster download from TMDb |
| 📋 **NFO Metadata** | NFO files compatible with Kodi, Plex, Jellyfin, Emby |
| 📊 **Human-readable Sizes** | Automatic bytes → KB/MB/GB conversion |
| 📝 **Logging** | Complete operation log |

---

## 📂 Repository Structure

```
├── mldonkey-telegram-notify.sh   # 🔧 Main script (current version)
├── SUBLIMINAL_SETUP.md           # 📖 Subliminal installation guide (IT)
├── TMDB_GUIDE.md                 # 📖 TMDb configuration guide (IT)
├── _Maurizio/                    # 📦 Original scripts (legacy)
│   ├── my_file_completed_cmd.sh  #     Original MLDonkey hook
│   ├── telegram-pipe.sh          #     Pipe → Telegram utility
│   ├── README.md                 #     Original documentation
│   └── LICENSE                   #     GPL-3.0 License
└── README.md                     # Main README (Italian)
```

---

## ⚡ Quick Start

### 1. Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y curl jq bc python3 python3-pip
pip3 install subliminal   # Recommended for subtitles
```

### 2. Create a Telegram Bot

1. Open Telegram → search **@BotFather** → send `/newbot`
2. Save the **Bot Token** (format: `123456789:ABCdefGHI...`)
3. Get your **Chat ID** from **@userinfobot**

### 3. Configure the Script

Edit the variables at the top of `mldonkey-telegram-notify.sh`:

```bash
TELEGRAM_BOT_TOKEN="your-token"
TELEGRAM_CHAT_ID="your-chat-id"

# Optional (but recommended)
TMDB_API_KEY="your-api-key"            # For posters and metadata
OPENSUBTITLES_USERNAME="username"       # For improved subtitles
OPENSUBTITLES_PASSWORD="password"
```

### 4. Configure MLDonkey

Set `file_completed_cmd` using one of these methods:

**Via `downloads.ini`:**
```ini
file_completed_cmd = "/path/to/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
```

**Via web interface** (http://localhost:4080):
Settings → Options → `file_completed_cmd`

**Via telnet:**
```bash
telnet localhost 4000
set file_completed_cmd "/path/to/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
save
```

### 5. Test

```bash
chmod +x mldonkey-telegram-notify.sh
./mldonkey-telegram-notify.sh "The.Matrix.1999.1080p.BluRay.mkv" "1073741824" "ABC123" "/downloads/The.Matrix.1999.1080p.BluRay.mkv"
```

---

## 📱 Notification Example

```
🎉 Download completed!

📁 File: The.Matrix.1999.1080p.BluRay.x264.mkv
📊 Size: 8.50 GB
🔑 Hash: ABC123DEF456
📂 Path: /home/downloads/The.Matrix.1999.1080p.BluRay.x264.mkv
🕐 Date: 30/01/2026 15:30:45

🎬 Video Info:
🎥 Type: Movie
🔗 View on IMDB
🖼️ Poster downloaded
📋 Metadata saved (NFO)
💬 ✅ Italian subtitles downloaded
```

### Files generated for each video:

```
/downloads/
├── The.Matrix.1999.1080p.BluRay.x264.mkv          # Video
├── The.Matrix.1999.1080p.BluRay.x264.srt           # Italian subtitles
├── The.Matrix.1999.1080p.BluRay.x264-poster.jpg    # HD poster
└── The.Matrix.1999.1080p.BluRay.x264.nfo           # XML metadata
```

---

## 🔧 How It Works

### Video Detection
Supported extensions: `.avi`, `.mkv`, `.mp4`, `.mov`, `.wmv`, `.flv`, `.m4v`, `.mpg`, `.mpeg`, `.divx`, `.xvid`, `.webm`, `.ogv`, `.3gp`, `.m2ts`, `.ts`

### Movie vs TV Series Detection
- **TV Series**: patterns like `S01E01`, `1x01`, `Season`, `Episode`
- **Movies**: everything else

### Subtitle Download (3 cascading methods)
1. **Subliminal** (recommended) — searches multiple providers automatically
2. **opensubtitles-cli** — npm-based alternative
3. **Direct OpenSubtitles API** — fallback using file hash

### Posters and Metadata (TMDb)
- Searches TMDb for movie/series using title extracted from filename
- Downloads poster in original resolution (~2000×3000px)
- Generates NFO file in XML format compatible with Kodi/Plex/Jellyfin

---

## 📖 Additional Guides

| Guide | Description |
|---|---|
| [SUBLIMINAL_SETUP.md](SUBLIMINAL_SETUP.md) | Subliminal installation and configuration (Italian) |
| [TMDB_GUIDE.md](TMDB_GUIDE.md) | TMDb setup for posters and metadata (Italian) |

---

## 📦 Legacy Scripts (`_Maurizio/`)

The `_Maurizio/` folder contains the **original scripts** that inspired this project:

- **`my_file_completed_cmd.sh`** — MLDonkey `file_completed_cmd` hook with subtitle download via [OpenSubtitlesDownload](https://github.com/emericg/OpenSubtitlesDownload)
- **`telegram-pipe.sh`** — Utility to send text to Telegram via pipe (`echo "message" | ./telegram-pipe.sh`)

These scripts are kept for historical reference. For new installations, use `mldonkey-telegram-notify.sh`.

---

## 🔍 Script Parameters

The script receives 4 parameters from MLDonkey:

| Parameter | Description |
|---|---|
| `$1` | File name |
| `$2` | Size in bytes |
| `$3` | MD4/ED2K hash |
| `$4` | Full file path |

---

## 🐛 Troubleshooting

<details>
<summary><b>Notification not arriving</b></summary>

1. Verify token and chat_id
2. Check that `curl` is installed
3. Test the bot: `curl https://api.telegram.org/bot<TOKEN>/getMe`
4. Check the log: `tail -f /var/log/mldonkey-telegram.log`
</details>

<details>
<summary><b>Subtitles not found</b></summary>

1. Install Subliminal: `pip3 install subliminal`
2. Verify the filename is in standard format (`Movie.Year.Quality.mkv`)
3. Register on OpenSubtitles for higher rate limits
</details>

<details>
<summary><b>Posters/metadata not downloaded</b></summary>

1. Verify your TMDb API Key
2. Test: `curl "https://api.themoviedb.org/3/search/movie?api_key=YOUR_KEY&query=matrix"`
3. Rate limit: max 40 requests every 10 seconds
</details>

---

## 📄 License

This project is licensed under the [GPL-3.0 License](LICENSE).

---

## 👤 Author

**Maurizio Tallarico** — [@mauriziotallarico](https://github.com/mauriziotallarico)

---

*Smart notifications for your downloads 🍿*
