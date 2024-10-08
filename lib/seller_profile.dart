import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DocumentSnapshot? _userData;
  double _profileCompletion = 0.0; // Initialize profile completion to 0%

  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';

        final snapshot =
            await _firestore.collection('users').doc(user.uid).get();
        if (snapshot.exists) {
          _userData = snapshot;

          Map<String, dynamic>? userData =
              _userData?.data() as Map<String, dynamic>?;
          _nameController.text =
              userData != null && userData.containsKey('name')
                  ? userData['name']
                  : '';
          _phoneController.text =
              userData != null && userData.containsKey('phone')
                  ? userData['phone']
                  : '';
        } else {
          await _firestore.collection('users').doc(user.uid).set({
            'name': '',
            'phone': '',
          });
        }
        _calculateProfileCompletion(); // Calculate completion after fetching data
      }
    } catch (e) {
      print('Error fetching user details: $e');
    } finally {
      setState(() {});
    }
  }

  void _calculateProfileCompletion() {
    int totalFields = 3; // Assuming 3 fields (email is pre-filled)
    int filledFields = 1; // email is pre-filled
    if (_nameController.text.isNotEmpty) filledFields++;
    if (_phoneController.text.isNotEmpty) filledFields++;

    _profileCompletion = (filledFields / totalFields) * 100.0;
    setState(() {});
  }

  Future<void> _saveUserDetails() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
        }, SetOptions(merge: true)); // Merge: update only provided fields
        setState(() {
          _isEditing = false;
          _calculateProfileCompletion(); // Recalculate completion after saving
        });
      }
    } catch (e) {
      print('Error saving user details: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Widget _buildUserDetailsContent() {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Column(
        children: [
          // Display profile completion percentage
          Text(
            'Profile Completion: ${_profileCompletion.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: _profileCompletion / 100.0,
              valueColor: AlwaysStoppedAnimation(Colors.green), // Green color
              backgroundColor: Colors.grey.shade200, // Light gray background
              minHeight: 10.0, // Adjust height as needed
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            readOnly: !_isEditing,
            decoration: InputDecoration(
              labelText: 'Name',
              border: const OutlineInputBorder(),
              suffixIcon: _isEditing ? const Icon(Icons.edit) : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            readOnly: !_isEditing,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              border: const OutlineInputBorder(),
              suffixIcon: _isEditing ? const Icon(Icons.edit) : null,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveUserDetails();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildUserDetailsContent(),
      ),
    );
  }
}
