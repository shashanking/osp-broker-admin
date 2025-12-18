'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "bb8f1c2990767ebb68571bc57671312a",
"version.json": "4372bf2a083995cbe14447310f9f651c",
"index.html": "45eb6f09475ef5b86402fa56a5250351",
"/": "45eb6f09475ef5b86402fa56a5250351",
"main.dart.js": "c0d196bd020d2ef2e112de174dbcd993",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "e6a772490c66fc12f616ff69bfaeafa7",
"assets/AssetManifest.json": "f858e6d793f7bad9aa7de09ca5931082",
"assets/NOTICES": "7b148f178b27933bb2ac2080ded62033",
"assets/FontManifest.json": "47a09097ab3c3ba0eef4ea68dcea2280",
"assets/AssetManifest.bin.json": "45e3f175cd87764b2675bf202b871877",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "d84ccb8baf461ed7f74e613fb1312984",
"assets/fonts/MaterialIcons-Regular.otf": "4bd351f2cf80a4ab187335cd3ae670c0",
"assets/assets/images/about-page-sec4-bg.png": "bd20295214c21f4fef68cf91fd6f9f06",
"assets/assets/images/membership_cardbg.png": "c224864bd6b1826f132144a99212a635",
"assets/assets/images/osp-logo.png": "3f2e52158c45f601f4a24e648edb9cdc",
"assets/assets/images/0_Hero.png": "18b59947ac22ebcfe0718b3680161729",
"assets/assets/images/rfp-banner-image.png": "e4da644b0e5a30a1c0c2d2610c4fa640",
"assets/assets/images/explore-img3.png": "2d6f59fcfd4709c95df4da2c0494bb90",
"assets/assets/images/explore-img2.png": "e98a21ef8704b289df2135ff7bc304c3",
"assets/assets/images/business_representative_login_hero_img.png": "9077634d24a17508a51844e19ceae0e4",
"assets/assets/images/about-us-banner.png": "c2f797c4bd824faa1bc624687c8371fd",
"assets/assets/images/explore-img1.png": "ab42fa283138aae9074bf31dcc78b7ee",
"assets/assets/images/featured-img3.png": "6d07be9ceee33fcc3e3a32aae8cff624",
"assets/assets/images/RFP_Hero_img.png": "d4ca92833091362251879d1d7c4452a5",
"assets/assets/images/featured-img2.png": "eead1b5704748f08762a54da7af4b5f7",
"assets/assets/images/testimonial-bg.png": "024ad020ace906005ac4a2618eb4a830",
"assets/assets/images/featured-img1.png": "5ac2ef10a212b9f6cb2fefd1d7879c12",
"assets/assets/images/about-page-join-bg.png": "7b06a0539ce9e973bd0a835368f5139d",
"assets/assets/images/RFP_Hero_circular_img.png": "95f73ac3a32fc81d109785c924b2304c",
"assets/assets/images/membership-sec-bg.png": "6d5e2b58572beb759b7633dc26906d28",
"assets/assets/images/about-us-page-sec2-bg.png": "257b4aa136cc90509d1d3a51bb7fc4f1",
"assets/assets/images/membership_herobanner.png": "c22f719a3e2a871a9622e25ead31ffc2",
"assets/assets/images/RFP_Track_Img.png": "afd572642af227a624120f88789c224a",
"assets/assets/images/RFP_Track_Img_bg.jpg": "1b3bdeb9ee2ed7cd2e44066fcd7462cc",
"assets/assets/images/about-us-banner2.png": "a0bf493eebc61614c9d7d72220ce400c",
"assets/assets/images/contact_us_heroimg.png": "96d97442ae786054f0bebe52be9c5d2c",
"assets/assets/images/landing-banner3.png": "3cac056ea6962ea52ec4af1dd28195d6",
"assets/assets/images/landing-bg3.png": "0f0ed6b3ba0ccd85c8975aa556d7bcd5",
"assets/assets/images/rfp-banner-background.png": "ce9be8106f21cd8d942402fdf47ea43d",
"assets/assets/images/osp-logo-footer.png": "d30186f9bd26624c05ae43be98f49ff1",
"assets/assets/images/user_login_hero_img.png": "2298976f2985028d56d508599582fa3c",
"assets/assets/images/profile.png": "71236188c5e31371b7f5a389af9ed4fe",
"assets/assets/images/explore-bg.png": "024ad020ace906005ac4a2618eb4a830",
"assets/assets/images/membership_hero_circular.png": "de0f2a3c7f8eb83ad9bcfc4e00311c30",
"assets/assets/images/testimonial-right-bg.png": "5f87443fe27141912c8d52ec542fef82",
"assets/assets/images/about-us-page-sec2-img.png": "a0bf493eebc61614c9d7d72220ce400c",
"assets/assets/images/testimonial-img.png": "bad74523d0f986010bc4de2d418bebad",
"assets/assets/images/about-us-banner2-bg.png": "845c63e7f1f35aa053b1477f6cc80565",
"assets/assets/images/auction-sample.png": "846be243c02855c6b28ad2c2f338f96f",
"assets/assets/videos/7021928_City_Smart_1920x1080.mp4": "c224819fec56bcfa8124bb4754cf289b",
"assets/assets/videos/landing-banner.mp4": "e5c33c46ff5df36eb8eddb102f96cb75",
"assets/assets/videos/3d-envelope-with-bell-notification-cartoon-new-email-message-notice-icon-3d-vector-illustration-message%25201.png": "383a4e868bb692df59a62776d9ac8032",
"assets/assets/videos/about-us-banner.mp4": "c7b3a76033c8b241636d142aacf67240",
"assets/assets/icons/arrow-circle-left.png": "c82efc40612b80ecfa68f4faeff0461c",
"assets/assets/icons/forum.png": "42c5f780f931d633037921a05fd00140",
"assets/assets/icons/rfp.png": "313eee0eb625b174c7eb6da50725c997",
"assets/assets/icons/instagram.png": "1ecba7706608b09da243edbcf3ae135a",
"assets/assets/icons/x.png": "bc3a89c3d71a45b1ae9e18ee5a0e1dc9",
"assets/assets/icons/logo_google.png": "a743354f792c33c4123e6e9c2d14ffab",
"assets/assets/icons/customer-centricity.png": "bdb9a12e9950ac74233986c7cd0b06b4",
"assets/assets/icons/forum/add-poll.png": "d896ada169c39ea3f8688169bea300bb",
"assets/assets/icons/forum/add-category.png": "eac90c21de6b5642318da81c272daf78",
"assets/assets/icons/forum/approvals.png": "93f0344044b1c874dda4354e719a2e9b",
"assets/assets/icons/forum/events.png": "485f25f7768a0d496ea21e0a7c80fdba",
"assets/assets/icons/forum/add-announcement.png": "9087e2a8c3145c73cded28c10a44b30c",
"assets/assets/icons/forum/add-event.png": "7f8c4266b0837f783dae752b2a2c9add",
"assets/assets/icons/forum/announcements.png": "79b4057a682836343d32ffda8064a7eb",
"assets/assets/icons/cloud.png": "102e0cb3e29dbf4c83bc6eb33c7bb1e2",
"assets/assets/icons/membership.png": "db6107c9d59ae3234ad89e8f7ddaa5f9",
"assets/assets/icons/logo_apple.png": "b2653071079f3e58a62d8fe33d452c0d",
"assets/assets/icons/logo_facebook.png": "df618e4f503247c9f944915f57b3162b",
"assets/assets/icons/protect.png": "376dcd3152f51581714dcebbc279b50b",
"assets/assets/icons/facebook.png": "30c358d509a436dd0e8c848c60e43977",
"assets/assets/icons/auction.png": "9ea2dcb41e00ddafb70a479aed349424",
"assets/assets/icons/membership/bronze.png": "1f4653cba418f4c23ad9d8edd7070dc6",
"assets/assets/icons/membership/silver.png": "9707b112f2901668c999f8021eff629e",
"assets/assets/icons/membership/diamond.png": "9ee5b7603dbf01d7d5672e70a3d38683",
"assets/assets/icons/membership/free.png": "5de8a61522d98ae2b7570ba07cf056a2",
"assets/assets/icons/membership/gold.png": "b92824e0c5ea147abf857f6392b838a3",
"assets/assets/icons/membership/platinum.png": "25c569b902f64c04e9b5ed7016b7c9ab",
"assets/assets/icons/about-page-join-icon.png": "383a4e868bb692df59a62776d9ac8032",
"assets/assets/fonts/BasementGrotesque-Black_v1.202.otf": "069afac8a426962d5167130a8a8d4cf4",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
