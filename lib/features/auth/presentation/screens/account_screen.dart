import 'dart:io';
import 'package:boticart/core/theme/app_theme.dart';
import 'package:boticart/core/widgets/custom_modal.dart';
import 'package:boticart/features/auth/presentation/providers/auth_logout_provider.dart';
import 'package:boticart/features/auth/presentation/providers/prescription_upload_provider.dart';
import 'package:boticart/features/auth/presentation/screens/account_settings_screen.dart';
import 'package:boticart/features/auth/presentation/screens/login_screen.dart';
import 'package:boticart/features/pharmacy/presentation/providers/medicine_provider.dart';
import 'package:boticart/features/pharmacy/presentation/providers/navigation_provider.dart';
import 'package:boticart/features/pharmacy/presentation/providers/search_provider.dart';
import 'package:boticart/features/pharmacy/presentation/screens/orders_screen.dart';
import 'package:boticart/features/pharmacy/presentation/widgets/bottom_nav_bar.dart';
import 'package:boticart/features/pharmacy/presentation/widgets/recent_searches_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/file_item.dart';
import '../providers/user_provider.dart';
import '../widgets/account_menu_item.dart';
import '../widgets/profile_picture_widget.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _isPersonalInfoExpanded = false;
  bool _isPrescriptionExpanded = false;
  bool _isDiscountExpanded = false;
  final TextEditingController _prescriptionNoteController =
      TextEditingController();

  @override
  void dispose() {
    _prescriptionNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsyncValue = ref.watch(currentUserProvider);
    final prescriptionUploadState = ref.watch(prescriptionUploadProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: userAsyncValue.when(
          data: (user) {
            if (user == null) {
              return const Center(
                child: Text('Please login to view your account'),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  ProfilePictureWidget(
                    userId: user.id,
                    email: user.email,
                    firstName: user.firstName,
                    lastName: user.lastName,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '${user.firstName} ${user.lastName}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8ECAE6),
                    ),
                  ),

                  // User email
                  Text(
                    user.email,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: AccountMenuItem(
                      title: 'Personal Information',
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8ECAE6),
                      ),
                      icon: _isPersonalInfoExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      onTap: () {
                        setState(() {
                          _isPersonalInfoExpanded = !_isPersonalInfoExpanded;
                        });
                      },
                    ),
                  ),

                  if (_isPersonalInfoExpanded)
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildPersonalInfoSection(user),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: AccountMenuItem(
                      title: 'Prescription Management',
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8ECAE6),
                      ),
                      icon: _isPrescriptionExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      onTap: () {
                        setState(() {
                          _isPrescriptionExpanded = !_isPrescriptionExpanded;
                        });
                      },
                    ),
                  ),

                  if (_isPrescriptionExpanded)
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildPrescriptionSection(
                        user.id,
                        prescriptionUploadState,
                      ),
                    ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: AccountMenuItem(
                      title: 'Account Settings',
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8ECAE6),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: AccountMenuItem(
                      title: 'Discount',
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8ECAE6),
                      ),
                      icon: _isDiscountExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      onTap: () {
                        setState(() {
                          _isDiscountExpanded = !_isDiscountExpanded;
                        });
                      },
                    ),
                  ),

                  if (_isDiscountExpanded)
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 16.0,
                        right: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _buildDiscountSection(user.id),
                    ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'More Actions',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8ECAE6),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.favorite_border,
                            label: 'Favorites',
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
                              ref.read(selectedFilterProvider.notifier).state =
                                  MedicineFilterType.favorites;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Orders',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const OrdersScreen(),
                                ),
                              );
                              ref.read(navigationIndexProvider.notifier).state =
                                  2;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => CustomModal(
                            title: 'Logout',
                            content:
                                'Are you sure you want to logout of the account?',
                            onCancel: () => Navigator.pop(context),
                            onConfirm: () {
                              ref.read(authLogoutProvider.notifier).logout();
                              // Navigate to login screen
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF8ECAE6)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(height: 15),
                            Text(
                              'Log out',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8ECAE6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 70),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Error loading user data')),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildPersonalInfoSection(user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            icon: Icons.phone,
            title: 'Phone Number',
            value: user.contact,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            icon: Icons.home,
            title: 'Address',
            value: user.address,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8ECAE6)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrescriptionSection(
    String userId,
    AsyncValue<String?> uploadState,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload your prescriptions',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _prescriptionNoteController,
            decoration: InputDecoration(
              hintText: 'Add notes about your prescription',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF8ECAE6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: const Color(0xFF8ECAE6)),
              ),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.image,
                  label: 'Upload Image',
                  onTap: () => _showFilePickerDialog(userId, 'image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Upload PDF',
                  onTap: () => _showFilePickerDialog(userId, 'pdf'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (uploadState.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (uploadState.hasError)
            Center(
              child: Text(
                'Upload failed. Please try again.',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
              ),
            )
          else if (uploadState.hasValue && uploadState.value != null)
            const SizedBox(height: 8),
          _buildPrescriptionsList(userId),
        ],
      ),
    );
  }

  Widget _buildDiscountSection(String userId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload your senior citizen ID to get discounts',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.image,
                  label: 'Upload ID Image',
                  onTap: () => _showDiscountIdPickerDialog(userId, 'image'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Upload ID PDF',
                  onTap: () => _showDiscountIdPickerDialog(userId, 'pdf'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDiscountCardsList(userId),
        ],
      ),
    );
  }

  void _showDiscountIdPickerDialog(String userId, String fileType) {
    showDialog(
      context: context,
      builder: (context) => CustomModal(
        title: 'Upload Senior Citizen ID',
        content: 'Do you want to upload this senior citizen ID for discount?',
        cancelText: 'Cancel',
        confirmText: 'Upload',
        confirmButtonColor: const Color(0xFF8ECAE6),
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          Navigator.pop(context);
          if (fileType == 'image') {
            _pickDiscountIdImage(userId);
          } else {
            _pickDiscountIdPdf(userId);
          }
        },
      ),
    );
  }

  Widget _buildPrescriptionsList(String userId) {
    final prescriptionsAsync = ref.watch(userPrescriptionsProvider(userId));

    return prescriptionsAsync.when(
      data: (prescriptions) {
        if (prescriptions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No prescriptions uploaded yet',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Prescriptions',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = prescriptions[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    prescription.fileType == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.image,
                    color: const Color(0xFF8ECAE6),
                  ),
                  title: Text(
                    'Prescription ${index + 1}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (prescription.fileType != 'pdf')
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppBar(
                                        title: Text(
                                          'Prescription',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        leading: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        backgroundColor: Color(0xFF8ECAE6),
                                        elevation: 0,
                                        centerTitle: true,
                                      ),
                                      Container(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.7,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                prescription.url,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: double.infinity,
                                                    height: 300,
                                                    alignment: Alignment.center,
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        width: double.infinity,
                                                        height: 200,
                                                        color: Colors.grey[100],
                                                        alignment:
                                                            Alignment.center,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 48,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Failed to load image',
                                                              style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.visibility,
                            size: 20,
                            color: Color(0xFF8ECAE6),
                          ),
                        ),
                      if (prescription.fileType != 'pdf')
                        const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => CustomModal(
                              title: 'Confirm Deletion',
                              content:
                                  'Are you sure you want to delete this prescription?',
                              cancelText: 'Cancel',
                              confirmText: 'Delete',
                              confirmButtonColor: Colors.redAccent,
                              onCancel: () => Navigator.pop(context),
                              onConfirm: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('prescriptions')
                                    .where('url', isEqualTo: prescription.url)
                                    .get()
                                    .then((snapshot) {
                                      for (var doc in snapshot.docs) {
                                        doc.reference.delete();
                                      }
                                      // ignore: unused_result
                                      ref.refresh(
                                        userPrescriptionsProvider(userId),
                                      );
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Prescription deleted successfully',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Color(0xFF8ECAE6),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Open prescription
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Text(
        'Failed to load prescriptions',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
      ),
    );
  }

  Widget _buildDiscountCardsList(String userId) {
    final discountCardsAsync = ref.watch(userDiscountCardsProvider(userId));

    return discountCardsAsync.when(
      data: (discountCards) {
        if (discountCards.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No discount cards uploaded yet',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Discount Cards',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: discountCards.length,
              itemBuilder: (context, index) {
                final discountCard = discountCards[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    discountCard.fileType == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.image,
                    color: const Color(0xFF8ECAE6),
                  ),
                  title: Text(
                    'Senior Citizen ID ${index + 1}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (discountCard.fileType != 'pdf')
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AppBar(
                                        title: Text(
                                          'Discount Card',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        leading: IconButton(
                                          icon: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                        ),
                                        backgroundColor: Color(0xFF8ECAE6),
                                        elevation: 0,
                                        centerTitle: true,
                                      ),
                                      Container(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.7,
                                        ),
                                        child: SingleChildScrollView(
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                discountCard.url,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return Container(
                                                    width: double.infinity,
                                                    height: 300,
                                                    alignment: Alignment.center,
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return Container(
                                                        width: double.infinity,
                                                        height: 200,
                                                        color: Colors.grey[100],
                                                        alignment:
                                                            Alignment.center,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 48,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              'Failed to load image',
                                                              style: GoogleFonts.poppins(
                                                                color: Colors
                                                                    .grey[700],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.visibility,
                            size: 20,
                            color: Color(0xFF8ECAE6),
                          ),
                        ),
                      // Add spacing only if preview button is shown
                      if (discountCard.fileType != 'pdf')
                        const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => CustomModal(
                              title: 'Confirm Deletion',
                              content:
                                  'Are you sure you want to delete this discount card?',
                              cancelText: 'Cancel',
                              confirmText: 'Delete',
                              confirmButtonColor: Colors.redAccent,
                              onCancel: () => Navigator.pop(context),
                              onConfirm: () {
                                // Delete the discount card
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(userId)
                                    .collection('discountCards')
                                    .where('url', isEqualTo: discountCard.url)
                                    .get()
                                    .then((snapshot) {
                                      for (var doc in snapshot.docs) {
                                        doc.reference.delete();
                                      }
                                      // ignore: unused_result
                                      ref.refresh(
                                        userDiscountCardsProvider(userId),
                                      );
                                      // ignore: use_build_context_synchronously
                                      Navigator.pop(context);
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Discount card deleted successfully',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          backgroundColor:
                                              AppTheme.primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.delete,
                          size: 20,
                          color: Color(0xFF8ECAE6),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Open discount card
                  },
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => Text(
        'Failed to load discount cards',
        style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8ECAE6)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF8ECAE6)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Color(0xFF8ECAE6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8ECAE6), size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilePickerDialog(String userId, String fileType) {
    showDialog(
      context: context,
      builder: (context) => CustomModal(
        title: 'Upload Prescription',
        content: 'Do you want to upload this prescription with the note?',
        cancelText: 'Cancel',
        confirmText: 'Upload',
        confirmButtonColor: const Color(0xFF8ECAE6),
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          Navigator.pop(context);
          if (fileType == 'image') {
            _pickPrescriptionImage(userId);
          } else {
            _pickPrescriptionPdf(userId);
          }
        },
      ),
    );
  }

  Future<void> _pickPrescriptionImage(String userId) async {
    try {
      // Check if image limit is reached
      final prescriptionsAsync = ref.read(userPrescriptionsProvider(userId));
      final prescriptionsValue = prescriptionsAsync.value;
      if (prescriptionsValue != null) {
        final imageCount = prescriptionsValue
            .where((p) => p.fileType == 'image')
            .length;
        if (imageCount >= 5) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum limit of 5 images reached. Please delete an existing image before uploading a new one.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }
      }

      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileName =
            'prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final note = _prescriptionNoteController.text;

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text(
                  'Uploading prescription.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await ref
            .read(prescriptionUploadProvider.notifier)
            .uploadPrescription(
              userId: userId,
              file: file,
              fileName: fileName,
              note: note,
            );

        _prescriptionNoteController.clear();

        // ignore: unused_result
        ref.refresh(userPrescriptionsProvider(userId));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prescription uploaded successfully!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload prescription: ${e.toString()}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _pickPrescriptionPdf(String userId) async {
    try {
      // Check if PDF limit is reached
      final prescriptionsAsync = ref.read(userPrescriptionsProvider(userId));
      final prescriptionsValue = prescriptionsAsync.value;
      if (prescriptionsValue != null) {
        final pdfCount = prescriptionsValue
            .where((p) => p.fileType == 'pdf')
            .length;
        if (pdfCount >= 5) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maximum limit of 5 PDF files reached. Please delete an existing PDF before uploading a new one.',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName =
            'prescription_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final note = _prescriptionNoteController.text;

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text(
                  'Uploading prescription PDF.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await ref
            .read(prescriptionUploadProvider.notifier)
            .uploadPrescription(
              userId: userId,
              file: file,
              fileName: fileName,
              note: note,
            );

        _prescriptionNoteController.clear();

        // ignore: unused_result
        ref.refresh(userPrescriptionsProvider(userId));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Prescription PDF uploaded successfully!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload prescription: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _pickDiscountIdImage(String userId) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileName =
            'discount_id_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text(
                  'Uploading discount ID.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await ref
            .read(discountCardUploadProvider.notifier)
            .uploadDiscountCard(userId: userId, file: file, fileName: fileName);

        // ignore: unused_result
        ref.refresh(userDiscountCardsProvider(userId));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discount ID uploaded successfully!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload discount ID: ${e.toString()}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _pickDiscountIdPdf(String userId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName =
            'discount_id_${DateTime.now().millisecondsSinceEpoch}.pdf';

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text(
                  'Uploading discount ID PDF.',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await ref
            .read(discountCardUploadProvider.notifier)
            .uploadDiscountCard(userId: userId, file: file, fileName: fileName);

        // ignore: unused_result
        ref.refresh(userDiscountCardsProvider(userId));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Discount ID PDF uploaded successfully!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: AppTheme.primaryColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking PDF: $e');

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload discount ID PDF: ${e.toString()}',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

final prescriptionUploadProvider =
    StateNotifierProvider<PrescriptionUploadNotifier, AsyncValue<String?>>((
      ref,
    ) {
      return PrescriptionUploadNotifier();
    });

final userPrescriptionsProvider = StreamProvider.family<List<FileItem>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('prescriptions')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return FileItem(
              url: data['url'] as String,
              fileName: data['fileName'] as String? ?? 'prescription',
              fileType:
                  data['fileType'] as String? ??
                  _determineFileTypeFromUrl(data['url'] as String),
              createdAt: data['uploadedAt'] != null
                  ? (data['uploadedAt'] as Timestamp).toDate()
                  : null,
            );
          }).toList(),
        );
  },
);

final discountCardUploadProvider =
    StateNotifierProvider<DiscountCardUploadNotifier, AsyncValue<String?>>((
      ref,
    ) {
      return DiscountCardUploadNotifier();
    });

final userDiscountCardsProvider = StreamProvider.family<List<FileItem>, String>(
  (ref, userId) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('discountCards')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return FileItem(
              url: data['url'] as String,
              fileName: data['fileName'] as String,
              fileType:
                  data['fileType'] as String? ??
                  _determineFileTypeFromUrl(data['url'] as String),
              createdAt: data['uploadedAt'] != null
                  ? (data['uploadedAt'] as Timestamp).toDate()
                  : null,
            );
          }).toList(),
        );
  },
);

String _determineFileTypeFromUrl(String url) {
  return url.toLowerCase().contains('.pdf') ? 'pdf' : 'image';
}

class DiscountCardUploadNotifier extends StateNotifier<AsyncValue<String?>> {
  DiscountCardUploadNotifier() : super(const AsyncValue.data(null));

  Future<void> uploadDiscountCard({
    required String userId,
    required File file,
    required String fileName,
  }) async {
    state = const AsyncValue.loading();

    try {
      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;

      // Determine file type
      final fileType = _getFileType(fileName);

      // Check if a file of this type already exists
      final existingFiles = await firestore
          .collection('users')
          .doc(userId)
          .collection('discountCards')
          .where('fileType', isEqualTo: fileType)
          .get();

      // If a file of this type already exists, delete it from storage and Firestore
      if (existingFiles.docs.isNotEmpty) {
        for (var doc in existingFiles.docs) {
          final existingFileName = doc['fileName'] as String;

          // Delete from Storage
          try {
            await storage
                .ref('discountCards/$userId/$existingFileName')
                .delete();
          } catch (e) {
            // File might not exist in storage, continue anyway
          }

          // Delete from Firestore
          await doc.reference.delete();
        }
      }

      final discountCardRef = storage.ref('discountCards/$userId');

      final uploadTask = await discountCardRef
          .child(fileName)
          .putFile(
            file,
            SettableMetadata(contentType: _getContentType(fileName)),
          );

      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('discountCards')
          .add({
            'url': downloadUrl,
            'fileName': fileName,
            'fileType': fileType,
            'uploadedAt': FieldValue.serverTimestamp(),
          });

      state = AsyncValue.data(downloadUrl);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  String _getFileType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'pdf';
    } else {
      return 'image';
    }
  }

  String _getContentType(String fileName) {
    if (fileName.toLowerCase().endsWith('.pdf')) {
      return 'application/pdf';
    } else if (fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg')) {
      return 'image/jpeg';
    } else if (fileName.toLowerCase().endsWith('.png')) {
      return 'image/png';
    }
    return 'application/octet-stream';
  }
}
