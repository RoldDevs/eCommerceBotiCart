import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/help_chat_message.dart';
import '../providers/help_chat_providers.dart';
import '../widgets/chat_bubble.dart';

class HelpChatScreen extends ConsumerStatefulWidget {
  const HelpChatScreen({super.key});

  @override
  ConsumerState<HelpChatScreen> createState() => _HelpChatScreenState();
}

class _HelpChatScreenState extends ConsumerState<HelpChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final message = HelpChatMessage(
        id: '', // Will be assigned by Firestore
        message: _messageController.text.trim(),
        userUID: currentUser.uid,
        createdAt: DateTime.now(),
      );

      final repository = ref.read(helpChatRepositoryProvider);
      await repository.sendMessage(message);
      _messageController.clear();
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserUID = ref.watch(currentUserUIDProvider);
    final chatMessagesAsyncValue = currentUserUID != null
        ? ref.watch(userChatMessagesProvider(currentUserUID))
        : const AsyncValue.loading();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Color(0xFF8ECAE6), size: 24),
            SizedBox(width: 8),
            Text(
              'Help and Support',
              style: GoogleFonts.poppins(
                color: Color(0xFF8ECAE6),
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chatMessagesAsyncValue.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'How can I help you?',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF8ECAE6).withAlpha(175),
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Column(
                      children: [
                        // User message
                        ChatBubble(
                          message: message.message,
                          isUser: true,
                          timestamp: message.createdAt,
                        ),
                        
                        // Admin reply (if exists)
                        if (message.reply != null && message.reply!.isNotEmpty)
                          ChatBubble(
                            message: message.reply!,
                            isUser: false,
                            timestamp: message.createdAt,
                          ),
                          
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF8ECAE6)),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading messages: $error',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            ),
          ),
          
          // Message input - Adding padding to raise it above the navigation bar
          SafeArea(
            bottom: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Address your concerns',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8ECAE6),
                    ),
                    child: IconButton(
                      icon: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}