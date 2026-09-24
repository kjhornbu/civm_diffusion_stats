#!/usr/bin/env bash
set -e

in=//duhsnas-pri.dhe.duke.edu/dusom_civm-kjh60/All_Staff/21.BatchQA.01/ComplexFigGen_Testing_2025_12_11/Scalar_and_Volume/anovan_1/ScanDate/Non_Erode/Bilateral/complex_figures/Scan_Date/volume_mm3/ontology_segment/pdf/Scan_Date_volume_mm3_pval_ontology_segment_4_wmt.pdf
if [ ! -d $WORKSTATION_USER_CACHE/test ];then
mkdir $WORKSTATION_USER_CACHE/test
fi;
if [ ! -f $WORKSTATION_USER_CACHE/test/in.pdf ];then
cp -pv $in $WORKSTATION_USER_CACHE/test/in.pdf;
fi;

ink_bin=$(dirname $(which inkscape));
cd "$ink_bin";
cd ../;

echo bin/inkscape --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
echo bin/inkscape --export-filename=$(cygpath -w $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -w $WORKSTATION_USER_CACHE/test/in.pdf)
#inkscape  --export-type=svg  --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) --file=$(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
# $(which inkscape) --without-gui --export-plain-svg=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) --file=$(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(which inkscape)  --export-type=svg  --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(which inkscape)--export-filename="$(cygpath -w $WORKSTATION_USER_CACHE/test/out.svg)" "$(cygpath -w $WORKSTATION_USER_CACHE/test/in.pdf)"
#$(which inkscape)  --export-type=svg  --export-extension=svg --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(which inkscape)  --export-type=svg  --export-extension=svg --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(which inkscape)  --export-page=1 --export-type=svg  --export-extension=svg --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(which inkscape) --export-type=svg  --export-extension=svg --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
# $(which inkscape)  --export-page=1  --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#$(cygpath -m $(which inkscape))  --pages=1  --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out.svg) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)

# echo $(cygpath -m $(which inkscape))  --pages=1  --export-type=svg,png --export-filename=$(cygpath -m $WORKSTATION_USER_CACHE/test/out) $(cygpath -m $WORKSTATION_USER_CACHE/test/in.pdf)
#echo $(cygpath -w $(which inkscape))  --pages=1  --export-type=svg,png --export-filename=$(cygpath -w $WORKSTATION_USER_CACHE/test/out) $(cygpath -w $WORKSTATION_USER_CACHE/test/in.pdf)

echo "inkscape stopped";echo "";echo "";
ls -ld $WORKSTATION_USER_CACHE/test/in.pdf $WORKSTATION_USER_CACHE/test/out.svg

