#!/bin/bash

config_file=${1:? "Usage: $0 config-file text-file"}
text_file=${2:? "Usage: $0 config-file text-file"}

source "$config_file"

error=${rapportage:? "Set rapportage"}

site=http://www.huibertvanrossum.nl/$rapportage/

rm -f index.html

echo "Download page from $site to extract links to pictures"

wget -q $site

cat index.html | grep -o 'wp-content/uploads[^">) ]*' | tr -d "'" | grep '_[0-9]*.jpg' | grep -i $term | sed 's/wp-content\/uploads\///g' >  $rapportage.pics

feature_img=$(head -n1 $rapportage.pics)

ofile="$date-$rapportage.md"

rm -f $ofile
touch $ofile

echo "Write blog post $ofile"

echo '---' >> $ofile
echo 'layout: "post"' >> $ofile
echo "title: \"$title\"" >> $ofile
echo 'subtitle: ""' >> $ofile
echo 'active: "blog"' >> $ofile
echo 'image:' >> $ofile
echo "  feature: \"$feature_img\"" >> $ofile
echo "date: \"$date\"" >> $ofile
echo "header-img: \"$feature_img\"" >> $ofile
echo 'comments: "true"' >> $ofile
echo 'tags: [bruiloft]' >> $ofile
echo 'gallery1:' >> $ofile

lcnt=0
# Skip first picture and the remaining ones to gallery1
{ 
  read -r line
  read -r line
  read -r line
  while IFS=, read -r line 
  do
    echo "  - image_path: $line" >> $ofile
    echo "    image-caption: $title" >> $ofile
    echo "    image-copyright: © Huibert van Rossum" >> $ofile
    lcnt=$((lcnt + 1))
    if [ "$lcnt" -eq 3 ]; then
      echo 'gallery2:' >> $ofile
    fi
  done 
} < "$rapportage.pics"

echo '---' >> $ofile

echo >> $ofile

echo "# $title" >> $ofile

echo >> $ofile

echo '{% include subgallery.html id="gallery1" %}' >> $ofile

echo >> $ofile

cat $text_file >> $ofile

echo '{% include subgallery.html id="gallery2" %}' >> $ofile

rm $rapportage.pics
rm -f index.html
