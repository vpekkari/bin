#!/bin/bash

pwd > /tmp/param.txt
echo $@ >>/tmp/param.txt

if [ "$1" == "" ]; then
  exit 1
fi

repl=0
output=$(echo "$1" | sed "s/.qif$/_conv.qif/g")
rm -f "$output"

cat "$1" | tr -d '\r' | while read line; do
  firstchar=$(echo $line | grep -o "^.")

  echo $line | grep -q "\[.*.]\/"
  if [ $? -eq 0 ]; then
     repl=1
     account=`echo "$line" | cut -d'/' -f2`
     line=`echo $line | cut -d"/" -f1`
     line=`echo $line | sed "s/\[.*.]/\[$account/"`\]
  fi
  buffer=$(echo -e "$buffer\n$line")

  if [ "$firstchar" == "^" ]; then
    # Flush
    if [ $repl -eq 1 ]; then
      buffer=$(echo "$buffer" | sed "s/^\([TU]\)\([^-]\)/#\1-\2/g" | sed "s/^\([TU]\)-/#\1/g" | sed "s/^#//g" )
    fi
    echo "$buffer" >>"$output"
    unset buffer
    repl=0
  fi
done

echo "$buffer" >>"$output"

