#!/bin/bash

folder="$1"

if ! [ -d ${folder}/test ]
then
    echo "test folder not found"
    exit 1
fi

if ! [ -d ${folder}/train ]
then
    echo "train folder not found"
    exit 1
fi

function check_xml()
{
    name="${1}"
    if ! [ -f ${name%.*}.xml ]
    then
	echo "WARNING: file ${name} does not have corresponding XML file"
    fi
}

test="${folder}/test"
train="${folder}/train"

nb_test=$(ls -1 ${test}/*.xml | wc -l)
nb_train=$(ls -1 ${train}/*.xml | wc -l)

printf "NB TEST: %d (%d)  TRAIN: %d (%d) TOTAL: %d\n" $nb_test $(echo "100*$nb_test/($nb_test+$nb_train)" | bc) $nb_train  $(echo "100*$nb_train/($nb_test+$nb_train)" | bc) $(($nb_test+$nb_train))

for file in ${test}/*.jp*g ; do
    #echo $file  ${file%.*}.xml
    check_xml "${file}"
done

#if [ -f ${test}/*.png ] ; then
    for file in ${test}/*.png ; do
	#echo $file  ${file%.*}.xml
	check_xml "${file}"
    done
#fi


for file in ${train}/*.jp*g ; do
    #echo $file  ${file%.*}.xml
    check_xml "${file}"
done

#if [ -f ${train}/*.png ] ; then
    for file in ${train}/*.png ; do
	#echo $file  ${file%.*}.xml
	check_xml "${file}"
    done
#fi
