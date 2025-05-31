import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pp1/book.dart';
import 'package:pp1/main.dart';
import 'package:pp1/profile.dart';


class Player {
  final String name;
  final int points;
  final bool isCurrentUser;

  Player({required this.name, required this.points, this.isCurrentUser = false});
}

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  bool isAnimating = false;
  Timer? _timer;
  int _lastAnimatedValue = -1;
  
  final List<Player> _players = [
    Player(name: "ahmad", points: 220),
    Player(name: "mohamed", points: 180),
    Player(name: "akram", points: 120),
    Player(name: "bilal", points: 100),
    Player(name: "yacine", points: 50),
    Player(name: "fares", points: 20),
    Player(name: "you", points: 0, isCurrentUser: true),
  ];

  @override
  void initState() {
    super.initState();
    pointsNotifier.addListener(_updateTreeAnimation);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateTreeAnimation();
    });
    _updateCurrentPlayerPoints();
  }

  void _updateCurrentPlayerPoints() {
    final currentUserIndex = _players.indexWhere((p) => p.isCurrentUser);
    if (currentUserIndex != -1) {
      setState(() {
        _players[currentUserIndex] = Player(
          name: "أنت",
          points: pointsNotifier.value,
          isCurrentUser: true
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    pointsNotifier.removeListener(_updateTreeAnimation);
    super.dispose();
  }

  void _updateTreeAnimation() {
    final currentValue = pointsNotifier.value;
    
    if (currentValue % 10 == 0 && currentValue > _lastAnimatedValue) {
      _lastAnimatedValue = currentValue;
      
      int animationSeconds;
      if (currentValue % 100 == 90) {
        animationSeconds = 18; 
      } else {
        animationSeconds = ((currentValue % 100) ~/ 10) * 2;
      }
      
      final animationDuration = Duration(seconds: animationSeconds);
      
      setState(() {
        isAnimating = true;
        _updateCurrentPlayerPoints();
      });

      _timer?.cancel();
      _timer = Timer(animationDuration, () {
        setState(() {
          isAnimating = false;
        });
      });
    }
  }

  bool _isActiveColumn(int currentPoints, int columnValue) {
    final rangeStart = (currentPoints ~/ 100) * 100;
    final rangeEnd = rangeStart + 100;
    return columnValue >= rangeStart && columnValue < rangeEnd;
  }

  @override
  Widget build(BuildContext context) {
    final currentPoints = pointsNotifier.value;
    final sortedPlayers = List<Player>.from(_players)
      ..sort((a, b) => b.points.compareTo(a.points));

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
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CoursesPage()),
            );
          }
          else if (index == 3) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfilePage()));
            
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.book, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.local_fire_department, size: 30), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person, size: 30), label: ''),
        ],
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: pointsNotifier,
            builder: (context, value, child) {
              return Positioned(
                left: 5,
                top: 50,
                child: TreeWidget(isAnimating: isAnimating),
              );
            },
          ),
          Positioned(
            left: 10,
            top: 50,
            bottom: 50,
            child: Column(
              children: List.generate(
                10,
                (index) {
                  final columnValue = (9 - index) * 100;
                  final isActive = _isActiveColumn(currentPoints, columnValue);
                  
                  return Expanded(
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        color: isActive ? const Color.fromARGB(255, 7, 189, 255) : Colors.blueAccent,
                        borderRadius: BorderRadius.circular(5),
                        border: isActive
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      margin: EdgeInsets.symmetric(vertical: 2),
                      padding: EdgeInsets.all(5),
                      child: Text(
                        '$columnValue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isActive ? Colors.black : Colors.white,
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 60,
            right: 30,
            child: PlayerList(players: sortedPlayers),
          ),
        ],
      ),
    );
  }
}

class PlayerList extends StatelessWidget {
  final List<Player> players;

  const PlayerList({required this.players});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 13, 35, 161),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "المركز",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "اللاعب",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "النقاط",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white),
          SizedBox(
            height: 150,
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  leading: Text(
                    "#${index + 1}",
                    style: TextStyle(
                      color: player.isCurrentUser ? Colors.amber : Colors.white,
                      fontWeight: player.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  title: Text(
                    player.name,
                    style: TextStyle(
                      color: player.isCurrentUser ? Colors.amber : Colors.white,
                      fontWeight: player.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: Text(
                    "${player.points}",
                    style: TextStyle(
                      color: player.isCurrentUser ? Colors.amber : Colors.grey[300],
                      fontWeight: player.isCurrentUser ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TreeWidget extends StatelessWidget {
  final bool isAnimating;

  TreeWidget({required this.isAnimating});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 450,
      child: Lottie.asset(
        'assets/tree.json',
        fit: BoxFit.contain,
        animate: isAnimating,
      ),
    );
  }
}