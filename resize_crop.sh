#!/bin/bash
 
# defaults
IMG_DEST_W_DEFAULT=2700
IMG_QULAITY_DEFAULT=80
BORDER_DEFAULT=0.5%
 
# main
resize_crop () {
    echo "Settings: Width $IMG_DEST_W, Quality: $IMG_QUALITY, Border: $BORDER, Aspect ratio: ${RATIO:-"Source"}"
    for file in "$@"; do
        read IMG_W IMG_H <<< "$(identify -format '%w %h' "$file")";
        # setup image aspect ratio
        if ! [ -z "${RATIO}" ]; then
            IMG_RATIO=$RATIO
        else
            # calulate source image aspect ratio
            IMG_RATIO="$(echo "scale=10; $IMG_W/$IMG_H" | bc)";
        fi
        # calculate destination image height
        IMG_DEST_H="$(echo "scale=0; $IMG_DEST_W/$IMG_RATIO" | bc)";
        IMG_DEST="$(echo "${IMG_DEST_W}x${IMG_DEST_H}")";
        # crop and resize
        convert "$file" -strip \
        -bordercolor White \
        -fuzz 1% -trim +repage \
        -border $BORDER \
        -resize $IMG_DEST -quality $IMG_QUALITY \
        -gravity center \
        -extent $IMG_DEST "$file";
    done
    echo "Finished";
}
 
# chek if val is unsigned integer
# https://stackoverflow.com/a/61835747/4751487
is_uint() { case $1 in ''|*[!0-9]*) return 1;;esac;}
is_num() { case ${1#[-+]} in ''|.|*[!0-9.]*|*.*.*) return 1;; esac ;}
 
help ()
{
   # Display Help
   if ! [ -z "${2}" ]; then
    RED="\033[0;31m"
    RESET="\033[0m"
    echo -e "${RED}${2}${RESET}"
   fi
   echo "Images: Resize, crop with border and expand to desired dimensions."
   echo
   echo "Syntax: $0 [-h| -w 1920| -q 90| -r 1.5| -b 5%] *.jpg"
   echo "options:"$
   echo "   -h     Print this Help."
   echo "   -w     Set destination image width ($IMG_DEST_W_DEFAULT)."
   echo "   -q     Set destination image quality ($IMG_QULAITY_DEFAULT)."
   echo "   -b     Set destination image border ($BORDER_DEFAULT)."
   echo "   -r     Set destination image aspect ratio. (default source image ratio)"
   echo "          Common values: 1.5 (3:2), 1.6 (16:10), 1,33333333333 (4:3), 1,77777777778 (16:9)"
   exit $1;
}
 
# Get the options
while getopts ":w:q:b:r:" o; do
    case "${o}" in
        w)
            IMG_DEST_W=${OPTARG}
            ;;
        q)
            IMG_QUALITY=${OPTARG}
            ;;
        b)
            BORDER=${OPTARG}
            ;;
        r)
            RATIO=${OPTARG}
            ;;
        \?)
            help 1
            ;;
    esac
done
shift $((OPTIND-1))
 
# test if param is empty
if [ -z "${1}" ]; then
   help 1 "Error: No files selected"
fi
 
# set options to default if not set
if [ -z "${IMG_DEST_W}" ]; then
   IMG_DEST_W=$IMG_DEST_W_DEFAULT
fi
if [ -z "${IMG_QUALITY}" ]; then
   IMG_QUALITY=$IMG_QULAITY_DEFAULT
fi
if [ -z "${BORDER}" ]; then
   BORDER=$BORDER_DEFAULT
fi
 
# test if options are correct
if ! is_uint ${IMG_DEST_W}; then
   help 1 "Error option w: must be unsigned integer"
fi
 
if ! is_uint ${IMG_QUALITY}; then
   help 1 "Error option q: must be unsigned integer"
fi
 
if ! [ -z "${RATIO}" ]; then
    if ! is_num ${RATIO}; then
        help 1 "Error option r: must be number"
    fi
fi
 
resize_crop "$@"; 
