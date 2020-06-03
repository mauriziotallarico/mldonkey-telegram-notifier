#!/bin/bash
# file_completed_cmd interface
HASH="$1"
SIZE="$2"
FILENAME_ONLY="MLDonkey has downloaded the file: "
FILENAME_ONLY+="$3"

FILENAME="/media/MAXTOR/mldonkey/incoming/files/"
FILENAME+="$3" #IMPORTANT: it's the name of the downloaded file.

#20200223 - Gather some othe infos from ENV variables
#Since MLDonkey 2.7.1 the arguments are set as environmental variables as well as the old arguments for backward compatibility reasons. Here are the environmental variables thar MLDonkey will set for the command:

#    TEMPNAME: Temp file name, including path.
#    FILEID: The MD4 hash of the file (same as $1).
#    FILESIZE: The size of the file in bytes (same as $2).
#    FILENAME: The file name for the download (same as $3).
#    FILEHASH: Internal hash.
#    DURATION: Download duration in seconds.
#    INCOMING: Directory used for commit.
#    NETWORK: Network name used for downloading.
#    ED2K_HASH: ed2k hash if MD4 is known.
#    DLFILES: Number of downloading files. (since 2.7.5)
#    FILE_OWNER: The user who owns the downloaded file.
#    FILE_GROUP: The group which owns the downloaded file.
#    USER_MAIL: E-mail of the user who owns the downloaded file. 

MY_NETWORK_ENV="This file was downloaded using Network: "
MY_NETWORK_ENV+=$NETWORK 
MY_DATE=$(date +"%x %r")


# Remove xtension from file, in case SUB has to be downloaded.
FILENAME_NO_EXT=`echo "${FILENAME%.*}"`
# First variable is the name that will be used to store the SUB.
# Second variable is the final name we want to give to the SUB file in order to be automatically loaded by STB.
FILENAME_SUB_ITA="${FILENAME_NO_EXT}_it.srt"
FILENAME_SUB_ITA_CORRECT="${FILENAME_NO_EXT}.srt"


# First trial, call googliser
# /home/pi/googliser/googliser.sh -n 1 -p "$FILENAME_NO_EXT" -g -q
python3 /home/pi/OpenSubtitlesDownload/OpenSubtitlesDownload.py -l ita "$FILENAME"




if [ -f "$FILENAME_SUB_ITA" ]
then
        mv "$FILENAME_SUB_ITA" "$FILENAME_SUB_ITA_CORRECT"
        #echo "$FILENAME_SUB_ITA"
fi

echo "$MY_DATE" | /home/pi/telegram-pipe.sh
echo "$FILENAME_ONLY" | /home/pi/telegram-pipe.sh
echo "$MY_NETWORK_ENV" | /home/pi/telegram-pipe.sh


if [ -f "$FILENAME_SUB_ITA_CORRECT" ]
then
        echo "Subtitle found!" | /home/pi/telegram-pipe.sh
else
        echo "Subtitle not found or not needed" | /home/pi/telegram-pipe.sh
fi


