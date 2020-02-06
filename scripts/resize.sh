#!/bin/bash
minimumWidth=1280
minimumHeight=720

for f in ${1}
do
    imageWidth=$(identify -format "%w" "$f")
    imageHeight=$(identify -format "%h" "$f")

    if [ "$imageWidth" -gt "$minimumWidth" ] || [ "$imageHeight" -gt "$minimumHeight" ]; then
	echo "RESISING $f to 1280x720"
        mogrify -resize ''"$minimumWidth"x"$minimumHeight"'' $f
    fi
done
