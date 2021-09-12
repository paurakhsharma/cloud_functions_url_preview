import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static CollectionReference get previewsRef =>
      FirebaseFirestore.instance.collection('previews');

  static Future<void> addNewUrl(String url) async {
    final collection = FirebaseFirestore.instance.collection('urls');
    await collection.add({'url': url});
  }
}
