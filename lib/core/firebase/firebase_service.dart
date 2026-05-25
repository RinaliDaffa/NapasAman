import 'package:firebase_core/firebase_core.dart';

class FirebaseService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDjP9HkeuGiVfgWCo8hkrupThZo2RFEJUc',
        appId: '1:1042339310245:android:9a9babfd4ce1c34063fb4c',
        messagingSenderId: '1042339310245',
        projectId: 'napasaman-fcc7b',
      ),
    );
  }
}