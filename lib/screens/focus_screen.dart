import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_drawer.dart';
import 'package:table_calendar/table_calendar.dart';

class FocusScreen extends StatefulWidget {
  @override
  _FocusScreenState createState() => _FocusScreenState();
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
  final ValueNotifier<List<Event>> _selectedEvents = ValueNotifier<List<Event>>([]);

  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  late String _userId;

  // Calendar state
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Sample events for demonstration
  final List<Event> _allEvents = [
    // Event(DateTime(2025, 5, 8), 1500),  // Example event (Focused time in seconds)
    // Event(DateTime(2025, 5, 9), 1800),
    // Add more events as needed
  ];

  List<Event> _getEventsForDay(DateTime day) {
    return _allEvents
        .where((event) =>
            event.date.year == day.year &&
            event.date.month == day.month &&
            event.date.day == day.day)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _userId = _user.uid;
    _focusedDay = DateTime.now(); // Initialize focusedDay to the current day
    _selectedDay = _focusedDay; // Initialize selectedDay to focusedDay
  }

  @override
  void dispose() {
    _selectedEvents.dispose(); // Dispose of ValueNotifier
    if (_isRunning) _timer.cancel(); // Cancel timer if running
    _hourController.dispose();
    _minuteController.dispose();
    _breakHourController.dispose();
    _breakMinuteController.dispose();
    super.dispose();
  }

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
            _storeFocusTimeToFirebase();
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

  // Format seconds to HH:MM:SS
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60; // Calculate remaining seconds
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Set custom work duration
  void _setCustomWorkDuration() {
    int hours = int.tryParse(_hourController.text) ?? 0;
    int minutes = int.tryParse(_minuteController.text) ?? 0;

    // Validate minute input (ensure it doesn't exceed 59)
    if (minutes > 59) {
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

  // Store Focus Time in Firebase
  Future<void> _storeFocusTimeToFirebase() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(_userId).collection('focus_sessions').add({
        'date': DateTime.now(),
        'focused_time': _totalFocusedTime.inSeconds,
      });
    } catch (e) {
      print("Error storing focus time: $e");
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
      body: SingleChildScrollView(
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
                  child: const Text("Set"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _breakHourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Break Hours"),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _breakMinuteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Break Minutes"),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _setCustomBreakDuration,
                  child: const Text("Set Break"),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(
                      _isWorkSession ? Colors.blue : Colors.green,
                    ),
                  )
                ),
                Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(
                    _isRunning ? Icons.pause : Icons.play_arrow,
                    size: 40,
                  ),
                ),
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh, size: 40),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Total Focus Time: $totalTimeSpent",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TableCalendar(
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedEvents.value = _getEventsForDay(selectedDay);
                });
              },
              eventLoader: _getEventsForDay,
              firstDay: DateTime.utc(2000, 1, 1),  // Starting date of the calendar
              lastDay: DateTime.utc(2100, 1, 1),   // Ending date of the calendar
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<List<Event>>(
              valueListenable: _selectedEvents,
              builder: (context, events, _) {
                return ListView(
                  shrinkWrap: true,
                  children: events
                      .map(
                        (event) => ListTile(
                          title: Text("Focus time: ${_formatTime(event.focusedTime)}"),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final DateTime date;
  final int focusedTime;

  Event(this.date, this.focusedTime);
}
