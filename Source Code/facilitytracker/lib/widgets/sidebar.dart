import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Container(
        color: Color(0xFFF8FAFC),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
      
          
          IconButton(
            icon: Icon(Icons.home, color: Color.fromARGB(255, 16, 134, 185)),
            onPressed: () {
              context.go('/facility');
            },
          ),
      
          IconButton(
            icon: Icon(Icons.sensors, color: Color.fromARGB(255, 16, 134, 185)),
            onPressed: () {
              context.go('/sensors');
            },
      
          ),
          IconButton(
            icon: Icon(Icons.send, color: Color.fromARGB(255, 16, 134, 185)),
            onPressed: () {
              context.go('/requests');
            },
          ),
          SizedBox(height: 40),
          IconButton(
            icon: Icon(Icons.admin_panel_settings, color: Color.fromARGB(255, 16, 134, 185)),
            onPressed: () {
              context.go('/adminlogin');
            },
          ),
        ],),
      ),
    );
  }
}