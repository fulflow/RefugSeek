import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'Posting/view_posts.dart';
import 'consts.dart';
import 'Posting/login.dart';
import 'chat_page.dart';
import 'main.dart';
import 'map.dart';
import 'ai.dart';

// Define your Resource class here (if not already done)
class Resource {
  final String title;
  final String description;
  final String url;

  Resource({required this.title, required this.description, required this.url});
}

// Sample data for recommendedResources
final List<Resource> recommendedResources = [
  Resource(title: 'United Nations', description: 'Global humanitarian aid organization providing services for displaced individuals worldwide.', url: 'https://www.un.org/'),
  Resource(title: 'American Red Cross', description: 'Supports disaster relief and homeless services, focusing on emergency shelters and resources.', url: 'https://www.redcross.org/about-us/our-work/disaster-relief.html'),
  Resource(title: 'Habitat for Humanity', description: 'Nonprofit helping individuals access affordable housing and employment opportunities.', url: 'https://www.habitat.org/'),
  Resource(title: 'National Alliance to End Homelessness', description: 'Focuses on policy advocacy and programs to prevent and end homelessness.', url: 'https://endhomelessness.org/'),
  Resource(title: 'Feeding America', description: 'Nationwide organization that provides food assistance and resources for homeless individuals.', url: 'https://www.feedingamerica.org/'),
  Resource(title: 'Salvation Army', description: 'Offers shelter, meals, and job resources to people in need, including the unsheltered.', url: 'https://www.salvationarmyusa.org/'),
  Resource(title: 'Job Corps', description: 'Offers free education and vocational training for young people, helping them secure jobs and housing.', url: 'https://www.jobcorps.gov/'),
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
              'Resource Center',
              style: TextStyle(fontSize: 20),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Supporting unsheltered individuals finding resources',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
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

            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  print("Want more resources? button pressed");
                },
                child: const Text('Want more resources?'),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomAppBar(
        color: darkBrown,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
