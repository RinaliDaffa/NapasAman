import 'package:flutter/material.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pantau'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Lokasi - Member 1 membangun ini di Phase 2'),
      ),
    );
  }
}