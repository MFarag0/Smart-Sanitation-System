import 'dart:async';
import 'package:facilitytracker/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  static List<Map<String, dynamic>> _messages = [];
  static Timer? _globalTimer;
  static int _unreadCount = 0;
  static String _lastMessage = '';
  static final List<Function()> _listeners = [];
  static final List<Function()> _messageUpdateListeners = [];

  static int getUnreadCount() => _unreadCount;
  static void clearUnreadCount() {
    _unreadCount = 0;
    _notifyListeners();
  }
  
  static void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
  
  static void _notifyMessageUpdateListeners() {
    for (var listener in _messageUpdateListeners) {
      listener();
    }
  }
  
  static void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  static void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  static void addMessageUpdateListener(Function() listener) {
    _messageUpdateListeners.add(listener);
  }
  
  static void removeMessageUpdateListener(Function() listener) {
    _messageUpdateListeners.remove(listener);
  }
  
  static void startGlobalFetching() {
    _globalTimer?.cancel();
    _globalTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchMessageStatic());
  }
  
  static void stopGlobalFetching() {
    _globalTimer?.cancel();
    _globalTimer = null;
  }
  
  static Future<void> _fetchMessageStatic() async {
    try {
      final response = await http
          .get(Uri.parse("http://192.168.4.1/fromadmin"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode != 200) return;

      final messageText = response.body.trim();
      if (messageText.isEmpty || messageText == _lastMessage) return;

      _lastMessage = messageText;
      final now = DateTime.now();
      final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      final timeString = '$hour:$minute $period';

      _messages.add({
        'message': messageText,
        'time': timeString,
        'timestamp': now,
        'isFromAdmin': true,
        'isAutomated': false,
      });
      
      _unreadCount++;
      _notifyListeners();
      _notifyMessageUpdateListeners();
    } catch (e) {
      // Silently fail
    }
  }

  // Static method for automated messages from dashboard
  static Future<void> sendAutomatedMessage(String messageText) async {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';
    
    // Add message to static list
    _messages.add({
      'message': messageText,
      'time': timeString,
      'timestamp': now,
      'isFromAdmin': false,
      'isAutomated': true,
    });
    
    
    try {
      await http.post(
        Uri.parse("http://192.168.4.1/sendtoadmin"),
        body: messageText,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw Exception('Failed to send automated message');
    }
  }

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    RequestsScreen.clearUnreadCount();
    RequestsScreen.startGlobalFetching();
    RequestsScreen.addMessageUpdateListener(_onMessageUpdate);
    
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    RequestsScreen.removeMessageUpdateListener(_onMessageUpdate);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageUpdate() {
    if (mounted) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final messageText = _messageController.text.trim();
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $period';
    
    // Add message to UI immediately
    setState(() {
      RequestsScreen._messages.add({
        'message': messageText,
        'time': timeString,
        'timestamp': now,
        'isFromAdmin': false,
        'isAutomated': false,
      });
      _messageController.clear();
    });
    
    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    
    
    try {
      await http.post(
        Uri.parse("http://192.168.4.1/sendtoadmin"),
        body: messageText,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      throw Exception('Failed to send message');
    }
  }



  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 800;
    final primaryColor = Color.fromARGB(255, 16, 134, 185);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Chat",
          style: GoogleFonts.jetBrainsMono(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (RequestsScreen._messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white),
              tooltip: 'Clear messages',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Clear Messages'),
                    content: Text('Are you sure you want to clear all messages?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            RequestsScreen._messages.clear();
                            RequestsScreen._lastMessage = '';
                          });
                          Navigator.pop(context);
                        },
                        child: Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
        toolbarHeight: 80,
        backgroundColor: primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, Color.fromARGB(255, 70, 229, 184)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Row(
          children: [
            Sidebar(),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: RequestsScreen._messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 64,
                                  color: Color(0xFF94A3B8),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No messages yet",
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Start a conversation with admin",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            color: Color(0xFFECECEC),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                              itemCount: RequestsScreen._messages.length,
                              itemBuilder: (context, index) {
                                final message = RequestsScreen._messages[index];
                                final isFromAdmin = message['isFromAdmin'] == true;
                                final isAutomated = message['isAutomated'] == true;
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment: isFromAdmin ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: isFromAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            isFromAdmin ? 'Admin' : (isAutomated ? 'You (Automated)' : 'You'),
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            message['time'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Color(0xFF999999),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.65,
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: isFromAdmin ? Colors.white : primaryColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Text(
                                          message['message'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Color(0xFF333333),
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.poppins(
                                color: Color(0xFFAAAAAA),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Color(0xFFF5F5F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) {
                              _sendMessage();
                            },
                            textInputAction: TextInputAction.send,
                            maxLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                        SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, Color.fromARGB(255, 70, 229, 184)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _sendMessage,
                              customBorder: CircleBorder(),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}