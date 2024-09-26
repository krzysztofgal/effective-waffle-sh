#!/bin/bash

# defaults
IMG_DEST_W_DEFAULT=1024
IMG_QULAITY_DEFAULT=50
BORDER_DEFAULT=0.5%
VARIANTS_DEFAULT=''
TEXT_COLOR_DEFAULT="black"
TEXT_SCALE_DEFAULT=0.09

# crop, resize and add text
gen_image() {
	magick "$file" -strip \
		-bordercolor White \
		-fuzz 1% -trim +repage \
		-border $BORDER \
		-resize $IMG_DEST -quality $IMG_QUALITY \
		-gravity center \
		-extent $IMG_DEST \
		-gravity SouthEast \
		-pointsize $TEXT_SIZE \
		-undercolor "#FFFFFF8F" \
		-fill "$TEXT_COLOR" \
		-annotate +10+10 "$TEXT" \
		"thumbnails/$TEXT.$EXTENSION"

	echo $TEXT
}

# main
gen_thumbnails() {
	for file in "$@"; do
		read IMG_W IMG_H <<<"$(identify -format '%w %h' "$file")"
		# setup image aspect ratio
		if ! [ -z "${RATIO}" ]; then
			IMG_RATIO=$RATIO
		else
			# calulate source image aspect ratio
			IMG_RATIO="$(echo "scale=10; $IMG_W/$IMG_H" | bc)"
		fi
		# calculate destination image height
		IMG_DEST_H="$(echo "scale=0; $IMG_DEST_W/$IMG_RATIO" | bc)"
		IMG_DEST="$(echo "${IMG_DEST_W}x${IMG_DEST_H}")"
		TEXT_SIZE="$(echo "$IMG_DEST_H * $TEXT_SCALE" | bc)"
		FILENAME=${file%%.*}
		EXTENSION="${file#*.}"

		mkdir -p thumbnails

		if [ -z "${VARIANTS}" ]; then
			TEXT=$FILENAME
			gen_image
		else
			for v in ${VARIANTS//,/ }; do
				if ! [ -z "$v" ]; then
					TEXT=$FILENAME"_$v"
				fi
				gen_image
			done
		fi

	done
	echo "Finished"
}

# chek if val is unsigned integer
# https://stackoverflow.com/a/61835747/4751487
is_uint() { case $1 in '' | *[!0-9]*) return 1 ;; esac }
is_num() { case ${1#[-+]} in '' | . | *[!0-9.]* | *.*.*) return 1 ;; esac }

help() {
	# Display Help
	if ! [ -z "${2}" ]; then
		RED="\033[0;31m"
		RESET="\033[0m"
		echo -e "${RED}${2}${RESET}"
	fi
	echo "Generate thumbnails with text annotation"
	echo "Images will be resized, cropped with border and expand to desired dimensions."
	echo
	echo "Syntax: $0 [-h| -w 1920| -q 90| -r 1.5| -b 5%| -v v36,v37| -c red| -c \"#ddd\"] *.jpg"
	echo
	echo "options:"
	echo "   -h     Print this Help."
	echo
	echo "   Text and variants:"
	echo "   -v     CSV variants. (36,41,etc...)"
	echo "   -c     Text color - either name (red) or quoted hex (\"#08C\")"
	echo "   -s     Text scale to height ratio ($TEXT_SCALE_DEFAULT)"
	echo
	echo "   Size and quality options:"
	echo "   -w     Set destination image width ($IMG_DEST_W_DEFAULT)."
	echo "   -q     Set destination image quality ($IMG_QULAITY_DEFAULT)."
	echo "   -b     Set destination image border ($BORDER_DEFAULT)."
	echo "   -r     Set destination image aspect ratio. (default source image ratio)"
	echo "          Common values: 1.5 (3:2), 1.6 (16:10), 1,33333333333 (4:3), 1,77777777778 (16:9)"
	exit $1
}

# Get the options
while getopts ":w:q:b:r:v:c:s:" o; do
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
	v)
		VARIANTS=${OPTARG}
		;;
	c)
		TEXT_COLOR=${OPTARG}
		;;
	s)
		TEXT_SCALE=${OPTARG}
		;;
	\?)
		help 1
		;;
	esac
done
shift $((OPTIND - 1))

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
if [ -z "${VARIANTS}" ]; then
	VARIANTS=$VARIANTS_DEFAULT
fi
if [ -z "${TEXT_COLOR}" ]; then
	TEXT_COLOR=$TEXT_COLOR_DEFAULT
fi
if [ -z "${TEXT_SCALE}" ]; then
	TEXT_SCALE=$TEXT_SCALE_DEFAULT
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

if ! is_num ${TEXT_SCALE}; then
	help 1 "Error option s: must be unsigned integer"
fi

echo "Settings: Width $IMG_DEST_W, Quality: $IMG_QUALITY, Border: $BORDER, Aspect ratio: ${RATIO:-"Source"}"
echo "Text color: $TEXT_COLOR, Text scale: $TEXT_SCALE, Variants: ${VARIANTS:-"None"}"
gen_thumbnails "$@"
