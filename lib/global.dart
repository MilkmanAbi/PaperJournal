import 'dart:convert';
import 'dart:io';

// global.dart - one big static class that every page imports
// yes its all static yes its a bit of a god object (rahhhhhhh) yes we know ; AAS
// the alternative was passing state down 5 widget layers and nobody wanted that kinda sexy hell so
// everything lives here -> session, bookings, notes, community msgs, org users
// the actual persistence is dart:io + jsonencode into the system temp (iirc, not sure what I put?) folder which
// is genuinely hacky shit but it works on android without adding shared_prefs (yeah, no, I just didn't feel like this bag of worms tbh, I could, but nah) as a dep
// if you wanna swap it out later, every load/save call is isolated at the bottom - ; AAS... (Please don't try to swap stuff out, my hacky shit breaks, if it works, leave it)
// just replace the file(..) calls with whatever plugin yw and the rest stays the same... same-ish? idk.
class Global {
  // who is logged in right now, null if nobody (null needed, or it defaults to admin? address that maybe...)
  // was non-nullable at one point, caused a fun crash on logout, never again ; AAS - yayyyy
  static String? userEmail;
  static String? userName;
  static DateTime? _loginAt; // tracks when the session started, used for the expiry check (for the 30 day remember me, I felt a bit extra coding this, felt cute ngl)

  static bool get isLoggedIn => userEmail != null;

  // this gets set to true when admin@example.com logs in via firebase auth
  // DO NOT FUCKING SET THIS MANUALLY ANYWHERE- it must come through login() because it hacky ; AAS
  // used in app_shell to decide which tabs to show, nowhere else - mind that, do not rewrite elsewhere
  static bool isAdmin = false;

  // if the user ticked remember me button on login we give them 30 days instead of 3 (I increased it because I kwpt forgting my own password)
  // this flag is read in loadSession() to pick the right window ; AAS
  static bool rememberMe = false;

  // company info the user fills in on the profile page
  // gets pushed firestore at save, pulled back on next login to autofill (PSV requested, acknowledged) ; AAS
  static String? companyName;
  static String? companyRole;
  static String? companyCode; // the code admin hands out to link employees to the org (PSV requested, acknowledged)

  // list of OrgUser pulled from firestore for the admin page (it'll fail if firestore slow - uhm, you can't really do anything. I considered adding a timeout and retry, but lazy, maybe is MSS forces me.)
  // completely empty for normal users, they never touch this (reserve for possible future use though. PSV); AAS
  static List<OrgUser> orgUsers = [];

  // community chat messages keeping in sync with the firestore stream
  // local copy is the fallback if the stream hasnt connected yet (happens a lot, again, this comment is just to prevent panic); AAS
  static List<CommunityMessage> communityMessages = [];

  // isAdmin is optional here - firebase_service passes it expllcitly after checking
  // the authentication token, loadSession() passes it from disk, both are fine enough ; AAS
  static void login({
    required String email,
    required String name,
    bool rememberMe = false,
    bool? isAdmin,
  }) {
    userEmail = email;
    userName = name;
    _loginAt = DateTime.now();
    Global.rememberMe = rememberMe;
    // if caller passed isAdmin explicitly (firebase auth flow), use it
    // otherwise derive from email alone (session restore path) ; AAS
    Global.isAdmin = isAdmin ?? (email.toLowerCase() == 'admin@example.com');
    _saveSession();
  }

  static void logout() {
    userEmail = null;
    userName = null;
    _loginAt = null;
    isAdmin = false;
    companyName = null;
    companyRole = null;
    companyCode = null;
    bookings.clear();
    notes.clear();
    orgUsers.clear();
    _saveSession();
    _saveBookings();
    _saveNotes();
    saveCommunityMessages();
  }

  // bookings list - mutate only through addBooking/cancelBooking/deleteBooking - only proper methpds implemented as of yet, psv
  // each of those calls -saveBookings() so disk stays in sync ; AAS
  static List<Booking> bookings = [];

  static void addBooking(Booking booking) {
    bookings.add(booking);
    _saveBookings();
  }

  static void cancelBooking(String id) {
    for (final booking in bookings) {
      if (booking.id == id) {
        booking.status = BookingStatus.cancelled;
        break; // break needed, break loop
      }
    }
    _saveBookings();
  }

  // deleteBooking actually removes from the list, cancelBooking just changes the status
  // cancelled bookings stay visible so you can see them and delete manually - MSS/PSV feature add
  // this is the one that makes findBooking return null ; AAS
  static void deleteBooking(String id) {
    bookings.removeWhere((b) => b.id == id);
    _saveBookings();
  }

  static Booking? findBooking(String id) {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null; // null here triggers the lonely cosmos error page in booking_page (see main for implementation, all unaccounted things get here - here, it's unfound bookings)
  }

  static List<Booking> bookingsForDay(DateTime day) {
    return bookings.where((b) => _isSameDay(b.dateTime, day)).toList();
  }

  // notes pinned to calendar days, same mutate then go save pattern ; AAS
  static List<Note> notes = [];

  static void addNote(Note note) {
    notes.add(note);
    _saveNotes();
  }

  static void deleteNote(String id) {
    notes.removeWhere((n) => n.id == id);
    _saveNotes();
  }

  static List<Note> notesForDay(DateTime day) {
    return notes.where((n) => _isSameDay(n.date, day)).toList();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ────────────────────────────────────────────────────────────────────
  // HACKY LOCAL PERSISTENCE - dart:io + system temp folder
  // yes this is genuinely hacky shit, yes it works, yes we use it anyway ; AAS
  // system temp gets cleared by the OS eventually but thats fine for an assignment, saad's laptop temp weird tho.
  // if you proper youd swap these File() calls for shared_preferences or hive or something but eh.
  // ────────────────────────────────────────────────────────────────────

  static File _sessionFile() =>
      File('${Directory.systemTemp.path}/paperjournal_session.json');

  static File _bookingsFile() =>
      File('${Directory.systemTemp.path}/paperjournal_bookings.json');

  static File _notesFile() =>
      File('${Directory.systemTemp.path}/paperjournal_notes.json');

  static void _saveSession() {
    try {
      final file = _sessionFile();
      if (userEmail == null) {
        // if nobody logged in just nuke the file, no point keeping stale data, I implemented this like last min, because it's doing weird things once the file gets even midly saturated man, idk wtf ; AAS
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(jsonEncode({
        'email': userEmail,
        'name': userName,
        'loginAt': _loginAt?.toIso8601String(),
        'isAdmin': isAdmin,
        'rememberMe': rememberMe,
        'companyName': companyName,
        'companyRole': companyRole,
        'companyCode': companyCode,
      }));
    } catch (_) {
      // write failed, probably no disk perms or temp dir doesnt exist - it happens now and then, like if you legit try to install using adb on acrtual android
      // not much we can do, just dont crash the app over it ; AAS
    }
  }

  static void _saveBookings() {
    try {
      final file = _bookingsFile();
      if (bookings.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(jsonEncode(bookings.map((b) => b.toJson()).toList()));
    } catch (_) {
      // same deal as _saveSession, silent fail ; AAS
    }
  }

  static void _saveNotes() {
    try {
      final file = _notesFile();
      if (notes.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(jsonEncode(notes.map((n) => n.toJson()).toList()));
    } catch (_) {
      // yep
    }
  }

  // call all three load methods in main() before runApp() - just put global.dart in gpt and ask how to if stuff breaks in main again
  // if a file doesnt exist yet, yeah its fine, we just start empty ; AAS
  // if a file is corrupted we start empty and dont crash which is the important part (if corrupted, just reset android emulator and pretend like the code works)

  static void loadSession() {
    try {
      final file = _sessionFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final loginAtStr = data['loginAt'] as String?;
      final loginAt = loginAtStr != null ? DateTime.tryParse(loginAtStr) : null;
      final savedRememberMe = (data['rememberMe'] as bool?) ?? false;
      // remember me = 30 day window, otherwise 3 days, then they log in again ; AAS
      final window = savedRememberMe ? const Duration(days: 30) : const Duration(days: 3);
      final expired = loginAt == null || DateTime.now().difference(loginAt) > window;

      if (expired) {
        // session too old, kill it and let them log in again (again, AAS feature add, me forget admin password T~T)
        file.deleteSync();
        return;
      }

      userEmail = data['email'] as String?;
      userName = data['name'] as String?;
      _loginAt = loginAt;
      rememberMe = savedRememberMe;
      isAdmin = (data['isAdmin'] as bool?) ?? false;
      companyName = data['companyName'] as String?;
      companyRole = data['companyRole'] as String?;
      companyCode = data['companyCode'] as String?;
    } catch (_) {
      // corrupt json or missing file, just leave everything null and show the login page, you might notice a startup delay - uhm, not too sure what we can do ; AAS
    }
  }

  static void loadBookings() {
    try {
      final file = _bookingsFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      bookings = data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // corrupt file, start empty ; AAS
    }
  }

  static void loadNotes() {
    try {
      final file = _notesFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      notes = data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // also start empty ; AAS
    }
  }

  // community messages are stored locally as a fallback while the stream loads (often actually)
  // they get overwritten by the firestore stream the moment it connects ; AAS (it does lead to some weird edge-cases that I can't really test because I enjoy my sleep)
  static File _communityFile() =>
      File('${Directory.systemTemp.path}/paperjournal_community.json');

  static void saveCommunityMessages() {
    try {
      final file = _communityFile();
      if (communityMessages.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(jsonEncode(communityMessages.map((m) => m.toJson()).toList()));
    } catch (_) {
      // meh ; AAS
    }
  }

  static void loadCommunityMessages() {
    try {
      final file = _communityFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      communityMessages = data.map((e) => CommunityMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // start empty ; AAS
    }
  }
}

// ------------------------------------------------------------------------------------------------------------------------
//  DATA ModeL
// plain dart classes with toJson/fromJson, no fancy code gen needed (win-win, simplicity and function, all good); AAS
// ----------------------------------------------------------------------------------------------------------------------

class Booking {
  final String id;
  final String serviceName;
  final DateTime dateTime;
  BookingStatus status;

  Booking({
    required this.id,
    required this.serviceName,
    required this.dateTime,
    this.status = BookingStatus.pending,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'dateTime': dateTime.toIso8601String(),
        'status': status.name,
      };

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        serviceName: json['serviceName'] as String,
        dateTime: DateTime.parse(json['dateTime'] as String),
        status: BookingStatus.values.byName(json['status'] as String),
      );
}

// three states, thats it, you wanna add more? talk to AAS first ; AAS
enum BookingStatus { pending, confirmed, cancelled }

class Note {
  final String id;
  final DateTime date; // date only, time is always midnight, doesnt matter
  final String text;

  Note({required this.id, required this.date, required this.text});

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'text': text,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        text: json['text'] as String,
      );
}

class CommunityMessage {
  final String id;
  final String authorName;
  final String authorEmail;
  final String text;
  final DateTime timestamp;

  CommunityMessage({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'text': text,
        'timestamp': timestamp.toIso8601String(), // stored as string locally
      };

  // firestore sends back a Timestamp object (took me a while to figure this out, google was paining me, gpt was fibbing me, i hate firestore), local storage sends back a string
  // this handles both because dart doesnt care and neither do we (mostly just I. I'm a good lil code monkey >:3) ; AAS
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    if (raw is DateTime) return raw;
    // Timestamp.toDate() exists on the firestore type but we cant import it here (Or can we...? vsauce music. but no.)
    // so we check the runtime type name like animals and call toDate dynamically, works enough
    if (raw.runtimeType.toString().contains('Timestamp')) {
      return (raw as dynamic).toDate() as DateTime;
    }
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now(); // absolute last resort, shouldnt ever hit this, if it does, please re-evaluate your mental health ; AAS
  }

  factory CommunityMessage.fromJson(Map<String, dynamic> json) => CommunityMessage(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        authorEmail: json['authorEmail'] as String,
        text: json['text'] as String,
        timestamp: _parseTimestamp(json['timestamp']),
      );
}

// pulled from firestore public db for the admin page
// normal users never see or touch this class, they used to until v3 and it was hidden, but I just fixed it a bit, less long term headache ; AAS
class OrgUser {
  final String id;
  final String name;
  final String email;
  final String? companyName;
  final String? companyRole;
  final String? companyCode;
  final List<Booking> bookings;

  OrgUser({
    required this.id,
    required this.name,
    required this.email,
    this.companyName,
    this.companyRole,
    this.companyCode,
    this.bookings = const [],
  });

  factory OrgUser.fromJson(Map<String, dynamic> json) => OrgUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        companyName: json['companyName'] as String?,
        companyRole: json['companyRole'] as String?,
        companyCode: json['companyCode'] as String?,
        bookings: (json['bookings'] as List<dynamic>? ?? [])
            .map((b) => Booking.fromJson(b as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'companyName': companyName,
        'companyRole': companyRole,
        'companyCode': companyCode,
        'bookings': bookings.map((b) => b.toJson()).toList(),
      };
}

// Yeah... global.dart was supposed to be tiny, uhm, it was like 80 lines. Idk why the features bled into here, not how I planned it, but it works, it's a monolithic mess, not modular
// likr i initially designed it, but it works, so heyyyy.


// so global.dart was supposed to be a facade. literally just a middleman.
// pages ask Global for data, Global holds it, firebase_service is the only
// one who actually knows how any of it works. clean right? yeah it was.
// then booking mutations needed to auto-save (not fun), so save logic came in here.
// then notes needed the same thing. then community needed a local fallback.
// then the models needed to live somewhere and this file was already
// imported by literally everyone so. yeah. you can see where this went.
// the original design is still technically alive in firebase_service.dart -
// that file genuinely doesn't know what the UI does, never talks to pages,
// just trusts Global. the facade contract held on that side. Global was
// supposed to be the same kind of thin on its other side. it is not thin.
// what started as an interface became the interface + persistence layer +
// redundancy logic + all the models because each individual addition made
// sense at the time and convenience is a hell of a drug, copium fr.
// i coded redundancy into the pages themselves, forced PSV and MSS to...
// then we coded redundancies for the redundancies...
// then we did i made another redundancy featureset in global. the app is literally
// build for demoing, will NEVER error out badly, but like... sheesh.
// i just did it accidentally... proud? horrified? yes. Scared? yes, very. Slightly turned on too. ; AAS