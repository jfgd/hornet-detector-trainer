#!/usr/bin/env python3

# Based on the 'annotate.py' script from
# https://github.com/AndrewCarterUK/tf-example-object-detection-api-race-cars

import numpy as np
import os
import tensorflow as tf
import sys

sys.path.append('models/research/')
sys.path.append('models/research/object_detection')

from PIL import Image
from utils import label_map_util
from pascal_voc_writer import Writer

print("Tensorflow version: ", tf.__version__)

PATH_TO_CKPT = 'graphs/ssdlite_mobilenet_v2_hornet_2020-02-11-09-16/frozen_inference_graph.pb' # 'inference/frozen_inference_graph.pb'
PATH_TO_LABELS = 'training/label_map.pbtxt'

NUM_CLASSES = 2

detection_graph = tf.Graph()
with detection_graph.as_default():
  od_graph_def = tf.compat.v1.GraphDef()
  with tf.io.gfile.GFile(PATH_TO_CKPT, 'rb') as fid:
    serialized_graph = fid.read()
    od_graph_def.ParseFromString(serialized_graph)
    tf.import_graph_def(od_graph_def, name='')

label_map = label_map_util.load_labelmap(PATH_TO_LABELS)
categories = label_map_util.convert_label_map_to_categories(label_map, max_num_classes=NUM_CLASSES, use_display_name=True)
category_index = label_map_util.create_category_index(categories)

def load_image_into_numpy_array(image):
  (im_width, im_height) = image.size
  return np.array(image.getdata()).reshape(
      (im_height, im_width, 3)).astype(np.uint8)

# Get all paths from arguments
TEST_IMAGE_PATHS = sys.argv[1:]

with detection_graph.as_default():
  with tf.compat.v1.Session(graph=detection_graph) as sess:
    # Definite input and output Tensors for detection_graph
    image_tensor = detection_graph.get_tensor_by_name('image_tensor:0')
    # Each box represents a part of the image where a particular object was detected.
    detection_boxes = detection_graph.get_tensor_by_name('detection_boxes:0')
    # Each score represent how level of confidence for each of the objects.
    # Score is shown on the result image, together with the class label.
    detection_scores = detection_graph.get_tensor_by_name('detection_scores:0')
    detection_classes = detection_graph.get_tensor_by_name('detection_classes:0')
    num_detections = detection_graph.get_tensor_by_name('num_detections:0')
    for image_path in TEST_IMAGE_PATHS:
      print("Auto Annotating ", image_path)
      image = Image.open(image_path)
      image_width, image_height = image.size
      # the array based representation of the image will be used later in order to prepare the
      # result image with boxes and labels on it.
      image_np = load_image_into_numpy_array(image)
      # Expand dimensions since the model expects images to have shape: [1, None, None, 3]
      image_np_expanded = np.expand_dims(image_np, axis=0)
      # Actual detection.
      (boxes, scores, classes, num) = sess.run(
          [detection_boxes, detection_scores, detection_classes, num_detections],
          feed_dict={image_tensor: image_np_expanded})

      boxes = np.squeeze(boxes)
      classes = np.squeeze(classes)
      scores = np.squeeze(scores)

      writer = Writer(image_path, image_width, image_height)

      for index, score in enumerate(scores):
        if score < 0.6:
          continue

        label = category_index[classes[index]]['name']
        ymin, xmin, ymax, xmax = boxes[index]

        writer.addObject(label, int(xmin * image_width), int(ymin * image_height),
                         int(xmax * image_width), int(ymax * image_height))


      annotation_path = os.path.splitext(image_path)[0] + '.xml'
      writer.save(annotation_path)

      # Use tab instead of 4 spaces to be aligned with labelImg XML
      os.system(os.path.join("sed -i 's/    /\t/g' ./", annotation_path))
