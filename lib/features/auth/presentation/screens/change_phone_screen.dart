import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/user_provider.dart';

class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _phoneController = TextEditingController(text: user?.contact ?? '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _savePhoneNumber() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a phone number',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not found');
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.id);
      
      await userRef.update({
        'contact': _phoneController.text.trim(),
      });
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Phone number updated',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF8ECAE6),
        ),
      );
      
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      
      // ignore: unused_result
      ref.refresh(currentUserProvider);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString()}',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
          'Change Phone Number',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF8ECAE6),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                hintText: 'Change phone number.',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF8ECAE6)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 120,
                height: 45,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePhoneNumber,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8ECAE6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}