import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/broadcast/services/broadcast_service.dart';
import 'package:igit_connects/storage_backend.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _linkController = TextEditingController();
  
  String _selectedAudience = 'all';
  XFile? _selectedImage;
  bool _isLoading = false;

  final _broadcastService = BroadcastService();
  final _storageBackend = StorageBackend();

  final List<String> _audienceOptions = ['all', 'student', 'alumni', 'faculty'];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _storageBackend.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _publishBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _storageBackend.uploadBroadcastImage(_selectedImage!);
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      final createdBy = currentUser?.uid ?? 'admin';

      await _broadcastService.createBroadcast(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        audience: _selectedAudience,
        createdBy: createdBy,
        imageUrl: imageUrl,
        linkUrl: _linkController.text.trim().isNotEmpty ? _linkController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish: \$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text(
          'Create Broadcast',
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.primaryAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined, size: 48, color: colors.secondaryText),
                                  const SizedBox(height: 8),
                                  Text("Add Banner Image (Optional)", style: TextStyle(color: colors.secondaryText)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: colors.secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageController,
                      style: TextStyle(color: colors.primaryText),
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        labelStyle: TextStyle(color: colors.secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Message is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _linkController,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        labelText: 'External Link (Optional)',
                        labelStyle: TextStyle(color: colors.secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAudience,
                      dropdownColor: colors.cardColor,
                      style: TextStyle(color: colors.primaryText),
                      decoration: InputDecoration(
                        labelText: 'Audience',
                        labelStyle: TextStyle(color: colors.secondaryText),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _audienceOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAudience = newValue;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _publishBroadcast,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Publish Broadcast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
