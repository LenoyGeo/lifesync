import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';  // Import login screen for direct navigation
import 'editable_profile_screen.dart';  // Import the editable profile screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    // Define a default username to show
    // If user is not null, use displayName, else use email
    String displayName = user?.displayName ?? user?.email ?? "User";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
        actions: [
          // Logout IconButton
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign out the user
              await FirebaseAuth.instance.signOut();
              // Navigate back to login screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
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
                      // Reload the username here (you can trigger any action after profile update)
                      // Usually you would use a setState to update the HomeScreen's UI
                      // But here just for simplicity, we show a message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')),
                      );
                    },
                  ),
                ),
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
