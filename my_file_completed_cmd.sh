#!/bin/bash
# file_completed_cmd interface
HASH="$1"
SIZE="$2"
FILENAME_ONLY="$3"
FILENAME="/media/MAXTOR/mldonkey/incoming/files/" #TODO: refer only to default mldonkey download folder, remove any reference to my RPI
FILENAME+="$3" #IMPORTANT: it's the name of the downloaded file but without full path. That's why i'm adding the path here



# Remove xtension from file, in case SUB has to be downloaded.
FILENAME_NO_EXT=`echo "${FILENAME%.*}"`
# First variable is the name that will be used to store the SUB.
# Second variable is the final name we want to give to the SUB file in order to be automatically loaded by STB.
FILENAME_SUB_ITA="${FILENAME_NO_EXT}_it.srt"
FILENAME_SUB_ITA_CORRECT="${FILENAME_NO_EXT}.srt"


# First trial, call googliser
# /home/pi/googliser/googliser.sh -n 1 -p "$FILENAME_NO_EXT" -g -q
python /home/pi/OpenSubtitlesDownload/OpenSubtitlesDownload.py -l ita "$FILENAME" #TODO bundle python script and load it from current folder, remove any reference to my RPI




if [ -f "$FILENAME_SUB_ITA" ]
then
        mv "$FILENAME_SUB_ITA" "$FILENAME_SUB_ITA_CORRECT"
        #echo "$FILENAME_SUB_ITA"
fi

echo "$FILENAME_ONLY" | /home/pi/telegram-pipe.sh #TODO bundle telegram script and load it from current folder, remove any reference to my RPI

if [ -f "$FILENAME_SUB_ITA_CORRECT" ]
then
        echo "Subtitle found!" | /home/pi/telegram-pipe.sh
else
        echo "Subtitle not found or not needed" | /home/pi/telegram-pipe.sh
fi


