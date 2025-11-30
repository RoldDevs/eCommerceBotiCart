import 'dart:async';

import 'package:boticart/features/pharmacy/presentation/providers/stock_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../providers/medicine_provider.dart';
import '../providers/filter_provider.dart';
import '../providers/recommendation_provider.dart';
import '../../domain/entities/medicine.dart';
import '../screens/medicine_detail_screen.dart';
import 'stock_badge.dart';
import 'filters/search_filters_screen.dart';

class RecentSearchesScreen extends ConsumerStatefulWidget {
  final List<String> recentSearches;
  final Function(String) onSearchTap;
  final VoidCallback onBackPressed;

  const RecentSearchesScreen({
    super.key,
    required this.recentSearches,
    required this.onSearchTap,
    required this.onBackPressed,
  });

  @override
  ConsumerState<RecentSearchesScreen> createState() =>
      _RecentSearchesScreenState();
}

class _RecentSearchesScreenState extends ConsumerState<RecentSearchesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });

    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Only save search after user stops typing for 1 second
    if (value.isNotEmpty) {
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        ref.read(searchHistoryProvider.notifier).addSearch(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicinesAsyncValue = ref.watch(medicineSearchProvider(_searchQuery));
    final selectedFilter = ref.watch(selectedFilterProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF8ECAE6),
                    ),
                    onPressed: widget.onBackPressed,
                  ),
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F3F8).withAlpha(60),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.search,
                            color: Color(0xFF8ECAE6),
                            size: 35,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.only(
                                  left: 5,
                                  top: 15,
                                  bottom: 15,
                                ),
                              ),
                              autofocus: true,
                              onChanged: _onSearchChanged,
                            ),
                          ),
                        ],
                      ),
                    ),
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

            // Filter tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'Relevance',
                      selectedFilter == MedicineFilterType.relevance,
                      () {
                        ref.read(selectedFilterProvider.notifier).state =
                            MedicineFilterType.relevance;
                      },
                    ),
                    _buildFilterChip(
                      'Latest',
                      selectedFilter == MedicineFilterType.latest,
                      () {
                        ref.read(selectedFilterProvider.notifier).state =
                            MedicineFilterType.latest;
                      },
                    ),
                    _buildFilterChip(
                      'Price',
                      selectedFilter == MedicineFilterType.price,
                      () {
                        ref.read(selectedFilterProvider.notifier).state =
                            MedicineFilterType.price;
                      },
                    ),
                    _buildFilterChip(
                      'Favorites',
                      selectedFilter == MedicineFilterType.favorites,
                      () {
                        ref.read(selectedFilterProvider.notifier).state =
                            MedicineFilterType.favorites;
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),

            // Content area - either recent searches or search results
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildRecentSearches()
                  : SingleChildScrollView(
                      child: _buildSearchResults(medicinesAsyncValue),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8ECAE6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF8ECAE6) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    // Watch filtered medicines provider instead of all medicines
    final filteredMedicines = ref.watch(filteredMedicinesByFiltersProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    final selectedProductTypes = ref.watch(selectedProductTypesProvider);
    final selectedConditionTypes = ref.watch(selectedConditionTypesProvider);

    // Apply current filter type (relevance, latest, price, favorites) to filtered medicines
    final filterType = ref.watch(selectedFilterProvider);
    final favorites = ref.watch(favoriteMedicinesProvider);

    List<Medicine> finalFilteredMedicines = filteredMedicines.map((medicine) {
      return medicine.copyWith(isFavorite: favorites.contains(medicine.id));
    }).toList();

    switch (filterType) {
      case MedicineFilterType.relevance:
        finalFilteredMedicines.sort(
          (a, b) => a.medicineName.compareTo(b.medicineName),
        );
        break;
      case MedicineFilterType.latest:
        finalFilteredMedicines.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
        );
        break;
      case MedicineFilterType.price:
        finalFilteredMedicines.sort((a, b) => b.price.compareTo(a.price));
        break;
      case MedicineFilterType.favorites:
        finalFilteredMedicines = finalFilteredMedicines
            .where((medicine) => favorites.contains(medicine.id))
            .toList();
        break;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Searches header with Clear button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(searchHistoryProvider.notifier).clearHistory();
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8ECAE6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recent searches list
          searchHistory.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    'No recent searches',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: searchHistory.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(
                        searchHistory[index],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.north_west,
                        size: 20,
                        color: Colors.grey,
                      ),
                      onTap: () {
                        _searchController.text = searchHistory[index];
                        setState(() {
                          _searchQuery = searchHistory[index];
                        });
                        widget.onSearchTap(searchHistory[index]);
                      },
                    );
                  },
                ),

          // Recommended Products Section (only if user has purchased from target categories)
          Consumer(
            builder: (context, ref, child) {
              final hasPurchased = ref.watch(
                hasPurchasedFromTargetCategoriesProvider,
              );
              final recommendedMedicinesAsync = ref.watch(
                recommendedMedicinesProvider,
              );

              if (!hasPurchased) {
                return const SizedBox.shrink();
              }

              return recommendedMedicinesAsync.when(
                data: (recommendedMedicines) {
                  if (recommendedMedicines.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recommended Products header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                        child: Text(
                          'Recommended Products',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      // Recommended medicines grid
                      SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: recommendedMedicines.length,
                          itemBuilder: (context, index) {
                            final medicine = recommendedMedicines[index];
                            return Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 16),
                              child: _buildRecommendedProductCard(medicine),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),

          // All Medicines Section
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              ref.watch(selectedFilterProvider) == MedicineFilterType.favorites
                  ? 'Favorite Medicines'
                  : 'All Medicines',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          // Filtered medicines grid
          finalFilteredMedicines.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      _getEmptyStateMessage(
                        filterType,
                        selectedProductTypes,
                        selectedConditionTypes,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: finalFilteredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = finalFilteredMedicines[index];
                    return _buildMedicineCard(medicine);
                  },
                ),
        ],
      ),
    );
  }

  String _getEmptyStateMessage(
    MedicineFilterType filterType,
    Set<MedicineProductType> selectedProductTypes,
    Set<MedicineConditionType> selectedConditionTypes,
  ) {
    if (filterType == MedicineFilterType.favorites) {
      return 'No favorite medicines yet';
    }

    if (selectedProductTypes.isNotEmpty || selectedConditionTypes.isNotEmpty) {
      return 'No medicines found matching your filters';
    }

    return 'No medicines available';
  }

  // Update search results to use filtered medicines as well
  Widget _buildSearchResults(AsyncValue<List<Medicine>> medicinesAsyncValue) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final selectedProductTypes = ref.watch(selectedProductTypesProvider);
    final selectedConditionTypes = ref.watch(selectedConditionTypesProvider);

    return medicinesAsyncValue.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No medicines found',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
              ),
            ),
          );
        }

        // Apply current filter to search results
        List<Medicine> filteredMedicines = medicines.map((medicine) {
          return medicine.copyWith(isFavorite: favorites.contains(medicine.id));
        }).toList();

        // Apply product type filter
        if (selectedProductTypes.isNotEmpty) {
          filteredMedicines = filteredMedicines.where((medicine) {
            return selectedProductTypes.contains(medicine.productType);
          }).toList();
        }

        // Apply condition type filter
        if (selectedConditionTypes.isNotEmpty) {
          filteredMedicines = filteredMedicines.where((medicine) {
            return selectedConditionTypes.contains(medicine.conditionType);
          }).toList();
        }

        final filterType = ref.watch(selectedFilterProvider);
        switch (filterType) {
          case MedicineFilterType.relevance:
            filteredMedicines.sort(
              (a, b) => a.medicineName.compareTo(b.medicineName),
            );
            break;
          case MedicineFilterType.latest:
            filteredMedicines.sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
            );
            break;
          case MedicineFilterType.price:
            filteredMedicines.sort((a, b) => b.price.compareTo(a.price));
            break;
          case MedicineFilterType.favorites:
            filteredMedicines = filteredMedicines
                .where((medicine) => favorites.contains(medicine.id))
                .toList();
            break;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: filteredMedicines.length,
          itemBuilder: (context, index) {
            final medicine = filteredMedicines[index];
            return _buildMedicineCard(medicine);
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'Error loading medicines: $error',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final isFavorite = favorites.contains(medicine.id);

    return Consumer(
      builder: (context, ref, child) {
        final stockAsyncValue = ref.watch(stockStreamProvider(medicine.id));

        return stockAsyncValue.when(
          data: (currentStock) =>
              _buildCardWithStock(medicine, isFavorite, currentStock),
          loading: () =>
              _buildCardWithStock(medicine, isFavorite, medicine.stock),
          error: (_, __) =>
              _buildCardWithStock(medicine, isFavorite, medicine.stock),
        );
      },
    );
  }

  Widget _buildCardWithStock(
    Medicine medicine,
    bool isFavorite,
    int currentStock,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicineDetailScreen(medicine: medicine),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine image with stock badge overlay
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    medicine.imageURL,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Stock badge overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: StockBadge(stock: currentStock),
                  ),
                ],
              ),
            ),
            // Medicine details
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    medicine.medicineName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine.majorTypeDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A4B8D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    medicine.productTypeDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ' ${medicine.productOffering.join(", ")}',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₱ ${medicine.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.red
                              : const Color(0xFF8ECAE6),
                          size: 28,
                        ),
                        onPressed: () {
                          ref
                              .read(favoriteMedicinesProvider.notifier)
                              .toggleFavorite(medicine.id);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedProductCard(Medicine medicine) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final isFavorite = favorites.contains(medicine.id);

    return Consumer(
      builder: (context, ref, child) {
        final stockAsyncValue = ref.watch(stockStreamProvider(medicine.id));

        return stockAsyncValue.when(
          data: (currentStock) => _buildRecommendedCardWithStock(
            medicine,
            isFavorite,
            currentStock,
          ),
          loading: () => _buildRecommendedCardWithStock(
            medicine,
            isFavorite,
            medicine.stock,
          ),
          error: (_, __) => _buildRecommendedCardWithStock(
            medicine,
            isFavorite,
            medicine.stock,
          ),
        );
      },
    );
  }

  Widget _buildRecommendedCardWithStock(
    Medicine medicine,
    bool isFavorite,
    int currentStock,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicineDetailScreen(medicine: medicine),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine image with stock badge overlay
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  Image.network(
                    medicine.imageURL,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Stock badge overlay
                  Positioned(
                    top: 4,
                    right: 4,
                    child: StockBadge(stock: currentStock),
                  ),
                ],
              ),
            ),
            // Medicine details
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    medicine.medicineName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine.majorTypeDisplayName,
                      style: GoogleFonts.poppins(
                        fontSize: 7,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A4B8D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    medicine.productTypeDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    ' ${medicine.productOffering.join(", ")}',
                    style: GoogleFonts.poppins(
                      fontSize: 8,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '₱ ${medicine.price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? Colors.red
                              : const Color(0xFF8ECAE6),
                          size: 24,
                        ),
                        onPressed: () {
                          ref
                              .read(favoriteMedicinesProvider.notifier)
                              .toggleFavorite(medicine.id);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
