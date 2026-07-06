import 'dart:io';

import 'package:flutter/material.dart';
import 'package:igit_connects/storage_backend.dart';
import 'package:image_picker/image_picker.dart';

class FacultyVerificationScreen extends StatefulWidget {
  const FacultyVerificationScreen({super.key});

  @override
  State<FacultyVerificationScreen> createState() =>
      _FacultyVerificationScreenState();
}

class _FacultyVerificationScreenState extends State<FacultyVerificationScreen> {
  final StorageBackend storage = StorageBackend();

  XFile? pickedImage;
  bool isLoading = false;

  // Capture image (local only)
  Future<void> capturePhoto() async {
    XFile? image = await storage.captureImage();

    if (image != null) {
      setState(() {
        pickedImage = image;
      });
    }
  }

  // Upload only on submit
  Future<void> submitProof() async {
    if (pickedImage == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      await storage.uploadImage(pickedImage!);

      if (!mounted) return;
      Navigator.pop(context, "faculty/${pickedImage!.name}");
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Faculty Verification"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Take a live photo of yourself for faculty verification.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 30),

            // Preview Container
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                clipBehavior: Clip.hardEdge,
                child: pickedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_rounded,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No photo captured",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      )
                    : Image.file(File(pickedImage!.path), fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 25),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else if (pickedImage == null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: capturePhoto,
                  child: const Text("Capture Live Photo"),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: OutlinedButton(
                        onPressed: capturePhoto,
                        child: const Text("Retake"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: ElevatedButton(
                        onPressed: submitProof,
                        child: const Text("Submit"),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
