import 'dart:io';

import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/storage_backend.dart';

class FacultyVerificationScreen extends StatefulWidget {
  const FacultyVerificationScreen({super.key});

  @override
  State<FacultyVerificationScreen> createState() =>
      _FacultyVerificationScreenState();
}

class _FacultyVerificationScreenState
    extends State<FacultyVerificationScreen> {
  final StorageBackend storage = StorageBackend();

  XFile? pickedImage;
  bool _hasAutoCaptured = false;

  @override
  void initState() {
    super.initState();
    // Open front camera automatically when screen launches for the first time
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAutoCaptured) {
        _hasAutoCaptured = true;
        capturePhoto();
      }
    });
  }

  // Capture image using front camera (stored locally until profile submit)
  Future<void> capturePhoto() async {
    XFile? image = await storage.captureImage();

    if (image != null && mounted) {
      setState(() {
        pickedImage = image;
      });
    }
  }

  // Return local photo path to onboarding form (upload is deferred until final submit)
  void submitProof() {
    if (pickedImage == null) return;
    Navigator.pop(context, pickedImage!.path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: AutoSizeText(
          "Faculty Verification",
          maxLines: 1,
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Instruction Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.primaryAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.camera_front_rounded,
                        color: colors.primaryAccent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoSizeText(
                            "Live Verification Selfie",
                            maxLines: 1,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AutoSizeText(
                            "Take a clear selfie showing your face & faculty ID.",
                            maxLines: 2,
                            minFontSize: 11,
                            maxFontSize: 12,
                            style: TextStyle(
                              color: colors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Image Preview Area
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colors.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: pickedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: colors.bgColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: colors.borderColor),
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 40,
                                color: colors.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AutoSizeText(
                              "No verification photo captured",
                              maxLines: 1,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AutoSizeText(
                              "Tap capture button to launch front camera",
                              maxLines: 1,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : Image.file(
                          File(pickedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Bottom Action Controls
              if (pickedImage == null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: capturePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: colors.onPrimaryAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      size: 20,
                      color: colors.onPrimaryAccent,
                    ),
                    label: AutoSizeText(
                      "Open Front Camera",
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.onPrimaryAccent,
                      ),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: capturePhoto,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primaryText,
                            side: BorderSide(color: colors.borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: colors.primaryText,
                          ),
                          label: AutoSizeText(
                            "Retake",
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: submitProof,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryAccent,
                            foregroundColor: colors.onPrimaryAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: colors.onPrimaryAccent,
                          ),
                          label: AutoSizeText(
                            "Use Photo",
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.onPrimaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
