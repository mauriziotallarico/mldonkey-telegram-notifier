# Guida TMDb - Download Poster e Metadata

## Cos'è TMDb?

The Movie Database (TMDb) è un database comunitario di film e serie TV che offre:
- Poster in alta risoluzione
- Metadata completi (titolo, anno, trama, cast, crew, generi, ecc.)
- Backdrop/Fanart
- API gratuita per sviluppatori

## Perché usare TMDb?

1. **Organizzazione automatica**: I file NFO permettono a Kodi/Plex/Jellyfin di riconoscere i tuoi video senza ricerca online
2. **Poster di qualità**: Scarica automaticamente poster in risoluzione originale
3. **Metadata completi**: Trama, cast, generi, rating, durata, ecc.
4. **Gratuito**: API key gratuita con limiti generosi (40 richieste per 10 secondi)

## Ottenere API Key

### 1. Registrazione

1. Vai su https://www.themoviedb.org/
2. Clicca su "Join TMDb" in alto a destra
3. Compila il modulo di registrazione
4. Verifica la tua email

### 2. Richiedere API Key

1. Accedi al tuo account
2. Vai su **Impostazioni** (Settings)
3. Clicca su **API** nel menu laterale
4. Clicca su **Richiedi una chiave API** (Request an API Key)

### 3. Compilare il form

Ti verrà chiesto lo scopo dell'uso:
- **Tipo**: Seleziona "Developer"
- **Nome applicazione**: "MLDonkey Notifier" (o un nome a tua scelta)
- **Descrizione**: "Script per scaricare automaticamente poster e metadata"
- **URL**: Puoi lasciare vuoto o mettere un placeholder

### 4. Ottenere la chiave

Dopo aver inviato la richiesta, riceverai immediatamente:
- **API Key (v3 auth)**: Questa è quella che ti serve
- **API Read Access Token (v4 auth)**: Non necessario per questo script

**Copia la API Key (v3 auth)** - è una stringa tipo: `1234567890abcdef1234567890abcdef`

## Configurare lo Script

Apri `mldonkey-telegram-notify.sh` e incolla la tua API key:

```bash
TMDB_API_KEY="1234567890abcdef1234567890abcdef"
```

Salva e chiudi. Lo script ora scaricherà automaticamente poster e metadata!

## Test della Configurazione

### Test manuale API

```bash
# Sostituisci TUA_API_KEY con la tua chiave
curl "https://api.themoviedb.org/3/search/movie?api_key=TUA_API_KEY&query=matrix&language=it-IT"
```

Se funziona, vedrai un JSON con i risultati di ricerca per "Matrix".

### Test con lo script

```bash
# Crea un file video di test
touch "/tmp/The.Matrix.1999.1080p.mkv"

# Esegui lo script
./mldonkey-telegram-notify.sh "The.Matrix.1999.1080p.mkv" "1073741824" "ABC123" "/tmp/The.Matrix.1999.1080p.mkv"

# Verifica che siano stati creati poster e NFO
ls -la /tmp/The.Matrix.1999.1080p*
```

Dovresti vedere:
- `The.Matrix.1999.1080p-poster.jpg`
- `The.Matrix.1999.1080p.nfo`

## Come Funziona

### 1. Ricerca del Film/Serie

Lo script:
1. Estrae il titolo dal nome del file
2. Determina se è un film o serie TV
3. Cerca su TMDb usando l'API di ricerca
4. Prende il primo risultato (di solito il più rilevante)

### 2. Download Poster

1. Ottiene i dettagli completi del film/serie
2. Estrae il path del poster
3. Scarica l'immagine in risoluzione "original"
4. Salva come `NomeFile-poster.jpg`

**Dimensioni disponibili su TMDb:**
- `w92` - 92px larghezza (molto piccolo)
- `w154` - 154px
- `w185` - 185px
- `w342` - 342px
- `w500` - 500px
- `w780` - 780px
- `original` - Dimensione originale (di solito 2000x3000px) ← **Usato dallo script**

### 3. Creazione File NFO

Il file NFO contiene:
- **Titolo** originale e tradotto
- **Anno** di uscita
- **Trama** in italiano
- **Durata** in minuti
- **Rating** (voto medio)
- **Generi** (azione, commedia, ecc.)
- **ID TMDb** per riferimento

**Esempio NFO generato:**

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<movie>
    <title>Matrix</title>
    <originaltitle>The Matrix</originaltitle>
    <year>1999</year>
    <plot>Thomas Anderson è un programmatore che vive una doppia vita...</plot>
    <runtime>136</runtime>
    <rating>8.7</rating>
    <tmdbid>603</tmdbid>
    <premiered>1999-03-30</premiered>
    <genre>Azione</genre>
    <genre>Fantascienza</genre>
</movie>
```

## Uso con Media Center

### Kodi

1. **Installazione**: Nessuna configurazione necessaria
2. **Rilevamento**: Kodi rileverà automaticamente i file NFO
3. **Impostazioni**: Vai su Impostazioni → Media → Video e attiva "Preferisci informazioni locali"
4. **Aggiornamento**: Scansiona la libreria e Kodi userà i file NFO invece di cercare online

**Vantaggi:**
- Caricamento istantaneo (no ricerca online)
- Informazioni sempre corrette
- Funziona offline

### Plex

1. **Agent**: Usa "Personal Media" o "Local Media Assets"
2. **Configurazione**: 
   - Impostazioni → Server → Librerie
   - Modifica libreria → Avanzate
   - Attiva "Usa risorse multimediali locali"
3. **Aggiornamento**: Scansiona la libreria

**Nota:** Plex preferisce la sua ricerca online, ma userà i NFO se configurato.

### Jellyfin

1. **Supporto nativo**: Jellyfin legge automaticamente i file NFO
2. **Configurazione**: Nessuna necessaria
3. **Priorità**: I file NFO hanno priorità rispetto alla ricerca online
4. **Aggiornamento**: Scansiona la libreria

**Vantaggi:**
- Supporto completo e nativo
- Priorità ai file NFO
- Perfetta integrazione

### Emby

1. **Supporto**: Simile a Jellyfin
2. **Configurazione**: Automatica
3. **Aggiornamento**: Scansiona la libreria

## Limiti e Restrizioni

### Rate Limiting

TMDb limita le richieste:
- **40 richieste** ogni **10 secondi**
- **Consiglio**: Per download massivi, aggiungi un delay tra le richieste

```bash
# Esempio: aggiungi 1 secondo di pausa
sleep 1
```

### Lingua

Lo script usa `language=it-IT` per ottenere:
- Titoli tradotti in italiano
- Trame in italiano
- Generi in italiano

Per cambiare lingua, modifica nello script:
```bash
&language=it-IT  →  &language=en-US  (per inglese)
```

### Disponibilità Contenuti

Non tutti i film/serie hanno:
- Poster in alta risoluzione
- Traduzioni italiane complete
- Metadata completi

Film molto vecchi o oscuri potrebbero avere informazioni limitate.

## Personalizzazioni Avanzate

### Scaricare più immagini

Oltre al poster, puoi scaricare:

**Backdrop (Fanart):**
```bash
local backdrop_path=$(echo "$metadata" | grep -oP '"backdrop_path":"[^"]+' | cut -d'"' -f4)
local backdrop_url="https://image.tmdb.org/t/p/original${backdrop_path}"
curl -s "$backdrop_url" -o "${filename_noext}-fanart.jpg"
```

**Logo:**
```bash
# Richiede richiesta aggiuntiva per /images
curl "https://api.themoviedb.org/3/movie/${tmdb_id}/images?api_key=${TMDB_API_KEY}"
```

### Aggiungere cast e crew al NFO

```bash
# Scarica i credits
local credits=$(curl -s "https://api.themoviedb.org/3/movie/${tmdb_id}/credits?api_key=${TMDB_API_KEY}")

# Estrai attori
echo "$credits" | jq -r '.cast[:5][] | "<actor><name>\(.name)</name><role>\(.character)</role></actor>"' >> "$nfo_file"

# Estrai regista
echo "$credits" | jq -r '.crew[] | select(.job=="Director") | "<director>\(.name)</director>"' >> "$nfo_file"
```

**Nota:** Richiede `jq` installato: `sudo apt install jq`

### Creare collezioni

Per film che fanno parte di una saga (es. Harry Potter):

```bash
# Ottieni dettagli collezione
local belongs_to=$(echo "$metadata" | grep -oP '"belongs_to_collection":\{[^}]+\}')
local collection_id=$(echo "$belongs_to" | grep -oP '"id":\d+' | grep -oP '\d+')

if [ -n "$collection_id" ]; then
    echo "    <set>${collection_name}</set>" >> "$nfo_file"
fi
```

### Scaricare trailer

```bash
# Ottieni trailer
local videos=$(curl -s "https://api.themoviedb.org/3/movie/${tmdb_id}/videos?api_key=${TMDB_API_KEY}&language=it-IT")
local trailer_key=$(echo "$videos" | grep -oP '"key":"[^"]+' | head -1 | cut -d'"' -f4)

if [ -n "$trailer_key" ]; then
    # URL YouTube del trailer
    echo "https://www.youtube.com/watch?v=${trailer_key}"
fi
```

## Struttura Directory Consigliata

Per massima compatibilità con Kodi/Plex/Jellyfin:

```
/Film/
├── Matrix (1999)/
│   ├── Matrix (1999).mkv
│   ├── Matrix (1999).nfo
│   ├── Matrix (1999)-poster.jpg
│   ├── Matrix (1999)-fanart.jpg
│   └── Matrix (1999).srt
├── Matrix Reloaded (2003)/
│   ├── Matrix Reloaded (2003).mkv
│   ├── Matrix Reloaded (2003).nfo
│   └── ...
```

Per serie TV:
```
/SerieTV/
├── Breaking Bad/
│   ├── Season 01/
│   │   ├── Breaking Bad - S01E01.mkv
│   │   ├── Breaking Bad - S01E01.nfo
│   │   └── Breaking Bad - S01E01.srt
│   ├── Season 02/
│   │   └── ...
│   ├── tvshow.nfo
│   └── poster.jpg
```

## Backup dei Metadata

È consigliabile fare backup dei file NFO e poster:

```bash
# Script di backup
#!/bin/bash
BACKUP_DIR="/backup/metadata"
MEDIA_DIR="/percorso/downloads"

find "$MEDIA_DIR" -name "*.nfo" -o -name "*-poster.jpg" | \
    tar czf "$BACKUP_DIR/metadata-$(date +%Y%m%d).tar.gz" -T -
```

## Risoluzione Problemi

### API Key non valida

Errore: `{"status_code":7,"status_message":"Invalid API key"}`

**Soluzione:**
1. Verifica di aver copiato correttamente la API Key
2. Assicurati di usare la v3 (non la v4)
3. Rigenera la key dalle impostazioni TMDb

### Nessun risultato trovato

Lo script non trova il film/serie:

**Cause:**
1. Titolo troppo generico o poco chiaro
2. Film molto recente (appena uscito al cinema)
3. Film molto oscuro o locale

**Soluzioni:**
1. Usa nomi file più standard: `Film.Anno.mkv`
2. Cerca manualmente su TMDb e verifica il titolo esatto
3. Modifica manualmente il file NFO se necessario

### Poster di bassa qualità

**Cause:**
1. Il film ha solo poster di bassa risoluzione su TMDb
2. Film molto vecchio

**Soluzioni:**
1. Cerca poster migliori su https://theposterdb.com/
2. Carica tu stesso poster migliori su TMDb (contribuisci!)
3. Usa servizi alternativi come FanArt.tv

### Rate limit superato

Errore: `{"status_code":25,"status_message":"Your request count (41) is over the allowed limit of 40."}`

**Soluzione:**
Aggiungi un delay tra le richieste:
```bash
sleep 0.5  # Pausa di 0.5 secondi
```

## Risorse Utili

- **Documentazione API**: https://developers.themoviedb.org/3
- **TMDb Website**: https://www.themoviedb.org/
- **Forum TMDb**: https://www.themoviedb.org/talk
- **Status API**: https://status.themoviedb.org/
- **Kodi NFO Guide**: https://kodi.wiki/view/NFO_files
- **Plex Naming**: https://support.plex.tv/articles/naming-and-organizing-your-movie-media-files/

## FAQ

**Q: La API key scade?**
A: No, le API key di TMDb non scadono se usi regolarmente il servizio.

**Q: Posso usare TMDb per scopi commerciali?**
A: Dipende. Leggi i termini di servizio: https://www.themoviedb.org/terms-of-use

**Q: Quante richieste posso fare?**
A: 40 ogni 10 secondi, ma puoi richiedere limiti più alti per uso intensivo.

**Q: I dati sono sempre aggiornati?**
A: TMDb è mantenuto dalla comunità. La maggior parte dei contenuti popolari è molto aggiornata.

**Q: Posso contribuire a TMDb?**
A: Sì! TMDb è comunitario. Puoi aggiungere poster, traduzioni, informazioni mancanti.

**Q: Cosa succede se cambio API key?**
A: Basta aggiornare lo script con la nuova chiave. I file già scaricati non vengono modificati.

**Q: Posso usare più API key?**
A: Sì, se hai più account TMDb. Utile per evitare rate limiting.
