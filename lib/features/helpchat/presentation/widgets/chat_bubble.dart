import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String timestamp;
  final String? senderName;
  final List<Map<String, dynamic>>? replies;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
    this.senderName,
    this.replies,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = const Color(0xFF8ECAE6);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main message bubble with proper alignment
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: 80,
              ),
              margin: EdgeInsets.only(
                left: isUser ? 40 : 0,
                right: isUser ? 0 : 40,
              ),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [bubbleColor, bubbleColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sender name for non-current user messages
                    if (!isUser && senderName != null && senderName!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderName!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: bubbleColor,
                          ),
                        ),
                      ),
                    
                    // Message content
                    Text(
                      message,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: isUser ? Colors.white : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Timestamp
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          timestamp,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: isUser 
                                ? Colors.white.withOpacity(0.8) 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Display replies with improved styling
          if (replies != null && replies!.isNotEmpty)
            ...replies!.asMap().entries.map((entry) {
              final index = entry.key;
              final reply = entry.value;
              
              // Extract reply data
              final replyContent = reply['content'] ?? '';
              final senderType = reply['senderType'] ?? 'admin';
              final senderName = reply['senderName'] ?? 'Support Admin';
              
              // Properly handle Firestore Timestamp conversion
              DateTime replyTimestamp;
              try {
                if (reply['timestamp'] is Timestamp) {
                  replyTimestamp = (reply['timestamp'] as Timestamp).toDate();
                } else if (reply['timestamp'] is DateTime) {
                  replyTimestamp = reply['timestamp'] as DateTime;
                } else {
                  replyTimestamp = DateTime.now();
                }
              } catch (e) {
                replyTimestamp = DateTime.now();
              }
              
              final isAdminReply = senderType == 'admin';
              final isUserReply = senderType == 'customer' || senderType == 'user';
              
              return Container(
                margin: EdgeInsets.only(
                  top: index == 0 ? 8 : 4,
                  left: isUserReply ? 40 : 20,
                  right: isUserReply ? 20 : 40,
                ),
                child: Align(
                  alignment: isUserReply ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.65,
                    ),
                    decoration: BoxDecoration(
                      gradient: isAdminReply
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF8ECAE6).withOpacity(0.2),
                                const Color(0xFF8ECAE6).withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : isUserReply
                              ? LinearGradient(
                                  colors: [
                                    bubbleColor.withOpacity(0.1),
                                    bubbleColor.withOpacity(0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                      color: (!isAdminReply && !isUserReply) ? Colors.grey.shade50 : null,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUserReply ? 16 : 4),
                        bottomRight: Radius.circular(isUserReply ? 4 : 16),
                      ),
                      border: Border.all(
                        color: isAdminReply 
                            ? const Color(0xFF8ECAE6).withOpacity(0.4)
                            : isUserReply
                                ? bubbleColor.withOpacity(0.2)
                                : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply header with sender info
                          if (isAdminReply)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8ECAE6).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 12,
                                      color: const Color(0xFF2A4B8D),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    senderName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2A4B8D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Reply content
                          Text(
                            replyContent,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isAdminReply 
                                  ? const Color(0xFF2A4B8D)
                                  : isUserReply
                                      ? bubbleColor.withOpacity(0.9)
                                      : Colors.grey.shade800,
                              height: 1.3,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Reply timestamp
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              DateFormat('h:mm a').format(replyTimestamp),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isAdminReply 
                                    ? const Color(0xFF8ECAE6)
                                    : isUserReply
                                        ? bubbleColor.withOpacity(0.7)
                                        : Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}