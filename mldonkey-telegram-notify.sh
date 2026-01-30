#!/bin/bash

################################################################################
# Script per notifiche Telegram da MLDonkey
# Usa: file_completed_cmd in MLDonkey per inviare messaggi a un bot Telegram
# Include: ricerca IMDB per video e download sottotitoli italiani
################################################################################

# === CONFIGURAZIONE ===
# Inserisci qui il token del tuo bot Telegram
TELEGRAM_BOT_TOKEN="IL_TUO_BOT_TOKEN"

# Inserisci qui il tuo chat_id (puoi ottenerlo da @userinfobot su Telegram)
TELEGRAM_CHAT_ID="IL_TUO_CHAT_ID"

# Inserisci qui il tuo username e password di OpenSubtitles (opzionale ma consigliato)
OPENSUBTITLES_USERNAME=""
OPENSUBTITLES_PASSWORD=""

# Inserisci qui la tua API key di TMDb per poster e metadata (opzionale ma consigliato)
# Ottieni gratuitamente da: https://www.themoviedb.org/settings/api
TMDB_API_KEY=""

# User agent per OpenSubtitles API
OPENSUBTITLES_USERAGENT="MLDonkeyNotifier v1.0"

# URL API Telegram
TELEGRAM_API="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage"

# Estensioni video supportate
VIDEO_EXTENSIONS="avi|mkv|mp4|mov|wmv|flv|m4v|mpg|mpeg|divx|xvid|webm|ogv|3gp|m2ts|ts"

# === PARAMETRI DA MLDONKEY ===
# MLDonkey passa i seguenti parametri quando chiama file_completed_cmd:
# $1 = Nome del file completato
# $2 = Dimensione del file (in bytes)
# $3 = Hash del file (MD4/ED2K)
# $4 = Percorso completo del file

FILE_NAME="${1:-File sconosciuto}"
FILE_SIZE="${2:-0}"
FILE_HASH="${3:-N/A}"
FILE_PATH="${4:-N/A}"

# === FUNZIONI ===

# Converte i bytes in formato leggibile
human_readable_size() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes} B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1024}") KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}") MB"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}") GB"
    fi
}

# Verifica se il file è un video
is_video_file() {
    local filename="$1"
    local extension="${filename##*.}"
    extension=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
    
    if echo "$VIDEO_EXTENSIONS" | grep -qw "$extension"; then
        return 0
    else
        return 1
    fi
}

# Estrae il titolo pulito dal nome del file
extract_clean_title() {
    local filename="$1"
    # Rimuove l'estensione
    local title="${filename%.*}"
    
    # Rimuove anno se presente (es. 2024, 1999)
    title=$(echo "$title" | sed -E 's/[.\[]?(19[0-9]{2}|20[0-9]{2})[.\]]?//g')
    
    # Rimuove tag comuni (1080p, 720p, BluRay, etc.)
    title=$(echo "$title" | sed -E 's/[.\[]?(1080p|720p|480p|2160p|4K|BluRay|BRRip|WEB-DL|WEBRip|HDRip|DVDRip|HDTV|x264|x265|HEVC|AAC|AC3|DTS|DD5\.1|5\.1)[.\]]?//gi')
    
    # Rimuove gruppi di release
    title=$(echo "$title" | sed -E 's/[.\[]-?[A-Z0-9]+$//g')
    
    # Sostituisce punti e underscore con spazi
    title=$(echo "$title" | tr '._' ' ')
    
    # Rimuove spazi multipli
    title=$(echo "$title" | sed 's/  */ /g' | sed 's/^ *//g' | sed 's/ *$//g')
    
    echo "$title"
}

# Cerca il film/serie su IMDB
search_imdb() {
    local query="$1"
    local encoded_query=$(echo "$query" | sed 's/ /+/g')
    
    # Cerca su IMDB usando l'API non ufficiale (OMDb)
    # Nota: potresti voler usare la tua API key di OMDb per risultati migliori
    local search_url="https://www.imdb.com/find?q=${encoded_query}&s=tt&ttype=ft,tv&ref_=fn_ft"
    
    # Estrae il primo risultato
    local imdb_page=$(curl -s -L -A "Mozilla/5.0" "$search_url" 2>/dev/null)
    local imdb_id=$(echo "$imdb_page" | grep -oP 'href="/title/(tt\d+)/' | head -1 | grep -oP 'tt\d+')
    
    if [ -n "$imdb_id" ]; then
        echo "https://www.imdb.com/title/${imdb_id}/"
    else
        echo ""
    fi
}

# Cerca metadata su TMDb
search_tmdb() {
    local query="$1"
    local type="${2:-movie}"  # movie o tv
    
    if [ -z "$TMDB_API_KEY" ]; then
        echo ""
        return 1
    fi
    
    local encoded_query=$(echo "$query" | sed 's/ /%20/g')
    local search_url="https://api.themoviedb.org/3/search/${type}?api_key=${TMDB_API_KEY}&query=${encoded_query}&language=it-IT"
    
    local result=$(curl -s "$search_url" 2>/dev/null)
    
    # Estrae l'ID del primo risultato
    local tmdb_id=$(echo "$result" | grep -oP '"id":\d+' | head -1 | grep -oP '\d+')
    
    if [ -n "$tmdb_id" ]; then
        echo "$tmdb_id"
    else
        echo ""
    fi
}

# Scarica metadata completi da TMDb
get_tmdb_metadata() {
    local tmdb_id="$1"
    local type="${2:-movie}"  # movie o tv
    
    if [ -z "$TMDB_API_KEY" ] || [ -z "$tmdb_id" ]; then
        echo ""
        return 1
    fi
    
    local details_url="https://api.themoviedb.org/3/${type}/${tmdb_id}?api_key=${TMDB_API_KEY}&language=it-IT"
    local result=$(curl -s "$details_url" 2>/dev/null)
    
    echo "$result"
}

# Scarica il poster del film/serie
download_poster() {
    local filepath="$1"
    local tmdb_id="$2"
    local type="${3:-movie}"
    
    if [ -z "$TMDB_API_KEY" ] || [ -z "$tmdb_id" ]; then
        echo "[$(date)] TMDb API key non configurata, skip download poster" >> /var/log/mldonkey-telegram.log
        return 1
    fi
    
    echo "[$(date)] Download poster per TMDb ID: $tmdb_id" >> /var/log/mldonkey-telegram.log
    
    # Ottieni i dettagli del film/serie
    local metadata=$(get_tmdb_metadata "$tmdb_id" "$type")
    
    # Estrae il percorso del poster
    local poster_path=$(echo "$metadata" | grep -oP '"poster_path":"[^"]+' | head -1 | cut -d'"' -f4)
    
    if [ -z "$poster_path" ]; then
        echo "[$(date)] Nessun poster trovato" >> /var/log/mldonkey-telegram.log
        return 1
    fi
    
    # URL completo del poster (dimensione originale)
    local poster_url="https://image.tmdb.org/t/p/original${poster_path}"
    
    # Determina il nome del file poster
    local directory=$(dirname "$filepath")
    local filename=$(basename "$filepath")
    local filename_noext="${filename%.*}"
    local poster_file="${directory}/${filename_noext}-poster.jpg"
    
    # Scarica il poster
    curl -s "$poster_url" -o "$poster_file" 2>/dev/null
    
    if [ -f "$poster_file" ] && [ -s "$poster_file" ]; then
        echo "[$(date)] Poster scaricato: $poster_file" >> /var/log/mldonkey-telegram.log
        echo "$poster_file"
        return 0
    else
        echo "[$(date)] Errore nel download del poster" >> /var/log/mldonkey-telegram.log
        rm -f "$poster_file" 2>/dev/null
        return 1
    fi
}

# Salva metadata in formato NFO (compatibile con Kodi/Plex)
save_metadata_nfo() {
    local filepath="$1"
    local metadata="$2"
    local type="${3:-movie}"
    
    if [ -z "$metadata" ]; then
        return 1
    fi
    
    local directory=$(dirname "$filepath")
    local filename=$(basename "$filepath")
    local filename_noext="${filename%.*}"
    local nfo_file="${directory}/${filename_noext}.nfo"
    
    echo "[$(date)] Salvataggio metadata in: $nfo_file" >> /var/log/mldonkey-telegram.log
    
    # Estrae informazioni dal JSON
    local title=$(echo "$metadata" | grep -oP '"title":"[^"]+' | head -1 | cut -d'"' -f4)
    local name=$(echo "$metadata" | grep -oP '"name":"[^"]+' | head -1 | cut -d'"' -f4)
    local original_title=$(echo "$metadata" | grep -oP '"original_title":"[^"]+' | head -1 | cut -d'"' -f4)
    local overview=$(echo "$metadata" | grep -oP '"overview":"[^"]+' | head -1 | cut -d'"' -f4)
    local release_date=$(echo "$metadata" | grep -oP '"release_date":"[^"]+' | head -1 | cut -d'"' -f4)
    local first_air_date=$(echo "$metadata" | grep -oP '"first_air_date":"[^"]+' | head -1 | cut -d'"' -f4)
    local vote_average=$(echo "$metadata" | grep -oP '"vote_average":[0-9.]+' | head -1 | grep -oP '[0-9.]+')
    local runtime=$(echo "$metadata" | grep -oP '"runtime":\d+' | head -1 | grep -oP '\d+')
    local genres=$(echo "$metadata" | grep -oP '"genres":\[[^\]]+\]' | head -1)
    local tmdb_id=$(echo "$metadata" | grep -oP '"id":\d+' | head -1 | grep -oP '\d+')
    
    # Usa title per film, name per serie TV
    if [ "$type" = "tv" ]; then
        title="$name"
    fi
    
    # Usa release_date per film, first_air_date per serie TV
    local date="$release_date"
    if [ "$type" = "tv" ]; then
        date="$first_air_date"
    fi
    local year=$(echo "$date" | cut -d'-' -f1)
    
    # Crea il file NFO in formato XML
    cat > "$nfo_file" << EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<${type}>
    <title>${title}</title>
    <originaltitle>${original_title}</originaltitle>
    <year>${year}</year>
    <plot>${overview}</plot>
    <runtime>${runtime}</runtime>
    <rating>${vote_average}</rating>
    <tmdbid>${tmdb_id}</tmdbid>
    <premiered>${date}</premiered>
EOF

    # Aggiungi generi se disponibili
    if [ -n "$genres" ]; then
        echo "$genres" | grep -oP '"name":"[^"]+' | cut -d'"' -f4 | while read genre; do
            echo "    <genre>${genre}</genre>" >> "$nfo_file"
        done
    fi
    
    echo "</${type}>" >> "$nfo_file"
    
    if [ -f "$nfo_file" ]; then
        echo "[$(date)] Metadata salvati in: $nfo_file" >> /var/log/mldonkey-telegram.log
        return 0
    else
        echo "[$(date)] Errore nel salvataggio metadata" >> /var/log/mldonkey-telegram.log
        return 1
    fi
}

# Determina se è un film o una serie TV
detect_media_type() {
    local filename="$1"
    local filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    
    # Pattern per serie TV
    if echo "$filename_lower" | grep -qE 's[0-9]{1,2}e[0-9]{1,2}|season|episode|[0-9]{1,2}x[0-9]{1,2}'; then
        echo "tv"
    else
        echo "movie"
    fi
}

# Rileva la lingua del video usando il nome del file
detect_video_language() {
    local filename="$1"
    local filename_lower=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
    
    # Cerca indicatori di lingua italiana
    if echo "$filename_lower" | grep -qE '(\.ita\.|\.italian\.|\.italy\.|ita\.sub|sub\.ita)'; then
        echo "italian"
        return 0
    fi
    
    # Se non trova indicatori italiani, assume che sia inglese o lingua straniera
    echo "foreign"
    return 1
}

# Calcola l'hash del file per OpenSubtitles
calculate_opensubtitles_hash() {
    local filepath="$1"
    
    # OpenSubtitles usa un hash specifico
    # Per semplicità, usiamo subliminal se disponibile, altrimenti saltiamo
    if command -v python3 &> /dev/null; then
        python3 -c "
import struct
import sys

def hashFile(name):
    try:
        longlongformat = 'q'
        bytesize = struct.calcsize(longlongformat)
        f = open(name, 'rb')
        filesize = f.seek(0, 2)
        hash = filesize
        if filesize < 65536 * 2:
            return 'SizeError'
        f.seek(0, 0)
        for x in range(int(65536/bytesize)):
            buffer = f.read(bytesize)
            (l_value,)= struct.unpack(longlongformat, buffer)
            hash += l_value
            hash = hash & 0xFFFFFFFFFFFFFFFF
        f.seek(max(0,filesize-65536), 0)
        for x in range(int(65536/bytesize)):
            buffer = f.read(bytesize)
            (l_value,)= struct.unpack(longlongformat, buffer)
            hash += l_value
            hash = hash & 0xFFFFFFFFFFFFFFFF
        f.close()
        returnedhash = '%016x' % hash
        return returnedhash
    except:
        return ''

print(hashFile('$filepath'))
" 2>/dev/null
    else
        echo ""
    fi
}

# Scarica i sottotitoli italiani da OpenSubtitles
download_subtitles() {
    local filepath="$1"
    local filename=$(basename "$filepath")
    local directory=$(dirname "$filepath")
    local title="$2"
    
    echo "[$(date)] Tentativo download sottotitoli per: $filename" >> /var/log/mldonkey-telegram.log
    
    # Controlla se subliminal è installato (metodo consigliato)
    if command -v subliminal &> /dev/null; then
        echo "[$(date)] Uso subliminal per scaricare i sottotitoli" >> /var/log/mldonkey-telegram.log
        subliminal download -l it "$filepath" >> /var/log/mldonkey-telegram.log 2>&1
        
        if [ $? -eq 0 ]; then
            echo "[$(date)] Sottotitoli scaricati con successo" >> /var/log/mldonkey-telegram.log
            return 0
        fi
    fi
    
    # Metodo alternativo: usa opensubtitles-cli se disponibile
    if command -v opensubtitles-cli &> /dev/null; then
        echo "[$(date)] Uso opensubtitles-cli" >> /var/log/mldonkey-telegram.log
        opensubtitles-cli --language it --file "$filepath" >> /var/log/mldonkey-telegram.log 2>&1
        
        if [ $? -eq 0 ]; then
            echo "[$(date)] Sottotitoli scaricati con successo" >> /var/log/mldonkey-telegram.log
            return 0
        fi
    fi
    
    # Metodo base: usa curl e l'API di OpenSubtitles (richiede più configurazione)
    echo "[$(date)] Tentativo download manuale da OpenSubtitles" >> /var/log/mldonkey-telegram.log
    
    # Calcola hash del file
    local file_hash=$(calculate_opensubtitles_hash "$filepath")
    local file_size=$(stat -f%z "$filepath" 2>/dev/null || stat -c%s "$filepath" 2>/dev/null)
    
    if [ -n "$file_hash" ] && [ -n "$file_size" ]; then
        # Cerca sottotitoli usando hash e dimensione file
        local search_result=$(curl -s "https://rest.opensubtitles.org/search/moviehash-${file_hash}/sublanguageid-ita" \
            -H "User-Agent: ${OPENSUBTITLES_USERAGENT}" 2>/dev/null)
        
        # Estrae URL del primo sottotitolo
        local sub_url=$(echo "$search_result" | grep -oP '"SubDownloadLink":"[^"]+' | head -1 | cut -d'"' -f4)
        
        if [ -n "$sub_url" ]; then
            # Scarica il sottotitolo
            local sub_file="${filepath%.*}.srt"
            curl -s "$sub_url" -o "${sub_file}.gz" 2>/dev/null
            
            if [ -f "${sub_file}.gz" ]; then
                gunzip -f "${sub_file}.gz" 2>/dev/null
                
                if [ -f "$sub_file" ]; then
                    echo "[$(date)] Sottotitolo scaricato: $sub_file" >> /var/log/mldonkey-telegram.log
                    return 0
                fi
            fi
        fi
    fi
    
    echo "[$(date)] Impossibile scaricare i sottotitoli" >> /var/log/mldonkey-telegram.log
    return 1
}

# Invia il messaggio a Telegram
send_telegram_message() {
    local message="$1"
    
    # Escape dei caratteri speciali per JSON
    message=$(echo "$message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    # Invia il messaggio usando curl
    curl -s -X POST "$TELEGRAM_API" \
        -H "Content-Type: application/json" \
        -d "{\"chat_id\": \"$TELEGRAM_CHAT_ID\", \"text\": \"$message\", \"parse_mode\": \"HTML\", \"disable_web_page_preview\": false}" \
        > /dev/null 2>&1
    
    return $?
}

# === MAIN ===

# Converti la dimensione in formato leggibile
READABLE_SIZE=$(human_readable_size $FILE_SIZE)

# Ottieni data e ora correnti
TIMESTAMP=$(date '+%d/%m/%Y %H:%M:%S')

# Variabili per informazioni aggiuntive
IMDB_LINK=""
SUBTITLE_STATUS=""
POSTER_STATUS=""
METADATA_STATUS=""
MEDIA_TYPE=""
TMDB_ID=""

# Verifica se è un file video
if is_video_file "$FILE_NAME"; then
    echo "[$(date)] File video rilevato: $FILE_NAME" >> /var/log/mldonkey-telegram.log
    
    # Estrai il titolo pulito
    CLEAN_TITLE=$(extract_clean_title "$FILE_NAME")
    echo "[$(date)] Titolo estratto: $CLEAN_TITLE" >> /var/log/mldonkey-telegram.log
    
    # Determina se è un film o una serie TV
    MEDIA_TYPE=$(detect_media_type "$FILE_NAME")
    echo "[$(date)] Tipo media rilevato: $MEDIA_TYPE" >> /var/log/mldonkey-telegram.log
    
    # Cerca su IMDB
    IMDB_LINK=$(search_imdb "$CLEAN_TITLE")
    if [ -n "$IMDB_LINK" ]; then
        echo "[$(date)] Link IMDB trovato: $IMDB_LINK" >> /var/log/mldonkey-telegram.log
    else
        echo "[$(date)] Nessun risultato IMDB trovato" >> /var/log/mldonkey-telegram.log
    fi
    
    # Cerca su TMDb per poster e metadata
    if [ -n "$TMDB_API_KEY" ]; then
        echo "[$(date)] Ricerca su TMDb..." >> /var/log/mldonkey-telegram.log
        TMDB_ID=$(search_tmdb "$CLEAN_TITLE" "$MEDIA_TYPE")
        
        if [ -n "$TMDB_ID" ]; then
            echo "[$(date)] TMDb ID trovato: $TMDB_ID" >> /var/log/mldonkey-telegram.log
            
            # Scarica poster
            POSTER_FILE=$(download_poster "$FILE_PATH" "$TMDB_ID" "$MEDIA_TYPE")
            if [ -n "$POSTER_FILE" ]; then
                POSTER_STATUS="🖼️ Poster scaricato"
            else
                POSTER_STATUS="⚠️ Poster non disponibile"
            fi
            
            # Scarica e salva metadata
            METADATA_JSON=$(get_tmdb_metadata "$TMDB_ID" "$MEDIA_TYPE")
            if [ -n "$METADATA_JSON" ]; then
                if save_metadata_nfo "$FILE_PATH" "$METADATA_JSON" "$MEDIA_TYPE"; then
                    METADATA_STATUS="📋 Metadata salvati (NFO)"
                else
                    METADATA_STATUS="⚠️ Errore salvataggio metadata"
                fi
            else
                METADATA_STATUS="⚠️ Metadata non disponibili"
            fi
        else
            echo "[$(date)] Nessun risultato TMDb trovato" >> /var/log/mldonkey-telegram.log
            POSTER_STATUS="⚠️ Film/Serie non trovato su TMDb"
            METADATA_STATUS=""
        fi
    else
        echo "[$(date)] TMDb API key non configurata, skip download poster/metadata" >> /var/log/mldonkey-telegram.log
    fi
    
    # Rileva la lingua del video
    VIDEO_LANG=$(detect_video_language "$FILE_NAME")
    echo "[$(date)] Lingua rilevata: $VIDEO_LANG" >> /var/log/mldonkey-telegram.log
    
    # Se il video non è in italiano, scarica i sottotitoli
    if [ "$VIDEO_LANG" != "italian" ]; then
        echo "[$(date)] Video non in italiano, ricerca sottotitoli..." >> /var/log/mldonkey-telegram.log
        
        # Prova a scaricare i sottotitoli
        if download_subtitles "$FILE_PATH" "$CLEAN_TITLE"; then
            SUBTITLE_STATUS="✅ Sottotitoli italiani scaricati"
        else
            SUBTITLE_STATUS="⚠️ Sottotitoli non trovati"
        fi
    else
        SUBTITLE_STATUS="🇮🇹 Video già in italiano"
    fi
fi

# Costruisci il messaggio base
MESSAGE="🎉 <b>Download completato!</b>

📁 <b>File:</b> ${FILE_NAME}
📊 <b>Dimensione:</b> ${READABLE_SIZE}
🔑 <b>Hash:</b> ${FILE_HASH}
📂 <b>Percorso:</b> ${FILE_PATH}
🕐 <b>Data:</b> ${TIMESTAMP}"

# Aggiungi informazioni video se disponibili
if [ -n "$IMDB_LINK" ] || [ -n "$SUBTITLE_STATUS" ] || [ -n "$POSTER_STATUS" ] || [ -n "$METADATA_STATUS" ]; then
    MESSAGE="${MESSAGE}

🎬 <b>Informazioni Video:</b>"
    
    if [ -n "$MEDIA_TYPE" ]; then
        if [ "$MEDIA_TYPE" = "tv" ]; then
            MESSAGE="${MESSAGE}
📺 Tipo: Serie TV"
        else
            MESSAGE="${MESSAGE}
🎥 Tipo: Film"
        fi
    fi
    
    if [ -n "$IMDB_LINK" ]; then
        MESSAGE="${MESSAGE}
🔗 <a href=\"${IMDB_LINK}\">Vedi su IMDB</a>"
    fi
    
    if [ -n "$POSTER_STATUS" ]; then
        MESSAGE="${MESSAGE}
${POSTER_STATUS}"
    fi
    
    if [ -n "$METADATA_STATUS" ]; then
        MESSAGE="${MESSAGE}
${METADATA_STATUS}"
    fi
    
    if [ -n "$SUBTITLE_STATUS" ]; then
        MESSAGE="${MESSAGE}
💬 ${SUBTITLE_STATUS}"
    fi
fi

MESSAGE="${MESSAGE}

✅ Download completato con successo da MLDonkey"

# Invia la notifica
send_telegram_message "$MESSAGE"

# Verifica l'esito
if [ $? -eq 0 ]; then
    echo "[$(date)] Notifica Telegram inviata con successo per: $FILE_NAME" >> /var/log/mldonkey-telegram.log
    exit 0
else
    echo "[$(date)] ERRORE: Impossibile inviare la notifica Telegram per: $FILE_NAME" >> /var/log/mldonkey-telegram.log
    exit 1
fi
