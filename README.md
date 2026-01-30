# Configurazione MLDonkey Telegram Notifier

## Funzionalità

- ✅ Notifiche Telegram per ogni download completato
- 🎬 Link IMDB automatico per file video
- 💬 Download automatico sottotitoli italiani per video in lingua straniera
- 🖼️ **Download automatico poster del film/serie**
- 📋 **Creazione file metadata in formato NFO (compatibile con Kodi/Plex/Jellyfin)**
- 📺 Rilevamento automatico Film vs Serie TV
- 📊 Conversione dimensioni file in formato leggibile
- 📝 Sistema di logging completo

## Prerequisiti

- MLDonkey installato e funzionante
- Un bot Telegram (crea uno con @BotFather su Telegram)
- curl installato sul sistema: `sudo apt install curl`
- Python3 (opzionale, per hash OpenSubtitles): `sudo apt install python3`
- **Subliminal** (consigliato per sottotitoli): `pip3 install subliminal`
  - Alternativa: `opensubtitles-cli`
- **TMDb API Key** (gratuita, per poster e metadata): https://www.themoviedb.org/settings/api

## Setup

### 1. Crea un Bot Telegram

1. Apri Telegram e cerca `@BotFather`
2. Invia il comando `/newbot`
3. Segui le istruzioni per creare il bot
4. Salva il **token** che ti viene fornito (formato: `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)

### 2. Ottieni il tuo Chat ID

1. Cerca `@userinfobot` su Telegram
2. Avvia la chat e otterrai il tuo **chat_id** (un numero come `123456789`)

### 2.1 Ottieni API Key TMDb (Opzionale ma Consigliato)

Per scaricare poster e metadata:

1. Vai su https://www.themoviedb.org/
2. Crea un account gratuito
3. Vai su Impostazioni → API: https://www.themoviedb.org/settings/api
4. Richiedi una API key (scegli "Developer" se richiesto)
5. Copia la **API Key (v3 auth)**

### 3. Configura lo Script

1. Apri il file `mldonkey-telegram-notify.sh` con un editor di testo
2. Sostituisci `IL_TUO_BOT_TOKEN` con il token del tuo bot
3. Sostituisci `IL_TUO_CHAT_ID` con il tuo chat_id
4. (Opzionale) Aggiungi le credenziali OpenSubtitles per migliorare il download dei sottotitoli
5. (Opzionale) Aggiungi la API Key di TMDb per scaricare poster e metadata

```bash
TELEGRAM_BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
TELEGRAM_CHAT_ID="123456789"
OPENSUBTITLES_USERNAME="tuo_username"  # Opzionale
OPENSUBTITLES_PASSWORD="tua_password"  # Opzionale
TMDB_API_KEY="tua_api_key_tmdb"        # Opzionale ma consigliato
```

**Nota:** Anche senza TMDb API Key, lo script funzionerà normalmente ma non scaricherà poster e metadata.

### 3.1 Installa Subliminal (Consigliato)

Per il download automatico dei sottotitoli, installa Subliminal:

```bash
# Installa pip3 se non presente
sudo apt install python3-pip

# Installa Subliminal
pip3 install subliminal

# Verifica l'installazione
subliminal --version
```

**Nota:** Subliminal è il metodo più affidabile per scaricare i sottotitoli. Senza di esso, lo script tenterà comunque di scaricare i sottotitoli ma con minore successo.

### 4. Rendi lo Script Eseguibile

```bash
chmod +x mldonkey-telegram-notify.sh
```

### 5. Configura MLDonkey

#### Metodo 1: Tramite interfaccia web
1. Accedi all'interfaccia web di MLDonkey (di solito http://localhost:4080)
2. Vai su "Settings" → "Options"
3. Cerca l'opzione `file_completed_cmd`
4. Imposta il valore: `/percorso/completo/mldonkey-telegram-notify.sh "%f" "%s" "%h" "%p"`

#### Metodo 2: Tramite file di configurazione
Aggiungi questa riga al file `downloads.ini` di MLDonkey:

```ini
file_completed_cmd = "/percorso/completo/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
```

#### Metodo 3: Tramite telnet
```bash
telnet localhost 4000
# Inserisci la password se richiesta
set file_completed_cmd "/percorso/completo/mldonkey-telegram-notify.sh \"%f\" \"%s\" \"%h\" \"%p\""
save
```

### 6. Verifica i Permessi

Assicurati che MLDonkey possa eseguire lo script:

```bash
# Posiziona lo script in una directory accessibile
sudo cp mldonkey-telegram-notify.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/mldonkey-telegram-notify.sh

# Crea il file di log
sudo touch /var/log/mldonkey-telegram.log
sudo chown mldonkey:mldonkey /var/log/mldonkey-telegram.log
```

### 7. Test

Per testare lo script manualmente:

```bash
# Test con file video
./mldonkey-telegram-notify.sh "The.Matrix.1999.1080p.BluRay.x264.mkv" "1073741824" "ABC123DEF456" "/home/downloads/The.Matrix.1999.1080p.BluRay.x264.mkv"

# Test con file non video
./mldonkey-telegram-notify.sh "archivio.zip" "524288000" "DEF789GHI" "/home/downloads/archivio.zip"
```

Dovresti ricevere una notifica Telegram. Per i video, lo script:
1. Cercherà il film su IMDB e includerà il link nel messaggio
2. Rileverà se il video è in italiano
3. Se non è in italiano, tenterà di scaricare i sottotitoli italiani

## Come Funziona

### Rilevamento Video

Lo script rileva automaticamente se il file scaricato è un video basandosi sull'estensione:
- Supporta: `.avi`, `.mkv`, `.mp4`, `.mov`, `.wmv`, `.flv`, `.m4v`, `.mpg`, `.mpeg`, `.divx`, `.xvid`, `.webm`, `.ogv`, `.3gp`, `.m2ts`, `.ts`

### Rilevamento Tipo Media

Lo script identifica automaticamente se il video è un Film o una Serie TV:
- **Serie TV**: Se il nome contiene pattern come `S01E01`, `1x01`, `Season`, `Episode`
- **Film**: Tutti gli altri casi

### Ricerca IMDB

Per i video, lo script:
1. Estrae il titolo pulito dal nome del file (rimuove anno, qualità, tag di release)
2. Cerca su IMDB usando il titolo estratto
3. Aggiunge il link al primo risultato trovato nel messaggio Telegram

### Download Poster e Metadata (TMDb)

Se hai configurato la TMDb API Key, lo script:

1. **Cerca il film/serie su TMDb** usando il titolo estratto
2. **Scarica il poster** in alta risoluzione
   - Salvato come: `NomeFile-poster.jpg` nella stessa cartella del video
   - Dimensione: Originale (di solito 2000x3000px)
3. **Crea file NFO con metadata** compatibile con Kodi/Plex/Jellyfin
   - Salvato come: `NomeFile.nfo` nella stessa cartella del video
   - Contiene: titolo, anno, trama, rating, generi, durata, ID TMDb

**Formato NFO creato:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<movie>
    <title>Matrix</title>
    <originaltitle>The Matrix</originaltitle>
    <year>1999</year>
    <plot>Descrizione del film...</plot>
    <runtime>136</runtime>
    <rating>8.7</rating>
    <tmdbid>603</tmdbid>
    <premiered>1999-03-30</premiered>
    <genre>Azione</genre>
    <genre>Fantascienza</genre>
</movie>
```

Questo formato è riconosciuto automaticamente da:
- **Kodi** - Userà il file NFO invece di cercare online
- **Plex** - Può usare il file NFO come fonte di metadata
- **Jellyfin** - Legge direttamente i file NFO
- **Emby** - Supporta i file NFO

### Rilevamento Lingua

Lo script identifica la lingua del video dal nome del file:
- Cerca pattern come `.ita.`, `.italian.`, `ita.sub`, ecc.
- Se non trova indicatori italiani, assume che sia in lingua straniera

### Download Sottotitoli

Se il video è in lingua straniera, lo script tenta di scaricare i sottotitoli italiani:

**Metodo 1 (Consigliato):** Usa Subliminal
- Cerca automaticamente i sottotitoli migliori
- Supporta molteplici provider (OpenSubtitles, Addic7ed, TVsubtitles, ecc.)
- Scarica il file `.srt` nella stessa cartella del video

**Metodo 2:** Usa opensubtitles-cli
- Alternativa se Subliminal non è disponibile

**Metodo 3:** API diretta OpenSubtitles
- Fallback se gli altri metodi non sono disponibili
- Usa l'hash del file per trovare i sottotitoli esatti

I sottotitoli vengono salvati con lo stesso nome del video ma estensione `.srt`

### File Creati per ogni Video

Dopo il download di un video, lo script può creare:
- `Film.mkv` - Il file video originale
- `Film.srt` - Sottotitoli italiani (se il video è in lingua straniera)
- `Film-poster.jpg` - Poster del film in alta risoluzione (se configurato TMDb)
- `Film.nfo` - Metadata in formato XML (se configurato TMDb)

## Esempio di Notifica

Per un video scaricato, riceverai un messaggio simile a:

```
🎉 Download completato!

📁 File: The.Matrix.1999.1080p.BluRay.x264.mkv
📊 Dimensione: 8.50 GB
🔑 Hash: ABC123DEF456
📂 Percorso: /home/downloads/The.Matrix.1999.1080p.BluRay.x264.mkv
🕐 Data: 30/01/2026 15:30:45

🎬 Informazioni Video:
🎥 Tipo: Film
🔗 Vedi su IMDB (cliccabile)
🖼️ Poster scaricato
📋 Metadata salvati (NFO)
💬 ✅ Sottotitoli italiani scaricati

✅ Download completato con successo da MLDonkey
```

### File creati nella cartella download:

```
/home/downloads/
├── The.Matrix.1999.1080p.BluRay.x264.mkv
├── The.Matrix.1999.1080p.BluRay.x264.srt          (sottotitoli)
├── The.Matrix.1999.1080p.BluRay.x264-poster.jpg   (poster)
└── The.Matrix.1999.1080p.BluRay.x264.nfo          (metadata)
```

## Parametri dello Script

Lo script accetta 4 parametri (passati automaticamente da MLDonkey):

- `$1` - Nome del file
- `$2` - Dimensione in bytes
- `$3` - Hash MD4/ED2K
- `$4` - Percorso completo del file

## Log

Lo script mantiene un log in `/var/log/mldonkey-telegram.log` che puoi consultare per verificare l'invio delle notifiche:

```bash
tail -f /var/log/mldonkey-telegram.log
```

## Risoluzione Problemi

### La notifica non arriva

1. Verifica che il bot token e il chat_id siano corretti
2. Controlla che curl sia installato: `which curl`
3. Verifica i permessi di esecuzione dello script
4. Controlla il log: `cat /var/log/mldonkey-telegram.log`
5. Testa manualmente lo script

### Errore permessi negati

```bash
sudo chown mldonkey:mldonkey /usr/local/bin/mldonkey-telegram-notify.sh
sudo chmod +x /usr/local/bin/mldonkey-telegram-notify.sh
```

### Il bot non risponde

1. Verifica che il bot sia stato creato correttamente
2. Assicurati di aver avviato almeno una volta una conversazione con il bot (invia /start)
3. Verifica il token con: `curl https://api.telegram.org/bot<TOKEN>/getMe`

### Il link IMDB non viene trovato

1. Verifica che il nome del file contenga il titolo del film/serie
2. Lo script funziona meglio con nomi file in formato standard (es. `Film.2024.1080p.mkv`)
3. Controlla il log per vedere quale titolo è stato estratto
4. Puoi modificare manualmente la funzione `extract_clean_title` per casi specifici

### I sottotitoli non vengono scaricati

**Verifica installazione Subliminal:**
```bash
subliminal --version
```

Se non è installato:
```bash
pip3 install subliminal
```

**Verifica permessi:**
Lo script deve avere permessi di scrittura nella cartella del video:
```bash
ls -la /percorso/cartella/download
```

**Test manuale download sottotitoli:**
```bash
subliminal download -l it "/percorso/video.mkv"
```

**Problemi comuni:**
1. **Provider OpenSubtitles richiede registrazione**: Crea un account gratuito su opensubtitles.org
2. **Rate limiting**: OpenSubtitles limita le richieste. Attendi qualche minuto e riprova
3. **Sottotitoli non disponibili**: Non tutti i video hanno sottotitoli italiani su OpenSubtitles
4. **Formato file non supportato**: Assicurati che il file sia un video valido

**Alternative se Subliminal non funziona:**

Installa opensubtitles-cli:
```bash
npm install -g opensubtitles-cli
```

O usa manualmente altri servizi come:
- https://www.opensubtitles.org
- https://www.subdivx.com (per sottotitoli italiani)

### Python non è installato

Se ricevi errori relativi a Python:
```bash
sudo apt update
sudo apt install python3 python3-pip
```

### I sottotitoli vengono scaricati ma sono in lingua sbagliata

1. Verifica che stai usando Subliminal con il flag `-l it` (italiano)
2. Controlla il file `.srt` scaricato per verificare la lingua
3. Alcuni video potrebbero non avere sottotitoli italiani disponibili

### Il video viene rilevato come italiano ma non lo è

Lo script cerca pattern nel nome del file. Se il nome contiene `.ita.` ma il video non è italiano:
1. Rinomina il file rimuovendo i tag `.ita.`
2. Lo script scaricherà automaticamente i sottotitoli

### Poster e metadata non vengono scaricati

**Verifica TMDb API Key:**
```bash
# Controlla se è configurata nello script
grep "TMDB_API_KEY" /usr/local/bin/mldonkey-telegram-notify.sh
```

Se non è configurata o è vuota:
1. Vai su https://www.themoviedb.org/settings/api
2. Copia la tua API Key
3. Aggiungila allo script nella variabile `TMDB_API_KEY`

**Verifica connessione a TMDb:**
```bash
# Test manuale API
curl "https://api.themoviedb.org/3/search/movie?api_key=TUA_API_KEY&query=matrix"
```

Se ricevi un errore 401, la tua API key non è valida.

**Problemi comuni:**
1. **API Key non valida**: Rigenera la key dalle impostazioni TMDb
2. **Rate limiting**: TMDb limita le richieste. Attendi qualche minuto
3. **Film/Serie non trovato**: Il titolo estratto potrebbe non corrispondere
4. **Permessi di scrittura**: Verifica che lo script possa scrivere nella cartella del video

**Verifica file creati:**
```bash
# Controlla se poster e NFO sono stati creati
ls -la /percorso/cartella/download/*.jpg
ls -la /percorso/cartella/download/*.nfo
```

### Il file NFO non viene riconosciuto da Kodi/Plex

1. **Verifica il formato del file NFO:**
```bash
cat /percorso/file.nfo
```
Dovrebbe essere XML valido.

2. **Per Kodi**: Assicurati che l'opzione "Preferisci informazioni locali" sia attiva
3. **Per Plex**: Usa l'agent "Personal Media" che supporta i file NFO
4. **Per Jellyfin**: I file NFO sono supportati nativamente, riavvia la scansione della libreria

### Il poster scaricato è di bassa qualità

Lo script scarica poster in dimensione "original" (massima qualità disponibile su TMDb).

Se il poster sembra di bassa qualità:
1. Verifica che il film su TMDb abbia poster in alta risoluzione
2. Alcuni film vecchi potrebbero avere solo poster di bassa qualità
3. Puoi cercare manualmente poster migliori su:
   - https://www.themoviedb.org/
   - https://fanart.tv/
   - https://theposterdb.com/

### TMDb trova il film sbagliato

Lo script usa il titolo estratto dal nome del file. Se trova il film sbagliato:

1. **Migliora il nome del file** prima del download:
   - Usa il formato: `Titolo.Anno.Qualità.mkv`
   - Esempio: `The.Matrix.1999.1080p.mkv`

2. **Modifica la funzione di estrazione del titolo** nello script per casi specifici

3. **Scarica manualmente** poster e metadata corretti dopo il download

### Debug avanzato

Per debug dettagliato, modifica lo script aggiungendo:
```bash
set -x  # All'inizio dello script per vedere tutti i comandi eseguiti
```

Controlla sempre il log per informazioni dettagliate:
```bash
tail -f /var/log/mldonkey-telegram.log
```

## Personalizzazione

### Messaggi Telegram

Puoi personalizzare il messaggio modificando la variabile `MESSAGE` nello script. 
Supporta la formattazione HTML di Telegram:

- `<b>testo</b>` - grassetto
- `<i>testo</i>` - corsivo
- `<code>testo</code>` - monospace
- `<a href="url">testo</a>` - link
- Emoji: usa i caratteri emoji direttamente

### Aggiungere altri formati video

Modifica la variabile `VIDEO_EXTENSIONS` per aggiungere altri formati:
```bash
VIDEO_EXTENSIONS="avi|mkv|mp4|mov|wmv|flv|m4v|mpg|mpeg|divx|xvid|webm|ogv|3gp|m2ts|ts|tuo_formato"
```

### Configurare lingue aggiuntive per i sottotitoli

Per scaricare sottotitoli in più lingue, modifica la funzione `download_subtitles`:
```bash
# Esempio: scarica sia italiano che inglese
subliminal download -l it -l en "$filepath"
```

### Personalizzare dimensione poster

Se vuoi poster di dimensione diversa, modifica la funzione `download_poster`:

```bash
# Opzioni dimensioni TMDb:
# w92, w154, w185, w342, w500, w780, original

# Esempio per poster di media dimensione (500px):
local poster_url="https://image.tmdb.org/t/p/w500${poster_path}"
```

### Aggiungere metadata aggiuntivi al file NFO

Puoi espandere il file NFO con più informazioni. Modifica la funzione `save_metadata_nfo`:

```bash
# Aggiungi attori, regista, studio, ecc.
# Esempio:
echo "    <director>Nome Regista</director>" >> "$nfo_file"
echo "    <actor><name>Nome Attore</name><role>Ruolo</role></actor>" >> "$nfo_file"
echo "    <studio>Warner Bros</studio>" >> "$nfo_file"
```

### Organizzare file in cartelle separate

Puoi modificare lo script per organizzare automaticamente i file:

```bash
# Esempio: sposta film in /Film e serie in /SerieTV
if [ "$MEDIA_TYPE" = "movie" ]; then
    DEST_DIR="/percorso/Film"
else
    DEST_DIR="/percorso/SerieTV"
fi

# Sposta file e metadata
mv "$FILE_PATH" "$DEST_DIR/"
mv "${FILE_PATH%.*}.srt" "$DEST_DIR/" 2>/dev/null
mv "${FILE_PATH%.*}.nfo" "$DEST_DIR/" 2>/dev/null
mv "${FILE_PATH%.*}-poster.jpg" "$DEST_DIR/" 2>/dev/null
```

### Scaricare anche backdrop/fanart

Oltre al poster, puoi scaricare anche le immagini di sfondo:

```bash
# Aggiungi nella funzione download_poster
local backdrop_path=$(echo "$metadata" | grep -oP '"backdrop_path":"[^"]+' | head -1 | cut -d'"' -f4)
if [ -n "$backdrop_path" ]; then
    local backdrop_url="https://image.tmdb.org/t/p/original${backdrop_path}"
    local backdrop_file="${directory}/${filename_noext}-fanart.jpg"
    curl -s "$backdrop_url" -o "$backdrop_file"
fi
```

### Migliorare la ricerca IMDB

Se vuoi risultati più accurati su IMDB, puoi:
1. Registrarti per una API key di OMDb (gratuita): http://www.omdbapi.com/
2. Modificare la funzione `search_imdb` per usare l'API invece dello scraping

Esempio con OMDb API:
```bash
search_imdb() {
    local query="$1"
    local encoded_query=$(echo "$query" | sed 's/ /+/g')
    local omdb_key="TUA_API_KEY"
    
    local result=$(curl -s "http://www.omdbapi.com/?t=${encoded_query}&apikey=${omdb_key}")
    local imdb_id=$(echo "$result" | grep -oP '"imdbID":"(tt\d+)"' | grep -oP 'tt\d+')
    
    if [ -n "$imdb_id" ]; then
        echo "https://www.imdb.com/title/${imdb_id}/"
    fi
}
```

### Disabilitare funzionalità specifiche

Se vuoi disabilitare alcune funzionalità:

**Disabilita ricerca IMDB:**
Commenta questa sezione nello script:
```bash
# IMDB_LINK=$(search_imdb "$CLEAN_TITLE")
```

**Disabilita download sottotitoli:**
Commenta questa sezione:
```bash
# if [ "$VIDEO_LANG" != "italian" ]; then
#     download_subtitles "$FILE_PATH" "$CLEAN_TITLE"
# fi
```

### Aggiungere notifiche per tipi di file specifici

Puoi aggiungere logica personalizzata per altri tipi di file:

```bash
# Esempio: notifica speciale per archivi
if [[ "$FILE_NAME" =~ \.(zip|rar|7z|tar|gz)$ ]]; then
    MESSAGE="${MESSAGE}
📦 <b>Archivio rilevato</b>"
fi
```

## Note Avanzate

### OpenSubtitles API

Se vuoi usare l'API ufficiale di OpenSubtitles (richiede registrazione):
1. Registrati su https://www.opensubtitles.com
2. Ottieni la tua API key
3. Modifica lo script per usare la nuova API REST

### Cache dei risultati IMDB

Per evitare ricerche ripetute, potresti implementare un sistema di cache:
```bash
# Crea una cartella cache
mkdir -p /var/cache/mldonkey-imdb

# Salva i risultati
echo "$IMDB_LINK" > "/var/cache/mldonkey-imdb/$(echo $CLEAN_TITLE | md5sum | cut -d' ' -f1)"
```

### Integrazione con Plex/Jellyfin

Dopo il download, potresti aggiungere comandi per:
1. Spostare i file in cartelle specifiche
2. Notificare Plex/Jellyfin di scansionare la libreria
3. Organizzare i file per stagione/episodio (per serie TV)

## Note

- Lo script converte automaticamente la dimensione del file in formato leggibile (KB, MB, GB)
- Include timestamp di quando il download è stato completato
- Usa la formattazione HTML per rendere il messaggio più leggibile
- Per i video, estrae automaticamente il titolo e cerca su IMDB
- Rileva la lingua del video dal nome del file
- Scarica automaticamente i sottotitoli italiani per video in lingua straniera
- **Scarica automaticamente poster in alta risoluzione da TMDb**
- **Crea file NFO con metadata per Kodi/Plex/Jellyfin**
- **Rileva automaticamente se è un Film o Serie TV**
- I sottotitoli vengono salvati nella stessa cartella del video con estensione `.srt`
- I poster vengono salvati come `NomeFile-poster.jpg`
- I metadata vengono salvati come `NomeFile.nfo` in formato XML
- Supporta molteplici formati video (avi, mkv, mp4, mov, ecc.)
- Il download dei sottotitoli richiede Subliminal (altamente consigliato) o opensubtitles-cli
- Il download di poster e metadata richiede una API Key gratuita di TMDb

## Licenza e Crediti

Script creato per semplificare l'uso di MLDonkey con notifiche Telegram.

**Servizi utilizzati:**
- Telegram Bot API
- IMDB (scraping)
- OpenSubtitles (tramite Subliminal)
- **TMDb (The Movie Database) API**

**Dipendenze consigliate:**
- curl
- python3
- subliminal

**Dipendenze opzionali:**
- TMDb API Key (per poster e metadata)

## Contribuire

Sentiti libero di modificare e migliorare lo script secondo le tue esigenze!

Alcune idee per miglioramenti futuri:
- Supporto per TVDB (per serie TV)
- Riconoscimento automatico di serie TV e organizzazione per stagione/episodio
- Integrazione con Plex/Jellyfin per aggiornamento automatico libreria
- ~~Download di poster e metadata~~ ✅ **Implementato!**
- Supporto per più bot Telegram (notifiche a gruppi diversi)
- Web interface per configurazione
- Statistiche sui download (totale GB scaricati, file più popolari, ecc.)
- Download automatico di trailer
- Riconoscimento facciale per attori nei poster
- Supporto per collezioni di film (trilogie, saghe)
