import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart'; // For uploading to Firebase
import 'package:google_ml_kit/google_ml_kit.dart'; // For OCR

class AuthenticatorPage extends StatefulWidget {
  const AuthenticatorPage({super.key});

  @override
  _AuthenticatorPageState createState() => _AuthenticatorPageState();
}

class _AuthenticatorPageState extends State<AuthenticatorPage> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _scannedText; // Variable to hold the extracted text

  // Function to pick an image
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _scannedText = null; // Reset scanned text when new image is picked
      });
      _extractTextFromImage(); // Extract text from the image
    }
  }

  // Function to upload image to Firebase Storage
  Future<void> _uploadImage() async {
    if (_imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = storageRef.putFile(_imageFile!);

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

      // Display success message or do something with the download URL
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload Successful!')));
      print('Image URL: $downloadUrl');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload Failed: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  // Function to extract text from the image using Google ML Kit
  Future<void> _extractTextFromImage() async {
    if (_imageFile == null) return;

    final inputImage = InputImage.fromFile(_imageFile!);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textDetector.processImage(inputImage);

    setState(() {
      _scannedText = recognizedText.text; // Store the extracted text
    });

    textDetector.close(); // Close the text detector
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        backgroundColor: Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _imageFile == null
                ? const Text('Please select an image', style: TextStyle(fontSize: 20))
                : Image.file(_imageFile!, height: 200),

            const SizedBox(height: 20),

            _scannedText != null
                ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Extracted Text: $_scannedText',
                style: const TextStyle(fontSize: 16),
              ),
            )
                : Container(),

            // Button to pick image from gallery
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.gallery),
              child: const Text('Select from Gallery'),
            ),

            // Button to pick image from camera
            ElevatedButton(
              onPressed: () => _pickImage(ImageSource.camera),
              child: const Text('Take a Picture'),
            ),

            const SizedBox(height: 20),

            // Button to upload the selected image
            _imageFile != null && !_isUploading
                ? ElevatedButton(
              onPressed: _uploadImage,
              child: const Text('Upload Image'),
            )
                : _isUploading
                ? const CircularProgressIndicator()
                : Container(),
          ],
        ),
      ),
    );
  }
}
