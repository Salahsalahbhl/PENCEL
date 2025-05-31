import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pp1/ExerciseScreen.dart';
import 'package:pp1/book.dart';
import 'package:pp1/list.dart';
import 'package:pp1/profile.dart';
import 'package:pp1/signup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

ValueNotifier<int> pointsNotifier = ValueNotifier<int>(0);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://gampklucybngozktedaz.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdhbXBrbHVjeWJuZ296a3RlZGF6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1OTM1MjAsImV4cCI6MjA2MTE2OTUyMH0.k6LgtWidSaPfuAdpJriiB8IxgP98QnlkT7v56CLGTPw",
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SignUpPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, int> _currentFileIndices = {
    'اجتماعيات': 1,
    'ت.إسلامية': 1,
    'علوم طبيعة': 1,
    'فيزياء': 1,
  };
  final Map<String, DateTime?> _fileDisplayTimes = {};
  final Map<String, Timer?> _fileTimers = {};

  @override
  void dispose() {
    _fileTimers.forEach((_, timer) => timer?.cancel());
    super.dispose();
  }

  void updateScore(int pointsEarned) {
    pointsNotifier.value = (pointsNotifier.value + pointsEarned).clamp(0, 9000);
  }

  Future<void> _showCurrentFile(BuildContext context, String category) async {
    final fileIndex = _currentFileIndices[category]!;
    final prefix = _getCategoryPrefix(category);
    final ext = category == 'فيزياء' ? 'jfif' : 'txt';
    final fileName = '$fileIndex$prefix.$ext';

    try {
      final response = await Supabase.instance.client
          .storage
          .from('reviser')
          .download(fileName);

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لا يوجد ملفات أخرى متاحة')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response, flush: true);

      if (!mounted) return;

      if (ext == 'txt') {
        final content = await file.readAsString();
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(category),
            content: SingleChildScrollView(child: Text(content)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      } else {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(category),
            content: Image.file(file),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('موافق'),
              ),
            ],
          ),
        );
      }

      _fileDisplayTimes[category] = DateTime.now();
      
      _fileTimers[category]?.cancel();
      _fileTimers[category] = Timer(Duration(minutes: 2), () {
        if (mounted) {
          setState(() {
            _currentFileIndices[category] = _currentFileIndices[category]! + 1;
          });
        }
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل في تحميل الملف: ${e.toString()}')),
      );
    }
  }

  void _handleCategoryPress(BuildContext context, String category) {
    final now = DateTime.now();
    final lastDisplayTime = _fileDisplayTimes[category];
    
    if (lastDisplayTime == null || now.difference(lastDisplayTime) < Duration(minutes: 2)) {
      _showCurrentFile(context, category);
      return;
    }
    
    _showCurrentFile(context, category);
  }

  String _getCategoryPrefix(String category) {
    return {
      'اجتماعيات': 'h',
      'ت.إسلامية': 'i',
      'علوم طبيعة': 's',
      'فيزياء': 'p',
    }[category]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8A89C0),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CoursesPage()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ListPage()));
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: ''),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: pointsNotifier,
                    builder: (context, value, child) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0xFF0D47A1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '$value',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.emoji_events, color: Colors.white),
                          ],
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.help_outline, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => CoursesPage()));
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book, size: 60, color: Color(0xFF0D47A1)),
                          SizedBox(height: 10),
                          Text(
                            'الدروس',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: 200,
                    height: 70,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D47A1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ExerciseScreen()),
                        );
                        if (result != null && result is int) {
                          updateScore(result);
                        }
                      },
                      child: Text(
                        'ابدأ التحدي',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildCategoryButton('اجتماعيات', Color(0xFF0D47A1)),
                  _buildCategoryButton('ت.إسلامية', Color(0xFF1A237E)),
                  _buildCategoryButton('علوم طبيعة', Color(0xFF283593)),
                  _buildCategoryButton('فيزياء', Color(0xFF303F9F)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(String text, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: () {
        _handleCategoryPress(context, text);
      },
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
