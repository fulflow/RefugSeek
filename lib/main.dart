import 'package:flutter/material.dart';
import 'page_one.dart';
import 'page_two.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Posting/login.dart';
import 'map.dart';
import 'chat_page.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core for Firebase initialization
import 'Posting/firebase_options.dart'; // Import the generated firebase_options.dart file



void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensure you're using platform-specific options
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnviroEquity',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'EnviroEquity'),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the color of the hamburger icon to white
        ),
      ),
      body: Stack(
        children: [
              Image.asset(
            "assets/images/homepic.jpg",
            fit: BoxFit.cover,
            height: double.infinity,
            width: double.infinity,
            errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
              return Center(child: Text('Failed to load image'));
            },
          ),

          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 75.0),
                child: Text(
                  "EnviroEquity",
                  style: GoogleFonts.lato(
                    fontSize: 45,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.indigo[900]!.withOpacity(0.5),
                        offset: const Offset(3.5, 3.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 32.0,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  print('Button pressed!');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent[400],
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  textStyle: const TextStyle(fontSize: 16.0),
                ),
                child: const Text('How does it happen?'),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Drawer Header'),
            ),
            ListTile(
              title: const Text('Login'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Login()),
                ).then((value) {
                  Navigator.pop(context); // Close the drawer
                });
              },
            ),
            ListTile(
              title: const Text('Resource Center'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PageTwo()),
                ).then((value) {
                  Navigator.pop(context); // Close the drawer
                });
              },
            ),
            ListTile(
              title: const Text('Map Screen'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                ).then((value) {
                  Navigator.pop(context); // Close the drawer
                });
              },
            ),

            ListTile(
              title: const Text('Mental Health Bot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatPage()),
                ).then((value) {
                  Navigator.pop(context); // Close the drawer
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
