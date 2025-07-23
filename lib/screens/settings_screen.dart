import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final String currentEmergencyMessage;
  final Function(String) onMessageChanged;
  final Function(String?) onProfilePictureChanged;
  final String? currentProfileImagePath;
  final VoidCallback onSignOut;
  final String currentUserName;
  final Function(String) onNameChanged;

  const SettingsScreen({
    super.key,
    required this.currentEmergencyMessage,
    required this.onMessageChanged,
    required this.onProfilePictureChanged,
    required this.currentProfileImagePath,
    required this.onSignOut,
    required this.currentUserName,
    required this.onNameChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _messageController;
  late TextEditingController _nameController;
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.currentEmergencyMessage,
    );
    _nameController = TextEditingController(
      text: widget.currentUserName,
    );
    _selectedImagePath = widget.currentProfileImagePath;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _saveMessage() {
    widget.onMessageChanged(_messageController.text);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Emergency message updated!')));
    FocusScope.of(context).unfocus();
  }

  void _saveName() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name cannot be empty!')));
      return;
    }
    widget.onNameChanged(_nameController.text.trim());
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Name updated!')));
    FocusScope.of(context).unfocus(); // Dismiss keyboard
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final localImage = await File(
        image.path,
      ).copy('${appDir.path}/$fileName.png');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', localImage.path);

      setState(() {
        _selectedImagePath = localImage.path;
      });
      widget.onProfilePictureChanged(localImage.path); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20.0,
          20.0,
          20.0,
          20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile Picture',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _selectedImagePath != null
                            ? FileImage(File(_selectedImagePath!))
                            : null,
                        child: _selectedImagePath == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Text('Change Profile Picture'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30), 

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Change Your Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Your Name'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                        child: const Text('Save Name'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30), 

            // Customize Emergency Message Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize Emergency Message',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'This message will be sent to your emergency contacts. Use "person name" for your name and "their coordinates" for your location. Default is "person name, their coordinates and I\'m in emergency".',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Message',
                        alignLabelWithHint: true,
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                        child: const Text('Save Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Sign Out Button
            Center(
              child: ElevatedButton.icon(
                onPressed: widget.onSignOut,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

