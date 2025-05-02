import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditableProfileScreen extends StatefulWidget {
  final VoidCallback onProfileUpdated;  // Add the onProfileUpdated callback

  const EditableProfileScreen({super.key, required this.onProfileUpdated});  // Ensure to receive it in the constructor

  @override
  _EditableProfileScreenState createState() => _EditableProfileScreenState();
}

class _EditableProfileScreenState extends State<EditableProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _username;
  String? _email;
  
  String _selectedGender = 'Male'; // Default gender
  DateTime? _selectedDob;
  TextEditingController _dobController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _username = user.displayName;
      _email = user.email;
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
          if (data['dob'] != null && data['dob'] is Timestamp) {
            _selectedDob = (data['dob'] as Timestamp).toDate();
            _dobController.text = DateFormat('dd/MM/yyyy').format(_selectedDob!);
          }
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update Firebase Auth profile (username, email)
        await user.updateProfile(displayName: _username);

        // Update email if needed
        if (_email != user.email) {
          await user.updateEmail(_email!);
        }

        // Update Firestore with gender and date of birth
        await _firestore.collection('users').doc(user.uid).update({
          'fullName': _username,
          'dob': Timestamp.fromDate(_selectedDob!),
          'gender': _selectedGender,
        });

        // Notify the HomeScreen that profile has been updated
        widget.onProfileUpdated();  // This triggers the callback from HomeScreen

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
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full Name field
            TextFormField(
              initialValue: _username,
              decoration: const InputDecoration(labelText: 'Full Name'),
              onChanged: (value) {
                _username = value;
              },
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              initialValue: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (value) {
                _email = value;
              },
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
    );
  }
}
