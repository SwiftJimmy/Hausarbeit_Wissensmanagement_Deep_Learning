#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import imageio
import imgaug as ia
import imgaug.augmenters as iaa
import xml.etree.ElementTree as ET
from imgaug.augmentables.bbs import BoundingBox, BoundingBoxesOnImage
from pascal_voc_writer import  Writer
import os

# Angabe der Pfade
img_directory = r'path/to/images'
anno_directory = r'path/to/annotations'
save_img = r'path/to/directory/to/save/images'
save_anno = r'path/to/directory/to/save/annotation'


# Ausführung der Funktionen
rotate_img("-20_to_-7",(-20,-7))
rotate_img("7_to_20",(7,20))
flip_img()
zoom_img()


#Funktion zum Rotieren der Images und Annotations
def rotate_img(rotationName,rotationRange):
    for entry in os.scandir(img_directory):
        if (entry.path.endswith(".jpg") and entry.is_file()):
            
            # read image
            image = imageio.imread(entry.path)
            
            # read xml file of img and extract all bounding boxes
            xml_Path = anno_directory + entry.name.replace(".jpg", ".xml")
            print(xml_Path)
            boundingBoxesBoxes = extract_bbx_from_XML(xml_Path)
            bbs_oi = BoundingBoxesOnImage(boundingBoxesBoxes, shape=image.shape)
            
            #rotate img
            rotate=iaa.Affine(rotate=rotationRange)
            image_aug, bbs_aug =rotate(image=image ,bounding_boxes=bbs_oi)
            
            #save rotated img
            new_img_path = save_img + entry.name.replace(".jpg", "") + "_rotated_"+rotationName+ ".jpg"
            imageio.imwrite(new_img_path, image_aug)
            
            #save rotated xml
            writer = Writer(new_img_path,  image_aug.shape[1],image_aug.shape[0])
        
            for object_boxes in bbs_aug.bounding_boxes:
                writer.addObject(object_boxes.label,int(round(object_boxes.x1)) , int(round(object_boxes.y1)), int(round(object_boxes.x2)), int(round(object_boxes.y2)))
            
            
            new_xml_path = save_anno + entry.name.replace(".jpg", "") + "_rotated_"+rotationName+ ".xml"
            
            writer.save(new_xml_path)


#Funktion zum vertikalen Spiegeln der Images und Annotations
def flip_img():
    for entry in os.scandir(img_directory):
        if (entry.path.endswith(".jpg") and entry.is_file()):
            
            # read image
            image = imageio.imread(entry.path)
            
            # read xml file of img and extract all bounding boxes
            xml_Path = anno_directory + entry.name.replace(".jpg", ".xml")
            print(xml_Path)
            boundingBoxesBoxes = extract_bbx_from_XML(xml_Path)
            bbs_oi = BoundingBoxesOnImage(boundingBoxesBoxes, shape=image.shape)
            
            #flip img
            flip=iaa.Fliplr(p=1.0)
            image_aug, bbs_aug =flip(image=image ,bounding_boxes=bbs_oi)
            
            #save fliped img
            new_img_path = save_img + entry.name.replace(".jpg", "") + "_flip.jpg"
            imageio.imwrite(new_img_path, image_aug)
            
            #save fliped xml
            writer = Writer(new_img_path,  image_aug.shape[1],image_aug.shape[0])
        
            for object_boxes in bbs_aug.bounding_boxes:
                writer.addObject(object_boxes.label,int(round(object_boxes.x1)) , int(round(object_boxes.y1)), int(round(object_boxes.x2)), int(round(object_boxes.y2)))
            
            
            new_xml_path = save_anno + entry.name.replace(".jpg", "") + "_flip.xml"
            
            writer.save(new_xml_path)
            
#Funktion zum Zoomen der Images und Annotations
def zoom_img():
    for entry in os.scandir(img_directory):
        if (entry.path.endswith(".jpg") and entry.is_file()):
            
            # read image
            image = imageio.imread(entry.path)
            
            # read xml file of img and extract all bounding boxes
            xml_Path = anno_directory + entry.name.replace(".jpg", ".xml")
            print(xml_Path)
            boundingBoxesBoxes = extract_bbx_from_XML(xml_Path)
            bbs_oi = BoundingBoxesOnImage(boundingBoxesBoxes, shape=image.shape)
            
            #zoom img
            scale=iaa.Affine(scale={"x": (0.8, 0.5), "y": (0.8, 0.5)})
            image_aug, bbs_aug =scale(image=image ,bounding_boxes=bbs_oi)
            
            #save zoomed img
            new_img_path = save_img + entry.name.replace(".jpg", "") + "_zoom.jpg"
            imageio.imwrite(new_img_path, image_aug)
            
            #save zommed xml
            writer = Writer(new_img_path,  image_aug.shape[1],image_aug.shape[0])
        
            for object_boxes in bbs_aug.bounding_boxes:
                writer.addObject(object_boxes.label,int(round(object_boxes.x1)) , int(round(object_boxes.y1)), int(round(object_boxes.x2)), int(round(object_boxes.y2)))
            
            
            new_xml_path = save_anno + entry.name.replace(".jpg", "") + "_zoom.xml"
            
            writer.save(new_xml_path)

# extrahiert alle Bounding Boxes aus einem XML File
def extract_bbx_from_XML(xml_file: str):

    tree = ET.parse(xml_file)
    root = tree.getroot()
    
    list_with_all_boxes = []

    for boxes in root.iter('object'):
        
        for box in boxes.findall("bndbox"):
            bndbx = BoundingBox(    x1=int(box.find("xmin").text), 
                            y1=int(box.find("ymin").text), 
                            x2=int(box.find("xmax").text), 
                            y2=int(box.find("ymax").text), 
                            label = boxes.find("name").text)


        list_with_all_boxes.append(bndbx);

    return list_with_all_boxes

