import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload PDF file to Firebase Storage (supports Web and Mobile)
  static Future<String?> uploadPDF({
    required String subject,
    required String chapter,
    required String materialType,
    File? file,
    Uint8List? bytes,
    String? fileNameOverride,
  }) async {
    try {
      // Create a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = fileNameOverride ?? '${materialType.toLowerCase().replaceAll(' ', '_')}_$timestamp.pdf';
      
      // Create storage reference
      final ref = _storage.ref().child('materials/$subject/$chapter/$fileName');
      
      // Upload based on platform/input
      UploadTask uploadTask;
      if (kIsWeb) {
        if (bytes == null) {
          throw Exception('No bytes provided for web upload');
        }
        final metadata = SettableMetadata(contentType: 'application/pdf');
        uploadTask = ref.putData(bytes, metadata);
      } else {
        if (file == null) {
          throw Exception('No file provided for mobile upload');
        }
        uploadTask = ref.putFile(file, SettableMetadata(contentType: 'application/pdf'));
      }
      // Complete with timeout to avoid indefinite spinner
      final snapshot = await uploadTask.timeout(const Duration(seconds: 60), onTimeout: () {
        throw Exception('Upload timed out. Please check your internet connection and try again.');
      });
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      // Save metadata to Firestore
      await _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .doc(chapter)
          .set({
        '${materialType.toLowerCase().replaceAll(' ', '')}Url': downloadUrl,
        '${materialType.toLowerCase().replaceAll(' ', '')}FileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading PDF: $e');
    }
  }

  // Pick PDF file from device (supports Web and Mobile)
  // Returns a map: { file (File?) , bytes (Uint8List?) , name (String) , size (int) }
  static Future<Map<String, dynamic>?> pickPDFAny() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final PlatformFile pf = result.files.first;
        if (kIsWeb) {
          // On web, use in-memory bytes
          if (pf.bytes == null) {
            throw Exception('No bytes received for selected file');
          }
          return {
            'file': null,
            'bytes': pf.bytes!,
            'name': pf.name,
            'size': pf.size,
          };
        } else {
          // On mobile/desktop, use File from path
          if (pf.path == null) {
            throw Exception('No file path available');
          }
          final file = File(pf.path!);
          return {
            'file': file,
            'bytes': null,
            'name': pf.name,
            'size': await file.length(),
          };
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error picking PDF: $e');
    }
  }

  // Get all materials for a subject
  static Future<List<Map<String, dynamic>>> getMaterials(String subject) async {
    try {
      final snapshot = await _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .get();

      List<Map<String, dynamic>> materials = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        materials.add({
          'chapter': doc.id,
          'data': data,
        });
      }
      return materials;
    } catch (e) {
      throw Exception('Error fetching materials: $e');
    }
  }

  // Delete a material
  static Future<void> deleteMaterial({
    required String subject,
    required String chapter,
    required String materialType,
  }) async {
    try {
      // Get the document to find the file URL
      final doc = await _firestore
          .collection('materials')
          .doc(subject)
          .collection('chapters')
          .doc(chapter)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final fieldName = '${materialType.toLowerCase().replaceAll(' ', '')}Url';
        final fileUrl = data[fieldName] as String?;

        if (fileUrl != null) {
          // Delete from Storage
          final ref = _storage.refFromURL(fileUrl);
          await ref.delete();
        }

        // Remove from Firestore
        await _firestore
            .collection('materials')
            .doc(subject)
            .collection('chapters')
            .doc(chapter)
            .update({
          fieldName: FieldValue.delete(),
          '${materialType.toLowerCase().replaceAll(' ', '')}FileName': FieldValue.delete(),
        });
      }
    } catch (e) {
      throw Exception('Error deleting material: $e');
    }
  }

  // Get file size in MB
  static String getFileSizeFromBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(2)} MB';
  }

  // Validate PDF file
  static bool isValidPDFName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return extension == 'pdf';
  }

  // Check if file size is within limits (10MB max)
  static bool isFileSizeValidBytes(int bytes) {
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    return bytes <= maxSizeInBytes;
  }
}

