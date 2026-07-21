import 'package:flutter/material.dart';
import '../global.dart';
import '../services/firebase_service.dart';

// ProfilePage - company details + sync button
// on initState, tries to pull existing profile from firestore to autofill the fields
// on save, writes locally and syncs to firestore simultaneously - no extra step needed
// the big sync button is still there for manual force-push if something drifts ; AAS
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyRoleCtrl;
  late TextEditingController _companyCodeCtrl;
  bool _syncing = false;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    // prefill controllers from whatever is already in Global, loaded from local session
    _companyNameCtrl = TextEditingController(text: Global.companyName ?? '');
    _companyRoleCtrl = TextEditingController(text: Global.companyRole ?? '');
    _companyCodeCtrl = TextEditingController(text: Global.companyCode ?? '');

    // if any field is still empty, pull from firestore to fill it in ; AAS
    if (Global.companyName == null || Global.companyRole == null) {
      _autofillFromFirestore();
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyRoleCtrl.dispose();
    _companyCodeCtrl.dispose();
    super.dispose();
  }

  // pull the user doc from public firestore and fill in blank fields only
  // doesnt overwrite anything the user already has locally ; AAS
  Future<void> _autofillFromFirestore() async {
    final email = Global.userEmail;
    if (email == null) return;

    setState(() => _loadingProfile = true);

    try {
      final doc = await FB.publicDB.collection('users').doc(email).get();
      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        // only fill in if local is empty - never clobber what they already typed ; AAS
        if ((Global.companyName == null || Global.companyName!.isEmpty) && data['companyName'] != null) {
          Global.companyName = data['companyName'] as String;
          _companyNameCtrl.text = Global.companyName!;
        }
        if ((Global.companyRole == null || Global.companyRole!.isEmpty) && data['companyRole'] != null) {
          Global.companyRole = data['companyRole'] as String;
          _companyRoleCtrl.text = Global.companyRole!;
        }
        if ((Global.companyCode == null || Global.companyCode!.isEmpty) && data['companyCode'] != null) {
          Global.companyCode = data['companyCode'] as String;
          _companyCodeCtrl.text = Global.companyCode!;
        }
        setState(() {});
      }
    } catch (_) {
      // firestore offline or doc missing - not fatal, local data is still there ; AAS
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  // saves locally + pushes to firestore immediately, no separate sync needed
  Future<void> _saveCompanyDetails() async {
    Global.companyName = _companyNameCtrl.text.trim().isEmpty ? null : _companyNameCtrl.text.trim();
    Global.companyRole = _companyRoleCtrl.text.trim().isEmpty ? null : _companyRoleCtrl.text.trim();
    Global.companyCode = _companyCodeCtrl.text.trim().isEmpty ? null : _companyCodeCtrl.text.trim();

    // stamp session so company details actually persist to disk ; AAS
    Global.login(email: Global.userEmail!, name: Global.userName!, rememberMe: Global.rememberMe);

    // fire and forget to firestore - user doesnt need to wait for this ; AAS
    FB.syncUserToPublic().then((err) {
      if (err != null) {
        // silent fail - it's saved locally so its not lost, firestore will get it on next sync
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved')),
    );
  }

  // manual force sync - bookings + profile to both dbs
  Future<void> _syncToDatabase() async {
    setState(() => _syncing = true);
    final err = await FB.fullSync();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err ?? 'Synced')),
    );
  }

  void _logout(BuildContext context) {
    Global.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                (Global.userName ?? '?').isNotEmpty ? Global.userName![0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Name'),
            subtitle: Text(Global.userName ?? 'there'),
          )),
          Card(child: ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(Global.userEmail ?? '-'),
          )),
          if (!Global.isAdmin) ...[
            Card(child: ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Bookings'),
              subtitle: Text('${Global.bookings.length} total'),
            )),
          ],

          const SizedBox(height: 24),

          Row(
            children: [
              Text('Company details', style: Theme.of(context).textTheme.titleMedium),
              if (_loadingProfile) ...[
                const SizedBox(width: 8),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _companyNameCtrl,
            decoration: const InputDecoration(labelText: 'Company name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _companyRoleCtrl,
            decoration: const InputDecoration(labelText: 'Your role / position'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _companyCodeCtrl,
            decoration: const InputDecoration(
              labelText: 'Org code',
              helperText: 'Get this from your admin',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _saveCompanyDetails,
            child: const Text('Save details'),
          ),

          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _syncing ? null : _syncToDatabase,
            icon: _syncing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_syncing ? 'Syncing...' : 'Sync account to database'),
          ),

          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
