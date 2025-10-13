// lib/screens/profile_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:chatpal/widgets/profile_form.dart';
import 'home_screen.dart';
import 'dart:io';

class ProfileSetupScreen extends StatelessWidget {
  final String email;

  ProfileSetupScreen({required this.email});

  Future<void> saveProfile(String name, String bio, File? image, BuildContext context) async {
    String imageUrl = '';
    if (image != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('$email.jpg');
      await storageRef.putFile(image);
      imageUrl = await storageRef.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('db_user').doc(email).set({
      'name': name,
      'bio': bio,
      'profilePicture': imageUrl,
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ProfileForm(
          onSave: (name, bio, image) => saveProfile(name, bio, image, context),
        ),
      ),
    );
  }
}
