// lib/widgets/profile_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileForm extends StatefulWidget {
  final String? initialName;
  final String? initialBio;
  final String? initialImageUrl;
  final Future<void> Function(String name, String bio, File? image) onSave;

  ProfileForm({
    this.initialName,
    this.initialBio,
    this.initialImageUrl,
    required this.onSave,
  });

  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late TextEditingController nameController;
  late TextEditingController bioController;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    bioController = TextEditingController(text: widget.initialBio ?? '');
  }

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  Future<void> save() async {
    setState(() => _isLoading = true);
    await widget.onSave(nameController.text.trim(), bioController.text.trim(), _profileImage);
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: pickImage,
          child: CircleAvatar(
            radius: 50,
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty)
                ? NetworkImage(widget.initialImageUrl!) as ImageProvider
                : null,
            child: (_profileImage == null &&
                (widget.initialImageUrl == null || widget.initialImageUrl!.isEmpty))
                ? Icon(Icons.add_a_photo, size: 50)
                : null,
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: 'Name'),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(labelText: 'Bio'),
        ),
        SizedBox(height: 20),
        _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(onPressed: save, child: Text('Save')),
      ],
    );
  }
}
