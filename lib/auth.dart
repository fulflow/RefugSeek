import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For persistent storage

class AuthenticatorPage extends StatefulWidget {
  const AuthenticatorPage({super.key});

  @override
  _AuthenticatorPageState createState() => _AuthenticatorPageState();
}

class _AuthenticatorPageState extends State<AuthenticatorPage> {
  final List<File> _imageFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String? _scannedText;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadImagesFromPrefs(); // Load saved images when the app starts
  }

  // Load image file paths from SharedPreferences
  Future<void> _loadImagesFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    List<String>? imagePaths = _prefs?.getStringList('images');

    if (imagePaths != null) {
      setState(() {
        _imageFiles.addAll(imagePaths.map((path) => File(path)).toList());
      });
    }
  }

  // Save image file paths to SharedPreferences
  Future<void> _saveImagesToPrefs() async {
    List<String> imagePaths = _imageFiles.map((file) => file.path).toList();
    await _prefs?.setStringList('images', imagePaths);
  }

  // Function to pick an image and save it persistently
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFiles.add(File(pickedFile.path));
        _scannedText = null; // Reset scanned text when new image is picked
      });
      _extractTextFromImage(File(pickedFile.path)); // Extract text from the image
      _saveImagesToPrefs(); // Save the updated list of images
    }
  }

  // Function to upload image to Firebase Storage
  Future<void> _uploadImage(File imageFile) async {
    if (imageFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('uploads/${DateTime.now().millisecondsSinceEpoch}.png');
      final uploadTask = storageRef.putFile(imageFile);

      await uploadTask;
      final downloadUrl = await storageRef.getDownloadURL();

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
  Future<void> _extractTextFromImage(File imageFile) async {
    if (imageFile == null) return;

    final inputImage = InputImage.fromFile(imageFile);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textDetector.processImage(inputImage);

    setState(() {
      _scannedText = recognizedText.text; // Store the extracted text
    });

    textDetector.close();
  }

  // Function to show the image in full screen
  void _showFullScreenImage(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Close the full-screen image on tap
                },
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Documents'),
        backgroundColor: Colors.brown,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 20),

            // Neatly styled container to display the extracted text
            _scannedText != null
                ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.brown, width: 1),
                ),
                child: Text(
                  'Extracted Text: $_scannedText',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  textAlign: TextAlign.left,
                ),
              ),
            )
                : Container(),

            const SizedBox(height: 20),

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

            // Displaying the list of uploaded images
            _imageFiles.isNotEmpty
                ? ListView.builder(
              shrinkWrap: true, // Ensure it fits inside the scrollable area
              physics: NeverScrollableScrollPhysics(), // Disable internal scrolling
              itemCount: _imageFiles.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.file(_imageFiles[index], height: 50, width: 50),
                  title: Text('Image ${index + 1}'),
                  onTap: () => _showFullScreenImage(_imageFiles[index]), // View image full screen
                  trailing: IconButton(
                    icon: const Icon(Icons.upload),
                    onPressed: () => _uploadImage(_imageFiles[index]), // Upload the image
                  ),
                );
              },
            )
                : const Text('No images uploaded yet'),

            const SizedBox(height: 20),

            // Show uploading progress indicator
            _isUploading ? const CircularProgressIndicator() : Container(),
          ],
        ),
      ),
    );
  }
}
