import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 

class Message {
  final String sender;
  final String text;

  Message({required this.sender, required this.text});
}

/// A screen for chatting with an AI assistant.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = []; // List to store chat messages
  bool _isLoadingAIResponse = false; // State for loading indicator
  final ScrollController _scrollController =
      ScrollController(); // For auto-scrolling

  // Suggested queries for women traveling or uncomfortable situations
  final List<String> _suggestedQueries = [
    "What are some safe neighborhoods to stay in?",
    "How can I report harassment while traveling?",
    "Are there any women-only travel groups or accommodations recommended?",
    "What are common local customs regarding dress code or interaction for women?",
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({String? messageText}) {
    final userMessage = messageText ?? _messageController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add(Message(sender: 'user', text: userMessage));
      _isLoadingAIResponse = true;
    });

    _messageController.clear();
    _scrollToBottom();

    _getAiResponse(userMessage);
  }

  Future<void> _getAiResponse(String userMessage) async {
    const String apiKey = "";
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey';

    try {
      final chatHistory = [
        {
          "role": "user",
          "parts": [
            {"text": userMessage},
          ],
        },
      ];

      final payload = {"contents": chatHistory};

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['candidates'] != null &&
            result['candidates'].isNotEmpty &&
            result['candidates'][0]['content'] != null &&
            result['candidates'][0]['content']['parts'] != null &&
            result['candidates'][0]['content']['parts'].isNotEmpty) {
          final text = result['candidates'][0]['content']['parts'][0]['text'];
          setState(() {
            _messages.add(Message(sender: 'ai', text: text));
          });
        } else {
          setState(() {
            _messages.add(
              Message(
                sender: 'ai',
                text: 'Error: Could not get a valid response from AI.',
              ),
            );
          });
        }
      } else {
        setState(() {
          _messages.add(
            Message(
              sender: 'ai',
              text: 'Error: API call failed with status ${response.statusCode}',
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(Message(sender: 'ai', text: 'Error: ${e.toString()}'));
      });
    } finally {
      setState(() {
        _isLoadingAIResponse = false; 
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 4.0,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: _suggestedQueries.map((query) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                    ),
                    child: ActionChip(
                      onPressed: () => _sendMessage(messageText: query),
                      label: Text(
                        query,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      backgroundColor: Colors.grey[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: BorderSide.none,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(10.0),
              itemCount: _messages.length + (_isLoadingAIResponse ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoadingAIResponse) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        vertical: 5.0,
                        horizontal: 8.0,
                      ),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2.0,
                      ),
                    ),
                  );
                }

                final message = _messages[index];
                final bool isUser = message.sender == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(
                      isUser
                          ? 60.0
                          : 8.0,
                      5.0,
                      isUser
                          ? 8.0
                          : 60.0, 
                      5.0,
                    ),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[900] : Colors.grey[800],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15.0),
                        topRight: const Radius.circular(15.0),
                        bottomLeft: isUser
                            ? const Radius.circular(15.0)
                            : const Radius.circular(
                                5.0,
                              ),
                        bottomRight: isUser
                            ? const Radius.circular(5.0)
                            : const Radius.circular(
                                15.0,
                              ), 
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      message.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _sendMessage(), // Send on enter
                  ),
                ),
                const SizedBox(width: 8.0),
                FloatingActionButton(
                  onPressed: _isLoadingAIResponse
                      ? null // Disable button while loading
                      : _sendMessage,
                  backgroundColor: Colors.blue[900],
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: _isLoadingAIResponse
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
