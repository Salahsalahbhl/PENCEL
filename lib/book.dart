import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pp1/list.dart';
import 'package:pp1/profile.dart';

class CoursesPage extends StatelessWidget {
  final Map<String, String> courseFiles = {
    "رياضيات": "assets/math.pdf",
    "إجتماعيات": "assets/social.pdf",
    "علوم طبيعية": "assets/science.pdf",
    "ت. اسلامية": "assets/islamic.pdf",
    "فلسفة": "assets/philosophy.pdf",
    "Français": "assets/french.pdf",
    "فيزياء": "assets/physics.pdf",
    "English": "assets/english.pdf",
    "العربية": "assets/arabic.pdf",
  };

  void openCourse(BuildContext context, String courseName) {
    String? filePath = courseFiles[courseName];

    if (filePath != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              CoursePdfViewer(courseName: courseName, pdfAssetPath: filePath),
        ),
      );
    }
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
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ListPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: ''),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "اختر مادة للتعلم",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.2,
                ),
                itemCount: courseFiles.keys.length,
                itemBuilder: (context, index) {
                  String courseName = courseFiles.keys.elementAt(index);
                  return InkWell(
                    onTap: () => openCourse(context, courseName),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF0D47A1),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          courseName,
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CoursePdfViewer extends StatelessWidget {
  final String courseName;
  final String pdfAssetPath;

  CoursePdfViewer({required this.courseName, required this.pdfAssetPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: Colors.blue,
      ),
      body: SfPdfViewer.asset(pdfAssetPath),
    );
  }
}
