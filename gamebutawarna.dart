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
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int level = 1;
  int score = 0;
  int highScore = 0; // Variabel untuk menyimpan skor tertinggi
  late Color targetColor;
  late Color oddColor;
  int gridSize = 2;
  late int oddBoxIndex;

  @override
  void initState() {
    super.initState();
    _loadHighScore(); // Memuat skor tertinggi saat aplikasi dimulai
    _generateLevel();
  }

  void _loadHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0; // Mengambil skor tertinggi dari SharedPreferences
    });
  }

  void _saveHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (score > highScore) {
      highScore = score; // Update highScore jika skor saat ini lebih tinggi
      await prefs.setInt('highScore', highScore); // Simpan skor tertinggi
    }
  }

  void _generateLevel() {
    gridSize = (2 + (level ~/ 3)).clamp(2, 10);
    
    Random random = Random();
    
    targetColor = Colors.primaries[random.nextInt(Colors.primaries.length)];
    
    oddColor = Color.fromARGB(
      targetColor.alpha,
      (targetColor.red + random.nextInt(60) - 15).clamp(0, 255),
      (targetColor.green + random.nextInt(60) - 15).clamp(0, 255),
      (targetColor.blue + random.nextInt(60) - 15).clamp(0, 255),
    );
    
    oddBoxIndex = random.nextInt(gridSize * gridSize);
    setState(() {});
  }

  void _checkAnswer(int index) {
    if (index == oddBoxIndex) {
      setState(() {
        score += 10;
        level++;
        _generateLevel();
      });
    } else {
      _saveHighScore(); // Simpan skor tertinggi saat salah
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Salah!"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Anda akan mulai dari Level 1."),
                const SizedBox(height: 10),
                Text(
                  "Warna yang benar adalah:",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 50,
                  height: 50,
                  color: oddColor, // Tampilkan warna yang benar
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Reset level dan score ke awal
                  setState(() {
                    level = 1;
                    score = 0;
                    _generateLevel();
                  });
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Game Buta Warna"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Level: $level", style: const TextStyle(fontSize: 24)),
          Text("Score: $score", style: const TextStyle(fontSize: 24)),
          Text("High Score: $highScore", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
              ),
              itemCount: gridSize * gridSize,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _checkAnswer(index),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    color: index == oddBoxIndex ? oddColor : targetColor,
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
