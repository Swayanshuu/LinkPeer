import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class StorageBackend {
  final supabase = Supabase.instance.client;

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    XFile? imagePicker = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    return imagePicker;
  }

  // Open camera and capture live photo
  Future<XFile?> captureImage() async {
    XFile? imagePicker = await ImagePicker().pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front, // selfie cam
      imageQuality: 90,
    );
    return imagePicker;
  }

  Future<void> removeImage(String imageName) async {
    String path = 'faculty/$imageName';

    await supabase.storage.from('images').remove([path]);

    debugPrint("Image Removed Successfully");
  }

  Future<void> removePostImage(String url) async {
    try {
      // The public URL looks like: https://.../storage/v1/object/public/post_images/posts/filename.ext
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      // Find the index of 'post_images' bucket
      final bucketIndex = segments.indexOf('post_images');
      if (bucketIndex != -1 && bucketIndex + 1 < segments.length) {
        // Path starts after the bucket name
        final path = segments.sublist(bucketIndex + 1).join('/');
        await supabase.storage.from('post_images').remove([path]);
        debugPrint("Deleted image from storage: $path");
      }
    } catch (e) {
      debugPrint("Error removing post image: $e");
    }
  }

  Future<String> uploadImage(XFile image) async {
    String path = 'faculty/${image.name}';
    File file = File(image.path);

    // upload
    String response = await supabase.storage.from('images').upload(path, file);
    debugPrint("Image Uploaded: $response");

    // public url
    String imageUrl = supabase.storage.from('images').getPublicUrl(path);

    return imageUrl;
  }

  Future<String> uploadPostImage(XFile image) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final ext = image.name.split('.').last;
    final fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${image.name.hashCode}.$ext';
    String path = '$uid/$fileName';
    File file = File(image.path);

    // upload
    await supabase.storage.from('post_images').upload(path, file);

    // public url
    String imageUrl = supabase.storage.from('post_images').getPublicUrl(path);

    return imageUrl;
  }

  Future<List<String>> uploadMultipleImages(List<XFile> images) async {
    List<String> urls = [];
    for (var image in images) {
      String url = await uploadPostImage(image);
      urls.add(url);
    }
    return urls;
  }
}
