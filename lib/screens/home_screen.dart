import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';  // Import login screen for direct navigation
import 'editable_profile_screen.dart';  // Import the editable profile screen
import 'task_manager_screen.dart';  // Import task manager screen for navigation

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    // Define a default username to show
    String displayName = user?.displayName ?? user?.email ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          // Profile Edit IconButton
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to the EditableProfileScreen when the icon is pressed
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditableProfileScreen(
                    // Pass the onProfileUpdated callback
                    onProfileUpdated: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          // Task Manager IconButton
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Task Manager',
            onPressed: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TaskManagerScreen(userId: user.uid),
                  ),
                );
              }
            },
          ),
          // Logout IconButton
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Welcome, $displayName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
