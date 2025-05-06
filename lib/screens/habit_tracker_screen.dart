import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../widgets/custom_drawer.dart';
import 'package:intl/intl.dart';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  final TextEditingController _habitController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _editingHabitId;
  bool _isUpdating = false;
  final DateTime _focusedDay = DateTime.now();
  Map<String, bool> showCalendarMap = {}; // Map to control visibility

  Future<void> _addOrUpdateHabit() async {
    String uid = _auth.currentUser!.uid;
    String habit = _habitController.text.trim();

    if (habit.isEmpty) return;

    final habitData = {
      'habit': habit,
      'createdAt': Timestamp.now(),
      'completedDates': [],
    };

    if (_isUpdating && _editingHabitId != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .doc(_editingHabitId)
          .update(habitData);
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('habits')
          .add(habitData);
    }

    _habitController.clear();
    setState(() {
      _isUpdating = false;
      _editingHabitId = null;
    });
  }

  Future<void> _toggleHabitCompletion(String docId, List completedDates) async {
    String uid = _auth.currentUser!.uid;
    final nowDate = DateTime.now();
    final today = DateTime(nowDate.year, nowDate.month, nowDate.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(today);  // Format the date to match

    final updatedDates = List<String>.from(completedDates);

    // Add or remove today's date in the completed dates list
    if (updatedDates.contains(todayStr)) {
      updatedDates.remove(todayStr);  // Mark undone
    } else {
      updatedDates.add(todayStr);  // Mark done
    }

    // Update Firestore with the new completedDates list
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('habits')
        .doc(docId)
        .update({'completedDates': updatedDates});

    // Rebuild the UI to reflect the updated state
    setState(() {});
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Habit"),
        content: const Text("Are you sure you want to delete this habit?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              String uid = _auth.currentUser!.uid;
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('habits')
                  .doc(docId)
                  .delete();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _startEditing(String docId, String habitName) {
    setState(() {
      _editingHabitId = docId;
      _habitController.text = habitName;
      _isUpdating = true;
    });
  }

  int calculateStreak(List<String> completedDates) {
    completedDates.sort((a, b) => b.compareTo(a));
    DateTime today = DateTime.now();
    int streak = 0;

    for (int i = 0; i < completedDates.length; i++) {
      DateTime date = DateTime.parse(completedDates[i]);
      DateTime compareDay = today.subtract(Duration(days: streak));
      if (DateTime(date.year, date.month, date.day) ==
          DateTime(compareDay.year, compareDay.month, compareDay.day)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  @override
  Widget build(BuildContext context) {
    String uid = _auth.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Habit Tracker")),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _habitController,
                    decoration: const InputDecoration(
                      labelText: 'Enter habit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addOrUpdateHabit,
                  child: Text(_isUpdating ? "Update" : "Add"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('habits')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final habits = snapshot.data!.docs;
                  if (habits.isEmpty) {
                    return const Center(child: Text("No habits added yet."));
                  }

                  return ListView.builder(
                    itemCount: habits.length,
                    itemBuilder: (context, index) {
                      final habitDoc = habits[index];
                      final habitData = habitDoc.data() as Map<String, dynamic>;
                      final completedDates = List<String>.from(habitData['completedDates'] ?? []);
                      final streak = calculateStreak(completedDates);
                      final habitName = habitData['habit'] ?? '';
                      final habitId = habitDoc.id;

                      final markedDays = {
                        for (var d in completedDates)
                          DateTime.parse(d): [const Event('Done')]
                      };

                      showCalendarMap.putIfAbsent(habitId, () => false);

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  habitName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text("Current streak: $streak day(s)"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        showCalendarMap[habitId]!
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          showCalendarMap[habitId] = !showCalendarMap[habitId]!;
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _startEditing(habitId, habitName),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showDeleteDialog(habitId),
                                    ),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                icon: Icon(
                                  completedDates.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      ? Icons.check_circle
                                      : Icons.check,
                                  color: completedDates.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      ? Colors.green
                                      : null,
                                ),
                                label: Text(
                                  completedDates.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      ? "Marked today as done"
                                      : "Mark today as done",
                                ),
                                onPressed: () => _toggleHabitCompletion(habitId, completedDates),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: completedDates.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                      ? Colors.green[100]
                                      : null,
                                ),
                              ),

                              if (showCalendarMap[habitId]!) ...[
                                const SizedBox(height: 10),
                                TableCalendar(
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  calendarFormat: CalendarFormat.month,
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    markerDecoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  eventLoader: (day) {
                                    return markedDays[DateTime(day.year, day.month, day.day)] ?? [];
                                  },
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
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

class Event {
  final String title;
  const Event(this.title);
}
