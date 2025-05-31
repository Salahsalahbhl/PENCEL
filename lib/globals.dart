import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

class ExerciseScreen extends StatefulWidget {
  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final supabase = Supabase.instance.client;
  int secondsLeft = 0;
  int pointsEarned = 0;
  bool timerActive = true;
  late Timer _timer;
  String? fileUrl;
  String? fileType;
  String? correctAnswer;
  List<String> options = [];
  int correctAnswerIndex = 0;
  int timeLimit = 90;

  @override
  void initState() {
    super.initState();
    loadExercise();
  }

  Future<void> loadExercise() async {
    final response = await supabase
        .from('exercises')
        .select()
        .order('created_at', ascending: false)
        .limit(1)
        .single();

    setState(() {
      fileUrl = response['file_url'];
      fileType = response['file_type'];
      correctAnswer = response['correct_answer'];
      timeLimit = response['time_limit'] ?? 90;
      secondsLeft = timeLimit;
      
      
      options = (response['wrong_answers'] as String).split(',');
      options.add(correctAnswer!);
      options.shuffle();
      correctAnswerIndex = options.indexOf(correctAnswer!);
      
      startTimer();
    });
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (secondsLeft > 0 && timerActive) {
        setState(() {
          secondsLeft--;
        });
      } else {
        _timer.cancel();
        endGame(-10, "انتهى الوقت! حاول مرة أخرى", "-10");
      }
    });
  }

  void endGame(int points, String message, String pointsText) {
    if (!timerActive) return;

    setState(() {
      pointsEarned += points;
      timerActive = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purple, 
                borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(pointsText, 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Icon(Icons.emoji_events, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, pointsEarned);
            },
            child: Text("حاول مجدداً", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void checkAnswer(int selectedIndex) {
    if (!timerActive) return;
    
    if (selectedIndex == correctAnswerIndex) {
      endGame(10, "إجابة صحيحة! أحسنت", "+10");
    } else {
      endGame(-10, "إجابة خاطئة! حاول مرة أخرى", "-10");
    }
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildExerciseContent() {
    if (fileType == 'txt') {
      return FutureBuilder<String>(
        future: http.read(Uri.parse(fileUrl!)),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(
              snapshot.data!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            );
          }
          return CircularProgressIndicator();
        },
      );
    } else if (fileType == 'jpg' || fileType == 'jfif' || fileType == 'png') {
      return Image.network(fileUrl!);
    } else {
      return Text(
        'نوع الملف غير مدعوم',
        style: TextStyle(fontSize: 24, color: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8A89C0),
      body: SafeArea(
        child: Column(
          children: [
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      formatTime(secondsLeft),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF0D47A1),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'النقاط: $pointsEarned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            
            
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3)),
                      ],
                    ),
                    child: _buildExerciseContent(),
                  ),
                ),
              ),
            ),
            
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: List.generate(options.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GestureDetector(
                      onTap: () => checkAnswer(index),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Color(0xFF0D47A1),
                          borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          options[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => loadExercise(),
        child: Icon(Icons.refresh),
        backgroundColor: Color(0xFF0D47A1),
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}