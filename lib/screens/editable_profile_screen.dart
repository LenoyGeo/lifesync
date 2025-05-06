import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';

class EditableProfileScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;

  const EditableProfileScreen({super.key, required this.onProfileUpdated});

  @override
  _EditableProfileScreenState createState() => _EditableProfileScreenState();
}

class _EditableProfileScreenState extends State<EditableProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _email;
  String? _usernameOnly;
  String _selectedGender = 'Male';
  DateTime? _selectedDob;

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _usernameOnlyController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _email = user.email;
      _emailController.text = _email!;
    }
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          _selectedGender = data['gender'] ?? 'Male';
          _usernameOnly = data['username'] ?? '';
          _usernameOnlyController.text = _usernameOnly!;
          _fullNameController.text = data['fullName'] ?? '';
          if (data['dob'] != null && data['dob'] is Timestamp) {
            _selectedDob = (data['dob'] as Timestamp).toDate();
            _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDob!);
          }
        });
      }
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return query.docs.any((doc) => doc.id != _auth.currentUser!.uid);
  }

  Future<void> _updateProfile() async {
    try {
      final user = _auth.currentUser;
      final username = _usernameOnlyController.text.trim();
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();

      if (user != null) {
        if (username.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username cannot be empty')),
          );
          return;
        }

        final isTaken = await _isUsernameTaken(username);
        if (isTaken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username is already taken')),
          );
          return;
        }

        await user.updateProfile(displayName: fullName);

        if (email != user.email) {
          await user.updateEmail(email);
        }

        await _firestore.collection('users').doc(user.uid).update({
          'fullName': fullName,
          'username': username,
          'dob': Timestamp.fromDate(_selectedDob!),
          'gender': _selectedGender,
        });

        widget.onProfileUpdated();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      drawer: const CustomDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username field
              TextFormField(
                controller: _usernameOnlyController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 16),

              // Full Name field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 16),

              // Date of Birth field
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Date of Birth (DD/MM/YYYY)'),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  DateTime initialDate = _selectedDob ?? DateTime(2000);
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDob = picked;
                      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Gender dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Save Changes button
              ElevatedButton(
                onPressed: _updateProfile,
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
