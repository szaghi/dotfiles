#!/bin/bash -
#===============================================================================
#
#          FILE: Ds+.sh
#
#         USAGE: ./Ds+.sh #Re
#
#   DESCRIPTION: Compute first cell spacing accordingly to Reynold Number in
#                order to obtain y+=1 at the first wall cell.
#
#        AUTHOR: Stefano Zaghi
#       CREATED: 07/05/2013 12:35:13 PM CEST
#===============================================================================
set -o nounset
HiRe=1000000
if [ $# -eq 0 ] ; then
  echo "Error: the Reynolds Number must be passed"
  echo "Usage:"
  echo " "`basename $0`" #Reynolds Number [#High Reynolds Number range]"
  echo " Optional arguments:"
  echo " #High Reynolds Number range => limit of switching between low-intermediate Re to high Re; default 10^6"
  echo "Examples:"
  echo " "`basename $0`" 2.E6"
  echo " "`basename $0`" 1.E6 1.d5"
  echo "Note:"
  echo " Exponential notation is admitted only in the form of [dD] or [eE], e.g. 1d6, 1D6, 1e6 or 1E6"
  exit 1
elif [ $# -eq 1 ] ; then
  Re=$1
elif [ $# -eq 2 ] ; then
  Re=$1
  HiRe=$2
  # eliminating exponential notation from HiRe
  HiRe=`echo ${HiRe/e/*10^}` ; HiRe=`echo ${HiRe/E/*10^}` ; HiRe=`echo ${HiRe/d/*10^}` ; HiRe=`echo ${HiRe/D/*10^}`
  HiRe=`echo "scale=10; $HiRe" | bc -l`
fi
# eliminating exponential notation from Re
Re10=`echo ${Re/e/*10^}` ; Re10=`echo ${Re10/E/*10^}` ; Re10=`echo ${Re10/d/*10^}` ; Re10=`echo ${Re10/D/*10^}`
ReD=`echo "scale=10; $Re10" | bc -l`
if [ $ReD -lt $HiRe ] ; then
  DsM=`python -c "x=1./$ReD**(2./5.); print x"` # modeled wall
  DsR=`python -c "x=1./$ReD**(9./5.); print x"` # resolved wall
else
  DsM=`python -c "x=1./$ReD; print x"`           # modeled wall
  DsR=`python -c "x=1./$ReD**(13./7.); print x"` # resolved wall
fi
DsM=`printf "%E" $DsM`
DsR=`printf "%E" $DsR`
HiReE=`printf "%E" $HiRe`
echo "Reynolds Number $Re"
echo "Low-intermediate to high Reynolds Numbers switch $HiReE"
echo "First grid spacing of modeled wall,  Ds+: $DsM"
echo "First grid spacing of resolved wall, Ds+: $DsR"
exit 0
