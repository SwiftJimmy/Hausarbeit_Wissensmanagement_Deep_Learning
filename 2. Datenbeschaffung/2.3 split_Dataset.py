#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from shutil import copyfile
import random
import os
import glob
import pandas as pd
import xml.etree.ElementTree as ET

# Funktion welche eine Liste aller Dateinamen von JPG Dateien zurückgibt
def getFileNames(path):
    file_list = []
    for jpg_file in glob.glob(path + '*.jpg'):
        file_list.append(jpg_file.replace(path, ""))
    return file_list

# Funktion zum kopieren von Dateien
def copy_img_and_xml(files,fromImgPath,toImgPath,fromXmlPath,toXmlPath):
    for file in files:
        copyfile(fromImgPath+ "/"+ file, toImgPath + "/"+ file)
        file = file.replace(".jpg",".xml")
        copyfile(fromXmlPath+ "/"+ file, toXmlPath + "/"+ file)

# Pfad aller XML und JPG Dateien
xmlFrom = r'path/to/all/xml/files'
imgFrom = r'path/to/all/JPG/files'

filenames = getFileNames(imgFrom)
# setzt einen Start-Seedwert
random.seed(230)
# vermischt die Dateinamen
random.shuffle(filenames)

# Dateien werden in 75% Trainingsdaten und 25% Testdaten geteilt
split_1 = int(0.75 * len(filenames))
train_filenames = filenames[:split_1]
test_filenames = filenames[split_1:]


# Pfad zur Ablage der Trainingsdateien
imgTo = r'path/to/train/img/directory'
xmlTo = r'path/to/train/xml/directory'

# Kopiert Trainingsdaten
copy_img_and_xml(train_filenames,imgFrom,imgTo,xmlFrom,xmlTo)

# Pfad zur Ablage der Testdateien
imgTo = r'path/to/test/img/directory'
xmlTo = r'path/to/test/xml/directory'

# Kopiert Testdaten
copy_img_and_xml(test_filenames,imgFrom,imgTo,xmlFrom,xmlTo)

