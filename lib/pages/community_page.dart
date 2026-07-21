import 'package:flutter/material.dart';
import '../global.dart';
import '../services/firebase_service.dart';

// community page - the group chat bit
// hooks into FB.communityStream() which is a live firestore snapshot listener
// so messages from other users just appear without any refresh needed - yeah its a stream, thats how streams work PSV
// local list is fallback while stream is connecting or offline. okay, this caches msgs. dude. PSV
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _msgController = TextEditingController();
  final _scrollController = ScrollController();

  late final Stream<List<CommunityMessage>> _msgStream;

  @override
  void initState() {
    super.initState();
    _msgStream = FB.communityStream();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final msg = CommunityMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: Global.userName ?? 'ghost user lol',
      authorEmail: Global.userEmail ?? '',
      text: text,
      timestamp: DateTime.now(),
    );

    _msgController.clear();
    await FB.sendMessage(msg); // writes local first then firestore, why tf would you write remote first PSV

    // scroll down after posting, bit annoying if its already at the bottom but whatever
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteMessage(String id) async {
    await FB.deleteMessage(id);
  }

  // groups messages by date and inserts separator rows between days. bruh why tf does this need 15 lines PSV
  List<_MsgOrSeparator> _grouped(List<CommunityMessage> messages) {
    final sorted = [...messages]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final result = <_MsgOrSeparator>[];
    DateTime? lastDate;

    for (final msg in sorted) {
      final d = DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (lastDate == null || d != lastDate) {
        result.add(_MsgOrSeparator.separator(d));
        lastDate = d;
      }
      result.add(_MsgOrSeparator.message(msg));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<CommunityMessage>>(
              stream: _msgStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // use firestore data if available, fall back to local. okay, this picks the better source. dude. PSV
                final messages = snap.data ?? Global.communityMessages;
                final grouped = _grouped(messages);

                if (grouped.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: scheme.outline),
                        const SizedBox(height: 8),
                        Text('Nothing here yet - say something I guess', style: TextStyle(color: scheme.outline)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: grouped.length,
                  itemBuilder: (context, i) {
                    final item = grouped[i];
                    if (item.isSeparator) return _DateSeparator(date: item.date!);
                    final msg = item.message!;
                    final isMe = msg.authorEmail == Global.userEmail;
                    return _MessageBubble(
                      msg: msg,
                      isMe: isMe,
                      onDelete: isMe ? () => _deleteMessage(msg.id) : null,
                    );
                  },
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      decoration: const InputDecoration(hintText: 'say something...', isDense: true),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(onPressed: _sendMessage, icon: const Icon(Icons.send_outlined)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// little helper union type so the listview can hold either a message or a separator
// why tf dart doesnt have a built-in discriminated union for this idk PSV
class _MsgOrSeparator {
  final bool isSeparator;
  final DateTime? date;
  final CommunityMessage? message;
  const _MsgOrSeparator._({required this.isSeparator, this.date, this.message});
  factory _MsgOrSeparator.separator(DateTime d) => _MsgOrSeparator._(isSeparator: true, date: d);
  factory _MsgOrSeparator.message(CommunityMessage m) => _MsgOrSeparator._(isSeparator: false, message: m);
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;
  const _DateSeparator({required this.date});

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_label(), style: Theme.of(context).textTheme.labelSmall),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final CommunityMessage msg;
  final bool isMe;
  final VoidCallback? onDelete;
  const _MessageBubble({required this.msg, required this.isMe, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeStr =
        '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // long press shows delete - bruh why tf would you want to delete your own message
        // anyway, this does it PSV
        onLongPress: onDelete != null
            ? () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete this?'),
                    content: const Text('Removes from firestore too, gone for everyone permanently.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete!();
                        },
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                )
            : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  msg.authorName,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: scheme.primary, fontWeight: FontWeight.bold),
                ),
              Text(msg.text),
              const SizedBox(height: 2),
              Text(
                timeStr,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
