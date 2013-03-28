#!/bin/bash
mencoder -quiet -mc 100 -vf harddup -tv driver=v4l2:norm=PAL_BGHIN:input=0:forceaudio:audiorate=48000:amode=1:width=768:height=576:buffersize=512:device=/dev/video1:alsa:adevice=hw.0,0 tv:// -ovc copy -oac copy -o video.avi

