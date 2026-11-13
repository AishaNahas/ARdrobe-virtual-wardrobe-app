import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav_bar.dart';

class NotificationScreen extends StatelessWidget {
  final String email;
  const NotificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4B4B4B)),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboard', arguments: email);
          },
        ),
        title: const Text('Notifications', style: TextStyle(color: Color(0xFF4B4B4B), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          final userId = userSnapshot.data!.docs.first.id;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, notifSnapshot) {
              if (!notifSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifs = notifSnapshot.data!.docs;
              if (notifs.isEmpty) {
                return const Center(child: Text('No notifications yet.'));
              }
              return ListView.builder(
                itemCount: notifs.length,
                itemBuilder: (context, index) {
                  final notif = notifs[index].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.notifications, color: Color(0xFFA4D3A0)),
                    title: Text(notif['notification_msg'] ?? ''),
                    subtitle: notif['date'] != null ? Text(notif['date'].toString()) : null,
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(selectedIndex: 3, email: email),
    );
  }
}
