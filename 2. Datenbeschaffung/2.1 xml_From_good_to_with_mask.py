#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as et
import os

# Pfad in welchem sich die XML Dateien befinden
anno_directory = r'path/to/xml/files'

# Funktion schreibt die Bounding Box Bezeichnung von good in with_mask und bad in without_mask um.
def rewrite_annotation(anno_directory):

	# für jede Datei im Ordner
    for entry in os.scandir(anno_directory):
    
    	# Falls es sich um eine XML Datei handelt
        if (entry.path.endswith(".xml") and entry.is_file()):
            tree = et.parse(entry.path)
            root = tree.getroot()
			
			# Für jedes annotierte Objekt 
            for boxes in root.iter('object'):
                if boxes.find("name").text == "good":
                    boxes.find("name").text = "with_mask"
                else :
                    boxes.find("name").text = "without_mask"
                    
            # Schreib Änderung in die Datei
            tree.write(entry.path)


# führe Funktion aus
rewrite_annotation(anno_directory)