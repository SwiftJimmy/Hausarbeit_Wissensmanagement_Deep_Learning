#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jun 26 11:14:02 2020

@author: swift
"""





from shutil import copyfile
import random
import os
import glob
import pandas as pd
import xml.etree.ElementTree as ET





def getFileNames(path):
    file_list = []
    for jpg_file in glob.glob(path + '*.jpg'):
        file_list.append(jpg_file.replace(path, ""))
    return file_list

def copy_img_and_xml(files,fromImgPath,toImgPath,fromXmlPath,toXmlPath):
    for file in files:
        copyfile(fromImgPath+ "/"+ file, toImgPath + "/"+ file)
        file = file.replace(".jpg",".xml")
        copyfile(fromXmlPath+ "/"+ file, toXmlPath + "/"+ file)

#shuffle Data 
path = "/Users/swift/Downloads/527030-966454-bundle-archive/images/"
filenames = getFileNames(path)
filenames.sort()  # make sure that the filenames have a fixed order before shuffling
random.seed(230)
random.shuffle(filenames) # shuffles the ordering of filenames (deterministic given the chosen seed)
split_1 = int(0.8 * len(filenames))
train_filenames = filenames[:split_1]
test_filenames = filenames[split_1:]


imgFrom = r'/Users/swift/Downloads/527030-966454-bundle-archive/images/'
imgTo = r'/Users/swift/Google Drive/models/research/object_detection/images/train/'
xmlFrom = r'/Users/swift/Downloads/527030-966454-bundle-archive/labels/'
xmlTo = r'/Users/swift/Google Drive/models/research/object_detection/images/train/'

copy_img_and_xml(train_filenames,imgFrom,imgTo,xmlFrom,xmlTo)


imgTo = r'/Users/swift/Google Drive/models/research/object_detection/images/test/'
xmlTo = r'/Users/swift/Google Drive/models/research/object_detection/images/test/'


copy_img_and_xml(test_filenames,imgFrom,imgTo,xmlFrom,xmlTo)

