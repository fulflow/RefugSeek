import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PageOne extends StatefulWidget {
  @override
  _PageOneState createState() => _PageOneState();
}

class _PageOneState extends State<PageOne> {
  TextEditingController _controller = TextEditingController();
  List<String> _messages = [];

  // Function to get chatbot response from OpenAI
  Future<String> getChatbotResponse(String userInput) async {
    final apiKey = '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'; // Replace with your actual OpenAI API key
    final url = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5', // Use GPT-4 or GPT-3.5 depending on your access
        'messages': [
          {'role': 'system', 'content': 'You are a helpful mental health assistant.'},
          {'role': 'user', 'content': userInput}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to load chatbot response');
    }
  }

  // Function to handle sending the message
  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add('You: ${_controller.text}'); // User message
      });

      String response = await getChatbotResponse(_controller.text);

      setState(() {
        _messages.add('Bot: $response'); // Bot response
        _controller.clear(); // Clear the input field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page One - Mental Health Chatbot')),
      body: Column(
        children: [
          // Chat messages display
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          // User input field and send button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type your message here',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



//  body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );




//import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// // Define your Resource class here (if not already done)
// class Resource {
//   final String title;
//   final String description;
//   final String url;
//
//   Resource({required this.title, required this.description, required this.url});
// }
//
// // Sample data for recommendedResources
// final List<Resource> recommendedResources = [
//   Resource(title: 'Resource 1', description: 'Description for resource 1', url: 'https://example.com'),
//   Resource(title: 'Resource 2', description: 'Description for resource 2', url: 'https://example.com'),
//   // Add more resources as needed
// ];
//
// class PageTwo extends StatelessWidget {
//   const PageTwo({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Page Two'),
//       ),
//       body: SingleChildScrollView( // Make the page scrollable
//         child: Column(
//           children: [
//             // Map each resource to a Card widget
//             ...recommendedResources.map((resource) => Card(
//               margin: const EdgeInsets.all(10),
//               child: ListTile(
//                 title: Text(resource.title),
//                 subtitle: Text(resource.description),
//                 onTap: () {
//                   _launchURL(resource.url);
//                 },
//               ),
//             )).toList(),
//
//             // "Want more resources?" button
//             Padding(
//               padding: const EdgeInsets.all(20),
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Handle button press (e.g., fetch more resources)
//                   print("Want more resources? button pressed");
//                 },
//                 child: const Text('Want more resources?'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Updated _launchURL method
//   Future<void> _launchURL(String url) async {
//     final Uri uri = Uri.parse(url);
//     if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
//       throw Exception('Could not launch $url');
//     }
//   }
// }
