#!/bin/bash

# Move ~20% of images in test/ to others go in train/

for img in "${1}"/*
do
    if [[ $img =~ \.xml$ ]]
    then
	# Skip XML files
	continue
    fi

    if [[ $(( ( RANDOM % 100 )  + 1 )) > 81 ]]
    then
	#echo "git mv ${img%.*}.* test/"
	git mv  ${img%.*}.* test/
    else
	#echo "git mv ${img%.*}.* train/"
	git mv ${img%.*}.* train/
    fi
done
