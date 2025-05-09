import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea( // 👈 Wrap with SafeArea
        child: Column(
          children: [
            Container(
              color: Colors.deepPurple,
              height: 80,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const Text(
                'LifeSync',
                style: TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.check_box),
                    title: const Text('Task Manager'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/tasks'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.track_changes),
                    title: const Text('Habit Tracker'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/habits'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.monitor_heart_outlined),
                    title: const Text('Digital Wellbeing'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/mood'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.center_focus_strong),
                    title: const Text('Focus'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/focus'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("Edit Profile"),
                    onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Logout'),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut(); // Actually log out
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false); // Clear backstack
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}