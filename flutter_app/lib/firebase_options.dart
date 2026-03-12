import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Replace these with your actual Firebase project configuration.
/// You can get these values from the Firebase Console.
class DefaultFirebaseOptions {
  /// Returns true when a non-placeholder configuration exists for
  /// the current platform. This lets the app gracefully skip Firebase
  /// when secrets are not provided (e.g. demo mode or CI).
  static bool get isConfiguredForCurrentPlatform {
    if (kIsWeb) return !_hasPlaceholder(web);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return !_hasPlaceholder(android);
      case TargetPlatform.iOS:
        return !_hasPlaceholder(ios);
      default:
        // No desktop targets configured.
        return false;
    }
  }

  static bool _hasPlaceholder(FirebaseOptions options) {
    return options.apiKey.startsWith('YOUR_') ||
        options.appId.startsWith('YOUR_') ||
        options.messagingSenderId.startsWith('YOUR_') ||
        (options.iosClientId?.startsWith('YOUR_') ?? false);
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Firebase configuration for Android
  /// TODO: Replace with your actual Firebase configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'kitchen-diary',
    storageBucket: 'kitchen-diary.appspot.com',
  );

  /// Firebase configuration for iOS
  /// TODO: Replace with your actual Firebase configuration
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'kitchen-diary',
    storageBucket: 'kitchen-diary.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.kitchendiary.app',
  );

  /// Firebase configuration for Web
  /// TODO: Replace with your actual Firebase configuration
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'kitchen-diary',
    storageBucket: 'kitchen-diary.appspot.com',
    authDomain: 'kitchen-diary.firebaseapp.com',
  );
}
