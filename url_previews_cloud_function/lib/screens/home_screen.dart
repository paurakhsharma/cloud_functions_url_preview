import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_previews_cloud_function/service/firestore_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('URL Previews'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: FirestoreService.previewsRef.snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData) return Text('Loading..');

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) return Text('Add urls to load their previews');

            final previews =
                docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

            return ListView.separated(
              padding: const EdgeInsets.all(0),
              itemCount: previews.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final preview = previews[index];
                return ListTile(
                  contentPadding: const EdgeInsets.all(0),
                  leading: preview['image'].isEmpty
                      ? Container(
                          height: 100,
                          width: 100,
                          color: Colors.grey,
                        )
                      : Image.network(
                          preview['image'],
                          height: 100,
                          width: 100,
                        ),
                  title: Text(preview['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(preview['description']),
                      SizedBox(height: 2),
                      Text(
                        preview['siteName'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final url = await _showUrlDialog(context);
          if (url == null) return;
          FirestoreService.addNewUrl(url);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URL added successfully!'),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<String?> _showUrlDialog(BuildContext context) async {
    String url = '';
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add URL'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              onChanged: (value) {
                url = value;
              },
              decoration: InputDecoration(
                hintText: 'https://www.flutter.dev',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(
                'Add',
              ),
              onPressed: () {
                Navigator.of(context).pop(url);
              },
            ),
          ],
        );
      },
    );

    return result;
  }
}
