import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TermsAndPrivacyModal extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const TermsAndPrivacyModal({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<TermsAndPrivacyModal> createState() => _TermsAndPrivacyModalState();
}

class _TermsAndPrivacyModalState extends State<TermsAndPrivacyModal>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _hasReachedBottom = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      final delta = 50.0; // Allow 50px before bottom to enable button

      if (!_hasReachedBottom && (currentScroll + delta) >= maxScroll) {
        setState(() {
          _hasReachedBottom = true;
        });
      } else if (_hasReachedBottom && (currentScroll + delta) < maxScroll) {
        setState(() {
          _hasReachedBottom = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: screenWidth > 600 ? 750 : screenWidth * 0.95,
          constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Enhanced Header with Gradient
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF8ECAE6), Color(0xFF3BBFB2)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8ECAE6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Terms & Privacy',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please read carefully',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Scrollable content with fade indicator
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            icon: Icons.info_outline_rounded,
                            title: '1. INTRODUCTION',
                            content: '''
Welcome to BotiCart, a mobile application that connects users to licensed pharmacies in the Philippines for the purchase of medicines and healthcare products.

By creating an account, accessing, or using the BotiCart mobile application, you acknowledge that you have read, understood, and agreed to be bound by these Terms and Conditions.

BotiCart acts as an online intermediary between Users and independent, FDA-licensed pharmacies. BotiCart does not own or operate any pharmacy and is not a pharmaceutical company, clinic, or hospital. All medicines are dispensed by third-party Pharmacies, which remain fully responsible for compliance with all applicable Philippine laws and regulations.

If you do not agree with these Terms, you must not use the App or any of its services.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.person_outline_rounded,
                            title: '2. ELIGIBILITY & USER ACCOUNT',
                            content: '''
To use BotiCart, you must:
• Be at least 18 years old, or
• If under 18, have the consent and supervision of a parent or legal guardian when using the App.

You must provide true, accurate, current, and complete information during registration, including your name, contact details, and delivery address.

You are responsible for:
• Keeping your login credentials confidential,
• Restricting access to your mobile device, and
• All activities that occur under your account.

You agree to notify BotiCart immediately if you suspect unauthorized access or misuse of your account.

BotiCart may suspend, restrict, or terminate your account if:
• False or misleading information is provided,
• Suspicious or fraudulent activity is detected, or
• You violate these Terms or any applicable law.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.shopping_cart_outlined,
                            title: '3. USE OF THE PLATFORM',
                            content: '''
BotiCart allows Users to:
• Browse and purchase medicines and healthcare products from partner Pharmacies,
• Upload valid prescriptions for prescription-only medicines,
• Track orders and delivery status, and
• Receive product recommendations based on your preferences and transaction history.

You agree to use the App only for lawful and personal purposes and not for resale or commercial redistribution of medicines.

You acknowledge that:
• Product availability, prices, and delivery times are set by each Pharmacy, not by BotiCart.
• BotiCart does not provide medical diagnosis or treatment. Any health concerns should be consulted with a licensed doctor.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.medical_services_outlined,
                            title: '4. PRESCRIPTIONS & MEDICAL COMPLIANCE',
                            content: '''
For prescription medicines, you must upload a clear and valid prescription issued by a licensed Filipino physician.

By uploading a prescription, you confirm that:
• The prescription belongs to you or a dependent for whom you are legally responsible, and
• The information provided (name, age, dosage, etc.) is accurate.

Pharmacies have the right to:
• Verify the authenticity of the prescription,
• Refuse or cancel orders if the prescription is invalid, incomplete, expired, or suspicious,
• Adjust quantities according to the doctor's instructions and regulatory limits.

Any misuse of prescriptions, including forged or altered prescriptions, may result in account termination and possible reporting to relevant authorities.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.payment_outlined,
                            title: '5. ORDERS, PAYMENTS & DELIVERY',
                            content: '''
Placing an order through BotiCart constitutes an offer to buy products from the selected Pharmacy. Acceptance of your order occurs when the Pharmacy confirms and processes it.

Pricing, discounts, stock availability, and delivery options are set by each Pharmacy and may change without prior notice.

Payment methods will be displayed in the App. You agree to pay the total amount shown at checkout, including product price, delivery fee, and any applicable charges.

Delivery is handled by third-party couriers or logistics partners. Estimated delivery times are for guidance only and may be affected by traffic, weather, and other factors.

You are responsible for:
• Being available at the delivery address at the scheduled time,
• Checking the items upon receipt,
• Reporting issues (wrong item, damaged packaging, etc.) within the time indicated in the App or Pharmacy policy.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.undo_outlined,
                            title: '6. CANCELLATION, RETURNS & REFUNDS',
                            content: '''
Due to health and safety regulations, medicines are generally not returnable or refundable once released to the customer, except in specific cases such as:
• Wrong item delivered,
• Damaged or tampered packaging upon delivery,
• Product recall as mandated by authorities.

Cancellation or modification of orders is subject to:
• The Pharmacy's internal policy, and
• The order status at the time of your request (e.g., already dispatched, in preparation, etc.).

Approved refunds (if any) will be processed through the original payment method, subject to the policies of the Pharmacy and BotiCart.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.block_outlined,
                            title: '7. USER CONDUCT & PROHIBITED ACTIVITIES',
                            content: '''
You agree not to:
• Use the App for fraudulent, illegal, or unauthorized purposes,
• Create multiple fake accounts or impersonate another person,
• Upload forged, altered, or invalid prescriptions,
• Attempt to bypass security features or access another user's account,
• Harass, abuse, or threaten Pharmacies, riders, or BotiCart staff,
• Post false reviews or manipulate ratings and feedback.

BotiCart may investigate and take appropriate actions, including account suspension or termination, if prohibited activities are detected.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.privacy_tip_outlined,
                            title:
                                '8. DATA PRIVACY & PERSONALIZED RECOMMENDATIONS',
                            content: '''
BotiCart collects and processes your personal data in accordance with the Data Privacy Act of 2012 (Republic Act No. 10173) and its Implementing Rules and Regulations.

By using the App, you consent to the collection and processing of information such as:
• Account details (name, contact information, address),
• Transaction history and order details,
• Prescription information that you voluntarily upload,
• App usage data and interaction logs,
• Discount card information such as Senior Citizen ID or PWD ID details that you voluntarily provide for the purpose of applying legally mandated discounts.

This information may be used to:
• Process and deliver your orders,
• Verify prescriptions and ensure medical compliance,
• Provide personalized product recommendations, particularly for vitamins, supplements, and health products based on your past transactions,
• Improve system performance, security, and user experience,
• Comply with legal, regulatory, or audit requirements.

BotiCart will not sell your personal data to third parties. Data may be shared only with:
• Partner Pharmacies to fulfill your orders,
• Delivery and logistics partners,
• Service providers supporting payment, hosting, analytics, or security,
• Government or regulatory agencies when required by law.

You have the right to:
• Access and update your personal information,
• Request correction of inaccurate data,
• Withdraw consent, subject to legal and contractual limitations.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.copyright_outlined,
                            title: '9. INTELLECTUAL PROPERTY',
                            content: '''
All content in the App—including logos, trademarks, graphics, text, icons, and software—is the property of BotiCart or its licensors and is protected by intellectual property laws.

You may not copy, modify, distribute, reverse-engineer, or create derivative works based on any part of the App without prior written consent from BotiCart.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.gavel_outlined,
                            title: '10. LIMITATION OF LIABILITY',
                            content: '''
To the maximum extent permitted by law, BotiCart is not liable for:
• Medical outcomes resulting from the use of purchased products,
• Errors in prescriptions provided by doctors,
• Actions or omissions of partner Pharmacies or delivery partners,
• Delays, failed deliveries, or product unavailability,
• Indirect, incidental, or consequential damages arising from your use of the App.

BotiCart provides the Platform on an "as is" and "as available" basis, without warranties of any kind, whether express or implied.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.account_circle_outlined,
                            title: '11. ACCOUNT SUSPENSION & TERMINATION',
                            content: '''
You may request account deletion at any time through the App or by contacting BotiCart support, subject to settlement of any pending orders or disputes.

BotiCart may suspend or terminate your account if you:
• Repeatedly violate these Terms,
• Engage in fraud, abuse, or illegal activity,
• Misuse prescriptions or attempt to obtain restricted medicines unlawfully,
• Pose a risk to other users, Pharmacies, or the Platform.

BotiCart reserves the right to retain certain data as required by law or for legitimate business purposes (e.g., transaction records, audit logs).
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.edit_outlined,
                            title: '12. CHANGES TO THE TERMS',
                            content: '''
BotiCart may update these Terms from time to time to reflect changes in laws, platform features, or business policies.

Significant changes will be communicated through in-app notifications or email. Continued use of the App after such updates constitutes your acceptance of the revised Terms.
                          ''',
                          ),
                          const SizedBox(height: 24),
                          _buildSection(
                            icon: Icons.contact_support_outlined,
                            title: '13. CONTACT INFORMATION',
                            content: '''
For questions, concerns, or feedback about these Terms, you may contact:

BotiCart Support
Email: boticart.management@gmail.com
                          ''',
                          ),
                          // Bottom padding to ensure last content is visible
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    // Scroll indicator at bottom
                    if (!_hasReachedBottom)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0),
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: const Color(0xFF8ECAE6),
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scroll to continue',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF8ECAE6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Enhanced Action buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onDecline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Decline',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: ElevatedButton(
                          onPressed: _hasReachedBottom ? widget.onAccept : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _hasReachedBottom
                                ? const Color(0xFF8ECAE6)
                                : Colors.grey.shade300,
                            foregroundColor: _hasReachedBottom
                                ? Colors.white
                                : Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: _hasReachedBottom ? 4 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_hasReachedBottom)
                                const Icon(Icons.check_circle_rounded, size: 20)
                              else
                                const Icon(Icons.lock_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'I Accept',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF8ECAE6), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8ECAE6),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: Colors.grey[800],
              height: 1.8,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
