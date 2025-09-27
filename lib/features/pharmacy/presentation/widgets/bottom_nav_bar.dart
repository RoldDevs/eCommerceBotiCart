import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import 'package:boticart/features/auth/presentation/screens/account_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/pharmacy_detail_screen.dart';
import '../../domain/entities/pharmacy.dart';
import '../providers/pharmacy_providers.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);
    
    return Container(
      height: 70,
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            index: 1,
            currentIndex: currentIndex,
            icon: Icons.shopping_cart,
            ref: ref,
            context: context,
          ),
          _buildNavItem(
            index: 3,
            currentIndex: currentIndex,
            icon: Icons.message,
            ref: ref,
            context: context,
          ),
          _buildNavItem(
            index: 0,
            currentIndex: currentIndex,
            icon: Icons.home,
            ref: ref,
            context: context,
          ),
          _buildNavItem(
            index: 2,
            currentIndex: currentIndex,
            icon: Icons.receipt_long,
            ref: ref,
            context: context,
          ),
          _buildNavItem(
            index: 4,
            currentIndex: currentIndex,
            icon: Icons.person,
            ref: ref,
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required int currentIndex,
    required IconData icon,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    final isSelected = index == currentIndex;
    
    return GestureDetector(
      onTap: () {
        // Set the navigation index
        ref.read(navigationIndexProvider.notifier).state = index;
        
        // Navigate to the appropriate screen based on the index
        if (index == 4) { // Profile tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AccountScreen()),
          );
        } else if (index == 1) { // Cart tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const CartScreen()),
          );
        } else if (index == 3) { // Messages tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MessagesScreen()),
          );
        } else if (index == 2) { // Orders tab
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const OrdersScreen()),
          );
        } else if (index == 0) { // Home tab
          final selectedStoreId = ref.read(selectedPharmacyStoreIdProvider);
          
          final pharmaciesAsyncValue = ref.read(pharmaciesStreamProvider);
          
          pharmaciesAsyncValue.whenData((pharmacies) {
            final selectedPharmacy = pharmacies.firstWhere(
              (pharmacy) => pharmacy.storeID == selectedStoreId,
              orElse: () => Pharmacy(
                id: 'default',
                name: 'Default Pharmacy',
                location: 'Main Street',
                rating: 4.5,
                reviewCount: 100,
                imageUrl: '',
                backgroundImgUrl: '',
                storeID: 1,
              ),
            );
            
            // Navigate to the pharmacy detail screen with the selected pharmacy
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => PharmacyDetailScreen(pharmacy: selectedPharmacy),
              ),
            );
          });
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 70, 
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isSelected 
              ? Border(
                  top: BorderSide(
                    color: const Color(0xFF8ECAE6),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 0.8,
            end: isSelected ? 1.2 : 0.8,
          ),
          curve: Curves.elasticOut,
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(
                icon,
                size: 36,
                color: isSelected ? const Color(0xFF8ECAE6) : Colors.grey.shade400,
              ),
            );
          },
        ),
      ),
    );
  }
}