#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import tflite_runtime.interpreter as tflite
from PIL import Image, ImageDraw , ImageFont
import numpy as np
import math 
import os

labels = ['with_mask', 'without_mask','mask_worn_incorrect']
modelPath = "fullintegermodel.tflite"
inputDir = r'/path/to/input/dir'
outputDir = r'/path/to/output/dir'

def resizeShapeX(shape):
    return (shape/300)*Image.open(imagepath).size[0]
def resizeShapeY(shape):
    return (shape/300)*Image.open(imagepath).size[1]
    
def printBoxIntoImage(index):
    shape = [(resizeShapeX(width*detection_boxes[0][index][1]),
              resizeShapeY(height*detection_boxes[0][index][0])), ( 
                  resizeShapeX(width*detection_boxes[0][index][3]), 
                  resizeShapeY(height*detection_boxes[0][index][2]))] 
    labelName = int(detection_classes[0][index])
    img1 = ImageDraw.Draw(imgOriginal)  

    
    if labels[labelName] == "with_mask":
         color = "green"
    elif labels[labelName] == "without_mask":
         color = "red"
    else: 
         color = "orange"
        
    img1.rectangle(shape, outline =color,width=3)
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", 20 )
    img1.text((resizeShapeX(width*detection_boxes[0][index][1]),resizeShapeY(height*detection_boxes[0][index][2]) ), labels[labelName], font=font,fill=color)
    
   


interpreter = tflite.Interpreter(model_path=modelPath)


interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
input_shape = input_details[0]['shape']


# check the type of the input tensor
floating_model = input_details[0]['dtype'] == np.float32


height = input_details[0]['shape'][1]
width = input_details[0]['shape'][2]


for filename in os.listdir(inputDir):
    imagepath = inputDir + "/" + filename
    if filename == ".DS_Store" :
        continue
    print(filename)
    imgOriginal = Image.open(imagepath)
    img = Image.open(imagepath).resize((width, height))
    input_data = np.expand_dims(img, axis=0)


    interpreter.set_tensor(input_details[0]['index'], input_data)


    interpreter.invoke()


    output_data = interpreter.get_tensor(output_details[0]['index'])

    detection_boxes = interpreter.get_tensor(output_details[0]['index'])
    detection_classes = interpreter.get_tensor(output_details[1]['index'])
    detection_scores = interpreter.get_tensor(output_details[2]['index'])
    num_boxes = interpreter.get_tensor(output_details[3]['index'])

    for i,value in enumerate(detection_scores[0]):
        if value >= 0.7:    
            
            printBoxIntoImage(i)
    tuplevalue = tuple(int(ti/2) for ti in Image.open(imagepath).size)
    img2 = img.resize(tuplevalue)
    imgOriginal.save(outputDir + "/" + filename)
    
     


