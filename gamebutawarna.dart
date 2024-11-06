import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

void main() {
  runApp(const ColorBlindnessGame());
}

class ColorBlindnessGame extends StatelessWidget {
  const ColorBlindnessGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  int level = 1;
  int score = 0;
  int highScore = 0;
  late Color targetColor;
  late Color oddColor;
  int gridSize = 2;
  late int oddBoxIndex;

  late AnimationController _animationController;
  bool _showHintAnimation = false;
  bool isClickable = true; // Menambah variabel untuk kontrol klik

  @override
  void initState() {
    super.initState();
    _loadHighScore();
    _generateLevel();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed && _showHintAnimation) {
          _animationController.forward();
        }
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score;
      await prefs.setInt('highScore', highScore);
    }
  }

  void _generateLevel() {
    gridSize = (2 + (level ~/ 3)).clamp(2, 10);
    Random random = Random();
    targetColor = Colors.primaries[random.nextInt(Colors.primaries.length)];
    oddColor = Color.fromARGB(
      targetColor.alpha,
      (targetColor.red + random.nextInt(80) - 15).clamp(0, 255),
      (targetColor.green + random.nextInt(80) - 15).clamp(0, 255),
      (targetColor.blue + random.nextInt(80) - 15).clamp(0, 255),
    );
    oddBoxIndex = random.nextInt(gridSize * gridSize);
    setState(() {});
  }

  void _checkAnswer(int index) {
    if (!isClickable) return; // Jika tidak bisa diklik, keluar dari fungsi

    if (index == oddBoxIndex) {
      setState(() {
        score += 10;
        level++;
        _generateLevel();
      });
    } else {
      _saveHighScore();
      int row = oddBoxIndex ~/ gridSize;
      int col = oddBoxIndex % gridSize;

      setState(() {
        _showHintAnimation = true;
        _animationController.forward();
        isClickable = false; // Blokir klik selama 3 detik
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Salah! Warna yang benar ada di baris ${row + 1}, kolom ${col + 1}.",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text("Mulai Ulang?"),
              content: const Text("Anda akan memulai kembali dari Level 1."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      level = 1;
                      score = 0;
                      _showHintAnimation = false;
                      _generateLevel();
                      isClickable = true; // Aktifkan kembali klik setelah reset
                    });
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Color Blindness Game"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal[100],
              borderRadius: BorderRadius.circular(10),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text("Level: $level", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Score: $score", style: const TextStyle(fontSize: 20)),
                Text("High Score: $highScore", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
              ),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    if (isClickable) _checkAnswer(index);
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      double scale = 1.0;
                      if (_showHintAnimation && index == oddBoxIndex) {
                        scale = 1 + _animationController.value * 0.3;
                      }
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: index == oddBoxIndex ? oddColor : targetColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                        ),
                      );
                    },
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
