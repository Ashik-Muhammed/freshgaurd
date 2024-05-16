from flask import Flask, jsonify, Response
import cv2
import torch
from PIL import Image
import numpy as np
import os

app = Flask(__name__)

model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

def check_spoilage(cropped_image):
    img = np.array(cropped_image)
    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    lower_yellow = np.array([20, 100, 100])
    upper_yellow = np.array([30, 255, 255])
    mask = cv2.inRange(hsv, lower_yellow, upper_yellow)
    yellow_pixels = cv2.countNonZero(mask)
    total_pixels = img.shape[0] * img.shape[1]
    yellow_percentage = (yellow_pixels / total_pixels) * 100

    spoilage_threshold = 10
    if yellow_percentage > spoilage_threshold:
        return True
    else:
        return False

def detect_freshness(cropped_image, class_name):
    global freshness
    img = np.array(cropped_image)
    img = cv2.cvtColor(img, cv2.COLOR_RGB2HSV)
    avg_hue = cv2.mean(img[:, :, 0])[0]

    if class_name == 'apple':
        if avg_hue < 30:
            freshness = 0
        elif avg_hue < 60:
            freshness = 1
        elif avg_hue < 90:
            freshness = 2
        elif avg_hue < 120:
            freshness = 3
        else:
            freshness = 4
    elif class_name == 'banana':
        if avg_hue < 20:
            freshness = 0
        elif avg_hue < 80:
            freshness = 1
        elif avg_hue < 140:
            freshness = 2
        elif avg_hue < 180:
            freshness = 3
        else:
            freshness = 4

    return freshness

@app.route('/detect_freshness', methods=['GET'])
def detect_freshness_webcam():
    cap = cv2.VideoCapture(0)
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        results = model(Image.fromarray(frame))
        labels = results.names
        pred_boxes = results.xyxy[0][:, :4]
        detections = []

        for label, bbox in zip(results.xyxy[0][:, -1].int(), pred_boxes):
            label = int(label)
            class_name = labels[label]
            if class_name in ['apple', 'banana', 'orange', 'mango', 'pear']:
                bbox = bbox.tolist()
                cropped_image = frame[int(bbox[1]):int(bbox[3]), int(bbox[0]):int(bbox[2])]
                freshness_score = detect_freshness(cropped_image, class_name)
                is_spoiled = check_spoilage(cropped_image)

                detection = {
                    'label': class_name,
                    'freshness': freshness_score,
                    'is_spoiled': is_spoiled}
                detections.append(detection)

        if detections:
            response = jsonify({'detections': detections})
            return Response(response.data, mimetype='application/json')

    cap.release()
    cv2.destroyAllWindows()
    return Response('No detections found', mimetype='text/plain')


if __name__ == '__main__':
    app.run(debug=False, host='192.168.137.1', port=5001)
