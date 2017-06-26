#!/bin/bash
# file_completed_cmd interface
HASH="$1"
SIZE="$2"
FILENAME="$3"
#INCOMING="incoming"

echo "$FILENAME" | /home/pi/telegram-pipe.sh

