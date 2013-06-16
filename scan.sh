#!/bin/bash

mkdir -p /tmp/scanner

SOUND=/usr/share/sounds/gnome/default/alerts/drip.ogg 
SCAN_OPTIONS="--resolution 400"
JOB="scan_`date +%s`"
CONTENT="Skannattu liite"
scanimage --verbose --device-name $2 \
          --mode Lineart --high-quality -x 210 -y 297 --format=tiff $SCAN_OPTIONS >"/tmp/scanner/${JOB}.tif"
tesseract "/tmp/scanner/${JOB}.tif" "/tmp/scanner/${JOB}"
BARCODE=`zbarimg --quiet "/tmp/scanner/${JOB}.tif"`
TYPE=`echo $BARCODE | cut -f1 -d':'`
CODE=`echo $BARCODE | cut -f2 -d':'`
TILI=""
EUROA=""
SENTTIA=""
VARALLA=""
VIITE=""
ERAPV=""
YRITYS=""
CONTENT=""
TXT=""
HEADER=""
if [ "$TYPE" = "CODE-128" ]; then
  if [ "`echo $CODE | awk '{print substr($0,1,1)}'`" = "4" ]; then
    # Lasku/IBAN
    HEADER="Lasku"
    TILI=`echo $CODE | awk '{print substr($0,2,16)}'`
    EUROA=`echo $CODE | awk '{print substr($0,18,6)}' | sed "s/^0*//g"`
    SENTTIA=`echo $CODE | awk '{print substr($0,24,2)}'`
    VARALLA=`echo $CODE | awk '{print substr($0,26,3)}'`
    VIITE=`echo $CODE | awk '{print substr($0,29,20)}' | sed "s/^0*//g"`
    ERAPV=`echo $CODE | awk '{print substr($0,49,6)}'`
  fi
fi
if [ "$TILI" != "" ]; then
  CONTENT="$CONTENT\\nTili: FI$TILI"
  YRITYS=$(cat `locate account.txt` | grep "^FI${TILI};")
  if [ "$YRITYS" != "" ]; then
    YRITYS=`echo $YRITYS | cut -f2 -d';'`
    CONTENT="$CONTENT\\nLaskuttaja: $YRITYS"
  fi
fi
if [ "$EUROA" != "" ]; then
  CONTENT="$CONTENT\\nEuroa: $EUROA,$SENTTIA"
fi
if [ "$VIITE" != "" ]; then
  CONTENT="$CONTENT\\nViite: $VIITE"
fi
if [ "$ERAPV" != "" ]; then
  CONTENT="$CONTENT\\nErapaiva: \
          `echo $ERAPV | \
          awk '{print substr($0,5,2) "." substr($0,3,2) ".20" substr($0,1,2)}'`"
fi
if [ "$BARCODE" != "" ]; then
  CONTENT="$CONTENT\\nViivakoodi: $BARCODE"
fi
CONTENT="$CONTENT\\n"

#CONTENT=$(echo $CONTENT | iconv --to "ISO-8859-1")
#cat "/tmp/${JOB}.pnm" | pnmtops -width=8.27 -height=11.69 | \
#                        ps2pdf - "/tmp/${JOB}.pdf"
echo $CONTENT > "/tmp/scanner/${JOB}.content"

#if [ -f $SOUND ]; then
#  su - vesa -l -c "paplay $SOUND"
#fi
if [ $1 -ne 4 ]; then
  if [ $1 -ne 2 ]; then
    exit 0
  fi
fi

if [ $1 -eq 2 ]; then
  name="Etunimi1 Sukunimi1 <nimi1@gmail.com>"
fi
if [ $1 -eq 4 ]; then
  name="Etunimi2 Sukunimi2 <nimi2@gmail.com>"
fi

DOC=`date +%s`
HEADER="Dokumentti"
CONTENT=`cat /tmp/scanner/*.content`
TXT=`cat /tmp/scanner/*.txt | iconv -c --to ISO-8859-15`

echo -e $CONTENT|grep -q "^Tili:"
if [ $? = 0 ]; then
  HEADER="Lasku `echo -e $CONTENT | grep "^Laskuttaja:" | cut -f2 -d':' | cut -f1 -d'\'`"
fi  

tiffcp /tmp/scanner/scan_*.tif /tmp/scanner/scan_all.tif

tiff2pdf -j -o "/tmp/scanner/scan_tmp.pdf" "/tmp/scanner/scan_all.tif"
pdfopt "/tmp/scanner/scan_tmp.pdf" "/tmp/scanner/${DOC}.pdf"
sendemail -f "Scanner <nimi1@gmail.com>" \
          -t "$name" \
          -m "$CONTENT $TXT" \
          -u "$HEADER $YRITYS" \
          -a "/tmp/scanner/${DOC}.pdf" \
          -o message-charset=ISO-8859-15 \
          -s smtp.dnainternet.net
rm -rf "/tmp/scanner"

