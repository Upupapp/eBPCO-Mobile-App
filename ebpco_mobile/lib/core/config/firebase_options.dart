import 'package:firebase_core/firebase_core.dart';

/// The castilla-ebpco Firebase project's client configuration for the Android
/// app `ph.gov.castillasorsogon.ebpco` — the values from the console's
/// google-services.json. These identify the app to Firebase; they are not
/// secrets (the server's service-account key is, and it never ships here).
///
/// iOS is not configured: push on iPhone also needs an APNs key from an Apple
/// Developer account, so the app skips Firebase on iOS until that exists.
class EbpcoFirebaseOptions {
  EbpcoFirebaseOptions._();

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBetnBp4UBqi3TvvJ-klKujTj6kBKZn1S0',
    appId: '1:809230154500:android:c236dee55e21ec28b92e51',
    messagingSenderId: '809230154500',
    projectId: 'castilla-ebpco',
    storageBucket: 'castilla-ebpco.firebasestorage.app',
  );
}
