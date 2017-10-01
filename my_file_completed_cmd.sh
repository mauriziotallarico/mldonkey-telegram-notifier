#!/bin/bash
# file_completed_cmd interface
HASH="$1"
SIZE="$2"
FILENAME="$3" #IMPORTANT: it's the name of the downloaded file.

# Remove xtension from file, in case SUB has to be downloaded.
FILENAME_NO_EXT=`echo "${FILENAME%.*}"`
# First variable is the name that will be used to store the SUB.
# Second variable is the final name we want to give to the SUB file in order to be automatically loaded by STB.
FILENAME_SUB_ITA="${FILENAME_NO_EXT}_it.srt"
FILENAME_SUB_ITA_CORRECT="${FILENAME_NO_EXT}.srt"


# First trial, call googliser
/home/pi/googliser/googliser.sh -n 1 -p "$FILENAME_NO_EXT" -g -q
python /home/pi/OpenSubtitlesDownload/OpenSubtitlesDownload.py -l ita "$FILENAME"




if [ -f "$FILENAME_SUB_ITA" ]
then
        mv "$FILENAME_SUB_ITA" "$FILENAME_SUB_ITA_CORRECT"
        #echo "$FILENAME_SUB_ITA"
fi

echo "$FILENAME" | /home/pi/telegram-pipe.sh

if [ -f "$FILENAME_SUB_ITA_CORRECT" ]
then
        echo "Subtitle found!" | /home/pi/telegram-pipe.sh
else
        echo "Subtitle not found or not needed" | /home/pi/telegram-pipe.sh
fi


