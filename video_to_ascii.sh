#!/bin/bash
# Author           : Michał Irek (michalirek0505@gmail.com)
# Created On       : 16.04.2025
# Last Modified By : Michał Irek (michalirek0505@gmail.com)
# Last Modified On : 2.05.2025
# Version          : 1.0
#
# Description      :
#  Skrypt video_to_ascii.sh przetwarza podany plik wideo, generując z niego animację
#   ASCII wyświetlaną w terminalu. Umożliwia dostosowanie rozdzielczości wyjściowej,
#   liczby klatek na sekundę oraz progu jasności, który wpływa na szczegółowość
#   generowanego obrazu ASCII. Ustawienia można również zapisać do pliku konfiguracyjnego.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)


# Domyślne ustawienia
FPS=2
THRESHOLD=10
WIDTH=160
HEIGHT=40
CONFIG_FILE="ascii_config.txt"
INPUT=""

# Funkcja do wczytywania konfiguracji
load_config() {
  if [ -f "$CONFIG_FILE" ]; then
    echo "📄 Wczytuję ustawienia z pliku konfiguracyjnego: $CONFIG_FILE"
    source "$CONFIG_FILE"
  else
    echo "❗ Nie znaleziono pliku konfiguracyjnego. Używam domyślnych ustawień."
  fi
}

# Funkcja do zapisywania konfiguracji
save_config() {
  echo "🎯 Zapisuję ustawienia do pliku konfiguracyjnego: $CONFIG_FILE"
  echo "INPUT=\"$INPUT\"" > "$CONFIG_FILE"
  echo "FPS=\"$FPS\"" >> "$CONFIG_FILE"
  echo "WIDTH=\"$WIDTH\"" >> "$CONFIG_FILE"
  echo "HEIGHT=\"$HEIGHT\"" >> "$CONFIG_FILE"
  echo "THRESHOLD=\"$THRESHOLD\"" >> "$CONFIG_FILE"
}

load_config

while getopts "i:r:w:h:t:c" opt; do
  case $opt in
    i) INPUT="$OPTARG" ;;
    r) FPS="$OPTARG" ;;
    w) WIDTH="$OPTARG" ;;
    h) HEIGHT="$OPTARG" ;;
    t) THRESHOLD="$OPTARG" ;;
    c) save_config ;;
    \?) echo "Nieprawidłowa opcja: -$OPTARG" >&2; exit 1 ;;
    :) echo "Opcja -$OPTARG wymaga wartości." >&2; exit 1 ;;
  esac
done


if [ -z "$INPUT" ]; then
  echo "❌ Musisz podać nazwę pliku wideo za pomocą -i <plik>"
  exit 1
fi

# Przygotowanie katalogów
rm -rf frames ascii_frames
mkdir -p "frames"
mkdir -p "ascii_frames"

echo "🎞️  Generuję klatki z pliku: $INPUT ..."
ffmpeg -loglevel error -i "$INPUT" -vf "scale=$WIDTH:$HEIGHT" -r "$FPS" "frames/frame%04d.png"

FILES=(frames/frame*.png)
TOTAL=${#FILES[@]}
COUNT=0


for IMAGE in "${FILES[@]}"; do
  FILENAME=$(basename "$IMAGE" .png)
  OUTPUT="ascii_frames/$FILENAME.txt"
  
  bash "./ascii_converter.sh" "$IMAGE" "$WIDTH" "$HEIGHT" "$THRESHOLD" "$OUTPUT"
  rm "$IMAGE"
  # ---- Progress bar ----
  ((COUNT++))
  PROGRESS=$(( COUNT * 100 / TOTAL ))
  BAR_WIDTH=50
  FILLED=$(( PROGRESS * BAR_WIDTH / 100 ))
  EMPTY=$(( BAR_WIDTH - FILLED ))

  printf "\r[%s%s] %d%% (%d/%d)" \
    "$(printf '#%.0s' $(seq 1 $FILLED))" \
    "$(printf ' %.0s' $(seq 1 $EMPTY))" \
    "$PROGRESS" "$COUNT" "$TOTAL"
done

echo "" 

echo "🎬 Wyświetlam animację ASCII..."
for FILE in ascii_frames/frame*.txt; do
  clear
  cat "$FILE"
  sleep 0.1 
done

echo "✅ Zakończono."