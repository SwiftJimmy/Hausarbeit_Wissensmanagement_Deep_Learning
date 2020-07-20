#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import cv2
videoPath = r'video.mp4'
saveDir = r'/Path/to/dir/'
vidcap = cv2.VideoCapture(videoPath)
success,image = vidcap.read()
count = 0
while success:
  info = "videoframe%d.jpg" % count
  cv2.imwrite(saveDir + info, image)     # save frame as JPEG file      
  success,image = vidcap.read()
  count += 1