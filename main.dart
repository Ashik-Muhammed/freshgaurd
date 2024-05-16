import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Freshguard',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _temperature = 0;
  int _humidity = 0;
  double _gasSensor = 0.0;
  bool _isLoading = false;
  String _foodStatus = '';
  String _currentTime = '';
  List<Detection> _detections = [];
  String _output = '';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateFormat.yMd().add_jm().format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  Future<void> _detectFreshness() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    try {
      final dio = Dio();
      final response = await dio.get('http://192.168.137.1:5001/detect_freshness');
      print('Response body: ${response.data}');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        setState(() {
          _detections = (jsonData['detections'] as List?)
              ?.map((jsonDetection) => Detection.fromJson(jsonDetection))
              .toList() ?? [];
          _output = jsonData['output'] ?? '';
          _isLoading = false;
        });

        setState(() {
          _temperature = jsonData['temperature'] ?? 0;
          _humidity = jsonData['humidity'] ?? 0;
          _gasSensor = jsonData['gas_sensor'] ?? 0.0;

          double cameraTemperature = 50.0;
          double cameraHumidity = 70.0;
          double cameraGasSensor = 100.0;

          double freshness = 0.0;

          if (_temperature > 0 && _humidity > 0 && _gasSensor > 0) {
            if (_temperature < cameraTemperature &&
                _humidity < cameraHumidity &&
                _gasSensor < cameraGasSensor) {
              freshness = 1.0; // Fresh
            } else if (_temperature > cameraTemperature &&
                _humidity > cameraHumidity &&
                _gasSensor > cameraGasSensor) {
              freshness = 0.0; // Spoiled
            } else {
              freshness = 0.5; // Partially spoiled
            }
          }

          _foodStatus = freshness == 1.0
              ? 'Fresh'
              : freshness == 0.0
              ? 'Spoiled'
              : 'Partially spoiled';
        });
      } else {
        setState(() {
          _output = 'Failed to detect freshness. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _output = 'An error occurred. Please try again.';
        _isLoading = false;
      });

      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freshguard',),
        centerTitle: true,
        backgroundColor: Colors.white70,
        leading: Image.asset('lib/assets/logo.png', height: 132, width: 120),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            const SizedBox(height: 16),
            Text(
              'Date and Time: ${DateFormat.yMd().add_jm().format(DateTime.now())}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Sensor Values',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading) ...[
                      const CircularProgressIndicator(),
                    ] else ...[
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.thermostat,
                                size: 24,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 28),
                              Text(
                                'Temperature:',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_temperature°C',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.water_drop_rounded,
                                size: 24,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 28),
                              Text(
                                'Humidity:',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_humidity%',
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Icon(
                                Icons.gas_meter_rounded,
                                size: 24,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 28),
                              Text(
                                'Gas Sensor:',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_gasSensor',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Detections:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_detections.isEmpty) ...[
              const Text('No detections'),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _detections.length,
                itemBuilder: (context, index) {
                  final detection = _detections[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(
                        detection.isSpoiled ? Icons.warning : Icons.check,
                        color: detection.isSpoiled ? Colors.red : Colors.green,
                      ),
                      title: Text(detection.label),
                      subtitle: Text('Freshness: ${detection.freshness}'),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 20),
            Text(
              'Food Status: ${_foodStatus.toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ?null : _detectFreshness,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Detect Food Freshness',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _output,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class Detection {
  final String label;
  final double freshness;
  final bool isSpoiled;

  Detection({required this.label, required this.freshness, required this.isSpoiled});

  factory Detection.fromJson(Map<String, dynamic> json) {
    return Detection(
      label: json['label'] ?? '',
      freshness: json['freshness'] ?? 0.0,
      isSpoiled: json['is_spoiled'] ?? false,
    );
  }
}
