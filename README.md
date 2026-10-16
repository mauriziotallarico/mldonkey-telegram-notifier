# 🎬 MLDonkey Telegram Notifier

> 🇮🇹 [Leggi in Italiano](README.it.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Automatic Telegram notifications for completed **MLDonkey** downloads, with IMDB lookup, subtitle download, poster art, and smart media detection.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📬 **Telegram Notifications** | Automatic message for every completed download |
| 🎥 **IMDB Lookup** | Automatic IMDB link for video files (via guessit) |
| 📺 **Movie/TV Detection** | Automatically distinguishes movies from TV series |
| 💬 **Subtitle Download** | Auto-download via Subliminal |
| 🖼️ **HD Posters** | Automatic poster download from TMDb |
| 📊 **Human-readable Sizes** | Automatic bytes → KB/MB/GB conversion |
| 🔄 **Fallback** | If HTML Telegram message fails, retries in plain text |
| 📝 **Logging** | Complete operation log |

---

## 📂 Repository Structure

```
├── mldonkey-notify.sh            # 🔧 Main script
├── mldonkey-notify.conf.example  # ⚙️ Configuration template
├── SUBLIMINAL_SETUP.md           # 📖 Subliminal installation guide
├── TMDB_GUIDE.md                 # 📖 TMDb configuration guide
├── LICENSE                       # 📄 MIT License
└── README.md                     # 📖 This file
```

---

## ⚡ Quick Start

### 1. Prerequisites

```bash
sudo apt-get update
sudo apt-get install -y curl jq python3 python3-pip
pip3 install guessit subliminal babelfish
```

### 2. Create a Telegram Bot

1. Open Telegram → search **@BotFather** → send `/newbot`
2. Save the **Bot Token** (format: `123456789:ABCdefGHI...`)
3. Get your **Chat ID** from **@userinfobot**

### 3. Install and Configure

```bash
git clone https://github.com/mauriziotallarico/mldonkey-telegram-notifier.git
cd mldonkey-telegram-notifier
cp mldonkey-notify.conf.example mldonkey-notify.conf
chmod +x mldonkey-notify.sh
```

Edit `mldonkey-notify.conf`:

```bash
TELEGRAM_BOT_TOKEN="your-token"
TELEGRAM_CHAT_ID="your-chat-id"
MLDONKEY_INCOMING="/path/to/mldonkey/incoming/files"

# Optional (but recommended)
TMDB_API_KEY="your-api-key"       # For posters and metadata
```

### 4. Configure MLDonkey

Set `file_completed_cmd` using one of these methods:

**Via `downloads.ini`:**
```ini
file_completed_cmd = "/path/to/mldonkey-notify.sh"
```

**Via telnet:**
```bash
telnet localhost 4000
set file_completed_cmd "/path/to/mldonkey-notify.sh"
save
```

### 5. Test

```bash
./mldonkey-notify.sh "The.Matrix.1999.1080p.BluRay.mkv"
```

---

## 📱 Notification Examples

**Movie with poster:**
> 🎉 **Download completed!**
>
> 📁 `Dune.Part.Two.2024.2160p.WEB-DL.DDP5.1.x265.mkv`
> 📦 1.44 GB ⏱ 2h 0m 🌐 ed2k
>
> 🎬 **Dune** (2024) — 2160p
> 🔗 IMDB
> 🗒 Subtitles: ✅ downloaded

**TV Series:**
> 📺 **Breaking Bad** S1E1 — 1080p

**Generic file:**
> 📁 `ubuntu-24.04-desktop-amd64.iso`
> 📦 4.38 GB ⏱ 15m 🌐 ed2k

---

## ⚙️ Configuration Options

| Parameter | Default | Description |
|-----------|---------|-------------|
| `TELEGRAM_BOT_TOKEN` | — | Telegram bot token (required) |
| `TELEGRAM_CHAT_ID` | — | Destination chat ID (required) |
| `MLDONKEY_INCOMING` | — | Path to mldonkey incoming directory |
| `TMDB_API_KEY` | empty | TMDb API key (optional, free) |
| `SUBTITLE_LANG` | `it` | Subtitle language |
| `SUBTITLE_ENABLED` | `true` | Enable subtitle download |
| `MEDIA_LOOKUP` | `true` | Look up IMDB/TMDb info for videos |
| `SEND_POSTER` | `true` | Send poster as Telegram photo |
| `LOG_FILE` | — | Log file path |

---

## 🏗️ Architecture

```
mldonkey (file_completed_cmd)
  └→ mldonkey-notify.sh
       ├── mldonkey-notify.conf    (external config)
       ├── guessit                 (filename parsing)
       ├── IMDB Suggest API        (free lookup)
       ├── TMDb API                (optional: HD posters + metadata)
       ├── subliminal              (subtitle download)
       └── Telegram Bot API        (notification + photo)
```

---

## 📖 Additional Guides

| Guide | Description |
|---|---|
| [SUBLIMINAL_SETUP.md](SUBLIMINAL_SETUP.md) | Subliminal installation and configuration |
| [TMDB_GUIDE.md](TMDB_GUIDE.md) | TMDb setup for posters and metadata |

---

## 🐛 Troubleshooting

<details>
<summary><b>Notification not arriving</b></summary>

1. Verify token and chat_id in `mldonkey-notify.conf`
2. Check that `curl` is installed
3. Test the bot: `curl https://api.telegram.org/bot<TOKEN>/getMe`
4. Check the log file
</details>

<details>
<summary><b>Subtitles not found</b></summary>

1. Install Subliminal: `pip3 install subliminal`
2. Verify the filename is in standard format (`Movie.Year.Quality.mkv`)
3. See [SUBLIMINAL_SETUP.md](SUBLIMINAL_SETUP.md) for details
</details>

<details>
<summary><b>Posters/metadata not downloaded</b></summary>

1. Verify your TMDb API Key
2. Test: `curl "https://api.themoviedb.org/3/search/movie?api_key=YOUR_KEY&query=matrix"`
3. See [TMDB_GUIDE.md](TMDB_GUIDE.md) for setup
</details>

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👤 Author

**Maurizio Tallarico** — [@mauriziotallarico](https://github.com/mauriziotallarico)

---

*Smart notifications for your downloads 🍿*
