import 'package:boticart/features/pharmacy/presentation/providers/medicine_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/cart_provider.dart';
import 'cart_checkout_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final filteredCartItems = ref.watch(filteredCartProvider);
    final cartNotifier = ref.watch(cartProvider.notifier);
    final isSelectionMode = ref.watch(selectionModeProvider);
    final isSelectAllActive = ref.watch(selectAllProvider);
    final hasSelectedItems = cartNotifier.hasSelectedItems;
    final selectedItemsCount = cartNotifier.selectedItemsCount;
    final selectedItemsTotal = cartNotifier.selectedItemsTotal;
    final searchQuery = ref.watch(cartSearchProvider);
    final favorites = ref.watch(favoriteMedicinesProvider);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'CART (${cartItems.length})',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F3F8).withAlpha(60),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        ref.read(cartSearchProvider.notifier).state = value;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF8ECAE6), size: 30),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  ref.read(cartSearchProvider.notifier).state = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF8ECAE6).withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list, color: Color(0xFF8ECAE6)),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          
          // Selection controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                if (isSelectionMode) ...[
                  // Select All button (only visible in selection mode)
                  InkWell(
                    onTap: () {
                      final newValue = !isSelectAllActive;
                      ref.read(selectAllProvider.notifier).state = newValue;
                      cartNotifier.selectAll(newValue);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Select All',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button (only visible in selection mode)
                  InkWell(
                    onTap: hasSelectedItems ? () {
                      cartNotifier.removeSelectedItems();
                    } : null,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(Icons.delete_outline, 
                        color: hasSelectedItems ? Colors.grey.shade700 : Colors.grey.shade400, 
                        size: 20),
                    ),
                  ),
                ],
                const Spacer(),
                // Toggle selection mode button
                ElevatedButton(
                  onPressed: () {
                    final newMode = !isSelectionMode;
                    ref.read(selectionModeProvider.notifier).state = newMode;
                    
                    // If turning off selection mode, clear all selections
                    if (!newMode) {
                      ref.read(selectAllProvider.notifier).state = false;
                      cartNotifier.clearAllSelections();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelectionMode ? Colors.grey : const Color(0xFF8ECAE6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    isSelectionMode ? 'Cancel' : 'Select',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search results info
          if (searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                ],
              ),
            ),
          
          // Cart items
          Expanded(
            child: filteredCartItems.isEmpty
                ? searchQuery.isNotEmpty
                    ? _buildNoSearchResults(searchQuery)
                    : _buildEmptyCart()
                : ListView.builder(
                    itemCount: filteredCartItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredCartItems[index];
                      final isFavorite = favorites.contains(item.medicine.id);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: item.isSelected && isSelectionMode 
                                ? const Color(0xFF8ECAE6) 
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: item.isSelected && isSelectionMode 
                              ? const Color(0xFFEDF6F9)
                              : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: isSelectionMode ? () {
                            cartNotifier.toggleItemSelection(item.medicine.id);
                            
                            // Update select all state if needed
                            if (!item.isSelected && isSelectAllActive) {
                              ref.read(selectAllProvider.notifier).state = false;
                            }
                          } : null,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product image aligned to the left
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: item.medicine.imageURL.isNotEmpty
                                    ? Image.network(
                                        item.medicine.imageURL,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => 
                                          const Icon(Icons.medication, size: 40, color: Color(0xFF8ECAE6)),
                                      )
                                    : const Icon(Icons.medication, size: 40, color: Color(0xFF8ECAE6)),
                                ),
                                
                                // Medicine name and price in a column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.medicine.medicineName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Medicine type tags
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 2,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.medicine.majorTypeDisplayName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF2A4B8D),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.medicine.productTypeDisplayName,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF2A4B8D),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '₱ ${item.medicine.price.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Qty: ${item.quantity}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Action buttons column
                                Column(
                                  children: [
                                    // Share and favorite icons
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.share, color: Color(0xFF8ECAE6), size: 20),
                                          onPressed: () {},
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            isFavorite ? Icons.favorite : Icons.favorite_border,
                                            color: isFavorite ? Colors.red : Color(0xFF8ECAE6),
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref.read(favoriteMedicinesProvider.notifier).toggleFavorite(item.medicine.id);
                                          },
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Quantity controls
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, color: Color(0xFF8ECAE6), size: 16),
                                          onPressed: item.quantity > 1 ? () async {
                                            try {
                                              await cartNotifier.decrementQuantity(item.medicine.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update quantity: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          } : null,
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          style: IconButton.styleFrom(
                                            backgroundColor: item.quantity > 1 
                                                ? const Color(0xFF8ECAE6).withValues(alpha: 0.1)
                                                : Colors.grey.withValues(alpha: 0.1),
                                            minimumSize: const Size(24, 24),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          icon: const Icon(Icons.add, color: Color(0xFF8ECAE6), size: 16),
                                          onPressed: () async {
                                            try {
                                              await cartNotifier.incrementQuantity(item.medicine.id);
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update quantity: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          constraints: const BoxConstraints(),
                                          padding: const EdgeInsets.all(4),
                                          style: IconButton.styleFrom(
                                            backgroundColor: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                                            minimumSize: const Size(24, 24),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Total and checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSelectionMode && hasSelectedItems
                      ? 'Total: ₱ ${selectedItemsTotal.toStringAsFixed(2)}'
                      : 'Total: ₱ ${cartNotifier.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton(
                  onPressed: (isSelectionMode && hasSelectedItems) || (!isSelectionMode && cartItems.isNotEmpty) ? () {
                    // Navigate to checkout screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CartCheckoutScreen(),
                      ),
                    );
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8ECAE6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    isSelectionMode && hasSelectedItems 
                        ? 'Check out ($selectedItemsCount)' 
                        : 'Check out',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const BottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: Color(0xFF8ECAE6),
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart to checkout',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: Color(0xFF8ECAE6),
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No items match "$query"',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}