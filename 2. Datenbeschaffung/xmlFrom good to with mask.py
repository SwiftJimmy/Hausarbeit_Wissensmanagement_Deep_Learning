#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jun 25 11:16:01 2020

@author: swift
"""


import xml.etree.ElementTree as et

import os



anno_directory = r'/Users/swift/Downloads/527030-966454-bundle-archive/labels/'





def rotate_img(anno_directory):
    for entry in os.scandir(anno_directory):
        if (entry.path.endswith(".xml") and entry.is_file()):
            

            
            tree = et.parse(entry.path)
            root = tree.getroot()
            
            for boxes in root.iter('object'):
                
                if boxes.find("name").text == "good":
                    boxes.find("name").text = "with_mask"
                else :
                    boxes.find("name").text = "without_mask"
            
               
            tree.write(entry.path)



rotate_img(anno_directory)