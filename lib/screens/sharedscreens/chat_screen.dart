import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String otherPartyName;

  const ChatScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
    required this.otherPartyName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final uid = auth.currentUserId;
    final name = auth.userName ?? 'Me';
    if (uid == null) return;

    _msgCtrl.clear();

    await context.read<ChatProvider>().sendMessage(
          jobId: widget.jobId,
          senderId: uid,
          senderName: name,
          text: text,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final uid = context.read<AuthProvider>().currentUserId ?? '';

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherPartyName,
                style: TextStyle(
                    color: AC.text(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text(widget.jobTitle,
                style: TextStyle(color: AC.textSec(context), fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: context.read<ChatProvider>().messagesStream(widget.jobId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: AC.textSec(context).withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('No messages yet',
                            style:
                                TextStyle(color: AC.textSec(context), fontSize: 15)),
                        const SizedBox(height: 6),
                        Text('Say hello to get started!',
                            style:
                                TextStyle(color: AC.textSec(context), fontSize: 13)),
                      ],
                    ),
                  );
                }
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final isMine = (data['senderId'] as String?) == uid;
                    final ts = data['createdAt'];
                    final time = ts is Timestamp
                        ? DateFormat('HH:mm').format(ts.toDate())
                        : '';
                    return _MessageBubble(
                      text: data['text'] as String? ?? '',
                      senderName: data['senderName'] as String? ?? '',
                      time: time,
                      isMine: isMine,
                      accent: accent,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          Container(
            color: AC.surface(context),
            padding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: 10,
              bottom: MediaQuery.of(context).viewInsets.bottom + 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AC.input(context),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      style: TextStyle(color: AC.text(context), fontSize: 14),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: AC.textSec(context)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<ChatProvider>(
                  builder: (context, chat, _) => GestureDetector(
                    onTap: chat.sending ? null : _send,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: chat.sending
                            ? accent.withValues(alpha: 0.5)
                            : accent,
                        shape: BoxShape.circle,
                      ),
                      child: chat.sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.black, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String time;
  final bool isMine;
  final Color accent;

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.time,
    required this.isMine,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(senderName,
                        style: TextStyle(
                            color: AC.textSec(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isMine ? accent : AC.surface(context),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMine ? Colors.black : AC.text(context),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(time,
                    style: TextStyle(
                        color: AC.textSec(context), fontSize: 10)),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
