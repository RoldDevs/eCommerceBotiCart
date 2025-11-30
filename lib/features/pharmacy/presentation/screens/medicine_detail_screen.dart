import 'package:boticart/features/pharmacy/presentation/providers/stock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../../domain/entities/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/selected_medicine_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/filter_provider.dart';
import '../widgets/related_product_card.dart';
import '../widgets/buy_now_modal.dart';
import '../widgets/filters/search_filters_screen.dart';
import 'order_information_screen.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Set the selected medicine when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedMedicineProvider.notifier).state = widget.medicine;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final isFavorite = favorites.contains(widget.medicine.id);
    final searchQuery = ref.watch(medicineSearchQueryProvider);

    // Get medicines based on search query and filters
    final List<Medicine> relatedMedicines;
    if (searchQuery.isEmpty) {
      // Use filtered medicines provider to apply any active filters
      final filteredMedicines = ref.watch(filteredMedicinesByFiltersProvider);
      relatedMedicines = filteredMedicines.isNotEmpty
          ? filteredMedicines
          : ref.watch(relatedMedicinesProvider);
    } else {
      // Use search provider and then apply filters
      final searchAsyncValue = ref.watch(medicineSearchProvider(searchQuery));
      final baseSearchResults = searchAsyncValue.when(
        data: (medicines) => medicines,
        loading: () => <Medicine>[],
        error: (_, __) => <Medicine>[],
      );

      // Apply filters to search results
      final selectedProductTypes = ref.watch(selectedProductTypesProvider);
      final selectedConditionTypes = ref.watch(selectedConditionTypesProvider);

      if (selectedProductTypes.isEmpty && selectedConditionTypes.isEmpty) {
        relatedMedicines = baseSearchResults;
      } else {
        relatedMedicines = baseSearchResults.where((medicine) {
          bool matchesProductType =
              selectedProductTypes.isEmpty ||
              selectedProductTypes.contains(medicine.productType);
          bool matchesConditionType =
              selectedConditionTypes.isEmpty ||
              selectedConditionTypes.contains(medicine.conditionType);
          return matchesProductType && matchesConditionType;
        }).toList();
      }
    }

    // Exclude the current medicine from related products to avoid redundancy
    final filteredRelatedMedicines = relatedMedicines
        .where((medicine) => medicine.id != widget.medicine.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar at the top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF8ECAE6),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search medicine',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        onChanged: (value) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 500),
                            () {
                              ref
                                      .read(
                                        medicineSearchQueryProvider.notifier,
                                      )
                                      .state =
                                  value;
                            },
                          );
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF8ECAE6)),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(medicineSearchQueryProvider.notifier).state =
                              '';
                        },
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: Color(0xFF8ECAE6),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SearchFiltersScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content below the search bar
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Image with Stock Badge
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Stack(
                        children: [
                          Image.network(
                            widget.medicine.imageURL,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: Colors.white,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 50,
                                  ),
                                ),
                              );
                            },
                          ),
                          // Stock badge positioned at top-right
                          Positioned(
                            top: 10,
                            right: 16,
                            child: Consumer(
                              builder: (context, ref, child) {
                                final stockAsyncValue = ref.watch(
                                  stockStreamProvider(widget.medicine.id),
                                );

                                return stockAsyncValue.when(
                                  data: (currentStock) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: currentStock <= 0
                                          ? Colors.red.shade600
                                          : currentStock <= 5
                                          ? Colors.orange.shade600
                                          : Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      currentStock <= 0
                                          ? 'Out of Stock'
                                          : currentStock <= 5
                                          ? '$currentStock left'
                                          : '$currentStock in stock',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  loading: () => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'Loading...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  error: (_, __) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.medicine.stock <= 0
                                          ? Colors.red.shade600
                                          : widget.medicine.stock <= 5
                                          ? Colors.orange.shade600
                                          : Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      widget.medicine.stock <= 0
                                          ? 'Out of Stock'
                                          : widget.medicine.stock <= 5
                                          ? '${widget.medicine.stock} left'
                                          : '${widget.medicine.stock} in stock',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price and Share/Favorite
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₱${widget.medicine.price.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8ECAE6),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Color(0xFF8ECAE6),
                                  size: 32,
                                ),
                                onPressed: () {
                                  // Share functionality
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFavorite
                                      ? Colors.red
                                      : Color(0xFF8ECAE6),
                                  size: 32,
                                ),
                                onPressed: () {
                                  ref
                                      .read(favoriteMedicinesProvider.notifier)
                                      .toggleFavorite(widget.medicine.id);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Medicine Name and Type
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.medicine.medicineName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8ECAE6,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.medicine.majorTypeDisplayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2A4B8D),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF8ECAE6,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.medicine.productTypeDisplayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2A4B8D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF8ECAE6,
                              ).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.medicine.conditionTypeDisplayName,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2A4B8D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Product Offerings
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      color: const Color(0xFFF5F8FA),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Offerings',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...widget.medicine.productOffering.map(
                            (offering) => Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      offering,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                      softWrap: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Product Description
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Description',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.medicine.productDescription,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Add to Cart and Buy Now buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final stockAsyncValue = ref.watch(
                            stockStreamProvider(widget.medicine.id),
                          );

                          return stockAsyncValue.when(
                            data: (currentStock) => Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: currentStock <= 0
                                        ? null
                                        : () {
                                            int quantity = 1;
                                            showDialog(
                                              context: context,
                                              builder: (context) => BuyNowModal(
                                                medicine: widget.medicine,
                                                buttonText: 'ADD TO CART',
                                                onQuantityChanged:
                                                    (newQuantity) {
                                                      quantity = newQuantity;
                                                    },
                                                onBuyNow: () async {
                                                  Navigator.of(context).pop();

                                                  try {
                                                    await ref
                                                        .read(
                                                          cartProvider.notifier,
                                                        )
                                                        .addToCart(
                                                          widget.medicine,
                                                          quantity,
                                                        );

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Added to cart successfully!',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF8ECAE6,
                                                              ),
                                                          duration:
                                                              const Duration(
                                                                seconds: 2,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to add to cart: ${e.toString()}',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                          duration:
                                                              const Duration(
                                                                seconds: 3,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                    icon: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: currentStock <= 0
                                          ? Colors.grey
                                          : const Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                    label: Text(
                                      currentStock <= 0
                                          ? 'Out of Stock'
                                          : 'Add to Cart',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentStock <= 0
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      foregroundColor: currentStock <= 0
                                          ? Colors.grey
                                          : Colors.black,
                                      side: BorderSide(
                                        color: currentStock <= 0
                                            ? Colors.grey
                                            : Colors.black26,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: currentStock <= 0
                                        ? null
                                        : () {
                                            int quantity = 1;
                                            showDialog(
                                              context: context,
                                              builder: (context) => BuyNowModal(
                                                medicine: widget.medicine,
                                                buttonText: 'BUY NOW',
                                                onQuantityChanged:
                                                    (newQuantity) {
                                                      quantity = newQuantity;
                                                    },
                                                onBuyNow: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderInformationScreen(
                                                            medicine:
                                                                widget.medicine,
                                                            quantity: quantity,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                    icon: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: currentStock <= 0
                                          ? Colors.grey
                                          : const Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                    label: Text(
                                      currentStock <= 0
                                          ? 'Out of Stock'
                                          : 'Buy Now',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: currentStock <= 0
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      foregroundColor: currentStock <= 0
                                          ? Colors.grey
                                          : Colors.black,
                                      side: BorderSide(
                                        color: currentStock <= 0
                                            ? Colors.grey
                                            : Colors.black26,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            loading: () => Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                    label: Text(
                                      'Loading...',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.grey,
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: null,
                                    icon: const Icon(
                                      Icons.shopping_bag_outlined,
                                      color: Colors.grey,
                                      size: 24,
                                    ),
                                    label: Text(
                                      'Loading...',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade200,
                                      foregroundColor: Colors.grey,
                                      side: const BorderSide(
                                        color: Colors.grey,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            error: (_, __) => Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: widget.medicine.stock <= 0
                                        ? null
                                        : () {
                                            // Add to cart functionality (fallback to original stock)
                                            int quantity = 1;
                                            showDialog(
                                              context: context,
                                              builder: (context) => BuyNowModal(
                                                medicine: widget.medicine,
                                                buttonText: 'ADD TO CART',
                                                onQuantityChanged:
                                                    (newQuantity) {
                                                      quantity = newQuantity;
                                                    },
                                                onBuyNow: () async {
                                                  Navigator.of(context).pop();

                                                  try {
                                                    await ref
                                                        .read(
                                                          cartProvider.notifier,
                                                        )
                                                        .addToCart(
                                                          widget.medicine,
                                                          quantity,
                                                        );

                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Added to cart successfully!',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          backgroundColor:
                                                              const Color(
                                                                0xFF8ECAE6,
                                                              ),
                                                          duration:
                                                              const Duration(
                                                                seconds: 2,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            'Failed to add to cart: ${e.toString()}',
                                                            style:
                                                                GoogleFonts.poppins(),
                                                          ),
                                                          backgroundColor:
                                                              Colors.red,
                                                          duration:
                                                              const Duration(
                                                                seconds: 3,
                                                              ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                    icon: Icon(
                                      Icons.shopping_cart_outlined,
                                      color: widget.medicine.stock <= 0
                                          ? Colors.grey
                                          : const Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                    label: Text(
                                      widget.medicine.stock <= 0
                                          ? 'Out of Stock'
                                          : 'Add to Cart',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          widget.medicine.stock <= 0
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      foregroundColor:
                                          widget.medicine.stock <= 0
                                          ? Colors.grey
                                          : Colors.black,
                                      side: BorderSide(
                                        color: widget.medicine.stock <= 0
                                            ? Colors.grey
                                            : Colors.black26,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: widget.medicine.stock <= 0
                                        ? null
                                        : () {
                                            int quantity = 1;
                                            showDialog(
                                              context: context,
                                              builder: (context) => BuyNowModal(
                                                medicine: widget.medicine,
                                                buttonText: 'BUY NOW',
                                                onQuantityChanged:
                                                    (newQuantity) {
                                                      quantity = newQuantity;
                                                    },
                                                onBuyNow: () {
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OrderInformationScreen(
                                                            medicine:
                                                                widget.medicine,
                                                            quantity: quantity,
                                                          ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                    icon: Icon(
                                      Icons.shopping_bag_outlined,
                                      color: widget.medicine.stock <= 0
                                          ? Colors.grey
                                          : const Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                    label: Text(
                                      widget.medicine.stock <= 0
                                          ? 'Out of Stock'
                                          : 'Buy Now',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          widget.medicine.stock <= 0
                                          ? Colors.grey.shade200
                                          : Colors.white,
                                      foregroundColor:
                                          widget.medicine.stock <= 0
                                          ? Colors.grey
                                          : Colors.black,
                                      side: BorderSide(
                                        color: widget.medicine.stock <= 0
                                            ? Colors.grey
                                            : Colors.black26,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Related Products
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            searchQuery.isEmpty
                                ? 'Related Products'
                                : 'Search Results',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.72,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: filteredRelatedMedicines.length,
                            itemBuilder: (context, index) {
                              return RelatedProductCard(
                                medicine: filteredRelatedMedicines[index],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
