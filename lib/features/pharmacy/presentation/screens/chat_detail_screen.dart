import 'package:boticart/features/pharmacy/domain/entities/pharmacy.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';
import '../../domain/entities/chat_message.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String pharmacyName;
  final String pharmacyImageUrl;
  final String pharmacyId;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.pharmacyName,
    required this.pharmacyImageUrl,
    required this.pharmacyId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(chatRepositoryProvider)
          .markConversationAsRead(widget.conversationId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    try {
      String currentConversationId = widget.conversationId;

      // If no conversation exists, create one first
      if (currentConversationId.isEmpty) {
        final chatRepository = ref.read(chatRepositoryProvider);

        // Create a pharmacy object for the conversation
        final pharmacy = Pharmacy(
          id: widget.pharmacyId,
          name: widget.pharmacyName,
          location: '',
          rating: 0.0,
          reviewCount: 0,
          contact: '',
          imageUrl: widget.pharmacyImageUrl,
          backgroundImgUrl: '',
          description: '',
          storeID: 0,
        );

        currentConversationId = await chatRepository.createConversation(
          user.id,
          pharmacy,
        );
      }

      final message = ChatMessage(
        id: '',
        senderId: user.id,
        receiverId: widget.pharmacyId, // Use pharmacyId as receiverId
        content: _messageController.text.trim(),
        timestamp: DateTime.now(),
        senderName: user.firstName,
        senderType: 'customer',
      );

      await ref
          .read(chatRepositoryProvider)
          .sendMessage(currentConversationId, message);
      _messageController.clear();

      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty conversationId by showing empty messages instead of trying to fetch
    final messagesAsyncValue = widget.conversationId.isEmpty
        ? const AsyncValue.data(<ChatMessage>[])
        : ref.watch(conversationMessagesProvider(widget.conversationId));

    final currentUser = ref.watch(currentUserProvider).value;
    final primaryColor = const Color(0xFF8ECAE6);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: widget.pharmacyImageUrl.isNotEmpty
                    ? NetworkImage(widget.pharmacyImageUrl)
                    : null,
                child: widget.pharmacyImageUrl.isEmpty
                    ? Text(
                        widget.pharmacyName.isNotEmpty
                            ? widget.pharmacyName[0]
                            : '?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.pharmacyName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4A6572),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messagesAsyncValue.when(
                data: (messages) {
                  // Scroll to bottom when messages load
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Color(0xFF8ECAE6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No messages yet",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8ECAE6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Start a conversation with this pharmacy",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isFromCurrentUser =
                          message.senderId == currentUser?.id;

                      // Add date headers between messages from different days
                      Widget? dateHeader;
                      if (index == 0 ||
                          !_isSameDay(
                            messages[index].timestamp,
                            messages[index - 1].timestamp,
                          )) {
                        dateHeader = _buildDateHeader(message.timestamp);
                      }

                      return Column(
                        children: [
                          if (dateHeader != null) dateHeader,
                          ChatMessageBubble(
                            message: message,
                            isFromCurrentUser: isFromCurrentUser,
                            bubbleColor: Color(0xFF8ECAE6),
                            showNestedReplies:
                                false, // We display replies as separate messages below
                          ),
                          // Display admin replies as separate messages immediately after the user message
                          if (message.replies.isNotEmpty && isFromCurrentUser)
                            ...message.replies.map((reply) {
                              final replyContent = reply['content'] ?? '';
                              final senderType = reply['senderType'] ?? 'admin';
                              // Always use pharmacy name for admin/pharmacy replies
                              final senderName =
                                  (senderType == 'admin' ||
                                      senderType == 'pharmacy')
                                  ? widget.pharmacyName
                                  : (reply['senderName'] ?? 'Admin');

                              // Create a ChatMessage object for the reply
                              final replyMessage = ChatMessage(
                                id:
                                    reply['id'] ??
                                    DateTime.now().millisecondsSinceEpoch
                                        .toString(),
                                senderId: reply['senderId'] ?? 'admin',
                                receiverId: message.senderId,
                                content: replyContent,
                                timestamp: reply['timestamp'] is Timestamp
                                    ? (reply['timestamp'] as Timestamp).toDate()
                                    : reply['timestamp'] is DateTime
                                    ? reply['timestamp'] as DateTime
                                    : DateTime.now(),
                                senderName: senderName,
                                senderType: senderType,
                              );

                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ChatMessageBubble(
                                  message: replyMessage,
                                  isFromCurrentUser: false,
                                  bubbleColor: Color(0xFF8ECAE6),
                                ),
                              );
                            }),
                        ],
                      );
                    },
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading messages',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red.shade300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // ignore: unused_result
                          ref.refresh(
                            conversationMessagesProvider(widget.conversationId),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 50),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.15),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: 5,
                        minLines: 1,
                        decoration: InputDecoration(
                          hintText: 'Type a message.',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 1,
                            ),
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(10),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == yesterday) {
      dateText = 'Yesterday';
    } else {
      dateText = '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          dateText,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
