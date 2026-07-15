import 'dart:convert';
import 'dart:io';

//Global - share data any page can read and write, just need to import
//Everything just static here, do stuff like Global.userEmail from anywhere in the app can
class Global {
  // User Session stuff, simple
  static String? userEmail;
  static String? userName; // was non-nullable before but logout() sets it to null, so it HAS to be String?
  static DateTime? _loginAt; // when login() last ran - this is what makes the 3-day thing work

  static bool get isLoggedIn => userEmail != null;

  // admin flag - true when logged in with the ADMIN account
  // normal users never have this set, so the admin tab stays invisible to them
  static bool isAdmin = false;

  // if true, session window is 30 days instead of 3 - set on login with "remember me"
  static bool rememberMe = false;

  // company/org details the user fills in on their profile page
  // these get pushed to Firestore on "Sync to database" - see profile_page.dart
  static String? companyName;
  static String? companyRole;
  static String? companyCode; // the org code admin shares with their team

  // org users list - only populated for admin, pulled from Firestore on sync
  // normal users never touch this
  static List<OrgUser> orgUsers = [];

  // community messages - the open chat board
  static List<CommunityMessage> communityMessages = [];

  static void login({required String email, required String name, bool rememberMe = false}) {
    userEmail = email;
    userName = name;
    _loginAt = DateTime.now();
    Global.rememberMe = rememberMe;
    // check if this is the admin account
    isAdmin = (email.toLowerCase() == 'admin@example.com' && name.toUpperCase() == 'ADMIN');
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

  // bookings — used to be "memory only" per the old comment, which was
  // exactly the bug: nothing here ever hit disk, so a fresh app launch
  // always started from an empty list. addBooking/cancelBooking/deleteBooking
  // all call _saveBookings() now, same pattern as _saveSession() below.
  static List<Booking> bookings = [];

  static void addBooking(Booking booking) {
    bookings.add(booking); //update array, just add
    _saveBookings();
  }

  static void cancelBooking(String id) {
    for (final booking in bookings) {
      if (booking.id == id) {
        booking.status = BookingStatus.cancelled;
        break; //not sure why it weird without this break lol
      }
    }
    _saveBookings();
  }

  // actually removes it from the list (cancelBooking just marks the status).
  // used by the "search a booking by id" flow on BookingPage - if you delete
  // one and then look it up, that's the "not found" / cosmos error case.
  static void deleteBooking(String id) {
    bookings.removeWhere((b) => b.id == id);
    _saveBookings();
  }

  static Booking? findBooking(String id) {
    for (final booking in bookings) {
      if (booking.id == id) return booking;
    }
    return null; // caller shows the Lonely-Cosmos error state on null
  }

  static List<Booking> bookingsForDay(DateTime day) {
    return bookings.where((b) => _isSameDay(b.dateTime, day)).toList();
  }

  // notes — the calendar's "tap a day, see what's on it" feature.
  // same save-on-every-mutation pattern as bookings above.
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

  // dart:io persistence, use jsonencode, one of many ways to store, jsonencode method is easier
  static File _sessionFile() {
    return File('${Directory.systemTemp.path}/paperjournal_session.json');
  }

  static File _bookingsFile() {
    return File('${Directory.systemTemp.path}/paperjournal_bookings.json');
  }

  static File _notesFile() {
    return File('${Directory.systemTemp.path}/paperjournal_notes.json');
  }

  static void _saveSession() {
    try {
      final file = _sessionFile();
      if (userEmail == null) {
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
      // Added ugly fallback, if no disk write perms, just no persistence, added because app no worky worky, it deding :(
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
      // same deal as _saveSession, just don't crash over it
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
      // same deal again
    }
  }

  // Call this once before runApp() so a returning user skips the login page, one time thing. I mean, call it twice or even thrie too, who am I to stop ya?
  // Session now expires after 3 days (login once every 3 days, per the
  // Honor app reference) - if loginAt is older than that, this just
  // wipes the session file and leaves userEmail null, so MyApp's
  // Global.isLoggedIn check sends them back to LoginPage same as a
  // fresh install.
  static void loadSession() {
    try {
      final file = _sessionFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final loginAtStr = data['loginAt'] as String?;
      final loginAt = loginAtStr != null ? DateTime.tryParse(loginAtStr) : null;
      final savedRememberMe = (data['rememberMe'] as bool?) ?? false;
      // remember me = 30 day window, normal = 3 days
      final window = savedRememberMe ? const Duration(days: 30) : const Duration(days: 3);
      final expired = loginAt == null || DateTime.now().difference(loginAt) > window;

      if (expired) {
        file.deleteSync();
        return;
      }

      userEmail = data['email'] as String?;
      userName = data['name'] as String?;
      _loginAt = loginAt;
      rememberMe = savedRememberMe;
      // restore admin flag from session if it was set
      isAdmin = (data['isAdmin'] as bool?) ?? false;
      companyName = data['companyName'] as String?;
      companyRole = data['companyRole'] as String?;
      companyCode = data['companyCode'] as String?;
    } catch (_) {
      // if missing or corrupt file just start logged out, no crash, crash VERY bad for morale
    }
  }

  // call alongside loadSession() before runApp() - same idea, just for bookings
  static void loadBookings() {
    try {
      final file = _bookingsFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      bookings = data.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // corrupt/missing file, just start with an empty list, no crash
    }
  }

  // and again for notes
  static void loadNotes() {
    try {
      final file = _notesFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      notes = data.map((e) => Note.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // corrupt/missing file, just start with an empty list, no crash
    }
  }

  // community messages - same pattern, public for CommunityPage to call after add/delete
  static File _communityFile() {
    return File('${Directory.systemTemp.path}/paperjournal_community.json');
  }

  static void saveCommunityMessages() {
    try {
      final file = _communityFile();
      if (communityMessages.isEmpty) {
        if (file.existsSync()) file.deleteSync();
        return;
      }
      file.writeAsStringSync(jsonEncode(communityMessages.map((m) => m.toJson()).toList()));
    } catch (_) {
      // same deal
    }
  }

  static void loadCommunityMessages() {
    try {
      final file = _communityFile();
      if (!file.existsSync()) return;
      final data = jsonDecode(file.readAsStringSync()) as List<dynamic>;
      communityMessages = data.map((e) => CommunityMessage.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // start empty on corrupt/missing
    }
  }
}

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

  // plain Map so jsonEncode in _saveBookings() can serialize it directly
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

enum BookingStatus { pending, confirmed, cancelled } //Yep, three states, these three. dictionary. :3
//tell me if you're gonna add more pls AAS

// a note pinned to a specific calendar day - this is the "note taking" half
// of "note taking, booking calendar app" that wasn't built yet
class Note {
  final String id;
  final DateTime date; // date-only, time portion is just midnight, doesn't matter
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

// a message on the community board
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
        'timestamp': timestamp.toIso8601String(),
      };

  // timestamp comes back as a Firestore Timestamp object from the stream,
  // but as an ISO string when loaded from local shared prefs - handle both AAS
  static DateTime _parseTimestamp(dynamic raw) {
    if (raw == null) return DateTime.now();
    // Firestore Timestamp has a .toDate() method
    if (raw is DateTime) return raw;
    if (raw.runtimeType.toString().contains('Timestamp')) {
      return (raw as dynamic).toDate() as DateTime;
    }
    // fallback: stored as ISO string locally
    if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
    return DateTime.now();
  }

  factory CommunityMessage.fromJson(Map<String, dynamic> json) => CommunityMessage(
        id: json['id'] as String,
        authorName: json['authorName'] as String,
        authorEmail: json['authorEmail'] as String,
        text: json['text'] as String,
        timestamp: _parseTimestamp(json['timestamp']),
      );
}

// a user record pulled from the org's Firestore collection
// admin sees a list of these, normal users never touch it
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