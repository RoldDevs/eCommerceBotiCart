import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/delivery_provider.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));
    final deliveryStatusAsync = ref.watch(deliveryStatusProvider(widget.orderId));

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
          
          return SingleChildScrollView(
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
                
                // Map view
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
                        target: LatLng(14.5995, 120.9842), // Default to Manila
                        zoom: 15,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        setState(() {
                        });
                      },
                      myLocationEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                ),
                
                // Track Order button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: deliveryStatusAsync.when(
                    data: (deliveryStatus) {
                      final trackingUrl = deliveryStatus['trackingUrl'] as String?;
                      
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: trackingUrl != null && trackingUrl.isNotEmpty
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
                    loading: () => const Center(child: CircularProgressIndicator()),
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
                        final data = snapshot.data!.data() as Map<String, dynamic>;
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
                
                // Delivery information
                if (order.isHomeDelivery) ...[
                  deliveryStatusAsync.when(
                    data: (deliveryStatus) {
                      final driverName = deliveryStatus['driverName'] as String? ?? 'Not assigned';
                      final driverPhone = deliveryStatus['driverPhone'] as String? ?? '';
                      
                      return Column(
                        children: [
                          // Pharmacy and Customer addresses
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('pharmacy')
                                      .where('storeID', isEqualTo: order.storeID)
                                      .limit(1)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return _buildAddressSection('Pharmacy Address', 'Loading.', isLoading: true);
                                    }
                                    
                                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      // Fallback to direct document fetch by ID
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('pharmacy')
                                            .doc(order.storeID.toString())
                                            .get(),
                                        builder: (context, docSnapshot) {
                                          if (docSnapshot.connectionState == ConnectionState.waiting) {
                                            return _buildAddressSection('Pharmacy Address', 'Loading.', isLoading: true);
                                          }
                                          
                                          if (docSnapshot.hasData && docSnapshot.data!.exists) {
                                            final data = docSnapshot.data!.data() as Map<String, dynamic>?;
                                            final address = data?['Location'] as String? ?? 'Unknown Pharmacy';
                                            return _buildAddressSection('Pharmacy Address', address);
                                          }
                                          
                                          return _buildAddressSection('Pharmacy Address', 'Address not available');
                                        },
                                      );
                                    }
                                    
                                    final pharmacyData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                                    final address = pharmacyData['Location'] as String? ?? 'Unknown Pharmacy';
                                    
                                    return _buildAddressSection('Pharmacy Address', address);
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildAddressSection('Customer Address', order.deliveryAddress ?? 'No address provided'),
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
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Failed to load order details')),
      ),
    );
  }
  
  Widget _buildAddressSection(String title, String address, {bool isLoading = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(
              address,
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
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
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black54,
            ),
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
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              IconButton(
                onPressed: onCallPressed,
                icon: const Icon(
                  Icons.phone,
                  color: Color(0xFF8ECAE6),
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open tracking URL')),
      );
    }
  }
  
  Future<void> _launchPhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not make phone call')),
      );
    }
  }
}