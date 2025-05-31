import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pp1/main.dart';
import 'package:pp1/book.dart';
import 'package:pp1/list.dart';
import 'package:pp1/signup.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = '';
  String userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userEmail = user.email ?? '';
      });

      try {
        
        final response = await Supabase.instance.client
            .from('profiles') 
            .select('full_name, email') 
            .eq('id', user.id) 
            .maybeSingle(); 

        if (response != null) {
          setState(() {
            userName = response['full_name'] ?? '';
            
            userEmail = response['email'] ?? user.email ?? '';
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  String _getUserLevel(int points) {
    if (points < 100) return 'مبتدئ';
    if (points < 200) return 'متوسط';
    if (points < 300) return 'متقدم';
    return 'محترف';
  }

  Color _getLevelColor(int points) {
    if (points < 100) return Colors.blue;
    if (points < 200) return Colors.green;
    if (points < 300) return Colors.orange;
    return Colors.red;
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('شرح التطبيق', textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHelpItem('1. الصفحة الرئيسية', 'هذه هي صفحتك الرئيسية حيث يمكنك الوصول إلى جميع الميزات'),
              SizedBox(height: 10),
              _buildHelpItem('2. الدروس', 'تحتوي على دروس تعليمية مقسمة حسب المستوى'),
              SizedBox(height: 10),
              _buildHelpItem('3. التحديات', 'اختبر معلوماتك وحصل على نقاط'),
              SizedBox(height: 10),
              _buildHelpItem('4. الملف الشخصي', 'عرض إحصائياتك وتقدمك في التطبيق'),
              SizedBox(height: 20),
              Text('كيفية كسب النقاط:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 5),
              Text('- كل إجابة صحيحة: +10 نقاط'),
              Text('- كل إجابة خاطئة: -10 نقاط'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('حسناً')),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تأكيد تسجيل الخروج'),
        content: Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('إلغاء')),
          TextButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => SignUpPage()),
                (Route<dynamic> route) => false,
              );
            },
            child: Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
        Text(description),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF8A89C0),
      appBar: AppBar(
        title: Text('الملف الشخصي'),
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: ValueListenableBuilder<int>(
        valueListenable: pointsNotifier,
        builder: (context, value, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/profile.png'),
                      backgroundColor: Colors.white,
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getLevelColor(value),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getUserLevel(value),
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.person, 'الإسم: ${userName.isNotEmpty ? userName : 'غير متوفر'}'),
                      Divider(),
                      _buildProfileItem(Icons.email, 'البريد الإلكتروني: ${userEmail.isNotEmpty ? userEmail : 'غير متوفر'}'),
                      Divider(),
                      _buildProfileItem(Icons.school, 'المستوى: ${_getUserLevel(value)}', valueColor: _getLevelColor(value)),
                      Divider(),
                      _buildProfileItem(Icons.emoji_events, 'النقاط: $value', valueColor: Color(0xFF0D47A1)),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      
                      Divider(),
                      _buildSettingsItem(Icons.help, 'المساعدة', () => _showHelpDialog(context)),
                      Divider(),
                      _buildSettingsItem(Icons.logout, 'تسجيل الخروج', () => _showLogoutConfirmation(context)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CoursesPage()));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ListPage()));
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: ''),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String text, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF0D47A1)),
          SizedBox(width: 15),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: text.split(':')[0] + ': ', style: TextStyle(fontSize: 16)),
                  TextSpan(
                    text: text.split(':').sublist(1).join(':'),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF0D47A1)),
      title: Text(text),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}