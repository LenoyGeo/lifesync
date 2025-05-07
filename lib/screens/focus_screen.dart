import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/custom_drawer.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({Key? key}) : super(key: key);

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  late Timer _timer;
  int _remainingSeconds = 1500; // Default to 25 mins
  bool _isRunning = false;
  bool _isWorkSession = true;

  int _workDuration = 1500; // Default work duration in seconds
  int _breakDuration = 300; // Default break duration (5 mins)
  int _completedSessions = 0;
  Duration _totalFocusedTime = Duration(); // Total focused time in Duration

  final TextEditingController _hourController = TextEditingController(); // TextField for hour input
  final TextEditingController _minuteController = TextEditingController(); // TextField for minute input
  final TextEditingController _breakHourController = TextEditingController(); // Break hour input
  final TextEditingController _breakMinuteController = TextEditingController(); // Break minute input

  // Start the timer
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _showSessionCompleteDialog();
        setState(() {
          if (_isWorkSession) {
            _completedSessions++;
            _totalFocusedTime += Duration(seconds: _workDuration - _remainingSeconds);
          }
          _isWorkSession = !_isWorkSession;
          _remainingSeconds = _isWorkSession ? _workDuration : _breakDuration;
          _isRunning = false;
        });
      }
    });
    setState(() {
      _isRunning = true;
    });
  }

  // Pause timer
  void _pauseTimer() {
    _timer.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  // Reset timer
  void _resetTimer() {
    _timer.cancel();
    setState(() {
      _remainingSeconds = _isWorkSession ? _workDuration : _breakDuration;
      _isRunning = false;
    });
  }

  // Format seconds to HH:MM
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  // Set custom work duration
  // Set custom work duration
  void _setCustomWorkDuration() {
    int hours = int.tryParse(_hourController.text) ?? 0;
    int minutes = int.tryParse(_minuteController.text) ?? 0;

    // Validate minute input (ensure it doesn't exceed 59)
    if (minutes > 59) {
      // If minutes exceed 59, show an alert or reset the minute input to 59
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minutes must be between 0 and 59')),
      );
      _minuteController.text = '59'; // Reset to 59 if the value exceeds 59
      return;
    }

    int totalSeconds = (hours * 3600) + (minutes * 60);
    if (totalSeconds > 0) {
      setState(() {
        _workDuration = totalSeconds;
        _remainingSeconds = totalSeconds;
        _isWorkSession = true;
        _isRunning = false;
      });
    }
  }

  // Set custom break duration
  void _setCustomBreakDuration() {
    int hours = int.tryParse(_breakHourController.text) ?? 0;
    int minutes = int.tryParse(_breakMinuteController.text) ?? 0;

    // Validate minute input (ensure it doesn't exceed 59)
    if (minutes > 59) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minutes must be between 0 and 59')),
      );
      _breakMinuteController.text = '59'; // Reset to 59 if the value exceeds 59
      return;
    }

    int totalSeconds = (hours * 3600) + (minutes * 60);
    if (totalSeconds > 0) {
      setState(() {
        _breakDuration = totalSeconds;
      });
    }
  }

  // Dialog when session completes
  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Session Complete!"),
        content: Text(_isWorkSession
            ? "Break over. Let's get back to focus."
            : "Great job! Time for a break."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startTimer();
            },
            child: const Text("Start Next"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Later"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isRunning) _timer.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    _breakHourController.dispose();
    _breakMinuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_isWorkSession
            ? (_workDuration - _remainingSeconds) / _workDuration
            : (_breakDuration - _remainingSeconds) / _breakDuration)
        .clamp(0.0, 1.0); // Clamp to avoid overflow

    // Total time spent
    String totalTimeSpent = _formatTime(_totalFocusedTime.inSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Focus Mode"),
        centerTitle: true,
      ),
      drawer: const CustomDrawer(),
      body: SingleChildScrollView( // Wrap the whole body in a SingleChildScrollView
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Set Focus Time",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _hourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Hours"),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _minuteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Minutes"),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _setCustomWorkDuration,
                  child: const Text("Set Work"),
                ),
              ],
            ), // ✅ Custom work duration input fields
            const SizedBox(height: 20),
            const Text(
              "Set Break Time",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _breakHourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Hours"),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _breakMinuteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Minutes"),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _setCustomBreakDuration,
                  child: const Text("Set Break"),
                ),
              ],
            ), // ✅ Custom break duration input fields
            const SizedBox(height: 20),
            const Text(
              "Preset Focus Sessions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workDuration = 25 * 60;
                      _breakDuration = 5 * 60;
                      _remainingSeconds = _workDuration;
                      _isWorkSession = true;
                      _isRunning = false;
                    });
                  },
                  child: const Text("Pomodoro"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workDuration = 15 * 60;
                      _breakDuration = 3 * 60;
                      _remainingSeconds = _workDuration;
                      _isWorkSession = true;
                      _isRunning = false;
                    });
                  },
                  child: const Text("Short Focus"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workDuration = 50 * 60;
                      _breakDuration = 10 * 60;
                      _remainingSeconds = _workDuration;
                      _isWorkSession = true;
                      _isRunning = false;
                    });
                  },
                  child: const Text("Deep Focus"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              _isWorkSession ? "Focus Session" : "Break Time", // ✅ Show current session type
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: progress, // ✅ Circular progress indicator
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>( 
                        _isWorkSession ? Colors.green : Colors.blue),
                  ),
                ),
                Text(
                                    _formatTime(_remainingSeconds), // ✅ Display formatted remaining time
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  child: Text(_isRunning ? "Pause" : "Start"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetTimer,
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "Total Time Focused: $totalTimeSpent", // ✅ Display total time spent
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 30),
            const Text(
              "Completed Sessions: ",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              '$_completedSessions',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text(
              "Focus Calendar:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            // Calendar or Focus log can be added here in the future
            const SizedBox(height: 20),
            // Example of displaying the total time spent for today (just for the sake of simplicity):
            Text(
              'Time Spent Today: $totalTimeSpent',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

