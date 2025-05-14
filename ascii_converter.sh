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

if [ "$#" -ne 5 ]; then
  echo "Użycie: $0 <ścieżka_do_obrazu> <szerokość> <wysokość> <próg> <ścieżka_wyjściowa>"
  exit 1
fi

IMAGE_PATH="$1"
WIDTH="$2"
HEIGHT="$3"
THRESHOLD="$4"
OUTPUT_PATH="$5"
CHARS=" .'\`^\",:;Il!i~+_-?][}{1)(|\\\/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$"

mapfile -t brightness_list < <(
  convert "$IMAGE_PATH" -resize "${WIDTH}x${HEIGHT}" -colorspace Gray txt:- |
  grep -o '#[0-9A-Fa-f]\{6\}' | while read -r color; do
    r=$((0x${color:1:2}))
    g=$((0x${color:3:2}))
    b=$((0x${color:5:2}))
    echo $(( (r * 299 + g * 587 + b * 114) / 1000 ))
  done
)

min=255
max=0
for val in "${brightness_list[@]}"; do
  (( val < min )) && min=$val
  (( val > max )) && max=$val
done
(( max == min )) && max=$((min + 1))

> "$OUTPUT_PATH"

i=0
for brightness in "${brightness_list[@]}"; do
  normalized=$(( (brightness - min) * 255 / (max - min) ))

  if (( normalized < THRESHOLD )); then
    printf " " >> "$OUTPUT_PATH"
  else
    index=$(( normalized * (${#CHARS} - 1) / 255 ))
    printf "%s" "${CHARS:$index:1}" >> "$OUTPUT_PATH"
  fi

  ((++i % WIDTH == 0)) && echo "" >> "$OUTPUT_PATH"
done