import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageBackend {
  final supabase = Supabase.instance.client;

  // Pick image from gallery
  Future<XFile?> pickImage() async {
    XFile? imagePicker = await ImagePicker().pickImage(
      source: ImageSource.gallery,
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

    print("Image Removed Successfully");
  }

  Future<String> uploadImage(XFile image) async {
    String path = 'faculty/${image.name}';
    File file = File(image.path);

    // upload
    String response = await supabase.storage.from('images').upload(path, file);
    print("Image Uploaded: $response");

    // public url
    String imageUrl = supabase.storage.from('images').getPublicUrl(path);

    String signedUrl = await supabase.storage
        .from('images')
        .createSignedUrl(path, 10);

    print(signedUrl);

    return imageUrl;
  }
}
