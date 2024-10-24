import 'dart:io';
import 'dart:typed_data';
import 'package:myapp/consts.dart';
import 'Posting/login.dart';
import 'page_two.dart';
import 'map.dart';
import 'chat_page.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'main.dart';
import 'consts.dart';
// Chat page that integrates Gemini API
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  bool isTyping = false;  // New variable to track typing indicator

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(
    id: "1",
    firstName: "Anchor",
    profileImage:
    "assets/images/anchor.jpg",
  );

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  // Add the initial welcome message for the user
  void _addWelcomeMessage() {
    ChatMessage welcomeMessage = ChatMessage(
      user: geminiUser,
      createdAt: DateTime.now(),
      text:
      "Welcome! I'm here to help with any mental health assistance or shelter-seeking support you may need.",
    );
    setState(() {
      messages = [welcomeMessage, ...messages];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Anchor"),
      ),
      body: _buildUI(),
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
            ],
          ),
        ),
      ),


    );
  }

  Widget _buildUI() {
    return DashChat(
      inputOptions: InputOptions(trailing: [
        IconButton(
          onPressed: _sendMediaMessage,
          icon: const Icon(Icons.image),
        ),
      ]),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  // System prompt to set the context
  String getSystemPrompt() {
    return "You are an advisor for shelter-seeking individuals on mental health. "
        "Your task is to help guide people to shelters, mainly offer mental health assistance, "
        "and provide some information about shelter availability and services. "
        "You should also offer emotional support for the struggles they may face and talk to them like you are their therapist."
        "You must address your output for the following prompt as if it is the person you are speaking to.";
  }

  // Show typing indicator (three dots) while waiting for the Gemini API response
  void _showTypingIndicator() {
    setState(() {
      isTyping = true;
      messages = [
        ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: '...',
        ),
        ...messages
      ];
    });
  }

  // Remove typing indicator once response is received
  void _removeTypingIndicator() {
    setState(() {
      isTyping = false;
      messages.removeAt(0); // Remove the typing indicator message
    });
  }

  // Send both the system instructions and the user's message to Gemini
  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    // Combine the system prompt with the user's input
    String systemPrompt = getSystemPrompt();
    String question = chatMessage.text;
    String combinedPrompt = "$systemPrompt \n\n User's message: $question";

    _showTypingIndicator(); // Show typing indicator before sending the request

    try {
      List<Uint8List>? images;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        images = [
          File(chatMessage.medias!.first.url).readAsBytesSync(),
        ];
      }

      StringBuffer fullResponse = StringBuffer();

      // Collect the full response from the Gemini API before displaying
      gemini.streamGenerateContent(combinedPrompt, images: images).listen((event) {
        fullResponse.write(event.content?.parts?.fold(
          "", (previous, current) => "$previous ${current.text}",
        ));

      }, onDone: () {
        _removeTypingIndicator(); // Remove typing indicator once response is ready

        // Once the full response is collected, display it in one message
        ChatMessage message = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: fullResponse.toString(),
        );
        setState(() {
          messages = [message, ...messages];
        });
      }, onError: (error) {
        print("Error generating content: $error");
        _removeTypingIndicator(); // Ensure typing indicator is removed even on error
      });
    } catch (e) {
      print("Error generating content: $e");
      _removeTypingIndicator(); // Ensure typing indicator is removed on exception
    }
  }

  // Handle media message (image)
  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMessage chatMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture?",
        medias: [
          ChatMedia(
            url: file.path,
            fileName: "",
            type: MediaType.image,
          ),
        ],
      );
      _sendMessage(chatMessage);
    }
  }
}

// Class for parsing and handling **bold** text in messages
class BoldTextParser {
  // Parse **bold** text and return list of TextSpans
  static List<TextSpan> parseBoldText(String text) {
    final boldRegex = RegExp(r'\*\*(.*?)\*\*');
    final spans = <TextSpan>[];
    int lastIndex = 0;

    text.splitMapJoin(boldRegex, onMatch: (match) {
      // Add normal text before the match
      if (lastIndex < match.start) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      // Add bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      lastIndex = match.end;
      return match.group(0)!;
    }, onNonMatch: (nonMatch) {
      // Add remaining text
      spans.add(TextSpan(text: nonMatch));
      return nonMatch;
    });

    return spans;
  }
}

// Widget for displaying parsed messages with bold text
class Messages extends StatelessWidget {
  final bool isUser;
  final String message;

  const Messages({
    super.key,
    required this.isUser,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isUser ? softBeige : warmBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          children: BoldTextParser.parseBoldText(message),
          style: TextStyle(
            fontSize: 20,
            color: isUser ? warmBrown : Colors.black,
          ),
        ),
      ),
    );
  }
}
