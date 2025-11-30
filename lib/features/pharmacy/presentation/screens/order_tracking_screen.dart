import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart' as loc;
import '../providers/delivery_provider.dart';
import '../providers/order_provider.dart';
import '../providers/location_provider.dart';
import '../services/directions_service.dart';
import '../widgets/pickup/im_here_button_widget.dart';
import '../widgets/pickup/pickup_status_tracker_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _pharmacyLocation;
  LatLng? _userLocation;
  bool _isLoadingPharmacyLocation = false;
  bool _isTrackingLocation = false;
  bool _hasLocationPermission = false;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  String? _pharmacyAddress;
  double _distanceToPharmacy = 0.0;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacyLocation(dynamic storeID) async {
    if (_isLoadingPharmacyLocation) return;

    setState(() {
      _isLoadingPharmacyLocation = true;
    });

    try {
      // Try to get pharmacy from stream first
      final pharmacySnapshot = await FirebaseFirestore.instance
          .collection('pharmacy')
          .where(
            'storeID',
            isEqualTo: storeID is int
                ? storeID
                : int.tryParse(storeID.toString()) ?? storeID,
          )
          .limit(1)
          .get();

      String? pharmacyAddress;

      if (pharmacySnapshot.docs.isNotEmpty) {
        final pharmacyData = pharmacySnapshot.docs.first.data();
        pharmacyAddress = pharmacyData['Location'] as String?;
      } else {
        // Fallback to direct document fetch
        final pharmacyDoc = await FirebaseFirestore.instance
            .collection('pharmacy')
            .doc(storeID.toString())
            .get();

        if (pharmacyDoc.exists) {
          final pharmacyData = pharmacyDoc.data();
          pharmacyAddress = pharmacyData?['Location'] as String?;
        }
      }

      if (pharmacyAddress != null && pharmacyAddress.isNotEmpty) {
        final location = await getLocationFromAddress(pharmacyAddress);
        if (location != null && mounted) {
          setState(() {
            _pharmacyLocation = location;
            _pharmacyAddress = pharmacyAddress;
            _updateMarkers();
          });

          // Update map camera to show pharmacy location
          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(location, 15),
            );
          }
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPharmacyLocation = false;
        });
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    final location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    try {
      // Check if location service is enabled
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location services are disabled. Please enable GPS to track your location.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                backgroundColor: const Color(0xFF8ECAE6),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              ),
            );
          }
          return;
        }
      }

      // Check location permission
      permissionGranted = await location.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted &&
            permissionGranted != loc.PermissionStatus.grantedLimited) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location permission is required to track your route to the pharmacy.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                backgroundColor: const Color(0xFF8ECAE6),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        setState(() {
          _hasLocationPermission = true;
        });
        await _startLocationTracking();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to enable location tracking. Please try again.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w400,
              ),
            ),
            backgroundColor: const Color(0xFF8ECAE6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
          ),
        );
      }
    }
  }

  Future<void> _startLocationTracking() async {
    if (!_hasLocationPermission || _pharmacyLocation == null) return;

    final location = loc.Location();
    location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 3000, // Update every 3 seconds for more real-time updates
      distanceFilter:
          5, // Update every 5 meters for more frequent route updates
    );

    _locationSubscription = location.onLocationChanged.listen(
      (loc.LocationData locationData) {
        if (locationData.latitude != null && locationData.longitude != null) {
          final newUserLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );

          setState(() {
            _userLocation = newUserLocation;
            _isTrackingLocation = true;
          });

          _updateMarkers();
          // Update route in real-time as user moves
          _updateRoute();
          // Don't auto-update bounds to allow user to explore map
          // _updateMapBounds();
        }
      },
      onError: (error) {
        // Handle location error
      },
    );
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add pharmacy marker
    if (_pharmacyLocation != null) {
      final blueMarker = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
      markers.add(
        Marker(
          markerId: const MarkerId('pharmacy_location'),
          position: _pharmacyLocation!,
          infoWindow: InfoWindow(
            title: 'Pharmacy Location',
            snippet: _pharmacyAddress ?? 'Destination',
          ),
          icon: blueMarker,
        ),
      );
    }

    // Add user location marker
    if (_userLocation != null) {
      final redMarker = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
          icon: redMarker,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  Future<void> _updateRoute() async {
    if (_userLocation == null || _pharmacyLocation == null) return;

    try {
      final routePoints = await DirectionsService.getRoutePolyline(
        origin: _userLocation!,
        destination: _pharmacyLocation!,
      );

      // Calculate distance
      _distanceToPharmacy = DirectionsService.calculateDistance(
        _userLocation!,
        _pharmacyLocation!,
      );

      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFF8ECAE6),
            width: 5,
            patterns: [],
          ),
        };
      });
    } catch (e) {
      // If route calculation fails, create a simple straight line
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_userLocation!, _pharmacyLocation!],
            color: const Color(0xFF8ECAE6),
            width: 5,
            patterns: [],
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final deliveryStatusAsync = ref.watch(
      deliveryStatusProvider(widget.orderId),
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ORDER INFORMATION',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          // Load pharmacy location for pickup orders
          if (!order.isHomeDelivery &&
              _pharmacyLocation == null &&
              !_isLoadingPharmacyLocation) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadPharmacyLocation(order.storeID);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '#${order.orderID}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8ECAE6),
                    ),
                  ),
                ),

                // Delivery type toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: order.isHomeDelivery ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: order.isHomeDelivery
                                ? const Color(0xFF8ECAE6)
                                : Colors.grey[300],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Home delivery',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: !order.isHomeDelivery ? () {} : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !order.isHomeDelivery
                                ? const Color(0xFF8ECAE6)
                                : Colors.grey[300],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Pick up',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Map view with route tracking (only for pickup orders)
                if (!order.isHomeDelivery) ...[
                  // Route info header
                  if (_isTrackingLocation &&
                      _userLocation != null &&
                      _pharmacyLocation != null)
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            color: const Color(0xFF8ECAE6),
                            size: 24,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'From: ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Your Location',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'To: ',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        _pharmacyAddress ?? 'Pharmacy',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF8ECAE6),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_distanceToPharmacy > 0) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Distance: ${_distanceToPharmacy.toStringAsFixed(2)} km',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 15),
                  // Map container
                  Container(
                    height: 250,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target:
                                  _pharmacyLocation ??
                                  const LatLng(14.5995, 120.9842),
                              zoom: 15,
                            ),
                            markers: _markers,
                            polylines: _polylines,
                            onMapCreated: (controller) {
                              _mapController = controller;
                              // Load pharmacy location for pickup orders
                              if (!order.isHomeDelivery) {
                                _loadPharmacyLocation(order.storeID);
                              }
                              // If we already have the location, update the camera
                              if (_pharmacyLocation != null &&
                                  !_isTrackingLocation) {
                                controller.animateCamera(
                                  CameraUpdate.newLatLngZoom(
                                    _pharmacyLocation!,
                                    15,
                                  ),
                                );
                              }
                              setState(() {});
                            },
                            myLocationEnabled: _isTrackingLocation,
                            myLocationButtonEnabled: _isTrackingLocation,
                            zoomControlsEnabled: true,
                            mapToolbarEnabled: false,
                            trafficEnabled: true, // Show traffic information
                            // Enable all gestures for map interaction
                            scrollGesturesEnabled: true,
                            zoomGesturesEnabled: true,
                            tiltGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            compassEnabled: true,
                            onTap: (_) {
                              if (!_isTrackingLocation) {
                                _requestLocationPermission();
                              }
                            },
                          ),
                          // Fullscreen button
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              elevation: 4,
                              child: InkWell(
                                onTap: () => _showFullscreenMap(context, order),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.fullscreen,
                                    color: const Color(0xFF8ECAE6),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Overlay message when GPS is not enabled
                          if (!_isTrackingLocation)
                            GestureDetector(
                              onTap: () {
                                _requestLocationPermission();
                              },
                              child: Container(
                                color: Colors.black.withValues(alpha: 0.3),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    margin: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: const Color(0xFF8ECAE6),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Tap to Enable GPS',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Enable location tracking to see your route to the pharmacy',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ] else
                  // Map view for delivery orders (unchanged)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target:
                              _pharmacyLocation ??
                              const LatLng(14.5995, 120.9842),
                          zoom: 15,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          setState(() {});
                        },
                        myLocationEnabled: false,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
                        trafficEnabled: true, // Show traffic information
                        // Enable all gestures for map interaction
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        compassEnabled: true,
                      ),
                    ),
                  ),

                // Track Order button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: deliveryStatusAsync.when(
                    data: (deliveryStatus) {
                      final trackingUrl =
                          deliveryStatus['trackingUrl'] as String?;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              trackingUrl != null && trackingUrl.isNotEmpty
                              ? () => _launchTrackingUrl(trackingUrl)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8ECAE6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Track Order',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ),

                // Order information
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('medicines')
                        .doc(order.medicineID)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      String medicineName = 'Product';
                      String medicineDetails = '';
                      String imageUrl = '';

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        medicineName = data['medicineName'] ?? 'Product';
                        medicineDetails = '${data['dosage'] ?? ''}';
                        imageUrl = data['imageURL'] ?? '';
                      }

                      return _buildOrderInfoCard(
                        medicineName: medicineName,
                        medicineDetails: medicineDetails,
                        imageUrl: imageUrl,
                        totalPrice: order.totalPrice,
                        quantity: order.quantity,
                      );
                    },
                  ),
                ),

                // Pickup information
                if (!order.isHomeDelivery) ...[
                  // Pickup status tracker
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: PickupStatusTrackerWidget(order: order),
                  ),

                  // "I'm here" button for curbside pickup
                  // Show whenever curbside pickup is enabled (regardless of status)
                  if (order.isCurbsidePickup) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: ImHereButtonWidget(
                        orderId: order.orderID,
                        pickupInstructions: order.pickupInstructions,
                        pickupStatus: order.pickupStatus ?? 'preparing',
                      ),
                    ),
                  ],

                  // Pickup location information
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('pharmacy')
                          .where('storeID', isEqualTo: order.storeID)
                          .limit(1)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildAddressSection(
                            'Pickup Location',
                            'Loading...',
                            isLoading: true,
                          );
                        }

                        if (snapshot.hasError ||
                            !snapshot.hasData ||
                            snapshot.data!.docs.isEmpty) {
                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('pharmacy')
                                .doc(order.storeID.toString())
                                .get(),
                            builder: (context, docSnapshot) {
                              if (docSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildAddressSection(
                                  'Pickup Location',
                                  'Loading...',
                                  isLoading: true,
                                );
                              }

                              if (docSnapshot.hasData &&
                                  docSnapshot.data!.exists) {
                                final data =
                                    docSnapshot.data!.data()
                                        as Map<String, dynamic>?;
                                final address =
                                    data?['Location'] as String? ??
                                    'Unknown Pharmacy';
                                return _buildAddressSection(
                                  'Pickup Location',
                                  address,
                                );
                              }

                              return _buildAddressSection(
                                'Pickup Location',
                                order.deliveryAddress ??
                                    'Address not available',
                              );
                            },
                          );
                        }

                        final pharmacyData =
                            snapshot.data!.docs.first.data()
                                as Map<String, dynamic>;
                        final address =
                            pharmacyData['Location'] as String? ??
                            'Unknown Pharmacy';

                        return _buildAddressSection('Pickup Location', address);
                      },
                    ),
                  ),

                  // Show scheduled pickup time if available
                  if (order.scheduledPickupTime != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: const Color(0xFF8ECAE6),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Scheduled Pickup Time',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _formatDateTime(order.scheduledPickupTime!),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF8ECAE6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],

                // Delivery information
                if (order.isHomeDelivery) ...[
                  deliveryStatusAsync.when(
                    data: (deliveryStatus) {
                      final driverName =
                          deliveryStatus['driverName'] as String? ??
                          'Not assigned';
                      final driverPhone =
                          deliveryStatus['driverPhone'] as String? ?? '';

                      return Column(
                        children: [
                          // Pharmacy and Customer addresses
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('pharmacy')
                                      .where(
                                        'storeID',
                                        isEqualTo: order.storeID,
                                      )
                                      .limit(1)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _buildAddressSection(
                                        'Pharmacy Address',
                                        'Loading.',
                                        isLoading: true,
                                      );
                                    }

                                    if (snapshot.hasError ||
                                        !snapshot.hasData ||
                                        snapshot.data!.docs.isEmpty) {
                                      // Fallback to direct document fetch by ID
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('pharmacy')
                                            .doc(order.storeID.toString())
                                            .get(),
                                        builder: (context, docSnapshot) {
                                          if (docSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return _buildAddressSection(
                                              'Pharmacy Address',
                                              'Loading.',
                                              isLoading: true,
                                            );
                                          }

                                          if (docSnapshot.hasData &&
                                              docSnapshot.data!.exists) {
                                            final data =
                                                docSnapshot.data!.data()
                                                    as Map<String, dynamic>?;
                                            final address =
                                                data?['Location'] as String? ??
                                                'Unknown Pharmacy';
                                            return _buildAddressSection(
                                              'Pharmacy Address',
                                              address,
                                            );
                                          }

                                          return _buildAddressSection(
                                            'Pharmacy Address',
                                            'Address not available',
                                          );
                                        },
                                      );
                                    }

                                    final pharmacyData =
                                        snapshot.data!.docs.first.data()
                                            as Map<String, dynamic>;
                                    final address =
                                        pharmacyData['Location'] as String? ??
                                        'Unknown Pharmacy';

                                    return _buildAddressSection(
                                      'Pharmacy Address',
                                      address,
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAddressSection(
                                  'Customer Address',
                                  order.deliveryAddress ??
                                      'No address provided',
                                ),
                              ],
                            ),
                          ),

                          // Rider information
                          if (driverName != 'Not assigned') ...[
                            const SizedBox(height: 16),
                            _buildRiderInfoCard(
                              riderName: driverName,
                              riderPhone: driverPhone,
                              onCallPressed: () {
                                if (driverPhone.isNotEmpty) {
                                  _launchPhoneCall(driverPhone);
                                }
                              },
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8ECAE6)),
              ),
            ),
          ),
        ),
        error: (_, __) =>
            const Center(child: Text('Failed to load order details')),
      ),
    );
  }

  Widget _buildAddressSection(
    String title,
    String address, {
    bool isLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(address, style: GoogleFonts.poppins(fontSize: 14)),
      ],
    );
  }

  Widget _buildOrderInfoCard({
    required String medicineName,
    required String medicineDetails,
    required String imageUrl,
    required double totalPrice,
    required int quantity,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Color(0xFF8ECAE6),
                            size: 24,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Color(0xFF8ECAE6),
                        size: 24,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quantity: $quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                if (medicineDetails.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    medicineDetails,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total Price:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '₱${totalPrice.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiderInfoCard({
    required String riderName,
    required String riderPhone,
    required VoidCallback onCallPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rider Name',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            riderName,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          Text(
            'Rider Contact Number',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                riderPhone,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              IconButton(
                onPressed: onCallPressed,
                icon: const Icon(Icons.phone, color: Color(0xFF8ECAE6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchTrackingUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open tracking URL')));
    }
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not make phone call')));
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final day = dateTime.day;
    final month = dateTime.month;
    final year = dateTime.year;

    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/${year} • ${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showFullscreenMap(BuildContext context, order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenMapView(
          pharmacyLocation: _pharmacyLocation,
          userLocation: _userLocation,
          markers: _markers,
          polylines: _polylines,
          isTrackingLocation: _isTrackingLocation,
          pharmacyAddress: _pharmacyAddress,
          distanceToPharmacy: _distanceToPharmacy,
          onRequestLocationPermission: _requestLocationPermission,
          storeID: order.storeID,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}

/// Fullscreen map view widget
class _FullscreenMapView extends ConsumerStatefulWidget {
  final LatLng? pharmacyLocation;
  final LatLng? userLocation;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool isTrackingLocation;
  final String? pharmacyAddress;
  final double distanceToPharmacy;
  final VoidCallback onRequestLocationPermission;
  final dynamic storeID;

  const _FullscreenMapView({
    required this.pharmacyLocation,
    required this.userLocation,
    required this.markers,
    required this.polylines,
    required this.isTrackingLocation,
    required this.pharmacyAddress,
    required this.distanceToPharmacy,
    required this.onRequestLocationPermission,
    required this.storeID,
  });

  @override
  ConsumerState<_FullscreenMapView> createState() => _FullscreenMapViewState();
}

class _FullscreenMapViewState extends ConsumerState<_FullscreenMapView> {
  GoogleMapController? _fullscreenMapController;
  Set<Marker> _fullscreenMarkers = {};
  Set<Polyline> _fullscreenPolylines = {};
  LatLng? _currentUserLocation;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  bool _isTracking = false;

  @override
  void initState() {
    super.initState();
    _fullscreenMarkers = widget.markers;
    _fullscreenPolylines = widget.polylines;
    _currentUserLocation = widget.userLocation;
    _isTracking = widget.isTrackingLocation;

    if (_isTracking) {
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _fullscreenMapController?.dispose();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    if (!_isTracking) {
      widget.onRequestLocationPermission();
      return;
    }

    final location = loc.Location();
    location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      interval: 3000, // Update every 3 seconds for more real-time updates
      distanceFilter:
          5, // Update every 5 meters for more frequent route updates
    );

    _locationSubscription = location.onLocationChanged.listen((
      loc.LocationData locationData,
    ) {
      if (locationData.latitude != null && locationData.longitude != null) {
        final newUserLocation = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );

        setState(() {
          _currentUserLocation = newUserLocation;
        });

        _updateMarkers();
        // Update route in real-time as user moves
        _updateRoute();
      }
    });
  }

  void _updateMarkers() {
    final markers = <Marker>{};

    // Add pharmacy marker
    if (widget.pharmacyLocation != null) {
      final blueMarker = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
      markers.add(
        Marker(
          markerId: const MarkerId('pharmacy_location'),
          position: widget.pharmacyLocation!,
          infoWindow: InfoWindow(
            title: 'Pharmacy Location',
            snippet: widget.pharmacyAddress ?? 'Destination',
          ),
          icon: blueMarker,
        ),
      );
    }

    // Add user location marker
    if (_currentUserLocation != null) {
      final redMarker = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueRed,
      );
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentUserLocation!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
          icon: redMarker,
        ),
      );
    }

    setState(() {
      _fullscreenMarkers = markers;
    });
  }

  Future<void> _updateRoute() async {
    if (_currentUserLocation == null || widget.pharmacyLocation == null) {
      return;
    }

    try {
      final routePoints = await DirectionsService.getRoutePolyline(
        origin: _currentUserLocation!,
        destination: widget.pharmacyLocation!,
      );

      setState(() {
        _fullscreenPolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFF8ECAE6),
            width: 5,
            patterns: [],
          ),
        };
      });
    } catch (e) {
      // Fallback to straight line
      setState(() {
        _fullscreenPolylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [_currentUserLocation!, widget.pharmacyLocation!],
            color: const Color(0xFF8ECAE6),
            width: 5,
            patterns: [],
          ),
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fullscreen map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  widget.pharmacyLocation ?? const LatLng(14.5995, 120.9842),
              zoom: 15,
            ),
            markers: _fullscreenMarkers,
            polylines: _fullscreenPolylines,
            onMapCreated: (controller) {
              _fullscreenMapController = controller;
              // Update camera to show both locations if available
              if (_currentUserLocation != null &&
                  widget.pharmacyLocation != null) {
                final bounds = LatLngBounds(
                  southwest: LatLng(
                    _currentUserLocation!.latitude <
                            widget.pharmacyLocation!.latitude
                        ? _currentUserLocation!.latitude
                        : widget.pharmacyLocation!.latitude,
                    _currentUserLocation!.longitude <
                            widget.pharmacyLocation!.longitude
                        ? _currentUserLocation!.longitude
                        : widget.pharmacyLocation!.longitude,
                  ),
                  northeast: LatLng(
                    _currentUserLocation!.latitude >
                            widget.pharmacyLocation!.latitude
                        ? _currentUserLocation!.latitude
                        : widget.pharmacyLocation!.latitude,
                    _currentUserLocation!.longitude >
                            widget.pharmacyLocation!.longitude
                        ? _currentUserLocation!.longitude
                        : widget.pharmacyLocation!.longitude,
                  ),
                );
                controller.moveCamera(
                  CameraUpdate.newLatLngBounds(bounds, 100),
                );
              } else if (widget.pharmacyLocation != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(widget.pharmacyLocation!, 15),
                );
              }
            },
            myLocationEnabled: _isTracking,
            myLocationButtonEnabled:
                false, // Disable built-in button, we'll use custom
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            trafficEnabled: true, // Show traffic information
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            tiltGesturesEnabled: true,
            rotateGesturesEnabled: true,
            compassEnabled: true,
            onTap: (_) {
              if (!_isTracking) {
                widget.onRequestLocationPermission();
                setState(() {
                  _isTracking = true;
                });
                _startLocationTracking();
              }
            },
          ),
          // Route info header (if tracking)
          if (_isTracking &&
              _currentUserLocation != null &&
              widget.pharmacyLocation != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.navigation,
                      color: const Color(0xFF8ECAE6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'From: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Your Location',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'To: ',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.pharmacyAddress ?? 'Pharmacy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8ECAE6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (widget.distanceToPharmacy > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Distance: ${widget.distanceToPharmacy.toStringAsFixed(2)} km',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Exit fullscreen button (below card, left side)
          if (_isTracking &&
              _currentUserLocation != null &&
              widget.pharmacyLocation != null)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  16 +
                  80, // Below the card
              left: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.fullscreen_exit,
                      color: const Color(0xFF8ECAE6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          // My Location button (below unfullscreen button, left side)
          if (_isTracking &&
              _currentUserLocation != null &&
              widget.pharmacyLocation != null)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  16 +
                  80 +
                  48, // Below the unfullscreen button
              left: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    // Center map on user's current location
                    if (_fullscreenMapController != null &&
                        _currentUserLocation != null) {
                      _fullscreenMapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentUserLocation!, 17),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.my_location,
                      color: const Color(0xFF8ECAE6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          // Pin location button (below card, right side)
          if (_isTracking &&
              _currentUserLocation != null &&
              widget.pharmacyLocation != null)
            Positioned(
              top:
                  MediaQuery.of(context).padding.top +
                  16 +
                  80, // Below the card
              right: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    // Center map on pharmacy location
                    if (_fullscreenMapController != null &&
                        widget.pharmacyLocation != null) {
                      _fullscreenMapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          widget.pharmacyLocation!,
                          17,
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.location_on,
                      color: const Color(0xFF8ECAE6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          // Exit fullscreen button (when not tracking - show at top right)
          if (!_isTracking ||
              _currentUserLocation == null ||
              widget.pharmacyLocation == null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                elevation: 4,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.fullscreen_exit,
                      color: const Color(0xFF8ECAE6),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          // GPS enable overlay (if not tracking)
          if (!_isTracking)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  widget.onRequestLocationPermission();
                  setState(() {
                    _isTracking = true;
                  });
                  _startLocationTracking();
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF8ECAE6),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to Enable GPS',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enable location tracking to see your route to the pharmacy',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
