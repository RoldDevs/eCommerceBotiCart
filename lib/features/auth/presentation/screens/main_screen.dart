import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boticart/features/pharmacy/presentation/providers/pharmacy_providers.dart';
import 'package:boticart/features/pharmacy/presentation/providers/filter_providers.dart';
import 'package:boticart/features/pharmacy/presentation/widgets/pharmacy_card.dart';
import 'package:boticart/features/helpchat/presentation/screens/help_chat_screen.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(pharmacySearchQueryProvider);
    final pharmaciesAsyncValue = searchQuery.isEmpty
        ? ref.watch(pharmaciesStreamProvider)
        : ref.watch(pharmacySearchResultsProvider);
    final favorites = ref.watch(favoritesProvider);
    final showOnlyFavorites = ref.watch(showOnlyFavoritesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref, showOnlyFavorites),

            Divider(height: 1, thickness: 1, color: Colors.grey[200]),

            _buildPharmacyList(
              pharmaciesAsyncValue,
              favorites,
              showOnlyFavorites,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    bool showOnlyFavorites,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // Store/Favorites toggle button
          _buildToggleButton(ref, showOnlyFavorites),

          // Search bar
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 23,
              ),
              child: _buildSearchBar(ref),
            ),
          ),

          // Support icon
          _buildSupportButton(context),
        ],
      ),
    );
  }

  Widget _buildToggleButton(WidgetRef ref, bool showOnlyFavorites) {
    return GestureDetector(
      onTap: () {
        ref.read(showOnlyFavoritesProvider.notifier).state = !showOnlyFavorites;
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: showOnlyFavorites ? const Color(0xFF8ECAE6) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8ECAE6).withAlpha(1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          showOnlyFavorites ? Icons.favorite : Icons.store,
          color: showOnlyFavorites
              ? Colors.white
              : const Color(0xFF8ECAE6).withAlpha(250),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    final searchController = TextEditingController(
      text: ref.watch(pharmacySearchQueryProvider),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF8ECAE6).withAlpha(50),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: const Color(0xFF8ECAE6), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(
                fontFamily: GoogleFonts.poppins().fontFamily,
                fontSize: 14,
              ),
              onChanged: (value) {
                ref.read(pharmacySearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                ref.read(pharmacySearchQueryProvider.notifier).state = '';
                searchController.clear();
              },
              child: Icon(Icons.clear, color: Colors.grey[500], size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildSupportButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => const HelpChatScreen()));
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8ECAE6).withAlpha(1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.headset_mic_outlined,
          color: const Color(0xFF8ECAE6).withAlpha(250),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildPharmacyList(
    AsyncValue<List<dynamic>> pharmaciesAsyncValue,
    List<String> favorites,
    bool showOnlyFavorites,
  ) {
    return Expanded(
      child: pharmaciesAsyncValue.when(
        data: (pharmacies) {
          final displayedPharmacies = showOnlyFavorites
              ? pharmacies
                    .where((pharmacy) => favorites.contains(pharmacy.id))
                    .toList()
              : pharmacies;

          if (showOnlyFavorites && displayedPharmacies.isEmpty) {
            return _buildEmptyFavoritesView();
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemCount: displayedPharmacies.length,
              itemBuilder: (context, index) {
                return PharmacyCard(pharmacy: displayedPharmacies[index]);
              },
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF8ECAE6)),
        ),
        error: (error, stack) => _buildErrorView(error),
      ),
    );
  }

  Widget _buildEmptyFavoritesView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.favorite_border, size: 64, color: Color(0xFF8ECAE6)),
          const SizedBox(height: 16),
          Text(
            'No favorite pharmacies yet',
            style: TextStyle(
              fontSize: 16,
              fontFamily: GoogleFonts.poppins().fontFamily,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Text(
        'Error loading pharmacies: $error',
        style: TextStyle(
          color: Colors.red,
          fontFamily: GoogleFonts.poppins().fontFamily,
        ),
      ),
    );
  }
}
