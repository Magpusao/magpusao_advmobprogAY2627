import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
    required this.receiverName,
  });

  final String receiverId;
  final String receiverEmail;
  final String receiverName;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isSending = false;
  bool _markingSeen = false;

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(widget.receiverId, message);
      _messageController.clear();
      _messageFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message not sent: ${_errorText(error)}')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _markMessagesSeen() {
    if (_markingSeen) return;
    _markingSeen = true;
    _chatService
        .markMessagesAsSeen(widget.receiverId)
        .catchError((_) {})
        .whenComplete(() => _markingSeen = false);
  }

  String _errorText(Object error) {
    if (error is StateError) return error.message;
    return 'Please check your connection and try again.';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _chatService.currentUser;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              child: Text(
                widget.receiverName.isEmpty
                    ? '?'
                    : widget.receiverName.characters.first.toUpperCase(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    widget.receiverEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: currentUser == null
          ? const Center(child: Text('Sign in to continue chatting.'))
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _chatService.getMessages(
                      currentUser.uid,
                      widget.receiverId,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Unable to load messages.'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }

                      final documents = snapshot.data?.docs ?? [];
                      if (documents.isEmpty) {
                        return _ConversationStarter(
                          receiverName: widget.receiverName,
                        );
                      }

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _markMessagesSeen();
                      });

                      return ListView.builder(
                        reverse: true,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                        itemCount: documents.length,
                        itemBuilder: (context, index) {
                          final document = documents[index];
                          final message = MessageModel.fromMap(document.data());
                          return _AnimatedMessageBubble(
                            key: ValueKey(document.id),
                            message: message,
                            isCurrentUser: message.senderId == currentUser.uid,
                          );
                        },
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isSending
                      ? const Padding(
                          key: ValueKey('sending'),
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Sending…',
                            style: TextStyle(fontSize: 12),
                          ),
                        )
                      : const SizedBox(key: ValueKey('not-sending')),
                ),
                _MessageComposer(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  isSending: _isSending,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }
}

class _AnimatedMessageBubble extends StatefulWidget {
  const _AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  final MessageModel message;
  final bool isCurrentUser;

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(widget.isCurrentUser ? 0.12 : -0.12, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mine = widget.isCurrentUser;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            margin: const EdgeInsets.only(bottom: 9),
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 7),
            decoration: BoxDecoration(
              color: mine ? colors.primary : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(mine ? 18 : 4),
                bottomRight: Radius.circular(mine ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  widget.message.message,
                  style: TextStyle(
                    color: mine ? colors.onPrimary : colors.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(widget.message.timestamp.toDate()),
                      style: TextStyle(
                        fontSize: 10,
                        color: mine
                            ? colors.onPrimary.withValues(alpha: 0.75)
                            : colors.onSurfaceVariant.withValues(alpha: 0.75),
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(width: 4),
                      Icon(
                        widget.message.status == 'seen'
                            ? Icons.done_all
                            : Icons.done,
                        size: 15,
                        color: widget.message.status == 'seen'
                            ? Colors.lightBlueAccent
                            : colors.onPrimary.withValues(alpha: 0.75),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 10, 10),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('messageInput'),
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              key: const Key('sendMessageButton'),
              tooltip: 'Send message',
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationStarter extends StatelessWidget {
  const _ConversationStarter({required this.receiverName});

  final String receiverName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.waving_hand_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation with $receiverName',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
