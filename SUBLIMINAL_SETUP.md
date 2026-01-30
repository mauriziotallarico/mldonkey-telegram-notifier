# Guida Installazione e Configurazione Subliminal

## Cos'è Subliminal?

Subliminal è uno strumento Python per la ricerca e il download automatico di sottotitoli per video. Supporta molteplici provider tra cui OpenSubtitles, Addic7ed, TVsubtitles e altri.

## Installazione

### Ubuntu/Debian

```bash
# Aggiorna i repository
sudo apt update

# Installa Python3 e pip
sudo apt install python3 python3-pip

# Installa Subliminal
pip3 install subliminal

# Verifica l'installazione
subliminal --version
```

### CentOS/RHEL/Fedora

```bash
# Installa Python3 e pip
sudo yum install python3 python3-pip

# Installa Subliminal
pip3 install subliminal

# Verifica l'installazione
subliminal --version
```

### macOS

```bash
# Usando Homebrew
brew install python3

# Installa Subliminal
pip3 install subliminal

# Verifica l'installazione
subliminal --version
```

## Configurazione OpenSubtitles

Per risultati migliori, registrati su OpenSubtitles e configura le credenziali:

### 1. Registrazione

1. Vai su https://www.opensubtitles.com/
2. Crea un account gratuito
3. Verifica la tua email

### 2. Configurazione credenziali

Crea un file di configurazione per Subliminal:

```bash
# Crea la cartella di configurazione
mkdir -p ~/.config/subliminal

# Crea il file di configurazione
nano ~/.config/subliminal/config
```

Aggiungi le seguenti righe:

```ini
[opensubtitles]
username = tuo_username
password = tua_password
```

Salva e chiudi (CTRL+O, CTRL+X).

### 3. Imposta i permessi

```bash
chmod 600 ~/.config/subliminal/config
```

## Uso Base di Subliminal

### Download sottotitoli per un singolo file

```bash
# Download sottotitolo italiano
subliminal download -l it /percorso/video.mkv

# Download sottotitoli in più lingue
subliminal download -l it -l en /percorso/video.mkv

# Download con provider specifico
subliminal download -l it --provider opensubtitles /percorso/video.mkv
```

### Download sottotitoli per una cartella

```bash
# Scarica sottotitoli per tutti i video in una cartella
subliminal download -l it /percorso/cartella/

# Con ricerca ricorsiva nelle sottocartelle
subliminal download -l it -r /percorso/cartella/
```

### Opzioni avanzate

```bash
# Scarica solo se non esistono già sottotitoli
subliminal download -l it --single /percorso/video.mkv

# Forza il download anche se esistono sottotitoli
subliminal download -l it --force /percorso/video.mkv

# Limita la ricerca a determinati provider
subliminal download -l it --provider opensubtitles --provider addic7ed /percorso/video.mkv

# Imposta un punteggio minimo per i sottotitoli
subliminal download -l it --min-score 80 /percorso/video.mkv

# Encoding specifico per i sottotitoli
subliminal download -l it --encoding utf-8 /percorso/video.mkv
```

## Provider Supportati

Subliminal supporta i seguenti provider:

- **OpenSubtitles** - Il più grande database di sottotitoli (richiede registrazione)
- **Addic7ed** - Ottimo per serie TV (richiede registrazione)
- **Podnapisi** - Database sloveno ma con molti sottotitoli internazionali
- **TheSubDB** - Database basato su hash dei file
- **TVsubtitles** - Specializzato in serie TV

### Configurare provider aggiuntivi

Per Addic7ed (consigliato per serie TV):

```bash
nano ~/.config/subliminal/config
```

Aggiungi:

```ini
[addic7ed]
username = tuo_username
password = tua_password
```

## Integrazione con lo Script MLDonkey

Lo script `mldonkey-telegram-notify.sh` usa automaticamente Subliminal se è installato. Non serve configurazione aggiuntiva se hai seguito i passaggi sopra.

### Verifica funzionamento

Testa manualmente:

```bash
# Scarica i sottotitoli per un video di test
subliminal download -l it /percorso/test-video.mkv

# Controlla se il file .srt è stato creato
ls -la /percorso/test-video.srt
```

## Cache di Subliminal

Subliminal mantiene una cache per migliorare le prestazioni:

### Posizione cache

```bash
~/.cache/subliminal/
```

### Pulire la cache

```bash
rm -rf ~/.cache/subliminal/
```

### Disabilitare la cache

```bash
subliminal --no-cache download -l it /percorso/video.mkv
```

## Risoluzione Problemi

### Subliminal non viene trovato

```bash
# Verifica dove è installato
which subliminal

# Se non è nel PATH, aggiungi al PATH
export PATH=$PATH:~/.local/bin
echo 'export PATH=$PATH:~/.local/bin' >> ~/.bashrc
```

### Errori di connessione a OpenSubtitles

```bash
# OpenSubtitles ha un rate limit, attendi qualche minuto
# Oppure registrati per limiti più alti
```

### Errore "No subtitles found"

1. Verifica che il video sia popolare (film/serie conosciuti)
2. Prova con provider diversi
3. Abbassa il `--min-score`
4. Controlla se il nome del file è corretto

### Permessi negati

```bash
# Assicurati che l'utente abbia permessi di scrittura
chmod 755 /percorso/cartella/
```

### Encoding errato dei sottotitoli

```bash
# Specifica l'encoding
subliminal download -l it --encoding utf-8 /percorso/video.mkv

# Oppure converti dopo il download
iconv -f ISO-8859-1 -t UTF-8 sottotitoli.srt -o sottotitoli-utf8.srt
```

## Performance e Ottimizzazione

### Velocizzare le ricerche

```bash
# Usa solo OpenSubtitles (più veloce)
subliminal download -l it --provider opensubtitles /percorso/video.mkv

# Disabilita la verifica della hash
subliminal download -l it --no-hash /percorso/video.mkv
```

### Download massivo

```bash
# Script per scaricare sottotitoli per molti file
find /percorso/cartella -type f \( -name "*.mkv" -o -name "*.mp4" -o -name "*.avi" \) -exec subliminal download -l it {} \;
```

## Alternative a Subliminal

Se Subliminal non funziona bene per te, considera:

### 1. opensubtitles-cli

```bash
npm install -g opensubtitles-cli
opensubtitles-cli --language it --file video.mkv
```

### 2. subdownloader

```bash
pip3 install subdownloader
subdownloader -l it /percorso/video.mkv
```

### 3. Manual download

- https://www.opensubtitles.org
- https://www.subdivx.com (italiano)
- https://www.subito.to

## Risorse Utili

- **Documentazione ufficiale**: https://subliminal.readthedocs.io/
- **GitHub**: https://github.com/Diaoul/subliminal
- **OpenSubtitles API**: https://www.opensubtitles.com/docs

## Consigli

1. **Registrati sempre su OpenSubtitles**: Avrai limiti più alti e risultati migliori
2. **Usa nomi file standard**: Subliminal funziona meglio con nomi come `Film.2024.1080p.mkv`
3. **Mantieni aggiornato Subliminal**: `pip3 install --upgrade subliminal`
4. **Configura il timeout**: Se hai connessione lenta, aumenta il timeout in `~/.config/subliminal/config`
5. **Usa la cache**: La cache velocizza notevolmente le ricerche ripetute

## Automazione

### Cron job per scaricare sottotitoli periodicamente

```bash
# Apri crontab
crontab -e

# Aggiungi questa riga per eseguire ogni ora
0 * * * * subliminal download -l it -r /percorso/cartella/downloads/
```

### Script bash per download automatico

```bash
#!/bin/bash
WATCH_DIR="/percorso/downloads"

while true; do
    find "$WATCH_DIR" -type f \( -name "*.mkv" -o -name "*.mp4" \) ! -name "*.srt" -exec subliminal download -l it --single {} \;
    sleep 300  # Controlla ogni 5 minuti
done
```

Salva come `auto-subtitle.sh`, rendi eseguibile e avvia in background.
