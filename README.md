# PaperJournal

<p align="center">
  <img src="assets/AppIcon/AmberJournal.png" alt="PaperJournal Logo" width="500"/>
</p>

> A booking and scheduling app built with Flutter for ET0529 Mobile Applications Development, SP School of Electrical & Electronic Engineering. Group project by Abinaash, Prabhu, and Shafqat. (⌐■_■)

---

## What is this?

PaperJournal is a workplace booking and scheduling app. The idea is simple: instead of firing off a "hey is Room A free on Thursday?" message in the group chat and waiting 45 minutes for a reply, you just open the app, see what's available, book it, and move on with your life.

It covers the full loop: browse services, make a booking, check your calendar, drop a message on the community board if something changes last minute, and let the admin handle the oversight side. Everyone stays on the same page without the back-and-forth.

The app is built around a booking/appointment theme as per the assignment brief. We went with a general workplace/facility booking context because it's the most universally relatable and gave us the most room to build actual useful features rather than padding.

---

## Screens (o^_^o)

The app has 7 user-facing screens. Here's a quick rundown of each:

### Login
First thing you see. Enter your email and password and you're in. No real auth backend yet (Firebase Auth is on the roadmap, see below), so right now any valid-looking email works. The session persists for 3 days before you have to log back in, so you're not re-entering your details every time you open the app.

Special case: logging in with `ADMIN@EXAMPLE` / `ADMIN` gives you the admin account. More on that below.

### Home (Calendar)
The main dashboard. Shows a monthly calendar with dots on days that have bookings. Tap a day to see what's on it. This is your at-a-glance view of the whole schedule.

There's a notification bell in the top right corner. If you have upcoming bookings, it gets a red dot. Tap it to go to the Notifications screen.

### Services
A catalogue of everything that can actually be booked. Haircuts, meeting rooms, lab slots, IT support, whatever your org has set up. You can search by name or filter by category using the chips at the top.

Each card shows the service name, a short description, category, and how long it takes. Tap "Book" on any of them and it takes you straight to the Bookings screen with the service name already filled in. No retyping needed. (^_^)v

### Bookings
Where you confirm a booking once you know what you want. Pick a date, hit confirm, done. Also has a look-up field where you can search for an existing booking by ID. If the booking's been deleted, it throws the Lonely Cosmos error screen instead of just doing nothing -- because "not found" should look like something.

You can cancel a booking (marks it cancelled) or delete it outright (removes it from the list entirely).

### Community
Open chat board for the whole team. Anyone logged in can post a message, everyone sees everything. Think of it like a public pinboard rather than a DM system.

Messages are grouped by date with separators (Today, Yesterday, then the actual date after that). Your own messages show on the right and you can long-press them to delete. Other people's messages show the sender's name on the left.

This is the "last minute changes" screen. If the meeting got moved or a room is suddenly unavailable, someone drops a message here and the whole team sees it. Way faster than a group chat that's also full of memes.

### Notifications
Shows all your upcoming bookings as reminder cards, sorted by how soon they are. The closer a booking is, the more urgent the card looks: red for under 24 hours, orange for under 3 days, normal otherwise.

Each card shows the service name, date, status, and a human-readable time label like "Tomorrow" or "In 3 days" instead of a raw timestamp. No new data needed for this screen -- it derives everything from your existing bookings.

### Profile
Your account info plus company details. You can fill in your company name, your role, and an org code (which your admin gives you). Once that's in, hit "Sync account to database" and your profile and bookings get pushed to the admin's Firebase org collection so they can see you. Firebase wiring is stubbed for now but the button, the loading state, and the Firestore call comments are all there.

---

## Admin Account (=`ω´=)

The app has a hidden admin mode baked in. Log in with:

```
Email:    ADMIN@EXAMPLE
Password: ADMIN
```

That's it. Same app, same login screen -- it just unlocks one extra tab at the end of the bottom bar.

The Admin tab shows:
- A list of all synced users (from the org's Firestore collection)
- Each user's bookings, expandable per user
- A conflict banner at the top if two users have booked the same service on the same day (and neither booking is cancelled)

Normal users never see this tab. It's not hidden or greyed out, it's just not rendered at all if `Global.isAdmin` is false. So there's no way to accidentally stumble into it.

The conflict detection is a straightforward scan: same service name, same day, both non-cancelled. Good enough for the scale this app is designed for.

---

## How the data layer works (roughly)

There's no proper database yet (that's the next phase), so right now everything lives in a class called `Global`. It's basically a big static store: any page in the app can read or write to it just by importing `global.dart`.

`Global` holds:
- The logged-in user's session (email, name, admin flag, company details)
- The list of bookings
- The list of day notes (for the calendar)
- The community messages
- The org users list (admin only, populated on sync)

Everything that changes gets written to a local JSON file in the device's temp directory so data survives the app being closed and reopened. On launch, `main()` calls `loadSession()`, `loadBookings()`, `loadNotes()`, and `loadCommunityMessages()` before `runApp()` kicks in. That's how you get your data back after a restart without needing a backend.

The session expires after 3 days. If you reopen the app after 3 days, `loadSession()` detects the stale timestamp, wipes the session file, and sends you back to the login screen.

It's not the most scalable thing in the world, but it's clean, easy to follow, and works for the current scope. The Firestore migration (see below) will replace the file-based persistence entirely.

---

## Firebase/Firestore roadmap

The current build is fully functional offline. Firebase integration is the next milestone and all the groundwork is already in place: the TODOs are written, the data models have `toJson()`/`fromJson()` methods, and the Firestore call structure is commented out in the relevant functions. When you wire it up, you're mostly uncommenting and removing the stubs.

Here's the rough plan:

**Firebase Auth**
Replace the current "any email works" login with real Firebase Auth sign-in. The `Global.login()` / `Global.logout()` pattern stays, just the credential check changes.

**Firestore for community messages**
`CommunityPage` already has a TODO comment showing exactly where to swap the local list for a `Firestore.instance.collection('community_messages').snapshots()` stream listener. Messages then become real-time and shared across all users on the same org.

**Firestore for org users (admin view)**
When a user taps "Sync account to database" on the Profile page, their profile and bookings should push to:
```
/orgs/{companyCode}/users/{email}
```
The admin's `AdminPage` then reads from that collection and populates the user list. Right now it reads from `Global.orgUsers` which is empty until Firestore is wired.

**Firebase Cloud Messaging (FCM)**
The Notifications screen currently derives reminders from local bookings. Once FCM is in, confirmed bookings can trigger push notifications so you get reminded even if the app isn't open. The in-app list stays as a fallback.

**Firestore for services**
The Services catalogue is hardcoded for now. The endgame is pulling it from a Firestore `services` collection so admins can add or edit services without a code change.

---

## Project info

- **Module:** ET0529 Mobile Applications Development, 2026/27 S1
- **Group:** Abinaash Abirama Sundaram (2520225), Prabhu Sumathi Vanavan (2520353), Muhammad Shafqat Ali Khan Saadat (2503237)
- **Class:** DCPE/FT/2B/23
- **Framework:** Flutter (Dart)
- **Theme:** PaperDesign (custom, based on Material 3)

---

## Running it

Standard Flutter run. Nothing special.

```bash
flutter pub get
flutter run
```

Works on Android, iOS, Windows, Linux, and web (the pubspec has all the targets). If something doesn't compile, check that your Flutter SDK is on 3.12.0 or above.

---

---

## Internal references

- [PaperDesign](https://github.com/MilkmanAbi/PaperDesign) - the design system the app is built on top of
- [PaperJournal-Theme](https://github.com/MilkmanAbi/PaperDesign/blob/main/General-Resources/Flutter/Paper-Base-Theme.dart) - the base Flutter theme file used directly in this project
- [Brief](https://gist.github.com/MilkmanAbi/124bef8bdec000570574e8943de06aef) - design brief and references for the Powerpoint presentation

---

*readme written by Abinaash. if something's wrong it's probably Shafqat's fault. (¬‿¬)*
