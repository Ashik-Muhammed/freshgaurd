import cv2
import numpy as np
import requests
import torch
from PIL import Image
from flask import Flask, jsonify, Response, request
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__, template_folder='.')

app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///users.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

model = torch.hub.load('ultralytics/yolov5', 'yolov5s')

detected_fruits = []


class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password = db.Column(db.String(120), nullable=False)


# Create the database
with app.app_context():
    db.create_all()


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

        results = model(Image.fromarray(frame))
        labels = results.names
        pred_boxes = results.xyxy[0][:, :4]
        detections = []

        detected_fruits = []
        for label, bbox in zip(results.xyxy[0][:, -1].int(), pred_boxes):
            label = int(label)
            class_name = labels[label]
            if class_name in ['apple', 'banana', 'orange', 'broccoli', 'carrot']:
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


@app.route('/users', methods=['GET'])
def get_users():
    users = User.query.all()
    user_list = [{"username": user.username, "password": user.password} for user in users]
    return jsonify({"users": user_list}), 200


@app.route('/signup', methods=['POST'])
def signup():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if User.query.filter_by(username=username).first() is not None:
        return jsonify({"message": "User already exists!"}), 400

    new_user = User(username=username, password=password)
    db.session.add(new_user)
    db.session.commit()
    return jsonify({"message": "User registered successfully!"}), 201


@app.route('/detected_fruits', methods=['GET'])
def get_detected_fruits():
    global detected_fruits
    return jsonify({'detected_fruits': detected_fruits})


if __name__ == "__main__":
    app.run(debug=False, host='192.168.137.1', port=5001)
