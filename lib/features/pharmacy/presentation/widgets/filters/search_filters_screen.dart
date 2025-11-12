import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/filter_provider.dart';
import '../../../domain/entities/medicine.dart';

class SearchFiltersScreen extends ConsumerStatefulWidget {
  const SearchFiltersScreen({super.key});

  @override
  ConsumerState<SearchFiltersScreen> createState() => _SearchFiltersScreenState();
}

class _SearchFiltersScreenState extends ConsumerState<SearchFiltersScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedProductTypes = ref.watch(selectedProductTypesProvider);
    final selectedConditionTypes = ref.watch(selectedConditionTypesProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8ECAE6),
                Color(0xFF8ECAE6),
              ],
            ),
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          'Search Filters',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Header stats section
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F9FF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3BBFB2).withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3BBFB2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Color(0xFF8ECAE6),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter Options',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A202C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Customize your search results',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF718096),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8ECAE6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${selectedProductTypes.length + selectedConditionTypes.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Type Section
                      _buildSectionTitle('Product Type', Icons.medical_services),
                      const SizedBox(height: 16),
                      _buildProductTypeFilters(selectedProductTypes),
                      
                      const SizedBox(height: 32),
                      
                      // Condition / Use Case Section
                      _buildSectionTitle('Condition / Use Case', Icons.health_and_safety),
                      const SizedBox(height: 16),
                      _buildConditionTypeFilters(selectedConditionTypes),
                      
                      const SizedBox(height: 100), // Space for floating button
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).pop();
          },
          backgroundColor: const Color(0xFF8ECAE6),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Apply & Search',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3BBFB2).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8ECAE6),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A202C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTypeFilters(Set<MedicineProductType> selectedTypes) {
    final productTypes = [
      MedicineProductType.prescriptionMedicines,
      MedicineProductType.overTheCounter,
      MedicineProductType.vitaminsSupplements,
      MedicineProductType.healthEssentials,
    ];

    return Column(
      children: productTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final isSelected = selectedTypes.contains(type);
        final displayName = _getProductTypeDisplayName(type);
        final icon = _getProductTypeIcon(type);
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(selectedProductTypesProvider.notifier).toggle(type);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8ECAE6),
                            Color(0xFF8ECAE6),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF8F9FA),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? const Color(0xFF8ECAE6).withValues(alpha: 0.3)
                          : const Color(0xFF64748B).withValues(alpha: 0.05),  
                      spreadRadius: 0,
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white 
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFFCBD5E0),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF3BBFB2),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF8ECAE6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected 
                            ? Colors.white 
                            : const Color(0xFF8ECAE6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConditionTypeFilters(Set<MedicineConditionType> selectedTypes) {
    final conditionTypes = [
      MedicineConditionType.painFever,
      MedicineConditionType.coughCold,
      MedicineConditionType.allergies,
      MedicineConditionType.digestiveHealth,
    ];

    return Column(
      children: conditionTypes.asMap().entries.map((entry) {
        final index = entry.key;
        final type = entry.value;
        final isSelected = selectedTypes.contains(type);
        final displayName = _getConditionTypeDisplayName(type);
        final icon = _getConditionTypeIcon(type);
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                ref.read(selectedConditionTypesProvider.notifier).toggle(type);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF8ECAE6),
                            Color(0xFF8ECAE6),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF8F9FA),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : const Color(0xFF8ECAE6).withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? const Color(0xFF8ECAE6).withValues(alpha: 0.3)
                          : const Color(0xFF64748B).withValues(alpha: 0.05),
                      spreadRadius: 0,
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white 
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFFCBD5E0),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Color(0xFF219EBC),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withValues(alpha: 0.2)
                            : const Color(0xFF3BBFB2).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isSelected 
                            ? Colors.white 
                            : const Color(0xFF8ECAE6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFF1A202C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getProductTypeIcon(MedicineProductType type) {
    switch (type) {
      case MedicineProductType.prescriptionMedicines:
        return Icons.medical_services;
      case MedicineProductType.overTheCounter:
        return Icons.local_pharmacy;
      case MedicineProductType.vitaminsSupplements:
        return Icons.eco;
      case MedicineProductType.healthEssentials:
        return Icons.health_and_safety;
    }
  }

  IconData _getConditionTypeIcon(MedicineConditionType type) {
    switch (type) {
      case MedicineConditionType.painFever:
        return Icons.thermostat;
      case MedicineConditionType.coughCold:
        return Icons.air;
      case MedicineConditionType.allergies:
        return Icons.coronavirus;
      case MedicineConditionType.digestiveHealth:
        return Icons.restaurant;
      case MedicineConditionType.other:
        return Icons.more_horiz;
    }
  }

  String _getProductTypeDisplayName(MedicineProductType type) {
    switch (type) {
      case MedicineProductType.prescriptionMedicines:
        return 'Prescription medicines';
      case MedicineProductType.overTheCounter:
        return 'Over-the-counter (OTC)';
      case MedicineProductType.vitaminsSupplements:
        return 'Vitamins & Supplements';
      case MedicineProductType.healthEssentials:
        return 'Health Essentials';
    }
  }

  String _getConditionTypeDisplayName(MedicineConditionType type) {
    switch (type) {
      case MedicineConditionType.painFever:
        return 'Pain & Fever';
      case MedicineConditionType.coughCold:
        return 'Cough & Cold';
      case MedicineConditionType.allergies:
        return 'Allergies';
      case MedicineConditionType.digestiveHealth:
        return 'Digestive Health';
      case MedicineConditionType.other:
        return 'Other';
    }
  }
}