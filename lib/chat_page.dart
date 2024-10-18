import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'consts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _openAI = OpenAI.instance.build(
      token: OPENAI_API_KEY,
      baseOption: HttpSetup(
        receiveTimeout: const Duration(seconds: 5),
      ),
      enableLog: true);

  final ChatUser _user = ChatUser(
    id: '1',
    firstName: 'Charles',
    lastName: 'Leclerc',
  );

  final ChatUser _gptChatUser = ChatUser(
    id: '2',
    firstName: 'Chat',
    lastName: 'GPT',
  );

  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  void initState() {
    super.initState();
    /*_messages.add(
      ChatMessage(
        text: 'Hey!',
        user: _user,
        createdAt: DateTime.now(),
      ),
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(
          0,
          166,
          126,
          1,
        ),
        title: const Text(
          'GPT Chat',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
        currentUser: _user,
        messageOptions: const MessageOptions(
          currentUserContainerColor: Colors.black,
          containerColor: Color.fromRGBO(
            0,
            166,
            126,
            1,
          ),
          textColor: Colors.white,
        ),
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
        typingUsers: _typingUsers,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m); // Add user message to the UI
      _typingUsers.add(_gptChatUser); // Show typing indicator for GPT
    });

    // Construct the message history with the correct `Messages` type
    List<Map<String, dynamic>> messagesHistory = _messages.reversed.map((m) {
      if (m.user == _user) {
        return Messages(role: Role.user, content: m.text).toJson();  // Convert Messages to Map
      } else {
        return Messages(role: Role.assistant, content: m.text).toJson();  // Convert Messages to Map
      }
    }).toList();

    final request = ChatCompleteText(
      messages: messagesHistory,  // Now passing List<Messages> as expected
      maxToken: 200,
      model: GptTurboChatModel(),
      temperature: 0.3,
      topP: 1.0,
      n: 1,
      presencePenalty: 0.0,
      frequencyPenalty: 0.0,
    );

    try {
      final response = await _openAI.onChatCompletion(request: request);

      if (response != null) {
        for (var element in response.choices) {
          if (element.message != null) {
            setState(() {
              _messages.insert(
                0,
                ChatMessage(
                  user: _gptChatUser,
                  createdAt: DateTime.now(),
                  text: element.message!.content, // GPT's response
                ),
              );
            });
          }
        }
      } else {
        print("Error: No response from OpenAI");
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      _typingUsers.remove(_gptChatUser); // Remove typing indicator
    });
  }
}
