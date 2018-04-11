#!/bin/bash

config_file=${1:? "Usage: $0 config-file text-file"}
text_file=${2:? "Usage: $0 config-file text-file"}

pre_text_file=$text_file.0

shave=10

source "$config_file"

error=${rapportage:? "Set rapportage"}

site=http://www.huibertvanrossum.nl/$rapportage/

rm -f index.html

echo "Download page from $site to extract links to pictures"

wget -q $site

first_picture=$(cat index.html | grep -o 'wp-content/uploads[^">) ]*' | tr -d "'" | grep '_[0-9]*.jpg' | grep -i $term | head -n1)

first_picture=$(echo "http://www.huibertvanrossum.nl/$first_picture")

if [ -n "${first_picture}" ]; then
  echo "Found pictures"
else 
  echo "No pictures found. Is the term in $2 correct?"
  exit
fi

wget -q $first_picture

echo $first_picture
fp_name=$(echo $first_picture | rev | cut -f1 -d'/' | rev )

img_dir=img/headers

shiftcmd=""
shavecmd="-shave ${shave}x${shave}"
if [ -n "${shift}" ]; then
  shiftcmd="-gravity south -chop 0x${shift}%"
fi

mkdir -p ../$img_dir
rm -f ../$img_dir/$fp_name
convert $fp_name $shavecmd $shiftcmd ../$img_dir/$fp_name 

header_img="$fp_name"

rm -f $fp_name

cat index.html | grep -o 'wp-content/uploads[^">) ]*' | tr -d "'" | grep '_[0-9]*.jpg' | grep -i $term | sed 's/wp-content\/uploads\///g' | uniq >  $rapportage.pics

feature_img=$(head -n1 $rapportage.pics)

ofile="$date-$rapportage.md"

rm -f $ofile
touch $ofile

echo "Write shoot to file $ofile"

echo '---' >> $ofile
echo 'layout: "post"' >> $ofile
echo "title: \"$title\"" >> $ofile
echo "subtitle: \"$subtitle\"" >> $ofile
echo 'active: "shoots"' >> $ofile
echo 'image:' >> $ofile
echo "  feature: \"$feature_img\"" >> $ofile
echo "date: \"$date\"" >> $ofile
echo "header-img: \"$header_img\"" >> $ofile
echo "local-header-img-url: \"$img_dir\"" >> $ofile
echo 'comments: "true"' >> $ofile
echo "tags: $tags" >> $ofile
echo 'gallery1:' >> $ofile

lcnt=0
# Skip first two pictures, add three pics to gallery1 and add the remaining ones to gallery2.
{ 
  while IFS=, read -r line 
  do
    echo "  - image_path: \"$line\"" >> $ofile
    echo "    image-caption: $title" >> $ofile
    echo "    image-copyright: © Huibert van Rossum" >> $ofile
    if [ -e $text_file ]; then
      lcnt=$((lcnt + 1))
      if [ "$lcnt" -eq 3 ]; then
        echo 'gallery2:' >> $ofile
      fi
    fi
  done 
} < "$rapportage.pics"

echo '---' >> $ofile

echo >> $ofile

echo "# $title" >> $ofile
  
echo >> $ofile

if [ -e $pre_text_file ]; then
  cat $pre_text_file >> $ofile
  echo >> $ofile
fi

echo '{% include subgallery.html id="gallery1" %}' >> $ofile

echo >> $ofile

if [ -e $text_file ]; then
  cat $text_file >> $ofile
  echo >> $ofile

  echo '{% include subgallery.html id="gallery2" %}' >> $ofile
fi

rm $rapportage.pics
rm -f index.html
