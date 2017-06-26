# mldonkey-telegram-notifier
Una serie di script per usare la feature di [mldonkey]( http://mldonkey.sourceforge.net/Main_Page) chiamata "file_completed_cmd" ed inviare una notifica tramite un BOT telegram all'avvenuto completamento del download di un file.

Per il BOT [Telegram](https://telegram.org/) mi sono basato sulla seguente guida:
https://community.onion.io/topic/499/sending-telegram-messages-via-bots

Tale guida elenca anche uno [script](https://github.com/mauriziotallarico/mldonkey-telegram-notifier/blob/master/telegram-pipe.sh) per fare pipe di un qualsiasi testo verso un BOT
[Telegram](https://telegram.org/).

Per usare correttamente lo script bisogna settare la locazione dello script stesso in 
"[downloads.ini](http://mldonkey.sourceforge.net/Downloads.ini)" (file di configurazione di mldonkey)

<b>file_completed_cmd = "$path_to/my_file_completed_cmd.sh"</b>
