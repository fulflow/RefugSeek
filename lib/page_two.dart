import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Define your Resource class here (if not already done)
class Resource {
  final String title;
  final String description;
  final String url;

  Resource({required this.title, required this.description, required this.url});
}

// Sample data for recommendedResources
final List<Resource> recommendedResources = [
  Resource(title: 'United Nations', description: 'Description for resource 1', url: 'https://www.un.org/'),
  Resource(title: 'American Red Cross', description: 'Description for resource 2', url: 'https://www.redcross.org/about-us/our-work/disaster-relief.html'),
  // Add more resources as needed
];

class PageTwo extends StatelessWidget {
  const PageTwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

        title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resource Center', // Main title
            style: TextStyle(fontSize: 20), // You can customize the font size here
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4.0), // Add padding between title and subtitle
            child: Text(
              'Supporting displaced women finding jobs', // Subtitle
              style: TextStyle(
                fontSize: 14, // Smaller font for subtitle
                color: Colors.black, // Adjust the color for visibility
              ),
            ),
          ),
        ],
      ),
      ),


      body: SingleChildScrollView( // Make the page scrollable
        child: Column(
          children: [
            // Map each resource to a Card widget
            ...recommendedResources.map((resource) => Card(
              margin: const EdgeInsets.all(10),
              child: ListTile(
                title: Text(resource.title),
                subtitle: Text(resource.description),
                onTap: () {
                  _launchURL(resource.url);
                },
              ),
            )).toList(),

            // "Want more resources?" button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  // Handle button press (e.g., fetch more resources)
                  print("Want more resources? button pressed");
                },
                child: const Text('Want more resources?'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _launchURL method
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
