import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const IconData kFreezeIcon = Icons.ac_unit;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Spoilage Detector',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _temperature = '';
  String _humidity = '';
  bool _isLoading = false;
  String _foodStatus = '';
  String _currentTime = '';
  String _gasSensor = '';

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now().toString();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=London&appid=f596234f7b2eb18b4a28194da7d158a4&units=metric'));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final temperature = jsonData['main']['temp'];
        final humidity = jsonData['main']['humidity'];

        setState(() {
          _temperature = '$temperature°C';
          _humidity = '$humidity%';

          if (temperature < 10 && humidity < 60) {
            _foodStatus = 'It is fresh';
          } else {
            _foodStatus = 'It is spoilt';
          }

          if (temperature > 20) {
            _gasSensor = 'Gas Sensor: High';
          } else {
            _gasSensor = 'Gas Sensor: Low';
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
     // print(error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Spoilage Detector'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Date and Time: $_currentTime',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Food Spoilage Detector',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                      children: [
                        const Text(
                          'Temperature:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _temperature,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Humidity:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _humidity,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Gas Sensor:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _gasSensor,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'The Detected Food Is:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _foodStatus,
                          style: TextStyle(fontSize: 20, color: _foodStatus == 'It is fresh'? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Check Food Spoilage'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FoodStorageTips()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Food Storage Tips'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>const UpcomingExpirationsList()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Upcoming Expirations'),
            ),
          ],
        ),
      ),
    );
  }
}

class FoodStorageTips extends StatelessWidget {
  const FoodStorageTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Storage Tips'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.grey[200],
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0,3),
                  ),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Refrigerate Properly',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Keep your refrigerator at the optimal temperature (below 40°F) to extend the shelf life of your food.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
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
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Freeze for Longer Storage',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Freeze items you wont use right away to prevent spoilage. Proper freezing can keep food fresh for months.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
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
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Check Expiration Dates',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Always check the expiration dates on your food and use items before they go bad.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpcomingExpirationsList extends StatelessWidget {
  const UpcomingExpirationsList({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> foods = [
      {'name': 'Apple', 'expiryDate': '2021-09-25'},
      {'name': 'Orange', 'expiryDate': '2021-08-12'},
      {'name': 'Milk', 'expiryDate': '2021-07-10'},
      {'name': 'Eggs', 'expiryDate': '2021-07-15'},
      {'name': 'Pasta', 'expiryDate': '2021-07-01'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Expirations'),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: foods.length,
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white,
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: const Icon(kFreezeIcon),
              title: Text(foods[index]['name']),
              subtitle: Text('Expires on: ${foods[index]['expiryDate']}'),
            ),
          );
        },
      ),
    );
  }
}

class StorageInfo extends StatelessWidget {
  const StorageInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Information'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: const [
           Card(
            color: Colors.white,
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(Icons.add_circle),
              title: Text('Fridge'),
              subtitle: Text('For items that need to be kept cold.'),
            ),
          ),
           Card(
            color: Colors.white,
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(kFreezeIcon),
              title: Text('Freezer'),
              subtitle: Text('For items that need to be kept frozen.'),
            ),
          ),
           Card(
            color: Colors.white,
            margin: EdgeInsets.all(10),
            child: ListTile(
              leading: Icon(Icons.timer),
              title: Text('Expiration Dates'),
              subtitle: Text('Keep track of when your food items will expire.'),
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeCards extends StatelessWidget {
  const RecipeCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        backgroundColor: Colors.blue,
      ),
      body: GridView.builder(
        itemCount: 5,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 3 / 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          return Card(
            color: Colors.white,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://source.unsplash.com/random?food',
                  width: 100,
                  height: 100,
                ),
                Text('Recipe ${index + 1}'),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.blue,
      ),
      body: const SingleChildScrollView(
        child: Column(
          children: [
            BannerButton('FoodStorage Tips',  FoodStorageTips()),
            BannerButton('Upcoming Expirations', UpcomingExpirationsList()),
            BannerButton('Storage Information', StorageInfo()),
            BannerButton('Recipes', RecipeCards()),
          ],
        ),
      ),
    );
  }
}

class BannerButton extends StatelessWidget {
  final String _title;
  final Widget _destination;

  const BannerButton(this._title, this._destination, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => _destination));
        },
        child: Text(_title),
      ),
    );
  }
}
