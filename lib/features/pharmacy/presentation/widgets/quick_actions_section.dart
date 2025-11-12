import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_action_card.dart';
import 'recent_searches_screen.dart';
import '../../domain/entities/pharmacy.dart';
import '../screens/pharmacy_reviews_screen.dart';
import '../screens/chat_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../providers/navigation_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/search_provider.dart';
import '../../../../features/auth/presentation/screens/account_screen.dart';

class QuickActionsSection extends ConsumerWidget {
  final Pharmacy? pharmacy;

  const QuickActionsSection({
    super.key,
    this.pharmacy,
  });

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
                  // Navigate to Account Screen (Profile) for prescription management
                  ref.read(navigationIndexProvider.notifier).state = 4;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'Wishlist',
                icon: Icons.favorite_border,
                onTap: () {
                  // Navigate to favorites products
                  ref.read(selectedFilterProvider.notifier).state = MedicineFilterType.favorites;
                  final initialSearches = ref.read(initialSearchesProvider);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => RecentSearchesScreen(
                        recentSearches: initialSearches,
                        onSearchTap: (query) {
                          ref.read(searchHistoryProvider.notifier).addSearch(query);
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
                onTap: () {
                  // Navigate to chat with this pharmacy
                  if (pharmacy != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          conversationId: '', // Empty means it will create new if doesn't exist
                          pharmacyName: pharmacy!.name,
                          pharmacyImageUrl: pharmacy!.imageUrl,
                          pharmacyId: pharmacy!.id,
                        ),
                      ),
                    );
                  }
                },
              ),
              QuickActionCard(
                title: 'Track Orders',
                icon: Icons.local_shipping_outlined,
                onTap: () {
                  // Navigate to Orders screen
                  ref.read(navigationIndexProvider.notifier).state = 2;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OrdersScreen(),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'About Us',
                icon: Icons.info_outline,
                onTap: () {
                  // Nothing for now - could show a dialog or snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coming soon!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              QuickActionCard(
                title: 'Reorder',
                icon: Icons.refresh,
                onTap: () {
                  // Nothing for now - could show a dialog or snackbar
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Coming soon!'),
                      duration: Duration(seconds: 1),
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
                        builder: (context) => PharmacyReviewsScreen(pharmacy: pharmacy!),
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