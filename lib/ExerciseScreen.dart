import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class ExerciseScreen extends StatefulWidget {
  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> with WidgetsBindingObserver {
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
  bool isLoading = true;
  String? errorMessage;
  DateTime? _backgroundTime;
  DateTime? _foregroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadExercise();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // التطبيق ذهب إلى الخلفية
      _backgroundTime = DateTime.now();
      _timer.cancel();
    } else if (state == AppLifecycleState.resumed && _backgroundTime != null) {
      // التطبيق عاد إلى الواجهة الأمامية
      _foregroundTime = DateTime.now();
      final duration = _foregroundTime!.difference(_backgroundTime!);
      if (secondsLeft > duration.inSeconds) {
        secondsLeft -= duration.inSeconds;
      } else {
        secondsLeft = 0;
      }
      if (timerActive && secondsLeft > 0) {
        startTimer();
      }
    }
  }

  Future<void> loadExercise() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await supabase
          .from('exercises')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      setState(() {
        fileUrl = response['file_url'];
        fileType = _getFileType(fileUrl);
        correctAnswer = response['correct_answer'];
        timeLimit = response['time_limit'] ?? 90;
        secondsLeft = timeLimit;
        
        options = (response['wrong_answers'] as String).split(',');
        options.add(correctAnswer!);
        options.shuffle();
        correctAnswerIndex = options.indexOf(correctAnswer!);
        
        isLoading = false;
        startTimer();
      });
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ في تحميل التمرين: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  String _getFileType(String? url) {
    if (url == null) return 'unknown';
    final uri = Uri.tryParse(url);
    if (uri == null) return 'unknown';
    
    final path = uri.path.toLowerCase();
    if (path.endsWith('.pdf')) return 'pdf';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image';
    if (path.endsWith('.png')) return 'image';
    if (path.endsWith('.txt')) return 'text';
    if (path.endsWith('.doc') || path.endsWith('.docx')) return 'doc';
    
    return 'unknown';
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
    if (isLoading) return Center(child: CircularProgressIndicator());
    if (errorMessage != null) return Center(child: Text(errorMessage!));
    if (fileUrl == null) return Center(child: Text('لا يوجد ملف متاح'));

    switch (fileType) {
      case 'pdf':
        return _buildPdfViewer();
      case 'image':
        return _buildImageViewer();
      case 'text':
        return _buildTextViewer();
      case 'doc':
        return _buildDocViewer();
      default:
        return _buildGenericViewer();
    }
  }

  Widget _buildPdfViewer() {
    return InteractiveViewer(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, size: 60, color: Colors.red),
            SizedBox(height: 16),
            Text('ملف PDF', style: TextStyle(fontSize: 20)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _launchUrl(fileUrl!),
              child: Text('فتح الملف'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      boundaryMargin: EdgeInsets.all(20),
      minScale: 0.1,
      maxScale: 4.0,
      child: Image.network(
        fileUrl!,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(child: Text('تعذر تحميل الصورة'));
        },
      ),
    );
  }

  Widget _buildTextViewer() {
    return FutureBuilder<String>(
      future: http.read(Uri.parse(fileUrl!)),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Text(
              snapshot.data!,
              style: TextStyle(fontSize: 18),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('تعذر تحميل النص'));
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildDocViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 60, color: Colors.blue),
          SizedBox(height: 16),
          Text('ملف وثيقة', style: TextStyle(fontSize: 20)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _launchUrl(fileUrl!),
            child: Text('فتح الملف'),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text('اضغط للانتقال الى الملف', style: TextStyle(fontSize: 20)),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _launchUrl(fileUrl!),
            child: Text('فتح الملف'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر فتح الرابط')),
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
        onPressed: loadExercise,
        child: Icon(Icons.refresh),
        backgroundColor: Color(0xFF0D47A1),
      ),
    );
  }
}