import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/search_provider.dart';
import '../providers/medicine_provider.dart';
import '../../domain/entities/medicine.dart';

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
  ConsumerState<RecentSearchesScreen> createState() => _RecentSearchesScreenState();
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF2A4B8D)),
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
                          const Icon(Icons.search, color: Color(0xFF8ECAE6), size: 35),
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
                                contentPadding: const EdgeInsets.only(left: 5, top: 15, bottom: 15),
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
                    icon: const Icon(Icons.filter_list, color: Color(0xFF2A4B8D)),
                    onPressed: () {},
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
                    _buildFilterChip('Relevance', selectedFilter == MedicineFilterType.relevance, () {
                      ref.read(selectedFilterProvider.notifier).state = MedicineFilterType.relevance;
                    }),
                    _buildFilterChip('Latest', selectedFilter == MedicineFilterType.latest, () {
                      ref.read(selectedFilterProvider.notifier).state = MedicineFilterType.latest;
                    }),
                    _buildFilterChip('Price', selectedFilter == MedicineFilterType.price, () {
                      ref.read(selectedFilterProvider.notifier).state = MedicineFilterType.price;
                    }),
                    _buildFilterChip('Favorites', selectedFilter == MedicineFilterType.favorites, () {
                      ref.read(selectedFilterProvider.notifier).state = MedicineFilterType.favorites;
                    }),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            
            // Content area - either recent searches or search results
            Expanded(
              child: _searchQuery.isEmpty
                  ? _buildRecentSearches()
                  : _buildSearchResults(medicinesAsyncValue),
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
    final filteredMedicines = ref.watch(filteredMedicinesProvider);
    final searchHistory = ref.watch(searchHistoryProvider);
    
    return Column(
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                    trailing: const Icon(Icons.north_west, size: 20, color: Colors.grey),
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
        Expanded(
          child: filteredMedicines.isEmpty
              ? Center(
                  child: Text(
                    ref.watch(selectedFilterProvider) == MedicineFilterType.favorites
                        ? 'No favorite medicines yet'
                        : 'No medicines available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredMedicines.length,
                  itemBuilder: (context, index) {
                    final medicine = filteredMedicines[index];
                    return _buildMedicineCard(medicine);
                  },
                ),
        ),
      ],
    );
  }

  // Update search results to use filtered medicines as well
  Widget _buildSearchResults(AsyncValue<List<Medicine>> medicinesAsyncValue) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    
    return medicinesAsyncValue.when(
      data: (medicines) {
        if (medicines.isEmpty) {
          return Center(
            child: Text(
              'No medicines found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          );
        }
        
        // Apply current filter to search results
        List<Medicine> filteredMedicines = medicines.map((medicine) {
          return medicine.copyWith(
            isFavorite: favorites.contains(medicine.id)
          );
        }).toList();
        
        final filterType = ref.watch(selectedFilterProvider);
        switch (filterType) {
          case MedicineFilterType.relevance:
            filteredMedicines.sort((a, b) => a.medicineName.compareTo(b.medicineName));
            break;
          case MedicineFilterType.latest:
            filteredMedicines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            break;
          case MedicineFilterType.price:
            filteredMedicines.sort((a, b) => b.price.compareTo(a.price));
            break;
          case MedicineFilterType.favorites:
            filteredMedicines = filteredMedicines.where((medicine) => favorites.contains(medicine.id)).toList();
            break;
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(
          'Error loading medicines: $error',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Widget _buildMedicineCard(Medicine medicine) {
    final favorites = ref.watch(favoriteMedicinesProvider);
    final isFavorite = favorites.contains(medicine.id);
    
    return Container(
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
          // Medicine image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              medicine.imageURL,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          
          // Medicine details
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine.medicineName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  ' ${medicine.productOffering.join(", ")}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₱ ${medicine.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : const Color(0xFF8ECAE6),
                        size: 40,
                      ),
                      onPressed: () {
                        ref.read(favoriteMedicinesProvider.notifier).toggleFavorite(medicine.id);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}