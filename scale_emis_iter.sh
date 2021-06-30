#!/bin/bash

# A script to scale emissions based on delta_E inference
baseemisdir=${1}
emisorig=${2}
emisnew=${3}
analysisfile=${4}

#cd ${baseemisdir} #base emis dir
#cd ${emisorig}
infs1=$(ls ${baseemisdir}/${emisorig}/repemis_mole_all.2017.Jul.???.nc) # only anthropogenic
echo $infs1
mkdir -p ${baseemisdir}/${emisnew}
# don't let scalefactor<0, very small instead
cat > scalefactor.nco << EOF
scalefactor=EMISDELR+1;
where(scalefactor<0) scalefactor=1e-4;
EOF
ncap2 -O -v -S scalefactor.nco ${analysisfile} scalefactor.nc #create scalefactor var and extract only that var

for emisfile in $infs1
do
echo '-----'
echo $emisfile
outf=`basename ${emisfile}`
echo $outf
echo '-----'
echo ''

ncks -O -v NO,NO2,HONO ${emisfile} ${emisfile}.tmp #extract NOx for multiplication
ncks -A -v scalefactor scalefactor.nc ${emisfile}.tmp #should append vars from scalefactor.nc into new emis.tmp file

# Dont create emissions where they dont exist
cat > scalenox.nco << EOF
where(NO>0) NO=NO*scalefactor;
where(NO2>0) NO2=NO2*scalefactor;
where(HONO>0) HONO=HONO*scalefactor;
EOF
ncap2 -S scalenox.nco ${emisfile}.tmp #scale NOx vars in tmp file
cp ${emisfile} ${baseemisdir}/${emisnew}/${outf} 
ncks -A -h -v NO,NO2,HONO ${emisfile}.tmp ${baseemisdir}/${emisnew}/${outf} # overwrite scaled NOx vars to emis file
rm ${emisfile}.tmp

done
