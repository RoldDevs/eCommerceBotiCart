import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_action_card.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/chat_message.dart';
import '../screens/pharmacy_reviews_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../widgets/recent_searches_screen.dart';
import '../providers/search_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/chat_providers.dart';
import '../../../auth/presentation/screens/account_screen.dart';
import '../../../auth/presentation/providers/user_provider.dart';

class QuickActionsSection extends ConsumerWidget {
  final Pharmacy? pharmacy;

  const QuickActionsSection({super.key, this.pharmacy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8ECAE6),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              QuickActionCard(
                title: 'Upload Prescription',
                icon: Icons.upload_file_outlined,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'Favorites',
                icon: Icons.favorite_border,
                onTap: () {
                  // Clear product type filters and set favorites filter
                  ref.read(selectedProductTypesProvider.notifier).clear();
                  ref.read(selectedConditionTypesProvider.notifier).clear();
                  ref.read(selectedFilterProvider.notifier).state =
                      MedicineFilterType.favorites;

                  final initialSearches = ref.read(initialSearchesProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecentSearchesScreen(
                        recentSearches: initialSearches,
                        onSearchTap: (query) {
                          ref
                              .read(searchHistoryProvider.notifier)
                              .addSearch(query);
                        },
                        onBackPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'Chat With Pharmacist',
                icon: Icons.chat_bubble_outline,
                onTap: () async {
                  if (pharmacy == null) return;
                  final currentPharmacy = pharmacy!;

                  final user = ref.read(currentUserProvider).value;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please log in to chat',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    final chatRepository = ref.read(chatRepositoryProvider);

                    // Find existing conversation or create new one
                    final conversationsAsync = ref.read(
                      userConversationsProvider,
                    );
                    String? conversationId;

                    await conversationsAsync.when(
                      data: (conversations) async {
                        try {
                          final existingConversation = conversations.firstWhere(
                            (conv) => conv.pharmacyId == currentPharmacy.id,
                          );
                          conversationId = existingConversation.id;
                        } catch (e) {
                          // No conversation found, will create one
                        }
                      },
                      loading: () {},
                      error: (_, __) {},
                    );

                    // If no conversation found, create one
                    if (conversationId == null) {
                      conversationId = await chatRepository.createConversation(
                        user.id,
                        currentPharmacy,
                      );

                      // Send welcome message from pharmacy
                      if (conversationId != null) {
                        final welcomeMessage = ChatMessage(
                          id: '',
                          senderId: currentPharmacy.id,
                          receiverId: user.id,
                          content:
                              'Hello! Welcome to ${currentPharmacy.name}. How can we help you today?',
                          timestamp: DateTime.now(),
                          senderName: currentPharmacy.name,
                          senderType: 'pharmacy',
                        );

                        await chatRepository.sendMessage(
                          conversationId!,
                          welcomeMessage,
                        );
                      }
                    }

                    // Navigate to chat
                    if (conversationId != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            conversationId: conversationId!,
                            pharmacyName: currentPharmacy.name,
                            pharmacyImageUrl: currentPharmacy.imageUrl,
                            pharmacyId: currentPharmacy.id,
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    // If conversation doesn't exist, create it
                    try {
                      final chatRepository = ref.read(chatRepositoryProvider);
                      final conversationId = await chatRepository
                          .createConversation(user.id, currentPharmacy);

                      // Send welcome message from pharmacy
                      final welcomeMessage = ChatMessage(
                        id: '',
                        senderId: currentPharmacy.id,
                        receiverId: user.id,
                        content:
                            'Hello! Welcome to ${currentPharmacy.name}. How can we help you today?',
                        timestamp: DateTime.now(),
                        senderName: currentPharmacy.name,
                        senderType: 'pharmacy',
                      );

                      await chatRepository.sendMessage(
                        conversationId,
                        welcomeMessage,
                      );

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            conversationId: conversationId,
                            pharmacyName: currentPharmacy.name,
                            pharmacyImageUrl: currentPharmacy.imageUrl,
                            pharmacyId: currentPharmacy.id,
                          ),
                        ),
                      );
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to start chat. Please try again.',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
              QuickActionCard(
                title: 'Track Orders',
                icon: Icons.local_shipping_outlined,
                onTap: () {
                  // Navigate to OrdersScreen with "In Transit" tab (index 5)
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const OrdersScreen(initialTabIndex: 5),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'About Us',
                icon: Icons.info_outline,
                onTap: () {
                  if (pharmacy != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PharmacyReviewsScreen(
                          pharmacy: pharmacy!,
                          initialTabIndex: 0, // Navigate to About tab
                        ),
                    ),
                  );
                  }
                },
              ),
              QuickActionCard(
                title: 'Reorder',
                icon: Icons.refresh,
                onTap: () {
                  // Navigate to OrdersScreen with "Complete" tab (index 7)
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const OrdersScreen(initialTabIndex: 7),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'Review',
                icon: Icons.star_border,
                onTap: () {
                  if (pharmacy != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            PharmacyReviewsScreen(pharmacy: pharmacy!),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
