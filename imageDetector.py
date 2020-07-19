#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Jul 19 09:59:50 2020

@author: swift
"""

import tflite_runtime.interpreter as tflite
from PIL import Image, ImageDraw 
import numpy as np
import math 

labels = ['with_mask', 'without_mask','mask_worn_incorrect']
imagepath = r'/Users/swift/Downloads/AS20191207000954_comm.jpg'
modelPath = "/Users/swift/Google Drive/models/research/object_detection/ssd_mobilenet_v2_quantized_300x300_coco/tfLite/quantModel/detect.tflite"

def printBoxIntoImage(index):
    shape = [(width*detection_boxes[0][index][1],
              height*detection_boxes[0][index][0]), ( 
                  width*detection_boxes[0][index][3], 
                  height*detection_boxes[0][index][2])] 
    labelName = int(detection_classes[0][index])
    img1 = ImageDraw.Draw(img)   
    img1.text((width*detection_boxes[0][index][1],height*detection_boxes[0][index][0]), labels[labelName], None)
    img1.rectangle(shape, outline ="green") 


interpreter = tflite.Interpreter(model_path=modelPath)


interpreter.allocate_tensors()
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
input_shape = input_details[0]['shape']


# check the type of the input tensor
floating_model = input_details[0]['dtype'] == np.float32


height = input_details[0]['shape'][1]
width = input_details[0]['shape'][2]

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

      
img.show()       
      
      



  
# create  rectangleimage 


