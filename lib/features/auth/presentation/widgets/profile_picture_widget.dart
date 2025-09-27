import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/profile_picture_provider.dart';

class ProfilePictureWidget extends ConsumerWidget {
  final String userId;
  final String email;
  final String firstName;
  final String lastName;

  const ProfilePictureWidget({
    super.key,
    required this.userId,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilePictureAsync = ref.watch(profilePictureProvider(userId));
    
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Profile picture
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF8ECAE6),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: profilePictureAsync.when(
              data: (imageUrl) {
                if (imageUrl != null && imageUrl.isNotEmpty) {
                  return Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitialsAvatar();
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: const Color(0xFF8ECAE6),
                        ),
                      );
                    },
                  );
                } else {
                  return _buildInitialsAvatar();
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF8ECAE6)),
              ),
              error: (_, __) => _buildInitialsAvatar(),
            ),
          ),
        ),
        
        // Edit button
        GestureDetector(
          onTap: () => _showImagePickerOptions(context, ref),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF8ECAE6),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInitialsAvatar() {
    final initials = '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}';
    
    return Container(
      color: const Color(0xFF8ECAE6),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
  
  void _showImagePickerOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _pickImage(ImageSource.gallery, ref);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: Text(
                  'Take a Photo',
                  style: GoogleFonts.poppins(),
                ),
                onTap: () {
                  _pickImage(ImageSource.camera, ref);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _pickImage(ImageSource source, WidgetRef ref) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                SizedBox(width: 16),
                Text('Uploading profile picture...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Upload the profile picture
        await ref.read(profilePictureUploadProvider.notifier).uploadProfilePicture(
          userId: userId,
          username: email.split('@').first,
          file: file,
        );
        
        // ignore: unused_result
        ref.refresh(profilePictureProvider(userId));
        
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(ref.context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile picture: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}