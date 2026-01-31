import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SidebarAdmin extends StatelessWidget {
  const SidebarAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    final adminColor = Color.fromARGB(255, 237, 189, 126);
    
    return SizedBox(
      width: 70,
      child: Container(
        color: Color(0xFFF8FAFC),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.dashboard, color: adminColor),
              onPressed: () {
                context.go('/admin');
              },
            ),
            IconButton(
              icon: Icon(Icons.send, color: adminColor),
              onPressed: () {
                context.go('/adminrequests');
              },
            ),
            SizedBox(height: 40),
            IconButton(
              icon: Icon(Icons.logout, color: adminColor),
              onPressed: () {
                context.go('/adminlogin');
              },
            ),
          ],
        ),
      ),
    );
  }
}