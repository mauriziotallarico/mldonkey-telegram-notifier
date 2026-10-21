#!/usr/bin/env bash
#
# mldonkey-notify.sh — Notifiche Telegram per download completati da MLDonkey
#
# Uso: viene chiamato da mldonkey come file_completed_cmd
#   file_completed_cmd = "/path/to/mldonkey-notify.sh"
#
# MLDonkey passa 3 argomenti posizionali:
#   $1 = hash ED2K del file
#   $2 = dimensione in bytes
#   $3 = nome del file
#
# Inoltre setta variabili d'ambiente:
#   FILEID, FILESIZE, FILENAME, FILEHASH, DURATION, INCOMING,
#   NETWORK, ED2K_HASH, DLFILES, FILE_OWNER, FILE_GROUP, USER_MAIL
#
set -uo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/mldonkey-notify.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "ERRORE: config non trovata: $CONF_FILE" >&2
    exit 1
fi
source "$CONF_FILE"

if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
    echo "ERRORE: TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID devono essere configurati" >&2
    exit 1
fi

# ─── Parametri da MLDonkey ───────────────────────────────────────────────────
FILE_HASH="${1:-${FILEID:-unknown}}"
FILE_SIZE="${2:-${FILESIZE:-0}}"
FILE_NAME="${3:-${FILENAME:-unknown}}"
FILE_NETWORK="${NETWORK:-unknown}"
FILE_DURATION="${DURATION:-0}"
FILE_INCOMING="${INCOMING:-$MLDONKEY_INCOMING}"
FILE_PATH="${FILE_INCOMING}/${FILE_NAME}"

# ─── Costanti ────────────────────────────────────────────────────────────────
TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
VIDEO_EXT_REGEX='\.(avi|mkv|mp4|mov|wmv|flv|m4v|mpg|mpeg|divx|xvid|webm|ogv|m2ts|ts)$'
NOW="$(date '+%Y-%m-%d %H:%M:%S')"

# ─── Logging ─────────────────────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

log "=== Nuovo download completato ==="
log "File: $FILE_NAME | Size: $FILE_SIZE | Hash: $FILE_HASH | Net: $FILE_NETWORK"

# ─── Funzioni utilità ────────────────────────────────────────────────────────

human_size() {
    local bytes=$1
    if (( bytes >= 1073741824 )); then
        awk "BEGIN {printf \"%.2f GB\", $bytes/1073741824}"
    elif (( bytes >= 1048576 )); then
        awk "BEGIN {printf \"%.2f MB\", $bytes/1048576}"
    elif (( bytes >= 1024 )); then
        awk "BEGIN {printf \"%.1f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

human_duration() {
    local secs=$1
    (( secs <= 0 )) && { echo "N/A"; return; }
    local d=$(( secs / 86400 )) h=$(( (secs % 86400) / 3600 )) m=$(( (secs % 3600) / 60 ))
    local r=""
    (( d > 0 )) && r+="${d}g "
    (( h > 0 )) && r+="${h}h "
    r+="${m}m"
    echo "$r"
}

is_video() {
    echo "$1" | grep -qiE "$VIDEO_EXT_REGEX"
}

# Escape HTML entities
html_escape() {
    local s="$1"
    s="${s//&/&amp;}"
    s="${s//</&lt;}"
    s="${s//>/&gt;}"
    echo "$s"
}

# ─── Telegram ────────────────────────────────────────────────────────────────

send_telegram_message() {
    local text="$1"
    log "Invio messaggio Telegram (${#text} chars)"
    local response
    response=$(curl -s --max-time 30 -X POST "${TELEGRAM_API}/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT_ID" \
        -d parse_mode="HTML" \
        --data-urlencode text="$text" \
        2>&1)
    log "Telegram response: $response"

    if echo "$response" | grep -q '"ok":false'; then
        log "WARN: HTML fallito, riprovo plain text"
        local plain
        plain=$(echo "$text" | sed 's/<[^>]*>//g')
        response=$(curl -s --max-time 30 -X POST "${TELEGRAM_API}/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT_ID" \
            --data-urlencode text="$plain" \
            2>&1)
        log "Telegram retry: $response"
    fi
}

send_telegram_photo() {
    local photo_path="$1"
    local caption="$2"
    log "Invio foto Telegram: $photo_path (${#caption} chars)"
    local response
    response=$(curl -s --max-time 30 -X POST "${TELEGRAM_API}/sendPhoto" \
        -F chat_id="$TELEGRAM_CHAT_ID" \
        -F photo="@${photo_path}" \
        -F caption="$caption" \
        -F parse_mode="HTML" \
        2>&1)
    log "Telegram photo: $response"

    if echo "$response" | grep -q '"ok":false'; then
        log "WARN: foto HTML fallita, riprovo plain"
        local plain
        plain=$(echo "$caption" | sed 's/<[^>]*>//g')
        response=$(curl -s --max-time 30 -X POST "${TELEGRAM_API}/sendPhoto" \
            -F chat_id="$TELEGRAM_CHAT_ID" \
            -F photo="@${photo_path}" \
            -F caption="$plain" \
            2>&1)
        log "Telegram photo retry: $response"
    fi
}

# ─── Guessit ─────────────────────────────────────────────────────────────────

parse_media_info() {
    python3 -c "
import json, sys
try:
    from guessit import guessit
    info = guessit(sys.argv[1])
    print(json.dumps({
        'title': str(info.get('title', '')),
        'year': str(info.get('year', '')),
        'type': str(info.get('type', 'unknown')),
        'season': str(info.get('season', '')),
        'episode': str(info.get('episode', '')),
        'source': str(info.get('source', '')),
        'resolution': str(info.get('screen_size', '')),
        'codec': str(info.get('video_codec', '')),
    }))
except Exception as e:
    print(json.dumps({'error': str(e)}))
" "$1" 2>/dev/null
}

# ─── IMDB lookup ─────────────────────────────────────────────────────────────

search_imdb() {
    local title="$1" year="$2" media_type="$3"

    # IMDB Suggest API — pubblica, nessuna key
    local suggest_query
    suggest_query=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/ /_/g' | head -c 20)
    local first_char="${suggest_query:0:1}"
    local suggest_url="https://v2.sg.media-imdb.com/suggestion/${first_char}/${suggest_query}.json"

    log "IMDB suggest: $suggest_url"
    local suggest_result
    suggest_result=$(curl -s --max-time 10 -L "$suggest_url" 2>/dev/null) || return 1

    [[ -z "$suggest_result" ]] && return 1

    local imdb_data
    imdb_data=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    mt = sys.argv[2]
    for r in data.get('d', []):
        qid = r.get('qid', '')
        if mt == 'episode' and qid not in ('tvSeries', 'tvMiniSeries'):
            continue
        if mt == 'movie' and qid not in ('movie', 'short', 'video'):
            continue
        img = r.get('i', {})
        print(json.dumps({
            'id': r.get('id', ''),
            'title': r.get('l', ''),
            'year': str(r.get('y', '')),
            'image': img.get('imageUrl', '') if isinstance(img, dict) else '',
        }))
        break
    else:
        if data.get('d'):
            r = data['d'][0]
            img = r.get('i', {})
            print(json.dumps({
                'id': r.get('id', ''),
                'title': r.get('l', ''),
                'year': str(r.get('y', '')),
                'image': img.get('imageUrl', '') if isinstance(img, dict) else '',
            }))
except Exception:
    pass
" "$suggest_result" "$media_type" 2>/dev/null)

    [[ -z "$imdb_data" ]] && return 1

    local imdb_id imdb_title imdb_year imdb_image
    imdb_id=$(echo "$imdb_data" | jq -r '.id // empty')
    imdb_title=$(echo "$imdb_data" | jq -r '.title // empty')
    imdb_year=$(echo "$imdb_data" | jq -r '.year // empty')
    imdb_image=$(echo "$imdb_data" | jq -r '.image // empty')

    [[ -z "$imdb_id" ]] && return 1

    log "IMDB trovato: $imdb_title ($imdb_year) — $imdb_id"

    echo "URL:https://www.imdb.com/title/${imdb_id}/"
    echo "TITLE:${imdb_title}"
    echo "YEAR:${imdb_year}"

    # Scarica poster IMDB se TMDb non configurato
    if [[ "$SEND_POSTER" == "true" && -n "$imdb_image" && -z "$TMDB_API_KEY" ]]; then
        local poster="/tmp/mldonkey_poster_$$.jpg"
        curl -s --max-time 15 -L "$imdb_image" -o "$poster" 2>/dev/null
        if [[ -f "$poster" && -s "$poster" ]]; then
            log "Poster IMDB scaricato"
            echo "POSTER:${poster}"
        fi
    fi
}

# ─── TMDb lookup (opzionale) ────────────────────────────────────────────────

search_tmdb() {
    local title="$1" year="$2" media_type="$3"

    [[ -z "$TMDB_API_KEY" ]] && return 1

    local tmdb_type="movie"
    [[ "$media_type" == "episode" ]] && tmdb_type="tv"

    local encoded
    encoded=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$title")

    local url="https://api.themoviedb.org/3/search/${tmdb_type}?api_key=${TMDB_API_KEY}&query=${encoded}&language=it-IT"
    [[ -n "$year" ]] && url+="&year=${year}"

    local result
    result=$(curl -s --max-time 10 "$url" 2>/dev/null) || return 1

    local tmdb_data
    tmdb_data=$(python3 -c "
import json, sys
try:
    data = json.loads(sys.argv[1])
    r = data.get('results', [None])[0]
    if r:
        print(json.dumps({
            'title': r.get('title', r.get('name', '')),
            'overview': r.get('overview', '')[:200],
            'poster': r.get('poster_path', ''),
            'vote': r.get('vote_average', 0),
            'id': r.get('id', ''),
        }))
except Exception:
    pass
" "$result" 2>/dev/null)

    [[ -z "$tmdb_data" ]] && return 1

    local t_title t_overview t_poster t_vote t_id
    t_title=$(echo "$tmdb_data" | jq -r '.title // empty')
    t_overview=$(echo "$tmdb_data" | jq -r '.overview // empty')
    t_poster=$(echo "$tmdb_data" | jq -r '.poster // empty')
    t_vote=$(echo "$tmdb_data" | jq -r '.vote // empty')
    t_id=$(echo "$tmdb_data" | jq -r '.id // empty')

    log "TMDb trovato: $t_title (⭐$t_vote) — ID $t_id"

    echo "TMDB_TITLE:${t_title}"
    echo "TMDB_OVERVIEW:${t_overview}"
    echo "TMDB_VOTE:${t_vote}"
    echo "TMDB_URL:https://www.themoviedb.org/${tmdb_type}/${t_id}"

    if [[ "$SEND_POSTER" == "true" && -n "$t_poster" && "$t_poster" != "null" ]]; then
        local poster="/tmp/mldonkey_poster_$$.jpg"
        curl -s --max-time 15 -L "https://image.tmdb.org/t/p/w500${t_poster}" -o "$poster" 2>/dev/null
        if [[ -f "$poster" && -s "$poster" ]]; then
            log "Poster TMDb scaricato"
            echo "POSTER:${poster}"
        fi
    fi
}

# ─── Sottotitoli ─────────────────────────────────────────────────────────────

download_subtitles() {
    local filepath="$1"
    local lang="${SUBTITLE_LANG:-it}"

    [[ "$SUBTITLE_ENABLED" != "true" ]] && { echo "SKIP"; return; }
    [[ ! -f "$filepath" ]] && { log "WARN: file non trovato: $filepath"; echo "FILE_NOT_FOUND"; return; }

    log "Cerco sottotitoli ($lang) per: $(basename "$filepath")"
    local out
    out=$(python3 -c "
import sys
try:
    from subliminal import download_best_subtitles, scan_video, save_subtitles, region
    from babelfish import Language
    region.configure('dogpile.cache.memory')
    video = scan_video(sys.argv[1])
    subs = download_best_subtitles({video}, {Language(sys.argv[2])},
        providers=['opensubtitlescom', 'podnapisi', 'addic7ed'])
    found = subs.get(video, [])
    if found:
        save_subtitles(video, found)
        print('FOUND')
    else:
        print('NOT_FOUND')
except ImportError:
    print('NOT_INSTALLED')
except Exception as e:
    print(f'ERROR:{e}')
" "$filepath" "$lang" 2>&1)

    log "Subliminal: $out"
    case "$out" in
        FOUND*)       echo "FOUND" ;;
        NOT_INSTALLED*) echo "NOT_INSTALLED" ;;
        *)            echo "NOT_FOUND" ;;
    esac
}

# ─── Costruisci messaggio HTML ───────────────────────────────────────────────

build_message() {
    local is_video_file="$1" media_json="$2" imdb_info="$3" tmdb_info="$4" sub_status="$5"

    local hr_size hr_duration
    hr_size=$(human_size "$FILE_SIZE")
    hr_duration=$(human_duration "$FILE_DURATION")

    local msg="🎉 <b>Download completato!</b>"$'\n\n'

    # Nome file
    msg+="📁 <code>$(html_escape "$FILE_NAME")</code>"$'\n'

    # Info base
    msg+="📦 $(html_escape "$hr_size")"
    [[ "$hr_duration" != "N/A" ]] && msg+=" ⏱ ${hr_duration}"
    msg+=" 🌐 ${FILE_NETWORK}"$'\n'

    # Info media
    if [[ "$is_video_file" == "true" && -n "$media_json" ]]; then
        local m_title m_year m_type m_season m_episode m_res
        m_title=$(echo "$media_json" | jq -r '.title // empty')
        m_year=$(echo "$media_json" | jq -r '.year // empty')
        m_type=$(echo "$media_json" | jq -r '.type // empty')
        m_season=$(echo "$media_json" | jq -r '.season // empty')
        m_episode=$(echo "$media_json" | jq -r '.episode // empty')
        m_res=$(echo "$media_json" | jq -r '.resolution // empty')

        msg+=$'\n'
        if [[ "$m_type" == "episode" ]]; then
            msg+="📺 <b>$(html_escape "$m_title")</b>"
            [[ -n "$m_season" && -n "$m_episode" ]] && msg+=" S${m_season}E${m_episode}"
        else
            msg+="🎬 <b>$(html_escape "$m_title")</b>"
        fi
        [[ -n "$m_year" ]] && msg+=" ($m_year)"
        [[ -n "$m_res" ]] && msg+=" — $m_res"
        msg+=$'\n'
    fi

    # IMDB
    local imdb_url
    imdb_url=$(echo "$imdb_info" | grep "^URL:" | cut -d: -f2-)
    if [[ -n "$imdb_url" ]]; then
        msg+="🔗 <a href=\"${imdb_url}\">IMDB</a>"$'\n'
    fi

    # TMDb
    local tmdb_url tmdb_vote tmdb_overview
    tmdb_url=$(echo "$tmdb_info" | grep "^TMDB_URL:" | cut -d: -f2-)
    tmdb_vote=$(echo "$tmdb_info" | grep "^TMDB_VOTE:" | cut -d: -f2-)
    tmdb_overview=$(echo "$tmdb_info" | grep "^TMDB_OVERVIEW:" | cut -d: -f2-)
    if [[ -n "$tmdb_url" ]]; then
        msg+="🎯 <a href=\"${tmdb_url}\">TMDb</a>"
        [[ -n "$tmdb_vote" && "$tmdb_vote" != "0" ]] && msg+=" ⭐ ${tmdb_vote}/10"
        msg+=$'\n'
        [[ -n "$tmdb_overview" && "$tmdb_overview" != "null" ]] && msg+="📝 <i>$(html_escape "$tmdb_overview")</i>"$'\n'
    fi

    # Sottotitoli
    if [[ "$is_video_file" == "true" ]]; then
        case "$sub_status" in
            FOUND)          msg+="🗒 Sottotitoli ITA: ✅ scaricati" ;;
            NOT_FOUND)      msg+="🗒 Sottotitoli ITA: ❌ non trovati" ;;
            SKIP)           msg+="🗒 Sottotitoli: ⏭ disabilitati" ;;
            NOT_INSTALLED)  msg+="🗒 Sottotitoli: ⚠️ subliminal non installato" ;;
            FILE_NOT_FOUND) msg+="🗒 Sottotitoli: ⚠️ file non accessibile" ;;
        esac
        msg+=$'\n'
    fi

    msg+=$'\n'"🕐 ${NOW}"

    echo "$msg"
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local is_video="false"
    local media_json="" imdb_info="" tmdb_info=""
    local sub_status="SKIP" poster_path=""

    if is_video "$FILE_NAME"; then
        is_video="true"
        log "File video rilevato"

        # Parsing nome file
        media_json=$(parse_media_info "$FILE_NAME") || true
        log "Guessit: $media_json"

        if [[ "$MEDIA_LOOKUP" == "true" && -n "$media_json" ]]; then
            local title year media_type
            title=$(echo "$media_json" | jq -r '.title // empty') || true
            year=$(echo "$media_json" | jq -r '.year // empty') || true
            media_type=$(echo "$media_json" | jq -r '.type // empty') || true

            if [[ -n "$title" ]]; then
                tmdb_info=$(search_tmdb "$title" "$year" "$media_type" 2>/dev/null) || true
                imdb_info=$(search_imdb "$title" "$year" "$media_type" 2>/dev/null) || true
            fi
        fi

        sub_status=$(download_subtitles "$FILE_PATH") || sub_status="NOT_FOUND"

        poster_path=$(echo "$tmdb_info" | grep "^POSTER:" | cut -d: -f2-) || true
        [[ -z "$poster_path" ]] && { poster_path=$(echo "$imdb_info" | grep "^POSTER:" | cut -d: -f2-) || true; }
    fi

    log "Build msg (video=$is_video sub=$sub_status poster=$poster_path)"
    local message
    message=$(build_message "$is_video" "$media_json" "$imdb_info" "$tmdb_info" "$sub_status") || true
    log "Messaggio: ${#message} chars"

    if [[ -n "$poster_path" && -f "$poster_path" ]]; then
        local caption
        caption=$(echo "$message" | head -c 1024)
        send_telegram_photo "$poster_path" "$caption"
        rm -f "$poster_path" 2>/dev/null
    else
        send_telegram_message "$message"
    fi

    log "=== Notifica completata ==="
}

main "$@"
