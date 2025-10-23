import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quick_action_card.dart';
import '../../domain/entities/pharmacy.dart';
import '../screens/pharmacy_reviews_screen.dart';

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
                onTap: () {},
              ),
              QuickActionCard(
                title: 'Wishlist',
                icon: Icons.favorite_border,
                onTap: () {},
              ),
              QuickActionCard(
                title: 'Chat With Pharmacist',
                icon: Icons.chat_bubble_outline,
                onTap: () {},
              ),
              QuickActionCard(
                title: 'Track Orders',
                icon: Icons.local_shipping_outlined,
                onTap: () {},
              ),
              QuickActionCard(
                title: 'About Us',
                icon: Icons.info_outline,
                onTap: () {},
              ),
              QuickActionCard(
                title: 'Reorder',
                icon: Icons.refresh,
                onTap: () {},
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