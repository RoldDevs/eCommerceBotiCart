import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/screen_utils.dart';
import '../widgets/recent_searches_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/quick_actions_section.dart';
import '../providers/search_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/filter_provider.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/medicine.dart';
import '../../../../features/auth/presentation/providers/user_provider.dart';
import '../../../../features/auth/presentation/screens/account_screen.dart';

class PharmacyDetailScreen extends ConsumerWidget {
  final Pharmacy pharmacy;

  const PharmacyDetailScreen({super.key, required this.pharmacy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationIndexProvider.notifier).state = 0;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopSection(context, ref),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(35, 15, 35, 15),
                      child: GestureDetector(
                        onTap: () {
                          final initialSearches = ref.read(
                            initialSearchesProvider,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RecentSearchesScreen(
                                recentSearches: initialSearches,
                                onSearchTap: (query) {
                                  ref
                                      .read(searchHistoryProvider.notifier)
                                      .addSearch(query);
                                },
                                onBackPressed: () =>
                                    Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F3F8).withAlpha(120),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 15,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search,
                                color: Color(0xFF8ECAE6),
                                size: 35,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'Search',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Welcome message with image
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.transparent),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Welcome to ${pharmacy.name} -',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8ECAE6),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Your health, our\npriority.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF8ECAE6),
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              width: 140,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SvgPicture.asset(
                                'assets/illus/vitamins.svg',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Categories section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Categories',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8ECAE6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCategoryCard(
                                  context: context,
                                  ref: ref,
                                  title: 'Prescription',
                                  svgPath: 'assets/illus/prescription.svg',
                                  onTap: () {
                                    // Navigate to Account Screen with prescription section
                                    ref
                                            .read(
                                              navigationIndexProvider.notifier,
                                            )
                                            .state =
                                        4;
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AccountScreen(),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildCategoryCard(
                                  context: context,
                                  ref: ref,
                                  title: 'Vitamins & Supplements',
                                  svgPath: 'assets/illus/supplements.svg',
                                  onTap: () {
                                    // Clear existing filters
                                    ref
                                        .read(
                                          selectedProductTypesProvider.notifier,
                                        )
                                        .clear();
                                    ref
                                        .read(
                                          selectedConditionTypesProvider
                                              .notifier,
                                        )
                                        .clear();
                                    // Apply Vitamins & Supplements filter
                                    ref
                                        .read(
                                          selectedProductTypesProvider.notifier,
                                        )
                                        .toggle(
                                          MedicineProductType
                                              .vitaminsSupplements,
                                        );
                                    // Navigate to products screen
                                    final initialSearches = ref.read(
                                      initialSearchesProvider,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecentSearchesScreen(
                                              recentSearches: initialSearches,
                                              onSearchTap: (query) {
                                                ref
                                                    .read(
                                                      searchHistoryProvider
                                                          .notifier,
                                                    )
                                                    .addSearch(query);
                                              },
                                              onBackPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildCategoryCard(
                                  context: context,
                                  ref: ref,
                                  title: 'Over the Counter',
                                  svgPath: 'assets/illus/counter.svg',
                                  onTap: () {
                                    // Clear existing filters
                                    ref
                                        .read(
                                          selectedProductTypesProvider.notifier,
                                        )
                                        .clear();
                                    ref
                                        .read(
                                          selectedConditionTypesProvider
                                              .notifier,
                                        )
                                        .clear();
                                    // Apply Over the Counter filter
                                    ref
                                        .read(
                                          selectedProductTypesProvider.notifier,
                                        )
                                        .toggle(
                                          MedicineProductType.overTheCounter,
                                        );
                                    // Navigate to products screen
                                    final initialSearches = ref.read(
                                      initialSearchesProvider,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecentSearchesScreen(
                                              recentSearches: initialSearches,
                                              onSearchTap: (query) {
                                                ref
                                                    .read(
                                                      searchHistoryProvider
                                                          .notifier,
                                                    )
                                                    .addSearch(query);
                                              },
                                              onBackPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                _buildCategoryCard(
                                  context: context,
                                  ref: ref,
                                  title: 'See all products',
                                  svgPath: 'assets/illus/all.svg',
                                  onTap: () {
                                    // Clear all filters to show all products
                                    ref
                                        .read(
                                          selectedProductTypesProvider.notifier,
                                        )
                                        .clear();
                                    ref
                                        .read(
                                          selectedConditionTypesProvider
                                              .notifier,
                                        )
                                        .clear();
                                    // Navigate to products screen
                                    final initialSearches = ref.read(
                                      initialSearchesProvider,
                                    );
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            RecentSearchesScreen(
                                              recentSearches: initialSearches,
                                              onSearchTap: (query) {
                                                ref
                                                    .read(
                                                      searchHistoryProvider
                                                          .notifier,
                                                    )
                                                    .addSearch(query);
                                              },
                                              onBackPressed: () =>
                                                  Navigator.of(context).pop(),
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Featured Products',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8ECAE6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {},
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    'assets/feature/feature.jpg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 180,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.3),
                                          const Color(
                                            0xFFE6F3F8,
                                          ).withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Promotions section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promotions',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8ECAE6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              // Handle promotions tap
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Stack(
                                children: [
                                  Image.asset(
                                    'assets/promoted/promoted.jpg',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 180,
                                  ),
                                  Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: 0.3),
                                          const Color(
                                            0xFFE6F3F8,
                                          ).withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions section
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 20),
                      child: QuickActionsSection(pharmacy: pharmacy),
                    ),

                    SizedBox(height: ScreenUtils.getBottomPadding(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildTopSection(BuildContext context, WidgetRef ref) {
    final userAsyncValue = ref.watch(currentUserProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 25.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, const Color(0xFFE6F3F8)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello,',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2A4B8D),
                ),
              ),
              userAsyncValue.when(
                data: (user) {
                  final firstName = user?.firstName ?? "Juan";
                  return Text(
                    '$firstName!',
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A4B8D),
                    ),
                  );
                },
                loading: () => Text(
                  'Juan!',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A4B8D),
                  ),
                ),
                error: (_, __) => Text(
                  'Juan!',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A4B8D),
                  ),
                ),
              ),
            ],
          ),

          // Notification icon
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 20, 0),
            child: Icon(
              Icons.mark_email_unread,
              color: const Color(0xFF8ECAE6),
              size: 45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String svgPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFFE6F3F8),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF8ECAE6), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(color: Colors.transparent),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.all(0),
                child: SvgPicture.asset(svgPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8ECAE6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
