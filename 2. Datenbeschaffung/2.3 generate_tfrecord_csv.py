#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import glob
import pandas as pd
import xml.etree.ElementTree as ET

path = "path/to/images"

# Funktion zum Speicherung der Annotationen
def xml_to_csv(path):
    xml_list = []
    # für jede XML Datei 
    for xml_file in glob.glob(path + '/*.xml'):
        tree = ET.parse(xml_file)
        root = tree.getroot()
        # für jedes Objekt in der XML Datei
        for member in root.findall('object'):
            value = (root.find('filename').text.replace("png","jpg"),
                     int(root.find('size')[0].text),
                     int(root.find('size')[1].text),
                     member[0].text,
                     int(member.find("bndbox")[0].text),
                     int(member.find("bndbox")[1].text),
                     int(member.find("bndbox")[2].text),
                     int(member.find("bndbox")[3].text)
                     )
            xml_list.append(value)
    column_name = ['filename', 'width', 'height', 'class', 'xmin', 'ymin', 'xmax', 'ymax']
    xml_df = pd.DataFrame(xml_list, columns=column_name)
    return xml_df

# Hauptfunktion für die CSV Generierung
def main():
	# erstellt eine CSV Datei jeweils für die Trainings- und Testdaten 
    for folder in ['train','test']:
        image_path = path  + folder
        xml_df = xml_to_csv(image_path)
        xml_df.to_csv((path + folder + '_labels.csv'), index=None)


# Funktion wird ausgeführt
main()