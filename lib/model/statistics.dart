
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:fresh_guard/model/detection.dart';
import 'package:google_fonts/google_fonts.dart';

class Statistics {
  int _totalFoods = 0;
  int _spoiledFoods = 0;
  List<Detection> _detections = [];

  Statistics(List<Detection> detectionList) {
    _totalFoods = detectionList.length;
    _spoiledFoods = detectionList.where((detection) {
      print('detection.foodStatus');
      print(detection.foodStatus);

      return detection.foodStatus == 'Rotten';
    }).length;

    _detections = detectionList;
  }

  String get spoilageRate => _totalFoods == 0
      ? 'Spoilage Rate: 0%'
      : 'Spoilage Rate: ${(_spoiledFoods / _totalFoods * 100).toStringAsFixed(2)}%';

  int get totalFoods => _totalFoods;

  int get spoiledFoods => _spoiledFoods;

  Map<String, int> get foodSpoilageCount {
    final foodSpoilageCount = <String, int>{};
    for (final detection in _detections) {
      if (detection.foodStatus == 'Rotten') {
        foodSpoilageCount[detection.label] = (foodSpoilageCount[detection.label]?? 0) + 1;

      }

    }
    return foodSpoilageCount;
  }
}

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});



  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  late Statistics _statistics;
  List<Detection> _detectionList = [];
  Map<String, List<Detection>> _foodDetections = {};
  SpoilagePredictor? _spoilagePredictor;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final box = GetStorage();
    final detections = box.read('detections') as List<dynamic>?;
print(detections);
    if (detections!= null) {
      //setState(()  {
      try{
        _detectionList= List<Detection>.from(detections.map((x) => Detection.fromJson(x)));

   // _detectionList = detections.map((json) => Detection.fromJson(json)).toList();
        print(_detectionList[0].foodStatus);
      }catch(e) {
        print(e);
      }


        _foodDetections = _groupBy(_detectionList, (detection) => detection.label);
        _statistics = Statistics(_detectionList);
        _spoilagePredictor = SpoilagePredictor(_detectionList);
     // });
    } else {
     // setState(() {
        _detectionList = [];
        _foodDetections = {};
        _statistics = Statistics([]);
        _spoilagePredictor = null;
     // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.openSans(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _statistics.spoilageRate,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total Foods scanned: ${_statistics.totalFoods}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Spoiled Foods: ${_statistics.spoiledFoods}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _foodDetections.length,
                itemBuilder: (context, index) {
                  final food = _foodDetections.keys.elementAt(index);
                  final detections = _foodDetections[food]!;
                  final spoiledDetections = detections.where((detection) =>  detection.foodStatus == 'Rotten').toList();
                  final totalDetections = detections.length;
                  final spoilageRate = (spoiledDetections.length / totalDetections * 100).toStringAsFixed(2);

                  if (_spoilagePredictor != null) {
                    final predictedSpoilageDates = _spoilagePredictor!.predictSpoilageDates();
                    final predictedSpoilageDate = predictedSpoilageDates[food];
                    final predictedDaysToSpoil = predictedSpoilageDate != null ? predictedSpoilageDate.difference(DateTime.now()).inDays : 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          leading: Icon(
                            Icons.fastfood_outlined,
                            color: Theme.of(context).primaryColor,
                          ),
                          title: Text(
                            food,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          children: [
                            ListTile(
                              title: Text(
                                'Spoilage Rate: $spoilageRate%',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total Detections: $totalDetections',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Spoiled Detections: ${spoiledDetections.length}',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'Predicted Days to Spoil: $predictedDaysToSpoil',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  Text(
                                    'spoilage date: $predictedSpoilageDate',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                spoiledDetections.isNotEmpty
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_rounded,
                                color: spoiledDetections.isNotEmpty
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Detection>> _groupBy(List<Detection> list, Function(Detection) keyFunction) {
    Map<String, List<Detection>> map = {};
    for (Detection item in list) {
      String key = keyFunction(item).toString();
      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(item);
    }
    return map;
  }
}

class SpoilagePredictor {
  final List<Detection> _detections;

  SpoilagePredictor(this._detections);

  Map<String, DateTime> predictSpoilageDates() {
    const freshnessScale = {
      'Very Fresh': 15,
      'Fresh': 12,
      'Slightly Stale': 8,
      'Stale': 4,
      'Rotten': 1 ,
    };
    final spoilageDates = <String, DateTime>{};
    for (final food in _detections.map((detection) => detection.label).toSet()) {
      final foodDetections = _detections.where((detection) => detection.label == food).toList();
      final freshnessValues = foodDetections.map((detection) => freshnessScale[detection.freshness]?? 0).toList();
      final daysToSpoil = foodDetections.map((detection) {
        final spoiledDate = detection.dateTime??DateTime.now();
        final storedDate = DateTime.parse(spoiledDate.toIso8601String().split('T')[0]);
        return spoiledDate.difference(storedDate).inDays.toDouble();
      }).toList();

      final slope = daysToSpoil.reduce((a, b) => a + b) / daysToSpoil.length;
      final intercept = freshnessValues.reduce((a, b) => a + b) / freshnessValues.length;

      final predictedDaysToSpoil = slope * (freshnessValues.length - 1) + intercept;
      final predictedSpoilageDate = DateTime.now().add(Duration(days: predictedDaysToSpoil.toInt()));

      spoilageDates[food] = predictedSpoilageDate;
    }
    return spoilageDates;
  }
}