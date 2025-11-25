import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdditionalCommentsScreen extends StatefulWidget {
  final String pharmacyName;
  final List<String> violations;

  const AdditionalCommentsScreen({
    super.key,
    required this.pharmacyName,
    required this.violations,
  });

  @override
  State<AdditionalCommentsScreen> createState() =>
      _AdditionalCommentsScreenState();
}

class _AdditionalCommentsScreenState extends State<AdditionalCommentsScreen> {
  final TextEditingController _commentsController = TextEditingController();
  final List<String> _badWords = [
    'fuck',
    'shit',
    'damn',
    'bitch',
    'asshole',
    'bastard',
    'crap',
    'piss',
    'hell',
    // Add more bad words as needed
  ];

  bool _hasBadWords = false;

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  void _checkBadWords(String text) {
    final lowerText = text.toLowerCase();
    final hasBadWords = _badWords.any((word) => lowerText.contains(word));
    setState(() {
      _hasBadWords = hasBadWords;
    });
  }

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
          'Additional Notes',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reporting: ${widget.pharmacyName}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF8ECAE6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selected Violations:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF8ECAE6),
                  ),
                ),
                const SizedBox(height: 4),
                ...widget.violations.map(
                  (violation) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: const Color(0xFF8ECAE6),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            violation,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF8ECAE6),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Additional Notes (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8ECAE6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _commentsController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                onChanged: _checkBadWords,
                decoration: InputDecoration(
                  hintText: 'Add any additional comments about this report...',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF8ECAE6),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasBadWords ? Colors.red : Colors.grey.shade300,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _hasBadWords
                          ? Colors.red
                          : const Color(0xFF8ECAE6),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF8ECAE6),
                ),
              ),
            ),
          ),
          if (_hasBadWords)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please avoid using inappropriate language',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.red.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 24,
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
                  onPressed: _hasBadWords
                      ? null
                      : () {
                          Navigator.pop(
                            context,
                            _commentsController.text.trim(),
                          );
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
                    'Submit Report',
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
