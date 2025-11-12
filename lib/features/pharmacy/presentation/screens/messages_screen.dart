import 'package:boticart/core/widgets/custom_modal.dart';
import 'package:boticart/features/pharmacy/domain/entities/chat_message.dart';
import 'package:boticart/features/pharmacy/presentation/services/order_message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/screen_utils.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/chat_providers.dart';
import '../providers/pharmacy_providers.dart';
import '../providers/order_message_provider.dart';
import '../providers/announcement_provider.dart';
import '../widgets/chat_list_item.dart';
import '../widgets/order_message_item.dart';
import '../widgets/announcement_list_item.dart';
import 'chat_detail_screen.dart';
import 'order_message_detail_screen.dart';
import 'announcement_detail_screen.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _filters = ['All', 'Orders', 'Chats', 'Announcements'];
  String _sortOrder = 'Newest';
  bool _isSelectionMode = false;
  final Set<String> _selectedItems = <String>{};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsyncValue = ref.watch(filteredUserConversationsProvider);
    final pharmaciesAsyncValue = ref.watch(pharmaciesStreamProvider);
    final orderMessagesAsyncValue = ref.watch(filteredUserOrderMessagesProvider);
    final announcementsAsyncValue = ref.watch(announcementsProvider);
    final currentUser = ref.watch(currentUserProvider).value;
    final unreadCount = ref.watch(unreadOrderMessageCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _isSelectionMode
            ? Text(
                '${_selectedItems.length} selected',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              )
            : Text(
                'MESSAGES',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
        centerTitle: true,
        actions: _isSelectionMode
            ? [
                IconButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedItems.clear();
                    });
                  },
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF8ECAE6),
                  ),
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF8ECAE6),
              labelColor: const Color(0xFF8ECAE6),
              unselectedLabelColor: Colors.grey,
              dividerColor: const Color(0xFF8ECAE6),
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: _filters.asMap().entries.map((entry) {
                final filter = entry.value;
                
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(filter),
                      if (filter == 'Orders' && unreadCount.value != null && unreadCount.value! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${unreadCount.value}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: _sortOrder,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8ECAE6)),
                  underline: Container(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8ECAE6),
                  ),
                  items: ['Newest', 'Oldest'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _sortOrder = newValue;
                      });
                      // ignore: unused_result
                      ref.refresh(userConversationsProvider);
                      // ignore: unused_result
                      ref.refresh(userOrderMessagesProvider);
                    }
                  },
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) {
                        _selectedItems.clear();
                      }
                    });
                  },
                  child: Text(
                    _isSelectionMode ? 'Cancel' : 'Select',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8ECAE6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // All Tab - Show both conversations, order messages, announcements, and all pharmacies
                _buildAllTabContent(conversationsAsyncValue, pharmaciesAsyncValue, orderMessagesAsyncValue, announcementsAsyncValue, currentUser),
                
                // Orders Tab - Show only order messages
                _buildOrderMessagesTab(orderMessagesAsyncValue),
                
                // Chats Tab
                _buildConversationsList(conversationsAsyncValue, currentUser),
                
                // Announcements Tab
                _buildAnnouncementsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomModal(
          title: 'Delete Messages',
          content: 'Are you sure you want to delete ${_selectedItems.length} selected message${_selectedItems.length > 1 ? 's' : ''}? This action cannot be undone.',
          cancelText: 'No',
          confirmText: 'Yes',
          confirmButtonColor: Colors.red,
          onCancel: () => Navigator.of(context).pop(),
          onConfirm: () {
            Navigator.of(context).pop();
            _deleteSelectedMessages();
          },
        );
      },
    );
  }

  void _deleteSelectedMessages() async {
    try {
      // Get the order message service
      final orderMessageService = ref.read(orderMessageServiceProvider);
      
      // Delete each selected message
      final selectedIds = List<String>.from(_selectedItems);
      for (final messageId in selectedIds) {
        await orderMessageService.deleteOrderMessage(messageId);
      }
      
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${selectedIds.length} message${selectedIds.length > 1 ? 's' : ''} deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: const Color(0xFF8ECAE6),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Refresh the data by invalidating the provider
      ref.invalidate(userOrderMessagesProvider);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete messages: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAllTabContent(
    AsyncValue<List<dynamic>> conversationsAsyncValue,
    AsyncValue<List<dynamic>> pharmaciesAsyncValue,
    AsyncValue<List<dynamic>> orderMessagesAsyncValue,
    AsyncValue<List<dynamic>> announcementsAsyncValue,
    dynamic currentUser
  ) {
    return pharmaciesAsyncValue.when(
      data: (pharmacies) {
        return conversationsAsyncValue.when(
          data: (conversations) {
            return orderMessagesAsyncValue.when(
              data: (orderMessages) {
                return announcementsAsyncValue.when(
                  data: (announcements) {
                    final Map<String, dynamic> conversationsByPharmacyId = {};
                    for (final conversation in conversations) {
                      conversationsByPharmacyId[conversation.pharmacyId] = conversation;
                    }
                    
                    final List<Widget> items = [];
                    
                    final sortedAnnouncements = List.from(announcements);
                    if (_sortOrder == 'Oldest') {
                      sortedAnnouncements.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    } else {
                      sortedAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    }
                    
                    for (final announcement in sortedAnnouncements) {
                      items.add(
                        AnnouncementListItem(
                          announcement: announcement,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnnouncementDetailScreen(announcement: announcement),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    
                    final sortedOrderMessages = List.from(orderMessages);
                    if (_sortOrder == 'Oldest') {
                      sortedOrderMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    } else {
                      sortedOrderMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    }
                    
                    for (final message in sortedOrderMessages) {
                      items.add(
                        OrderMessageItem(
                          message: message,
                          isSelectionMode: _isSelectionMode,
                          isSelected: _selectedItems.contains(message.id),
                          onSelectionToggle: () {
                            setState(() {
                              if (_selectedItems.contains(message.id)) {
                                _selectedItems.remove(message.id);
                              } else {
                                _selectedItems.add(message.id);
                              }
                            });
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderMessageDetailScreen(message: message),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    
                    // Add conversations
                    final sortedConversations = List.from(conversations);
                    if (_sortOrder == 'Oldest') {
                      sortedConversations.sort((a, b) => a.lastMessageTime.compareTo(b.lastMessageTime));
                    } else {
                      sortedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
                    }
                    
                    for (final conversation in sortedConversations) {
                      items.add(
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ChatListItem(
                            conversation: conversation,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    conversationId: conversation.id,
                                    pharmacyName: conversation.pharmacyName,
                                    pharmacyImageUrl: conversation.pharmacyImageUrl,
                                    pharmacyId: conversation.pharmacyId,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                    
                    // Add pharmacies without conversations
                    final selectedStoreId = ref.watch(selectedPharmacyStoreIdProvider);
                    final selectedPharmacy = selectedStoreId != null 
                        ? pharmacies.firstWhere(
                            (p) => p.storeID == selectedStoreId,
                            orElse: () => throw Exception('Pharmacy not found'),
                          )
                        : null;
                    
                    if (selectedPharmacy != null) {
                      final hasConversation = conversationsByPharmacyId.containsKey(selectedPharmacy.id);
                      
                      if (!hasConversation) {
                        items.add(
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ChatListItem.fromPharmacy(
                              pharmacy: selectedPharmacy,
                              onTap: () async {
                                // Automatically create conversation with welcome message
                                final user = ref.read(currentUserProvider).value;
                                if (user != null) {
                                  final chatRepository = ref.read(chatRepositoryProvider);
                                  
                                  try {
                                    // Create conversation
                                    final conversationId = await chatRepository.createConversation(user.id, selectedPharmacy);
                                    
                                    // Send welcome message from pharmacy
                                    final welcomeMessage = ChatMessage(
                                      id: '',
                                      senderId: selectedPharmacy.id,
                                      receiverId: user.id,
                                      content: 'Hello! Welcome to ${selectedPharmacy.name}. How can we help you today?',
                                      timestamp: DateTime.now(),
                                      senderName: selectedPharmacy.name,
                                      senderType: 'pharmacy',
                                    );
                                    
                                    await chatRepository.sendMessage(conversationId, welcomeMessage);
                                    
                                    // Navigate to chat with the new conversation
                                    Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailScreen(
                                          conversationId: conversationId,
                                          pharmacyName: selectedPharmacy.name,
                                          pharmacyImageUrl: selectedPharmacy.imageUrl,
                                          pharmacyId: selectedPharmacy.id,
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    // Fallback to empty conversation if creation fails
                                    Navigator.push(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatDetailScreen(
                                          conversationId: '',
                                          pharmacyName: selectedPharmacy.name,
                                          pharmacyImageUrl: selectedPharmacy.imageUrl,
                                          pharmacyId: selectedPharmacy.id,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }
                    }
                    
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.message_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No messages yet',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: ScreenUtils.getBottomPadding(context)), 
                      itemCount: items.length,
                      itemBuilder: (context, index) => items[index],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading announcements',
                      style: GoogleFonts.poppins(color: Colors.red),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading order messages',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text(
              'Error loading conversations',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          'Error loading pharmacies',
          style: GoogleFonts.poppins(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    final announcementsAsyncValue = ref.watch(announcementsProvider);
    
    return announcementsAsyncValue.when(
      data: (announcements) {
        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 80,
                  color: Color(0xFF8ECAE6),
                ),
                const SizedBox(height: 20),
                Text(
                  'No announcements',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New announcements will appear here',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort announcements
        final sortedAnnouncements = List.from(announcements);
        if (_sortOrder == 'Newest') {
          sortedAnnouncements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else {
          sortedAnnouncements.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100), 
          itemCount: sortedAnnouncements.length,
          itemBuilder: (context, index) {
            final announcement = sortedAnnouncements[index];
            return AnnouncementListItem(
              announcement: announcement,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnnouncementDetailScreen(
                      announcement: announcement,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFF8ECAE6),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load announcements',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please try again later or contact support',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMessagesTab(AsyncValue<List<dynamic>> orderMessagesAsyncValue) {
    return orderMessagesAsyncValue.when(
      data: (orderMessages) {
        if (orderMessages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Color(0xFF8ECAE6),
                ),
                const SizedBox(height: 20),
                Text(
                  'No order messages',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order updates will appear here',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sort order messages
        final sortedMessages = List.from(orderMessages);
        if (_sortOrder == 'Oldest') {
          sortedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        } else {
          sortedMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: 8, bottom: ScreenUtils.getBottomPadding(context)),
          itemCount: sortedMessages.length,
          itemBuilder: (context, index) {
            final message = sortedMessages[index];
            return OrderMessageItem(
              message: message,
              isSelectionMode: _isSelectionMode,
              isSelected: _selectedItems.contains(message.id),
              onSelectionToggle: () {
                setState(() {
                  if (_selectedItems.contains(message.id)) {
                    _selectedItems.remove(message.id);
                  } else {
                    _selectedItems.add(message.id);
                  }
                });
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderMessageDetailScreen(message: message),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFF8ECAE6),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load order messages',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please try again later or contact support',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList(AsyncValue<List<dynamic>> conversationsAsyncValue, dynamic currentUser) {
    return conversationsAsyncValue.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 80,
                  color: Color(0xFF8ECAE6),
                ),
                const SizedBox(height: 20),
                Text(
                  'No messages yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final sortedConversations = List.from(conversations);
        if (_sortOrder == 'Oldest') {
          sortedConversations.sort((a, b) => a.lastMessageTime.compareTo(b.lastMessageTime));
        } else {
          sortedConversations.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: ScreenUtils.getBottomPadding(context)), 
          itemCount: sortedConversations.length,
          itemBuilder: (context, index) {
            final conversation = sortedConversations[index];
            return ChatListItem(
              conversation: conversation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      conversationId: conversation.id,
                      pharmacyName: conversation.pharmacyName,
                      pharmacyImageUrl: conversation.pharmacyImageUrl,
                      pharmacyId: conversation.pharmacyId,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 60,
              color: Color(0xFF8ECAE6),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load conversations',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Please try again later or contact support',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
