#!/bin/bash

# Move ~20% of images in test/

for img in tosort/*
do
    if [[ $(( ( RANDOM % 100 )  + 1 )) > 80 ]]
    then
	git mv ${img} test/
    else
	git mv ${img} train/
    fi
done
