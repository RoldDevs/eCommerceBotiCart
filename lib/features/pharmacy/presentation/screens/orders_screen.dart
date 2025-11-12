import 'package:boticart/features/pharmacy/presentation/screens/order_tracking_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/order_verification/pending_verification_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/order_verification/payment_screen.dart';
import 'package:boticart/core/utils/screen_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../domain/entities/order.dart';
import '../widgets/bottom_nav_bar.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ORDERS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF8ECAE6),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF8ECAE6),
          indicatorWeight: 3,
          dividerColor: const Color(0xFF8ECAE6),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'To Process'), 
            Tab(text: 'To Receive'),
            Tab(text: 'To Ship'),
            Tab(text: 'To Pickup'),
            Tab(text: 'In Transit'),
            Tab(text: 'Delivered'),
            Tab(text: 'Complete'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Please log in to view orders'),
            );
          }
          
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(user.id, null),
              _buildOrdersList(user.id, OrderStatus.toProcess), 
              _buildOrdersList(user.id, OrderStatus.toReceive),
              _buildOrdersList(user.id, OrderStatus.toShip),
              _buildOrdersList(user.id, OrderStatus.toPickup),
              _buildOrdersList(user.id, OrderStatus.inTransit),
              _buildOrdersList(user.id, OrderStatus.delivered),
              _buildOrdersList(user.id, OrderStatus.completed), 
              _buildOrdersList(user.id, OrderStatus.cancelled),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Text('Error loading user data'),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
  
  Stream<QuerySnapshot> _getOrdersStream(String userUID, OrderStatus? status) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userUID', isEqualTo: userUID);
    
    // Don't filter by status at database level for "To Process" tab
    // because "To Process" is determined by verification status, not order status
    if (status != null && status != OrderStatus.toProcess) {
      query = query.where('status', isEqualTo: status.displayName);
    }
    
    return query.snapshots();
  }

  Widget _buildOrdersList(String userUID, OrderStatus? status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getOrdersStream(userUID, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final allOrders = snapshot.data!.docs
            .map((doc) => OrderEntity.fromFirestore(doc))
            .toList();
        
        // Filter orders based on status and verification
        final orders = allOrders.where((order) {
          if (status == null) {
            // Show all orders in "All Orders" tab
            return true;
          } else if (status == OrderStatus.toProcess) {
            // Show only unverified home delivery orders in "To Process" tab
            return order.isHomeDelivery && !order.isCompletelyVerified;
          } else {
            // For other tabs, show orders that match the status AND are not "To Process"
            bool matchesStatus = order.status == status;
            bool isNotToProcess = !(order.isHomeDelivery && !order.isCompletelyVerified);
            return matchesStatus && isNotToProcess;
          }
        }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); 
        
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: Color(0xFF8ECAE6),
                ),
                const SizedBox(height: 20),
                Text(
                  'No orders found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status == null 
                      ? 'You haven\'t placed any orders yet'
                      : 'No orders with ${status.displayName} status',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: ScreenUtils.getBottomPadding(context),
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }
  
  Widget _buildOrderCard(OrderEntity order) {
    // Determine display status - show "To Process" for unverified home delivery orders
    String displayStatus;
    Color statusColor;
    
    if (order.isHomeDelivery && !order.isCompletelyVerified) {
      displayStatus = 'To Process';
      statusColor = Colors.orange;
    } else {
      displayStatus = order.status.displayName;
      statusColor = _getStatusColor(order.status);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderID}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8ECAE6),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayStatus,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on: ${_formatDate(order.createdAt)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('medicines')
                      .doc(order.medicineID)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8ECAE6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8ECAE6)),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8ECAE6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.medication,
                          color: Color(0xFF8ECAE6),
                          size: 24,
                        ),
                      );
                    }
                    
                    final medicineData = snapshot.data!.data() as Map<String, dynamic>;
                    final imageURL = medicineData['imageURL'] as String?;
                    
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageURL != null && imageURL.isNotEmpty
                            ? Image.network(
                                imageURL,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFF8ECAE6).withOpacity(0.1),
                                    child: const Icon(
                                      Icons.medication,
                                      color: Color(0xFF8ECAE6),
                                      size: 24,
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: const Color(0xFF8ECAE6).withOpacity(0.1),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8ECAE6)),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: const Color(0xFF8ECAE6).withOpacity(0.1),
                                child: const Icon(
                                  Icons.medication,
                                  color: Color(0xFF8ECAE6),
                                  size: 24,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medicine Order',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Qty: ${order.quantity}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (order.isHomeDelivery) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Home Delivery',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ₱${order.totalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8ECAE6),
                      ),
                    ),
                    if (order.discountAmount != null && order.discountAmount! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Discount: -₱${order.discountAmount!.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.deliveryAddress!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () {
                    _showOrderDetails(order);
                  },
                  child: Text(
                    'View Details',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF8ECAE6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.toProcess:
        return Colors.orange;
      case OrderStatus.toReceive:
        return Colors.blue;
      case OrderStatus.toShip:
        return Colors.purple;
      case OrderStatus.toPickup:
        return Colors.amber;
      case OrderStatus.inTransit:
        return Colors.indigo;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
  
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
  
  void _showOrderDetails(OrderEntity order) {
    // For home delivery orders that need verification, navigate to appropriate screen
    if (order.isHomeDelivery && !order.isCompletelyVerified) {
      if (!order.isInitiallyVerified) {
        // Order is waiting for initial verification - show pending screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PendingVerificationScreen(orderId: order.orderID),
          ),
        );
      } else if (!order.isPaid) {
        // Order is verified but not paid - show payment screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(orderId: order.orderID),
          ),
        );
      } else {
        // Order is paid but not completely verified - show pending screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PendingVerificationScreen(orderId: order.orderID),
          ),
        );
      }
      return;
    }

    // For other orders, show the original modal bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Order ID', '#${order.orderID}'),
                  _buildDetailRow('Status', order.status.displayName),
                  _buildDetailRow('Quantity', '${order.quantity}'),
                  _buildDetailRow('Total Price', '₱${order.totalPrice.toStringAsFixed(2)}'),
                  if (order.discountAmount != null && order.discountAmount! > 0)
                    _buildDetailRow('Discount', '-₱${order.discountAmount!.toStringAsFixed(2)}'),
                  _buildDetailRow('Delivery Type', order.isHomeDelivery ? 'Home Delivery' : 'Pickup'),
                  if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
                    _buildDetailRow('Delivery Address', order.deliveryAddress!),
                  _buildDetailRow('Order Date', _formatDate(order.createdAt)),
                  if (order.idDiscount != null)
                    _buildDetailRow('Beneficiary ID Applied', 'Yes'),
                
                  // Add Track Order button if it's a home delivery
                  if (order.isHomeDelivery && order.lalamoveOrderId != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderTrackingScreen(orderId: order.orderID),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8ECAE6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Track Order',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8ECAE6),
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}