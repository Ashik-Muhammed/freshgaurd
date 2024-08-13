import 'dart:convert';
import 'package:meta/meta.dart';


class ResponseModel {
  List<Detection> detections;
  int gasSensor;
  int humidity;
  int temperature;

  ResponseModel({
    required this.detections,
    required this.gasSensor,
    required this.humidity,
    required this.temperature,
  });

  factory ResponseModel.fromRawJson(String str) => ResponseModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
    detections: List<Detection>.from(json["detections"].map((x) => Detection.fromJson(x))),
    gasSensor: json["gas_sensor"],
    humidity: json["humidity"],
    temperature: json["temperature"],
  );

  Map<String, dynamic> toJson() => {
    "detections": List<dynamic>.from(detections.map((x) => x.toJson())),
    "gas_sensor": gasSensor,
    "humidity": humidity,
    "temperature": temperature,
  };
}

class Detection {
  String freshness;
  bool isSpoiled;
  String label;
  @required
  DateTime? dateTime;
  String? foodStatus;

  Detection({
    required this.freshness,
    required this.isSpoiled,
    required this.label,
    required this.foodStatus,
    required this.dateTime,
  }) ;

  factory Detection.fromRawJson(String str) => Detection.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory Detection.fromJson(Map<String, dynamic> json) {

    return Detection(
      freshness: json["freshness"],
      isSpoiled: json["is_spoiled"],
      label: json["label"],
      foodStatus: json["food_status"],
      dateTime: json["date_time"] == null ? null : DateTime.parse(json["date_time"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "freshness": freshness,
    "is_spoiled": isSpoiled,
    "label": label,
    "date_time": dateTime?.toIso8601String(),
    "food_status": foodStatus,
  };
}