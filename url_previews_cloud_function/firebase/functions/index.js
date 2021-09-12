// packages to make api request and parse response
const got = require('got');
const cheerio = require('cheerio');

const functions = require("firebase-functions");
const admin = require('firebase-admin'); // Cloud Firestore access
const db = admin.initializeApp().firestore();

exports.addUrlPreview = functions.firestore
  .document('urls/{urlId}')
  .onCreate(async (snapshot) => {
    var querySnapshot = await snapshot.ref.get();
    var data = querySnapshot.data();
    var url = data.url;
    if (url.trim() === '') {
      console.log('Empty string... Skipping...')
      return;
    }

    const ogData = await getOGData(url);
    console.log(ogData);

    const publicationRef = db.collection('previews');
    await publicationRef.add(ogData);
  });


/**
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
