# mldonkey-telegram-notifier
Una serie di script per usare la feature di [mldonkey]( http://mldonkey.sourceforge.net/Main_Page) chiamata "file_completed_cmd" ed inviare una notifica tramite un BOT telegram all'avvenuto completamento del download di un file.

Per il BOT [Telegram](https://telegram.org/) mi sono basato sulla seguente guida:
https://community.onion.io/topic/499/sending-telegram-messages-via-bots

Tale guida elenca anche uno [script](https://github.com/mauriziotallarico/mldonkey-telegram-notifier/blob/master/telegram-pipe.sh) per fare pipe di un qualsiasi testo verso un BOT
[Telegram](https://telegram.org/).

Per usare correttamente lo script bisogna settare la locazione dello script stesso in 
"[downloads.ini](http://mldonkey.sourceforge.net/Downloads.ini)" (file di configurazione di mldonkey)

<b>file_completed_cmd = "$path_to/my_file_completed_cmd.sh"</b>

Ho aggiunto anche la possibilità di scaricare automaticamente i sottotitoli (ITA) da OpenSubTitles in caso il file scaricato sia un 
telefilm in lingua originale.
Mi sono servito di questo script Python [OpenSubtitlesDownload](https://github.com/emericg/OpenSubtitlesDownload).


A series of scripts to use the [mldonkey] feature (http://mldonkey.sourceforge.net/Main_Page) called "file_completed_cmd" and send a notification via a BOT telegram when a file has been downloaded.

For the BOT [Telegram] (https://telegram.org/) I have based on the following guide:
https://community.onion.io/topic/499/sending-telegram-messages-via-bots

This guide also lists a [script] (https://github.com/mauriziotallarico/mldonkey-telegram-notifier/blob/master/telegram-pipe.sh) to pipe any text to a BOT
[Telegram] (https://telegram.org/).

To use the script correctly, set the location of the script in
"[downloads.ini] (http://mldonkey.sourceforge.net/Downloads.ini)" (mldonkey configuration file)

<b> file_completed_cmd = "$ path_to / my_file_completed_cmd.sh" </ b>

I have also added the ability to automatically download subtitles (ITA) from OpenSubTitles in case the downloaded file is a
telefilm in the original language.
I used this Python script [OpenSubtitlesDownload] (https://github.com/emericg/OpenSubtitlesDownload).
