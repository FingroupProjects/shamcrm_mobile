
import 'package:flutter/material.dart';

class PlaceholderScreen extends StatelessWidget {
  final String message;

  PlaceholderScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
