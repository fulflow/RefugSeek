import 'dart:typed_data';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'utils.dart';
import 'package:myapp/Posting/image_store_methods.dart';
import 'firebase_options.dart';
import 'view_posts.dart';
import 'package:geolocator/geolocator.dart';
import 'login.dart';
import '../page_two.dart';
import '../map.dart';
import '../chat_page.dart';
import '../main.dart';
import '../consts.dart';
import '../ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Login());
}

class Login extends StatelessWidget {
  const Login({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RefugSeek',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: darkBrown),
        useMaterial3: true,
        primaryColor: darkBrown,
        scaffoldBackgroundColor: softBeige,
      ),
      home: const MyHomePage(title: 'User State'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Uint8List? _file;
  final TextEditingController _descriptionController = TextEditingController();

  bool _isLoading = false;

  void postImage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        showSnackBar('Location services are disabled', context);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          showSnackBar('Location permissions are denied', context);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        showSnackBar('Location permissions are permanently denied', context);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      double latitude = position.latitude;
      double longitude = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(
          latitude, longitude);
      Placemark place = placemarks[0];

      String city = place.locality ?? 'Unknown city';
      String state = place.administrativeArea ?? 'Unknown state';

      String res = await ImageStoreMethods().uploadPost(
        _descriptionController.text,
        _file!,
        latitude,
        longitude,
        city,
        state,
      );

      if (res == 'success') {
        showSnackBar('Posted Successfully', context);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ViewPostsPage(),
          ),
        );

        clearImage();
      } else {
        showSnackBar(res, context);
      }
    } catch (err) {
      showSnackBar(err.toString(), context);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void clearImage() {
    setState(() {
      _file = null;
    });
  }

  _imageSelect(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text('Select Image'),
            children: [
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: Text('Take a Photo'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.camera,
                  );
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: Text('Choose From Gallery'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  Uint8List file = await pickImage(
                    ImageSource.gallery,
                  );
                  setState(() {
                    _file = file;
                  });
                },
              ),
              SimpleDialogOption(
                padding: EdgeInsets.all(20),
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Shelter or Service Information'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder Image or Selected Image
              _file != null
                  ? Column(
                children: [
                  _isLoading
                      ? const LinearProgressIndicator()
                      : const Padding(padding: EdgeInsets.only(top: 0)),
                  const Divider(),
                  SizedBox(
                    height: 300,
                    width: 300,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: MemoryImage(_file!),
                          fit: BoxFit.contain,  // Maintain aspect ratio
                          alignment: FractionalOffset.topCenter,
                        ),
                      ),
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Write a Description',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : postImage,
                        child: _isLoading
                            ? CircularProgressIndicator()
                            : Text("Post"),
                      ),
                    ],
                  ),
                ],
              )
                  : Column(
                children: [
                  SizedBox(
                    height: 300,  // Specify your desired box height
                    width: 300,   // Specify your desired box width
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/placeholder.png'), // Path to your placeholder image
                          fit: BoxFit.contain // Shrink image to fit within the box while maintaining aspect ratio
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      'No image selected. Post an image of the shelter or service you want to share.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Button: Post Shelter or Service Near You
              ElevatedButton(
                onPressed: () {
                  // Show the UI for posting an image (Shelter or service)
                  _imageSelect(context);
                },
                child: const Text('Post Shelter or Service Near You'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: darkBrown,  // Background color for footer
        child: Padding(
          padding: const EdgeInsets.all(10.0),  // Padding inside the footer
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,  // Evenly space items
            children: [
              // Login Button Icon (Login action)
              IconButton(
                icon: const Icon(Icons.home),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.post_add),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MapScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.list),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PageTwo()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ChatPage()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.medical_information),
                color: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DrugRecommendationApp()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
