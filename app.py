import random
import cv2
import numpy as np
import requests
import torch
from PIL import Image
from flask import Flask, jsonify, Response

app = Flask(__name__, template_folder='.')

model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

detected_fruits = []


def check_spoilage(cropped_image):
    img = np.array(cropped_image)
    img = cv2.cvtColor(img, cv2.COLOR_RGB2BGR)
    hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    lower_yellow = np.array([20, 100, 100])
    upper_yellow = np.array([30, 255, 255])
    lower_green = np.array([40, 100, 100])
    upper_green = np.array([70, 255, 255])
    lower_brown = np.array([10, 50, 50])
    upper_brown = np.array([20, 200, 200])

    mask_yellow = cv2.inRange(hsv, lower_yellow, upper_yellow)
    mask_green = cv2.inRange(hsv, lower_green, upper_green)
    mask_brown = cv2.inRange(hsv, lower_brown, upper_brown)

    yellow_pixels = cv2.countNonZero(mask_yellow)
    green_pixels = cv2.countNonZero(mask_green)
    brown_pixels = cv2.countNonZero(mask_brown)

    total_pixels = img.shape[0] * img.shape[1]
    yellow_percentage = (yellow_pixels / total_pixels) * 100
    green_percentage = (green_pixels / total_pixels) * 100
    brown_percentage = (brown_pixels / total_pixels) * 100

    spoilage_threshold_yellow = 10
    spoilage_threshold_green = 20
    spoilage_threshold_brown = 30

    if yellow_percentage > spoilage_threshold_yellow:
        return True
    elif green_percentage > spoilage_threshold_green:
        return True
    elif brown_percentage > spoilage_threshold_brown:
        return True
    else:
        return False


def detect_freshness(cropped_image, class_name):
    img = np.array(cropped_image)
    img = cv2.cvtColor(img, cv2.COLOR_RGB2HSV)
    avg_hue = cv2.mean(img[:, :, 0])[0]
    global freshness
    freshness_values = {
        0: 'Very Fresh',
        1: 'Fresh',
        2: 'Slightly Stale',
        3: 'Stale',
        4: 'Rotten'
    }

    if class_name == 'apple':
        if avg_hue < 30:
            freshness = freshness_values[0]
        elif avg_hue < 60:
            freshness = freshness_values[1]
        elif avg_hue < 90:
            freshness = freshness_values[2]
        elif avg_hue < 120:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'banana':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'orange':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'broccoli':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'sandwich':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'donut':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'cake':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'hot dog':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'pizza':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    elif class_name == 'carrot':
        if avg_hue < 20:
            freshness = freshness_values[0]
        elif avg_hue < 80:
            freshness = freshness_values[1]
        elif avg_hue < 140:
            freshness = freshness_values[2]
        elif avg_hue < 180:
            freshness = freshness_values[3]
        else:
            freshness = freshness_values[4]
    return freshness


@app.route('/detect_freshness', methods=['GET'])
def detect_freshness_webcam():
    global detected_fruits
    cap = cv2.VideoCapture(0)
    while True:
        ret, frame = cap.read()
        if not ret:
            break

        # Detect objects using YOLOv5
        results = model(Image.fromarray(frame))
        labels = results.names
        pred_boxes = results.xyxy[0][:, :4]
        detections = []

        detected_fruits = []
        for label, bbox in zip(results.xyxy[0][:, -1].int(), pred_boxes):
            label = int(label)
            class_name = labels[label]
            if class_name in ['apple', 'banana', 'orange', 'sandwich', 'broccoli', 'carrot', 'hot dog', 'pizza',
                              'donut', 'cake']:
                bbox = bbox.tolist()
                cropped_image = frame[int(bbox[1]):int(bbox[3]), int(bbox[0]):int(bbox[2])]
                freshness_score = detect_freshness(cropped_image, class_name)
                is_spoiled = check_spoilage(cropped_image)

                detection = {
                    'label': class_name,
                    'freshness': freshness_score,
                    'is_spoiled': is_spoiled
                }
                detections.append(detection)
                detected_fruits.append(class_name)


        esp32_url = 'http://192.168.137.131:8080/sensors'
        try:
            response = requests.get(esp32_url)
            sensor_data = response.json()
            temp = round(sensor_data['temperature'])
            humidity = round(sensor_data['humidity'])
            gas_sensor_reading = sensor_data['gas_sensor']

            if detections:
                response = jsonify({
                    'detections': detections,
                    'temperature': temp,
                    'humidity': humidity,
                    'gas_sensor': gas_sensor_reading
                })
                return Response(response.data, mimetype='application/json')

        except requests.exceptions.RequestException as e:
            print(f"Error fetching sensor data from ESP32: {e}")
            return Response(f"Error fetching sensor data from ESP32: {e}", status=500)

    cap.release()
    cv2.destroyAllWindows()
    return Response('No detections found', mimetype='text/plain')


@app.route('/detected_fruits', methods=['GET'])
def get_detected_fruits():
    global detected_fruits
    return jsonify({'detected_fruits': detected_fruits})


if __name__ == "__main__":
    app.run(debug=False, host='192.168.137.1', port=5001)


get_detected_fruits()
