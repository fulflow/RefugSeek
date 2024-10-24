import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(DrugRecommendationApp());

class DrugRecommendationApp extends StatefulWidget {
  @override
  _DrugRecommendationAppState createState() => _DrugRecommendationAppState();
}

class _DrugRecommendationAppState extends State<DrugRecommendationApp> {
  final TextEditingController _controller = TextEditingController();
  String _recommendation = '';

  // Function to send user input to Hugging Face API and get the drug recommendation
  Future<void> getRecommendation(String description) async {
    final url = 'https://api-inference.huggingface.co/models/sd872346/gemma-2b-it-sum-drug_recommend';  // Correct API endpoint
    final headers = {
      "Authorization": "Bearer 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",  // Replace with your Hugging Face API token
      "Content-Type": "application/json"
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({"inputs": description}),  // Send the description to the model
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recommendation = data[0]['generated_text'];  // Access the generated text
        });
      } else {
        print('Error response: ${response.body}');
        setState(() {
          _recommendation = 'Error fetching recommendation';
        });
      }
    } catch (error) {
      print('Error occurred: $error');
      setState(() {
        _recommendation = 'Failed to connect to the server';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drug Recommendation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Enter your symptoms'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                getRecommendation(_controller.text);  // Call the Hugging Face API
              },
              child: Text('Get Recommendation'),
            ),
            SizedBox(height: 20),
            Text(_recommendation.isNotEmpty ? _recommendation : 'Enter your symptoms to get a recommendation.'),
          ],
        ),
      ),
    );
  }
}
