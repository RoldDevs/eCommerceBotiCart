import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/review.dart';
import '../providers/review_provider.dart';
import '../widgets/review_item_widget.dart';
import 'add_review_screen.dart';

class PharmacyReviewsScreen extends ConsumerStatefulWidget {
  final Pharmacy pharmacy;
  final int? initialTabIndex;

  const PharmacyReviewsScreen({
    super.key,
    required this.pharmacy,
    this.initialTabIndex,
  });

  @override
  ConsumerState<PharmacyReviewsScreen> createState() =>
      _PharmacyReviewsScreenState();
}

class _PharmacyReviewsScreenState extends ConsumerState<PharmacyReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _pharmacyLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 2,
    );
    _tabController.addListener(() {
      setState(() {});
    });
    _getPharmacyLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getPharmacyLocation() async {
    try {
      List<Location> locations = await locationFromAddress(
        widget.pharmacy.location,
      );
      if (locations.isNotEmpty) {
        setState(() {
          _pharmacyLocation = LatLng(
            locations.first.latitude,
            locations.first.longitude,
          );
          _markers = {
            Marker(
              markerId: const MarkerId('pharmacy_location'),
              position: _pharmacyLocation!,
              infoWindow: InfoWindow(
                title: widget.pharmacy.name,
                snippet: widget.pharmacy.location,
              ),
            ),
          };
        });
      }
    } catch (e) {
      // If geocoding fails, use default Manila location
      setState(() {
        _pharmacyLocation = const LatLng(14.5995, 120.9842);
        _markers = {
          Marker(
            markerId: const MarkerId('pharmacy_location'),
            position: _pharmacyLocation!,
            infoWindow: InfoWindow(
              title: widget.pharmacy.name,
              snippet: widget.pharmacy.location,
            ),
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildStoreVisualsTab(),
                  _buildUserReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddReviewScreen(pharmacy: widget.pharmacy),
                  ),
                );
              },
              backgroundColor: const Color(0xFF8ECAE6),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.rate_review),
              label: Text(
                'Add Review',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: widget.pharmacy.backgroundImgUrl.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(widget.pharmacy.backgroundImgUrl),
                fit: BoxFit.cover,
              )
            : null,
        gradient: widget.pharmacy.backgroundImgUrl.isEmpty
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF8ECAE6).withValues(alpha: 0.8),
                  const Color(0xFF219EBC).withValues(alpha: 0.6),
                ],
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.3),
              Colors.black.withValues(alpha: 0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row with back button only
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Pharmacy info centered
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: widget.pharmacy.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.pharmacy.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.local_pharmacy,
                                      color: Color(0xFF8ECAE6),
                                      size: 25,
                                    );
                                  },
                                )
                              : const Icon(
                                  Icons.local_pharmacy,
                                  color: Color(0xFF8ECAE6),
                                  size: 25,
                                ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.pharmacy.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (index) {
                            return Icon(
                              index < widget.pharmacy.rating.floor()
                                  ? Icons.star
                                  : index < widget.pharmacy.rating
                                  ? Icons.star_half
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${widget.pharmacy.rating.toStringAsFixed(1)} (${widget.pharmacy.reviewCount})',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF8ECAE6), width: 1.0),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF8ECAE6),
        unselectedLabelColor: Colors.grey[600],
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicatorColor: const Color(0xFF8ECAE6),
        indicatorWeight: 2,
        dividerColor: const Color(0xFF8ECAE6),
        tabs: const [
          Tab(text: 'About'),
          Tab(text: 'Store Visuals'),
          Tab(text: 'User Reviews'),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pharmacy Identity',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8ECAE6),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.pharmacy.description.isNotEmpty
                ? widget.pharmacy.description
                : '',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8ECAE6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _pharmacyLocation != null
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _pharmacyLocation!,
                        zoom: 15,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8ECAE6),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.pharmacy.location,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreVisualsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildVisualItem(
            'Storefront',
            Icons.arrow_forward_ios,
            widget.pharmacy.drugstorePictureUrl,
          ),
          const SizedBox(height: 16),
          _buildVisualItem(
            'FDA License',
            Icons.arrow_forward_ios,
            widget.pharmacy.fdaLicenseUrl,
          ),
          const SizedBox(height: 16),
          _buildVisualItem(
            'Business Permit',
            Icons.arrow_forward_ios,
            widget.pharmacy.businessPermitUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildVisualItem(String title, IconData icon, String? imageUrl) {
    return GestureDetector(
      onTap: () {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          _showImageDialog(context, title, imageUrl);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title image is not available'),
              backgroundColor: Colors.grey[600],
            ),
          );
        }
      },
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8ECAE6),
            ),
          ),
          Icon(icon, color: Colors.grey[600], size: 16),
        ],
        ),
      ),
    );
  }

  void _showImageDialog(BuildContext context, String title, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8ECAE6),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 500),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Failed to load image',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: const Color(0xFF8ECAE6),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserReviewsTab() {
    return Consumer(
      builder: (context, ref, child) {
        final reviewsAsyncValue = ref.watch(
          pharmacyReviewsProvider(widget.pharmacy.id),
        );

        return reviewsAsyncValue.when(
          data: (reviews) => _buildReviewsList(reviews),
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF8ECAE6)),
          ),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reviews',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsList(List<Review> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with title only
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Store Ratings and Reviews',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8ECAE6),
            ),
          ),
        ),
        // Reviews list
        Expanded(
          child: reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 64,
                        color: Color(0xFF8ECAE6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8ECAE6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to review this pharmacy!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return ReviewItemWidget(
                      review: reviews[index],
                      margin: const EdgeInsets.only(bottom: 16),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
