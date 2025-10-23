import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/pharmacy.dart';

class ChatListItem extends StatelessWidget {
  final ChatConversation? conversation;
  final Pharmacy? pharmacy;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.conversation,
    required this.onTap,
  }) : pharmacy = null;

  const ChatListItem.fromPharmacy({
    super.key,
    required this.pharmacy,
    required this.onTap,
  }) : conversation = null;

  @override
  Widget build(BuildContext context) {
    final String pharmacyName = conversation?.pharmacyName ?? pharmacy?.name ?? '';
    final String pharmacyImageUrl = conversation?.pharmacyImageUrl ?? pharmacy?.imageUrl ?? '';
    final String lastMessage = conversation?.lastMessage ?? 'Start a conversation';
    final DateTime lastMessageTime = conversation?.lastMessageTime ?? DateTime.now();
    final int unreadCount = conversation?.unreadCount ?? 0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: pharmacyImageUrl.isNotEmpty
                      ? NetworkImage(pharmacyImageUrl)
                      : null,
                  child: pharmacyImageUrl.isEmpty
                      ? Text(
                          pharmacyName.isNotEmpty
                              ? pharmacyName[0]
                              : '?',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        )
                      : null,
                ),
                // Unread count badge (only show for conversations)
                if (conversation != null && unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8ECAE6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacyName,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: conversation != null && unreadCount > 0 ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: conversation != null && unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                      fontWeight: conversation != null && unreadCount > 0 ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(lastMessageTime),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: conversation != null && unreadCount > 0 ? const Color(0xFF8ECAE6) : Colors.grey.shade500,
                    fontWeight: conversation != null && unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (conversation != null && unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF8ECAE6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(time);
    } else {
      return DateFormat('MM/dd/yy').format(time);
    }
  }
}