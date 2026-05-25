import 'package:flutter/material.dart';
import 'core/firebase/firebase_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const NapasAmanApp());
}