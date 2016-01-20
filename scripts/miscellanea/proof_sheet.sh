#!/bin/bash

function print_usage {
  echo
  echo "`basename $0`"
  echo "Make proof sheet of images into the current directory"
  echo "Usage: `basename $0` [args]"
  echo "Valid command line optional arguments are:"
  echo "  [ -Nx #images_number_along_x -Ny #images_number_along_y -cs #caption_point_size -o 'output file name']"
  echo
  echo "Defaults of optional arguments:"
  echo "  -Nx 8"
  echo "  -Ny 4"
  echo "  -cs 28"
  echo "  -o 'proof_sheet.jpg'"
  echo
  echo "Examples:"
  echo "  `basename $0` -Nx 16 -Ny 4 -o example.jpg (make a 16x4 proof sheet(s) named example(-#).jpg)"
  echo "  `basename $0` -h (print this help message)"
  echo
}

# defaults
Nx=8
Ny=4
cs=28
of='proof_sheet.jpg'

#parsing command line
while [ $# -gt 0 ]; do
  case "$1" in
    "-Nx")
      shift; Nx=$1 # number of image in x direction
      ;;
    "-Ny")
      shift; Ny=$1 # number of image in y direction
      ;;
    "-cs")
      shift; cs=$3 # pointsize of captions
      ;;
    "-o")
      shift; of=$4 # output file name
      ;;
    "-h")
      print_usage; exit 0
      ;;
    *)
      echo; echo "Unknown switch $1"; print_usage; exit 1
      ;;
  esac
  shift
done

# sorting image between protrait and landscape formats
mkdir -p landscape portrait
Nl=0 # number of landscape images
Np=0 # number of portrait images
for file in $( ls *.jpg ); do
  wd=`exiftool -s -ImageSize $file | awk '{print $3}' | awk -F x '{print $1}'`
  ht=`exiftool -s -ImageSize $file | awk '{print $3}' | awk -F x '{print $2}'`
  if [ $wd -gt $ht ] ; then
    let Nl=Nl+1
    cd landscape/
    ln -s ../$file .
    cd ..
  else
    let Np=Np+1
    cd portrait/
    ln -s ../$file .
    cd ..
  fi
done

# creating proof sheets of landscape images
if [ $Nl -gt 0 ]; then
  cd landscape
  # dimensions of first image
  f1=`ls | awk '{print $1}' | head -n 1`
  wd=`exiftool -s -ImageSize $f1 | awk '{print $3}' | awk -F x '{print $1}'`
  ht=`exiftool -s -ImageSize $f1 | awk '{print $3}' | awk -F x '{print $2}'`
  # scaled dimensions
  wd_s=`echo "scale=10; $wd/$Nx" | bc -l`
  ht_s=`echo "scale=10; $ht/$Nx" | bc -l`
  montage -label '%f' -pointsize $cs -tile $Nx'x'$Ny *.jpg  -geometry $wd_s'x'$ht_s+4+4 landscape-$of
  mv landscape-* ../
  cd ..
  rm -rf landscape
fi
# creating proof sheets of portrait images
if [ $Np -gt 0 ]; then
  cd portrait
  # dimensions of first image
  f1=`ls | awk '{print $1}' | head -n 1`
  wd=`exiftool -s -ImageSize $f1 | awk '{print $3}' | awk -F x '{print $1}'`
  ht=`exiftool -s -ImageSize $f1 | awk '{print $3}' | awk -F x '{print $2}'`
  # scaled dimensions
  wd_s=`echo "scale=10; $wd/$Nx" | bc -l`
  ht_s=`echo "scale=10; $ht/$Nx" | bc -l`
  montage -label '%f' -pointsize $cs -tile $Nx'x'$Ny *.jpg  -geometry $wd_s'x'$ht_s+4+4 portrait-$of
  mv portrait-* ../
  cd ..
  rm -rf portrait
fi
