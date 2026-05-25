import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peringatan'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Peringatan - Member 2 membangun ini di Phase 3'),
      ),
    );
  }
}