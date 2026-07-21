import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../global.dart';

// firebase_service.dart - literally the only file allowed to know firebase exists
// everything else just calls FB.whatever() and doesnt care how it works ; AAS
// keeping it all in one place means if stuff breaks
// we only have to fix one file instead of hunting through every page... again.

// TWO PROJECTS because yes:
//   public  - paperjournal-public  - community chat, user profiles, bookings
//   private - paperjournal-private - org user mirror for admin, legacy stuff // I genuinely have no clue what I did with this again, some reserved feature PSV suggested, forgot to note down.
// both get initialised in main() before runApp(), dont call FB anything before that

// PUBLIC DB RULES NEEDED (paste into firebase console -> firestore -> rules):
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//     match /users/{userId} {
//       allow read, write: if request.auth != null && request.auth.token.email == userId;
//       allow read: if request.auth != null && request.auth.token.email == 'admin@example.com';
//       match /bookings/{bookingId} {
//         allow read, write: if request.auth != null && request.auth.token.email == userId;
//         allow read: if request.auth != null && request.auth.token.email == 'admin@example.com';
//       }
//     }
//     match /community_messages/{msgId} {
//       allow read, write: if request.auth != null;
//     }
//   }
// }
// DO NOT FUCKING TOUCH THIS WITHOUT UPDATING THE PRIVATE DB RULES TOO, I SUFFERED ENOUGH BECAUSE OF THE MISMATCH REEEEEEE ; AAS

class FB {
  FB._(); // static only, instantiating this would be weird and wrong, and frankly perverse. just dont... ; AAS

  static FirebaseApp? publicApp;
  static FirebaseApp? privateApp;

  // shorthand so call sites dont have to write FirebaseFirestore.instanceFor(app: publicApp!) every single time, because I keep forgetting ; AAS
  static FirebaseFirestore get publicDB => FirebaseFirestore.instanceFor(app: publicApp!);
  static FirebaseFirestore get privateDB => FirebaseFirestore.instanceFor(app: privateApp!);
  static FirebaseAuth get auth => FirebaseAuth.instanceFor(app: publicApp!);

  // call this once in main() before runApp(), await it - pls use async ; ooh Future AAS haunting you boo!
  static Future<void> init({
    required FirebaseOptions publicOptions,
    required FirebaseOptions privateOptions,
  }) async {
    publicApp = await Firebase.initializeApp(
      name: 'public',
      options: publicOptions,
    );
    privateApp = await Firebase.initializeApp(
      name: 'private',
      options: privateOptions,
    );
  }

  // -----------------------------------------------------------------------
  // AUTH
  // returns null on success (NULL ON SUCESS, please rmb, I change it from returning "sucess" string), an error string on failure
  // the switch on e.code (i almost forgot what this is) is because firebase auth errors are strings not enums for some reason - it's logical ah, but inconvienient for my specific fucked up use case I mean lol ; AAS
  // ------------------------------------------------------------------------

  static Future<String?> signIn(String email, String password) async {
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user;
      if (user == null) return 'login came back null, very weird ; AAS';

      // admin check is email match only - display name isnt reliably set on firebase auth (I TRIED MAN, WHERE TF IS DISPLAY NAME) ; AAS
      final isAdmin = email.toLowerCase() == 'admin@example.com';

      Global.login(
        email: user.email ?? email,
        name: user.displayName ?? email.split('@').first,
        rememberMe: Global.rememberMe,
        isAdmin: isAdmin,
      );

      return null; // null = all good
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No account with that email';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Wrong password';
        case 'invalid-email':
          return 'That email looks wrong';
        case 'user-disabled':
          return 'Account disabled, talk to admin';
        case 'too-many-requests':
          return 'Too many attempts, chill for a bit';
        default:
          return 'Auth error: ${e.code}';
      }
    } catch (e) {
      return 'Something exploded: $e'; // ; AAS
    }
  }

  // sign up - creates the firebase auth account AND writes a user doc immediately
  // so admin can see them even before they fill in any profile details ; AAS
  static Future<String?> signUp(String email, String password, String displayName) async {
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);

      try {
        await publicDB.collection('users').doc(email).set({
          'name': displayName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastSynced': FieldValue.serverTimestamp(),
          'companyName': null,
          'companyRole': null,
          'companyCode': null,
        }, SetOptions(merge: true));
      } catch (_) {
        // firestore write failed but auth account still exists, not fatal, just a headache... ENJOY IT :3 ; AAS
      }

      Global.login(email: email, name: displayName, rememberMe: Global.rememberMe);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'That email is already registered';
        case 'weak-password':
          return 'Password too weak, try harder';
        case 'invalid-email':
          return 'Email looks wrong';
        default:
          return 'Sign up failed: ${e.code}';
      }
    } catch (e) {
      return 'Something broke: $e';
    }
  }

  static Future<void> signOut() async {
    await auth.signOut();
    Global.logout();
  }

  // ---------------------------------------------------------------------
  // COMMUNITY MESSAGES
  // no limit on the query so all history is always visible ; AAS (like obv, its bad in actual apps, but this is just class, so it good.)
  // even brand new users see everything that was ever posted (which yes, intentional)
  //  ---------------------------------------------------------------------

  static Stream<List<CommunityMessage>> communityStream() {
    return publicDB
        .collection('community_messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityMessage.fromJson({...d.data(), 'id': d.id}))
            .toList());
  }

  static Future<void> sendMessage(CommunityMessage msg) async {
    // write locally first so the ui feels instant, firestore catches up ; AAS
    Global.communityMessages.add(msg);
    Global.saveCommunityMessages();

    try {
      await publicDB.collection('community_messages').doc(msg.id).set({
        'id': msg.id,
        'authorName': msg.authorName,
        'authorEmail': msg.authorEmail,
        'text': msg.text,
        'timestamp': FieldValue.serverTimestamp(), // server time so ordering is always correct (I think it defaults to American timing, PSV fix this for me UwO??) ; AAS
      });
    } catch (e) {
      // firestore write failed, message is still locally visible at least - PSV req acknowledged ; AAS
    }
  }

  static Future<void> deleteMessage(String id) async {
    Global.communityMessages.removeWhere((m) => m.id == id);
    Global.saveCommunityMessages();
    try {
      await publicDB.collection('community_messages').doc(id).delete();
    } catch (_) {} // silent fail, local already removed ; AAS
  }

  // ─────────────────────────────────────────────────────────────────
  // USER PROFILE + BOOKINGS SYNC - public project
  // ─────────────────────────────────────────────────────────────────

  static Future<String?> syncUserToPublic() async {
    final email = Global.userEmail;
    if (email == null) return 'not logged in lol';

    try {
      final userDoc = publicDB.collection('users').doc(email);

      await userDoc.set({
        'name': Global.userName,
        'email': email,
        'companyName': Global.companyName,
        'companyRole': Global.companyRole,
        'companyCode': Global.companyCode,
        'lastSynced': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // batch write all bookings so its one round trip not N ; AAS
      final bookingsCol = userDoc.collection('bookings');
      final batch = publicDB.batch();
      for (final b in Global.bookings) {
        batch.set(bookingsCol.doc(b.id), b.toJson());
      }
      await batch.commit();

      return null;
    } catch (e) {
      return 'Sync failed: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ADMIN pull all users from public dbase
  // reads users collection + each users bookings subcollection ; AAS
  // requires admin@example.com to be logged in through firebase auth
  // (not the old hardcoded bypass - that never set a token, hence permission-denied) ; AAS
  // ─────────────────────────────────────────────────────────────────

  static Future<String?> fetchAllPublicUsers() async {
    if (!Global.isAdmin) return 'not admin, nice try'; // ; AAS

    try {
      final snap = await publicDB.collection('users').get();
      final users = <OrgUser>[];

      for (final doc in snap.docs) {
        final data = doc.data();

        final bookingSnap = await publicDB
            .collection('users')
            .doc(doc.id)
            .collection('bookings')
            .get();

        final bookings = bookingSnap.docs.map((b) {
          try {
            return Booking.fromJson(b.data());
          } catch (_) {
            return null; // malformed booking doc, skip it ; AAS (idk why I got like major deja vu writing this, felt like the global.dart lol)
          }
        }).whereType<Booking>().toList();

        users.add(OrgUser(
          id: doc.id,
          name: data['name'] as String? ?? doc.id,
          email: data['email'] as String? ?? doc.id,
          companyName: data['companyName'] as String?,
          companyRole: data['companyRole'] as String?,
          companyCode: data['companyCode'] as String?,
          bookings: bookings,
        ));
      }

      Global.orgUsers = users;
      return null;
    } catch (e) {
      return 'Fetch failed: $e';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // ADMIN - totally does things; AAS
  // ─────────────────────────────────────────────────────────────────

  static Future<String?> fetchOrgUsers() async {
    if (!Global.isAdmin) return 'still not admin ; AAS';

    try {
      final snap = await privateDB.collection('org_users').get();
      Global.orgUsers = snap.docs.map((d) {
        final data = d.data();
        return OrgUser.fromJson({...data, 'id': d.id});
      }).toList();
      return null;
    } catch (e) {
      return 'Fetch failed: $e';
    }
  }

  static Future<void> mirrorUserToPrivate({
    required String email,
    required String name,
    String? companyName,
    String? companyRole,
    String? companyCode,
    required List<Booking> bookings,
  }) async {
    try {
      await privateDB.collection('org_users').doc(email).set({
        'id': email,
        'name': name,
        'email': email,
        'companyName': companyName,
        'companyRole': companyRole,
        'companyCode': companyCode,
        'bookings': bookings.map((b) => b.toJson()).toList(),
        'lastMirrored': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // mirror is not critical, if it fails we just skip it ; AAS
    }
  }

  // public sync + private mirror in one call, this is what the sync button uses (uhm. don't spam sync like Vanavan did, VERY BAD) ; AAS
  static Future<String?> fullSync() async {
    final err = await syncUserToPublic();
    if (err != null) return err;

    await mirrorUserToPrivate(
      email: Global.userEmail!,
      name: Global.userName ?? '',
      companyName: Global.companyName,
      companyRole: Global.companyRole,
      companyCode: Global.companyCode,
      bookings: Global.bookings,
    );

    return null;
  }
}

// Am I cute? Felt cute coding this hehe. I.I