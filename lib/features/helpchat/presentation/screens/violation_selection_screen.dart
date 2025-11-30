import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ViolationSelectionScreen extends StatefulWidget {
  final String pharmacyName;

  const ViolationSelectionScreen({super.key, required this.pharmacyName});

  @override
  State<ViolationSelectionScreen> createState() =>
      _ViolationSelectionScreenState();
}

class _ViolationSelectionScreenState extends State<ViolationSelectionScreen> {
  final Set<String> _selectedViolations = {};

  final List<String> _violationTypes = [
    'Selling Fake/Counterfeit Products',
    'Selling Expired Products',
    'Operating Without Valid License',
    'Multiple Customer Complaints',
    'Pricing Violations',
    'Terms of Service Violation',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8ECAE6)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Offense Type(s)',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Reporting: ${widget.pharmacyName}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _violationTypes.length,
              itemBuilder: (context, index) {
                final violation = _violationTypes[index];
                final isSelected = _selectedViolations.contains(violation);

                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedViolations.remove(violation);
                      } else {
                        _selectedViolations.add(violation);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF8ECAE6).withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF8ECAE6)
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFF8ECAE6,
                                ).withValues(alpha: 0.2),
                                spreadRadius: 0,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF8ECAE6)
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                            color: isSelected
                                ? const Color(0xFF8ECAE6)
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            violation,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: const Color(0xFF8ECAE6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedViolations.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, _selectedViolations.toList());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8ECAE6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
