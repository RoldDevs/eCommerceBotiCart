import 'package:cloud_firestore/cloud_firestore.dart';

class FileItem {
  final String url;
  final String fileName;
  final String fileType; 
  final DateTime? createdAt;

  FileItem({
    required this.url,
    required this.fileName,
    required this.fileType,
    this.createdAt,
  });

  factory FileItem.fromMap(Map<String, dynamic> map) {
    return FileItem(
      url: map['url'] as String,
      fileName: map['fileName'] as String,
      fileType: map['fileType'] as String,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'fileName': fileName,
      'fileType': fileType,
      'createdAt': createdAt != null ? FieldValue.serverTimestamp() : null,
    };
  }
}