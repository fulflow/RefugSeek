import 'package:flutter/material.dart';
import 'package:myapp/consts.dart';
import 'package:url_launcher/url_launcher.dart';  // Import url_launcher for dialer functionality
import 'package:google_fonts/google_fonts.dart';
import 'Posting/login.dart';
import 'page_two.dart';
import 'map.dart';
import 'chat_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Posting/firebase_options.dart';
import 'package:geolocator/geolocator.dart';  // For accessing the location
import 'package:http/http.dart' as http;  // For making HTTP requests
import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:audioplayers/audioplayers.dart';  // For playing audio
import 'package:flutter/services.dart';  // For platform channels (SOS related)
import 'auth.dart';
import 'ai.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  Gemini.init(
    apiKey: GEMINI_API_KEY,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const MyHomePage(title: 'RefugSeek'),
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
  String _weatherDescription = '';
  double _humidity = 0.0;
  double _windSpeed = 0.0;
  bool _loading = true;  // Track loading state
  final AudioPlayer _audioPlayer = AudioPlayer();  // For playing the SOS alarm sound
  static const platform = MethodChannel('com.example.myapp/volume_dnd');  // Platform channel for volume and DND

  @override
  void initState() {
    super.initState();
    _fetchLocationData();  // Fetch location and weather data on startup
    _checkDndPermission();  // Check and request DND permission at startup
  }

  // Check DND access at startup and request permission if needed
  Future<void> _checkDndPermission() async {
    try {
      await platform.invokeMethod('checkDNDPermission');  // Invoke the method to check DND permission
    } catch (e) {
      print("Error checking DND permission: $e");
    }
  }

  // Fetch user's location and weather data based on it
  Future<void> _fetchLocationData() async {
    try {
      Position position = await _getUserLocation();
      print("Location: ${position.latitude}, ${position.longitude}");  // Debug
      await _getWeatherData(position.latitude, position.longitude);

      // Update state with fetched data
      setState(() {
        _loading = false;  // Data has been loaded
      });
    } catch (e) {
      print('Error fetching location data: $e');
      setState(() {
        _loading = false;  // Set loading to false even in case of error
      });
    }
  }

  // Get the user's current location
  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Fetch weather data from OpenWeatherMap API
  Future<void> _getWeatherData(double lat, double lng) async {
    final String apiKey = OPENWEATHER_API_KEY;  // Your API key here
    final url = 'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lng&appid=$apiKey&units=metric';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        _weatherDescription = data['weather'][0]['description'];  // Weather description
        _humidity = data['main']['humidity'].toDouble();  // Humidity as a percentage
        _windSpeed = data['wind']['speed'].toDouble();  // Wind speed in meters/second
      });
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  // Function to launch the phone's dialer with a predefined number
  Future<void> _launchDialer(String phoneNumber) async {
    final Uri url = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);  // Launches the phone dialer
    } else {
      throw 'Could not launch $url';
    }
  }

  // Add the SOS functionality here
  void _showSosDialog() {
    // Play the alarm when the SOS button is pressed
    _playSosAlarm();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SOS Confirmation'),
          content: const Text('Do you want to dial 911?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                _stopSosAlarm();  // Stop the alarm when "Cancel" is pressed
                Navigator.of(context).pop();  // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _stopSosAlarm();  // Stop the alarm when "Proceed" is pressed
                Navigator.of(context).pop();  // Close the dialog
                _launchDialer('911');  // Input the emergency number (replace with the correct one)
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  // Method to play the SOS alarm
  Future<void> _playSosAlarm() async {
    try {
      // Set volume to maximum using platform channel
      await _setMaxVolume();

      // Bypass DND settings using platform channel
      await _bypassDND();

      // Play the SOS alarm sound
      await _audioPlayer.play(AssetSource('sounds/sosalarm.mp3'));
    } catch (e) {
      print("Error playing alarm: $e");
    }
  }

  // Platform channel for setting volume to maximum
  Future<void> _setMaxVolume() async {
    try {
      await platform.invokeMethod('setMaxVolume');  // Invoke the Kotlin method to set volume to max
    } catch (e) {
      print("Error setting volume: $e");
    }
  }

  // Platform channel for bypassing Do Not Disturb
  Future<void> _bypassDND() async {
    try {
      await platform.invokeMethod('bypassDND');  // Invoke the Kotlin method to bypass DND
    } catch (e) {
      print("Error bypassing DND: $e");
    }
  }

  // Method to stop the SOS alarm
  Future<void> _stopSosAlarm() async {
    try {
      await _audioPlayer.stop();  // Stop the alarm sound
    } catch (e) {
      print("Error stopping alarm: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softBeige,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),  // Set custom AppBar height
        child: AppBar(
          backgroundColor: darkBrown,  // Custom background color for AppBar
          iconTheme: const IconThemeData(
            color: lightGrey,  // Set color of icons in the AppBar
          ),
          title: Padding(
            padding: const EdgeInsets.only(top: 10.0),  // Adjust padding for vertical centering
            child: Stack(
              children: [
                Center(
                  child: Text(
                    'View Documents',  // Center the title
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: lightGrey,  // Color for the title
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  // Align the icon to the right
                  child: IconButton(
                    icon: const Icon(Icons.lock),  // Add an icon to the AppBar
                    iconSize: 30.0,
                    color: lightGrey,  // Color for the icon
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                          builder: (context) => const AuthenticatorPage(),// Define what happens when the icon is pressed
                      ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner while waiting for data
          : Stack(
        children: [
          Positioned(
            top: 0.0, // Adjust the top position for where you want the image to start
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity, // Fill the width of the screen
              height: MediaQuery.of(context).size.width * (200 / 300), // Maintain aspect ratio (adjust 200/300 based on your image's ratio)
              decoration: BoxDecoration(
                color: Colors.grey[300], // Placeholder color
                image: const DecorationImage(
                  image: AssetImage('assets/images/homepic.jpg'), // Replace with your actual image
                  fit: BoxFit.cover,
                  opacity: 0.7,
                  // Cover the container while maintaining aspect ratio
                ),
              ),
            ),
          ),

          // "RefugSeek" text centered on top of the image
          Positioned(
            top: 75.0, // Adjust the positioning of the text
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "RefugSeek",
                style: GoogleFonts.lato(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: darkBrown,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: darkBrown.withOpacity(0.5),
                      offset: const Offset(3.5, 3.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // "RefugSeek" text centered on top of the image
          Positioned(
            top: 150.0, // Adjust the positioning under the first text
            left: 20.0, // Add left and right padding if needed
            right: 20.0,
            child: Center(
              child: RichText(
                textAlign: TextAlign.center,  // Center the text
                text: TextSpan(
                  text: "Help fellow shelter seekers by posting services! You can also find services near you (get real time updates as they are added), look through job resources, or chat with ",
                  style: GoogleFonts.lato(  // Regular style
                    fontSize: 17,// Set base text to bold
                    color: darkBrown,
                  ),
                  children: [
                    TextSpan(
                      text: 'Anchor',  // The word to be bolded
                      style: TextStyle(
                        fontWeight: FontWeight.bold,  // Bold just this word
                      ),
                    ),
                    TextSpan(
                      text: '--the mental health chatbot.',  // Continuing the regular text
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300.0, // Position this above the weather data container
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Today's Dashboard:",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: warmBrown,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),


          // Weather data in a styled container
          Positioned(
            top: 350.0, // Adjust top position if needed
            left: 20.0,
            right: 20.0,
            child: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: warmBrown, // Brown background for the container
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,  // Center vertically
                  crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
                  children: [

                    Text(
                      "Weather: $_weatherDescription",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: softBeige,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),  // Add spacing between elements
                    Text(
                      "Humidity: $_humidity%",
                      style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: softBeige,

                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Wind Speed: $_windSpeed m/s",
                      style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: softBeige,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
              ),
            ),
          ),

          // Display additional stats under the weather description

          // SOS button
          Positioned(
            bottom: 25.0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SOS Button
                ElevatedButton(
                  onPressed: _showSosDialog, // Show confirmation dialog
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mutedRed,  // Red color for SOS
                    padding: const EdgeInsets.symmetric(horizontal: 60.0, vertical: 24.0),
                    foregroundColor: softBeige,  // Set the text color to softBeige
                    textStyle: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('SOS'),
                ),

                // Warning / Terms & Conditions Text
                Padding(
                  padding: const EdgeInsets.only(top: 8.0), // Adds space between the button and the text
                  child: const Text(
                    'WARNING: If you are in immediate danger, press this button to dial 911.',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.red,  // Warning text in red
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center, // Center-align the text
                  ),
                ),
              ],
            ),
          ),
        ],
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

              // Resource Center Icon (Replace "Resource Center")
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

              // Map Screen Icon (Replace "Map Screen")

              // Mental Health Bot Icon (Replace "Mental Health Bot")
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
