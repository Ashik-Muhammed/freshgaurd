import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/detection.dart';

class DetectionList extends StatefulWidget {
  const DetectionList({super.key});

  @override
  State<DetectionList> createState() => _DetectionListState();
}

class _DetectionListState extends State<DetectionList> {
  List<Detection> foods = [];
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    var result = box.read('detections') as List<dynamic>?;


    if (result != null) {
      foods = result.map((json) => Detection.fromJson(json)).toList();
    } else {
      foods = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detections',
          style: GoogleFonts.montserrat(
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
        padding: const EdgeInsets.all(16.0),
        child: foods.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
          itemCount: foods.length,
          separatorBuilder: (context, index) => const Divider(
            thickness: 1,
            color: Colors.grey,
          ),
          itemBuilder: (context, index) {
            return _buildFoodItem(foods[index]);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.food_bank,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            'No foods detected',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Please scan a food item to start tracking.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(Detection food) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          food.label,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Freshness: ${food.freshness
              }',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Detected on: ${DateFormat.yMMMd().add_Hm().format(food.dateTime??DateTime.now())}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        trailing: food.freshness == 'Very Fresh' || food.freshness == 'Fresh'
            ? const Icon(
          Icons.sentiment_very_satisfied,
          color: Colors.green,
          size: 32,
        )
            : food.freshness == 'Slightly Stale'
            ? Icon(
          Icons.sentiment_neutral,
          color: Colors.yellow.shade700,
          size: 32,
        )
            : food.freshness == ' Stale'
            ? Icon(
          Icons.sentiment_dissatisfied,
          color: Colors.red.shade600,
          size: 32,
        )
            : Icon(
          Icons.sentiment_dissatisfied_rounded,
          color: Colors.red.shade800,
          size: 32,
        ),
      ),
    );
  }
}