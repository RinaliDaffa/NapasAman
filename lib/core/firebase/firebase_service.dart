import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    await Firebase.initializeApp();
  }
}
