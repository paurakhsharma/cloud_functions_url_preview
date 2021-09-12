# Using Firebase Cloud Functions to Generate URL Preview

Hello Flutter Devs,

In this article we are going to learn how to use Firebase cloud functions
to parse the URL [og tags](https://ogp.me/) and display the URL previews
in the Flutter app.

![URL Preview Demo](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/lezxa2b18ay8kfyss30z.png)

### How this works?

1. User adds a url in the Firestore collection `urls`.
2. Cloud functions then triggers `onCreate()` which:

     i) Makes the request to the url

     ii) Parses the og tags from the response

     iii) Saves the og details in the Firestore collection `previews`

### Let's get started

We are going to use `FloatingActionButton` to open the dialog where user can add new url.

![Adding new URL](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/wqxakzcp4wre6n4nb581.png)

```dart
FloatingActionButton(
  onPressed: () async {
    final url = await _showUrlDialog(context);
    if (url == null) return;
    final collection = FirebaseFirestore.instance.collection('urls');
    collection.add({'url': url});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('URL added successfully!'),
      ),
    );
  },
  child: Icon(Icons.add),
)
```

Lets implement `_shorUrlDialog`

```dart
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
```

Now, [Initialize a cloud functions](https://firebase.google.com/docs/functions/get-started) for your Firebase project.

Go to the `functions` directory.

We need to install two packages which makes requesting url and parsing the og tags easier.

```
npm install got cheerio
```

Now you are ready to add the cloud functions.

Add this code to your `functions/index.js`

```js
// packages to make api request and parse response
const got = require('got');
const cheerio = require('cheerio');

const functions = require('firebase-functions');
const admin = require('firebase-admin'); // Cloud Firestore access
const db = admin.initializeApp().firestore();

exports.addUrlPreview = functions.firestore
  .document('urls/{urlId}')
  .onCreate(async (snapshot) => {
    var querySnapshot = await snapshot.ref.get();
    var data = querySnapshot.data();
    var url = data.url;
    if (url.trim() === '') {
      console.log('Empty string... Skipping...');
      return;
    }

    const ogData = await getOGData(url);
    console.log(ogData);

    const publicationRef = db.collection('previews');
    await publicationRef.add(ogData);
  });

/**
 * Get the og details from the URL
 *
 * @param {String} url
 * @return {Promise} of object containing site's title, description, siteName, and image.
 */
async function getOGData(url) {
  if (!url || url.length === 0) return;
  const response = await got(url);

  const $ = cheerio.load(response.body);

  const titleAttr = $('meta[property="og:title"]').attr();
  const descriptionAttr = $('meta[property="og:description"]').attr();
  const siteNameAttr = $('meta[property="og:site_name"]').attr();
  const imageAttr = $('meta[property="og:image"]').attr();

  return {
    title: titleAttr ? titleAttr.content : '',
    description: descriptionAttr ? descriptionAttr.content : '',
    siteName: siteNameAttr ? siteNameAttr.content : '',
    image: imageAttr ? imageAttr.content : '',
    url: url,
  };
}
```

Now you can display the URL previews in your Flutter app.

I am going to use `StreamBuilder` for this purpose.

```dart
StreamBuilder(
  stream: FirebaseFirestore.instance.collection('urls').snapshots(),
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
)
```

And you are done.

You can make further improvements to `getOGData()` method to make it more robust.

You can find the complete source code here: 

Happy Coding!