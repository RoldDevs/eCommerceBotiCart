import 'package:boticart/features/pharmacy/presentation/screens/order_tracking_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/order_verification/pending_verification_screen.dart';
import 'package:boticart/features/pharmacy/presentation/screens/order_verification/payment_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/presentation/providers/user_provider.dart';
import '../../domain/entities/order.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/orders/order_card_widget.dart';
import '../providers/order_status_change_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  final int? initialTabIndex;

  const OrdersScreen({super.key, this.initialTabIndex});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialTabIndex ?? 0;
    _tabController = TabController(
      length: 9,
      vsync: this,
      initialIndex: initialIndex,
    );
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
            return const Center(child: Text('Please log in to view orders'));
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
        error: (_, __) => const Center(child: Text('Error loading user data')),
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
          return Center(child: Text('Error: ${snapshot.error}'));
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
            bool isNotToProcess =
                !(order.isHomeDelivery && !order.isCompletelyVerified);
            return matchesStatus && isNotToProcess;
          }
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCardWidget(
              order: order,
              onViewDetails: () => _showOrderDetails(order),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _showOrderDetails(OrderEntity order) {
    // Mark order status changes as read when viewing details
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      final repository = ref.read(orderStatusChangeRepositoryProvider);

      // Mark existing status change records as read
      repository.markOrderStatusChangesAsRead(order.orderID, user.id);

      // If order is in verification state, create a "read" record to prevent showing indicator again
      if (order.isHomeDelivery &&
          order.isInitiallyVerified &&
          !order.isPaid &&
          !order.isCompletelyVerified) {
        // Check if a status change record exists for this state
        FirebaseFirestore.instance
            .collection('orderStatusChanges')
            .where('orderId', isEqualTo: order.orderID)
            .where('userId', isEqualTo: user.id)
            .where('newStatus', isEqualTo: 'Initial Verification')
            .get()
            .then((snapshot) {
              if (snapshot.docs.isEmpty) {
                // Create a read record so it doesn't show again
                repository
                    .createStatusChange(
                      orderId: order.orderID,
                      userId: user.id,
                      oldStatus: 'Pending',
                      newStatus: 'Initial Verification',
                      timestamp: DateTime.now(),
                    )
                    .then((_) {
                      // Immediately mark it as read
                      repository.markOrderStatusChangesAsRead(
                        order.orderID,
                        user.id,
                      );
                    });
              }
            });
      }
    }

    // For home delivery orders that need verification, navigate to appropriate screen
    if (order.isHomeDelivery && !order.isCompletelyVerified) {
      if (!order.isInitiallyVerified) {
        // Order is waiting for initial verification - show pending screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PendingVerificationScreen(orderId: order.orderID),
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
            builder: (context) =>
                PendingVerificationScreen(orderId: order.orderID),
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
                  _buildDetailRow(
                    'Total Price',
                    '₱${order.totalPrice.toStringAsFixed(2)}',
                  ),
                  if (order.discountAmount != null && order.discountAmount! > 0)
                    _buildDetailRow(
                      'Discount',
                      '-₱${order.discountAmount!.toStringAsFixed(2)}',
                    ),
                  _buildDetailRow(
                    'Order Type',
                    order.isHomeDelivery ? 'Home Delivery' : 'Pickup',
                  ),
                  if (order.deliveryAddress != null &&
                      order.deliveryAddress!.isNotEmpty)
                    _buildDetailRow(
                      order.isHomeDelivery
                          ? 'Delivery Address'
                          : 'Pickup Address',
                      order.deliveryAddress!,
                    ),
                  _buildDetailRow('Order Date', _formatDate(order.createdAt)),
                  if (order.idDiscount != null)
                    _buildDetailRow('Beneficiary ID Applied', 'Yes'),

                  // Show delivery date/time if order is completed or delivered
                  if (order.status == OrderStatus.completed ||
                      order.status == OrderStatus.delivered) ...[
                    const SizedBox(height: 20),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('orders')
                          .doc(order.orderID)
                          .get(),
                      builder: (context, snapshot) {
                        DateTime? deliveredDate;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          // Check for deliveredAt, completedAt, or updatedAt field
                          if (data['deliveredAt'] != null) {
                            deliveredDate = (data['deliveredAt'] as Timestamp)
                                .toDate();
                          } else if (data['completedAt'] != null) {
                            deliveredDate = (data['completedAt'] as Timestamp)
                                .toDate();
                          } else if (data['updatedAt'] != null) {
                            deliveredDate = (data['updatedAt'] as Timestamp)
                                .toDate();
                          }
                        }

                        // Fallback to createdAt if no delivery date found
                        deliveredDate ??= order.createdAt;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(
                              'Date Delivered',
                              _formatDate(deliveredDate),
                            ),
                            _buildDetailRow(
                              'Time Delivered',
                              _formatTime(deliveredDate),
                            ),
                          ],
                        );
                      },
                    ),
                  ] else if (order.isHomeDelivery &&
                      order.lalamoveOrderId != null) ...[
                    // Add Track Order button if it's a home delivery and not completed/delivered
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderTrackingScreen(orderId: order.orderID),
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
                  ] else if (!order.isHomeDelivery) ...[
                    // Add View Order Details button for pickup orders
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the bottom sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrderTrackingScreen(orderId: order.orderID),
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
                          'View Order Details',
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
