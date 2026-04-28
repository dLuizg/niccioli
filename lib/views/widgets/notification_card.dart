import 'package:flutter/material.dart';

class NotificationCard extends StatelessWidget {
  final String title, message, time;
  final IconData icon;
  final Color iconColor;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(message, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          time,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ),
    );
  }
}
