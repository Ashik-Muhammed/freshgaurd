import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fresh_guard/model/statistics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fresh_guard/model/chat_screen.dart';
import 'package:fresh_guard/model/detection.dart';
import 'package:fresh_guard/view/animations.dart';
import 'package:fresh_guard/view/detection_list.dart';
import 'package:get_storage/get_storage.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/services.dart';


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  int _temperature = 0;
  int _humidity = 0;
  int _gasSensor = 0;
  bool _isLoading = false;
  String _foodStatus = '';
  List<Detection> _detections = [];


 // Timer? _timer;
  final box = GetStorage();

  @override
  void initState() {
    super.initState();

   // _updateTime();
  }

  void _updateTime() {
    // _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    //   setState(() {});
    // });
  }

  @override
  void dispose() {
   // _timer?.cancel();
    super.dispose();
  }

  Future<void> _detectFreshness() async {
    try {
      setState(() {
        _isLoading = true;
      });

        final dio = Dio();
       final response = await dio.get('http://192.168.137.1:5001/detect_freshness').timeout(const Duration(seconds: 30));
//final data ={"detections":[{"freshness":"Fresh","is_spoiled":false,"label":"Banana"}],"gas_sensor":19,"humidity":89,"temperature":31};
     // response.statusCode == 200
      if (response.statusCode == 200) {
        final data = response.data;
        final model = ResponseModel.fromJson(data);
        setState(() {
          _detections = model.detections;

        });

        setState(() {
          _temperature = model.temperature;
          _humidity = model.humidity;
          _gasSensor = model.gasSensor;


          double freshnessScore = 0.0;
          bool isSpoiledByCamera = _detections[0].isSpoiled;


          if (_temperature > 0 && _humidity > 0 && _gasSensor > 0) {
            double temperatureScore = (_temperature < 20) ? 1.0 : (_temperature < 25) ? 0.9 : (_temperature < 30) ? 0.8 : 0.5;
            double humidityScore = (_humidity < 50) ? 1.0 : (_humidity < 60) ? 0.9 : (_humidity < 70) ? 0.8 : 0.5;
            double gasSensorScore = (_gasSensor < 15) ? 1.0 : (_gasSensor < 20) ? 0.9 : (_gasSensor < 25) ? 0.8 : 0.5;
            freshnessScore = (temperatureScore + humidityScore + gasSensorScore) / 3.0;
          } else {
            freshnessScore = 0.0;
          }

          if (isSpoiledByCamera) {
            freshnessScore *= 0.5;
          }

          if (freshnessScore < 0.2) {
            _foodStatus = 'Rotten';
          } else if (freshnessScore < 0.4) {
            _foodStatus = 'Rotten';
          } else if (freshnessScore < 0.6) {
            _foodStatus = 'Rotten';
          } else if (freshnessScore < 0.8) {
            _foodStatus = 'fresh';
          } else {
            _foodStatus = 'fresh';
          }

          model.detections[0].foodStatus= _foodStatus;
          model.detections[0].dateTime= DateTime.now();
          var jsonString = model.detections[0].toJson();

          var prevDetections = box.read('detections') ?? [];
          // print(jsonString);
          // print(prevDetections);
          prevDetections.add(jsonString);

          box.write('detections', prevDetections);
          _isLoading = false;

        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Failed to detect freshness. Please try again.', lottieAsset: 'lib/assets/network.json');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e is DioException) {
        if (e.error.toString().contains('Connection timed out')) {
          _showErrorMessage('Connection timed out', lottieAsset: 'lib/assets/timeout.json');
        } else if (e.type == DioExceptionType.sendTimeout) {
          _showErrorMessage('Connection timed out', lottieAsset: 'lib/assets/timeout.json');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          _showErrorMessage('Connection timed out', lottieAsset: 'lib/assets/timeout.json');
        } else if (e.type == DioExceptionType.cancel) {
          _showErrorMessage('Request cancelled. Please try again.', lottieAsset: 'lib/assets/cancel.json');
        } else if (e.response != null) {
          _showErrorMessage('Failed to fetch data from server', lottieAsset: 'lib/assets/network.json');
        } else {
          _showErrorMessage('No Network Connection.', lottieAsset: 'lib/assets/lostconn.json');
        }

      } else if (e is TimeoutException) {
        _showErrorMessage('Server taking too long to respond. Please try again', lottieAsset: 'lib/assets/timeout.json');
      } else {
        _showErrorMessage('An unknown error occurred. Please try again.', lottieAsset: 'lib/assets/error.json');
      }
    }
  }

  void _showErrorMessage(String errorMessage, {String lottieAsset = 'lib/assets/lostconn.json'}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          title: const Text(
            'Error',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(lottieAsset, height: 100, width: 100),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, -50 + 50 * value),
              child: child,
            );
          },
          child: Text(
            'FreshGuard',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(0),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Lottie.asset('lib/assets/bot1.json', width: 100, height:100),
                  //const SizedBox(width: 0),
                 //const Text('Chat'),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
                image: DecorationImage(
                  image: AssetImage('lib/assets/logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
              margin: EdgeInsets.zero,
              padding: EdgeInsets.all(16),
              child: Text('FreshGuard', style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.food_bank, color: Colors.blue),
              title: const Text('Detected Foods'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DetectionList(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.insert_chart, color: Colors.blue),
              title: const Text('Statistics'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const  StatisticsPage(),

                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.blue),
              title: const Text('Chatbot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.blue),
              title: const Text('Quit'),
              onTap: () {

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Confirm Exit'),
                      content: const Text('Are you sure you want to quit?'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        TextButton(
                          child: const Text('Quit'),
                          onPressed: () {
                            Navigator.of(context).pop();
                            SystemNavigator.pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            )

          ],
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const SizedBox(
              width: double.infinity,
              height: double.infinity,
              //child: Lottie.asset('lib/assets/bck.json'),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // Sensor Values
                  FadeIn(
                    duration: const Duration(milliseconds: 1000),
                    child: Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sensor Values',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          if (_isLoading)...[
                            const LottieAnimation(),
                          ] else
                            ...[
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  String title;
                                  String value;
                                  String lottieAsset;
                                  Color color;
                                  double progressValue;

                                  switch (index) {
                                    case 0:
                                      title = 'Temperature:';
                                      value = '$_temperature°C';
                                      lottieAsset = 'lib/assets/temp.json';
                                      color = _temperature > 40 ? Colors.red.shade600 : Colors.green.shade900;
                                      progressValue = _temperature.toDouble();
                                      break;
                                    case 1:
                                      title = 'Humidity:';
                                      value = '$_humidity%';
                                      lottieAsset = 'lib/assets/humid.json';
                                      color = _humidity > 60 ? Colors.red.shade600 : Colors.green.shade900;
                                      progressValue = _humidity.toDouble();
                                      break;
                                    case 2:
                                      title = 'Gas Sensor:';
                                      value = '$_gasSensor';
                                      lottieAsset = 'lib/assets/gassens.json';
                                      color = _gasSensor > 50 ? Colors.red.shade600 : Colors.green.shade900;
                                      progressValue = _gasSensor.toDouble();
                                      break;
                                    default:
                                      throw Exception('Invalid index');
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SlideIn(
                                        direction: Axis.horizontal,
                                        duration: const Duration(milliseconds: 500),
                                        child: Row(
                                          children: [
                                            Lottie.asset(
                                              lottieAsset,
                                              width: 30,
                                              height: 30,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        value,
                                        style: TextStyle(fontSize: 20, color: color),
                                      ),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: progressValue / 100,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  );
                                },
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),

                  // Camera Detections
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Detected Food:',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        if (_detections.isEmpty)
                          const Text('No detections')
                        else
                          FadeIn(
                            duration: const Duration(milliseconds: 500),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _detections.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final detection = _detections[index];
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          detection.isSpoiled ? Icons.warning : Icons.check,
                                          color: detection.isSpoiled ? Colors.red : Colors.green,
                                          size: 32,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detection.label,
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              //Text(
                                              // 'Freshness: ${detection.freshness}',
                                              // style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
                                              //),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Food Status
                  Container(
                    margin: const EdgeInsets.only(top: 20, bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Food Status:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _foodStatus,
                          style: TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: _foodStatus == 'SPOILED' ? Colors.red : Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),

                  // Buttons
                  SingleChildScrollView(
                    child: Center(
                      child: AnimatedScale(
                        alignment: Alignment.center,
                        scale: _isLoading ? 0.95 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _detectFreshness,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                            ),
                            elevation: 5.0,
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedOpacity(
                                opacity: _isLoading ? 0.0 : 1.0,
                                duration: const Duration(milliseconds: 200),
                                child: const Text(
                                  'Check Freshness',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 24.0,
                                  height: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            )



          ],
        ),

      ),

    );
  }
}

