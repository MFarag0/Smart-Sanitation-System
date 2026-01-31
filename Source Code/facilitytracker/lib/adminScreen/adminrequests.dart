import 'dart:async';
import 'package:facilitytracker/widgets/sidebar_admin.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  static Map<String, Map<String, dynamic>> _facilities = {
    'Zone 1 - A': {'zone': 'Zone 1', 'facility': 'A', 'messages': []},
    'Zone 1 - B': {'zone': 'Zone 1', 'facility': 'B', 'messages': []},
    'Zone 1 - C': {'zone': 'Zone 1', 'facility': 'C', 'messages': []},
    'Zone 2 - A': {'zone': 'Zone 2', 'facility': 'A', 'messages': []},
    'Zone 2 - B': {'zone': 'Zone 2', 'facility': 'B', 'messages': []},
    'Zone 2 - C': {'zone': 'Zone 2', 'facility': 'C', 'messages': []},
    'Zone 3 - A': {'zone': 'Zone 3', 'facility': 'A', 'messages': []},
    'Zone 3 - B': {'zone': 'Zone 3', 'facility': 'B', 'messages': []},
    'Zone 3 - C': {'zone': 'Zone 3', 'facility': 'C', 'messages': []},
  };
  
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
          .get(Uri.parse("http://192.168.4.1/fromfacility"))
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

      // Only add to Zone 1 - A
      (AdminRequestsScreen._facilities['Zone 1 - A']!['messages'] as List).add({
        'message': messageText,
        'time': timeString,
        'timestamp': now,
        'isFromFacility': true,
      });
      
      _unreadCount++;
      _notifyListeners();
      _notifyMessageUpdateListeners();
    } catch (e) {
      // Silently fail
    }
  }

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _selectedFacility = 'Zone 1 - A';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AdminRequestsScreen.clearUnreadCount();
    AdminRequestsScreen.startGlobalFetching();
    AdminRequestsScreen.addMessageUpdateListener(_onMessageUpdate);
  }

  @override
  void dispose() {
    AdminRequestsScreen.removeMessageUpdateListener(_onMessageUpdate);
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onMessageUpdate() {
    if (mounted) {
      setState(() {});
      // Auto-scroll to bottom when new message arrives
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
      (AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List).add({
        'message': messageText,
        'time': timeString,
        'timestamp': now,
        'isFromFacility': false,
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
    
    // Send to server
    try {
      await http.post(
        Uri.parse("http://192.168.4.1/sendtofacility"),
        body: messageText,
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      // Silently fail
    }
  }

  void _showClearDialog() {
    final primaryColor = Color.fromARGB(255, 16, 134, 185);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Clear Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to clear all messages? This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF64748B),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  (AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List).clear();
                  AdminRequestsScreen._lastMessage = '';
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All messages cleared for $_selectedFacility',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Clear',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
        toolbarHeight: 80,
        backgroundColor: primaryColor,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 237, 189, 126), Color.fromARGB(255, 229, 221, 70)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          if ((AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List).isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.white),
              onPressed: _showClearDialog,
              tooltip: 'Clear all messages',
            ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            SidebarAdmin(),
            
            // Facility list sidebar
            if (!isPhone) Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  right: BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.business,
                          color: Color.fromARGB(255, 237, 189, 126),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Facilities',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: AdminRequestsScreen._facilities.keys.length,
                      itemBuilder: (context, index) {
                        final facilityKey = AdminRequestsScreen._facilities.keys.elementAt(index);
                        final facility = AdminRequestsScreen._facilities[facilityKey]!;
                        final isSelected = facilityKey == _selectedFacility;
                        final messageCount = (facility['messages'] as List).length;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedFacility = facilityKey;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color.fromARGB(255, 237, 189, 126).withOpacity(0.1) : Colors.transparent,
                              border: Border(
                                left: BorderSide(
                                  color: isSelected ? Color.fromARGB(255, 237, 189, 126) : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility['zone'] as String,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Facility ${facility['facility']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Color.fromARGB(255, 237, 189, 126) : Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    if (messageCount > 0)
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Color.fromARGB(255, 237, 189, 126),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$messageCount',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Column(
                children: [
                  // Messages list
                  Expanded(
                    child: (AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List).isEmpty
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
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Messages from $_selectedFacility will appear here",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            color: Color(0xFFF8FAFC),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.all(16),
                              itemCount: (AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List).length,
                              itemBuilder: (context, index) {
                                final message = (AdminRequestsScreen._facilities[_selectedFacility]!['messages'] as List)[index];
                                final isFromFacility = message['isFromFacility'] ?? true;
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: isFromFacility ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisAlignment: isFromFacility ? MainAxisAlignment.start : MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            isFromFacility ? _selectedFacility : 'Admin',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            message['time'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Container(
                                        constraints: BoxConstraints(
                                          maxWidth: MediaQuery.of(context).size.width * 0.6,
                                        ),
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isFromFacility ? Colors.white : Color.fromARGB(255, 237, 189, 126).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color(0xFFE2E8F0),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryColor.withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          message['message'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Color(0xFF1E293B),
                                            height: 1.5,
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
                  
                  // Message input
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: GoogleFonts.poppins(
                                color: Color(0xFF94A3B8),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 237, 189, 126),
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        SizedBox(width: 12),
                        Material(
                          color: Color.fromARGB(255, 237, 189, 126),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: _sendMessage,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
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
