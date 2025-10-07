import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import '../services/storage_service.dart';
import 'view_material_page.dart';

class UploadMaterialPage extends StatefulWidget {
  const UploadMaterialPage({super.key});

  @override
  State<UploadMaterialPage> createState() => _UploadMaterialPageState();
}

class _UploadMaterialPageState extends State<UploadMaterialPage> {
  bool uploading = false;
  final TextEditingController _urlController = TextEditingController();
  // Cross-platform selected file state
  // Mobile/Desktop: use selectedFile
  // Web: use selectedBytes
  dynamic selectedFile; // File on mobile/desktop; null on web
  Uint8List? selectedBytes; // non-null on web
  String? selectedFileName;
  String? selectedFileSize;

  final List<String> subjects = ['AML', 'DL', 'ESD', 'BDA'];
  final List<String> chapters = ['Chapter 1', 'Chapter 2', 'Chapter 3', 'Chapter 4', 'Chapter 5'];
  final List<String> materialTypes = ['Notes', 'Syllabus', 'Question Bank'];
  final List<String> uploadTypes = ['URL Link', 'PDF File'];

  String? selectedSubject;
  String? selectedChapter;
  String? selectedMaterialType;
  String selectedUploadType = 'URL Link';

  bool _isValidUrl(String url) {
    final pattern = r'^(https?:\/\/)[\w\-]+(\.[\w\-]+)+[/#?]?.*$';
    final regExp = RegExp(pattern, caseSensitive: false);
    return regExp.hasMatch(url);
  }

  Future<void> saveMaterial() async {
    if (selectedSubject == null || selectedChapter == null || selectedMaterialType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select subject, chapter & material type!")),
      );
      return;
    }

    setState(() => uploading = true);

    try {
      if (selectedUploadType == 'URL Link') {
        await _saveUrlLink();
      } else {
        await _savePDFFile();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving material: $e')),
      );
    }
  }

  Future<void> _saveUrlLink() async {
    final enteredUrl = _urlController.text.trim();

    if (!_isValidUrl(enteredUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid URL!")),
      );
      setState(() => uploading = false);
      return;
    }

    final docRef = FirebaseFirestore.instance
        .collection('materials')
        .doc(selectedSubject)
        .collection('chapters')
        .doc(selectedChapter);

    final Map<String, dynamic> dataToSave = {
      'timestamp': FieldValue.serverTimestamp(),
    };

    switch (selectedMaterialType) {
      case 'Notes':
        dataToSave['notesUrl'] = enteredUrl;
        break;
      case 'Syllabus':
        dataToSave['syllabusUrl'] = enteredUrl;
        break;
      case 'Question Bank':
        dataToSave['questionBankUrl'] = enteredUrl;
        break;
    }

    await docRef.set(dataToSave, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link saved successfully!')),
    );

    setState(() {
      uploading = false;
      _urlController.clear();
    });
  }

  Future<void> _savePDFFile() async {
    if (selectedFile == null && selectedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a PDF file!")),
      );
      setState(() => uploading = false);
      return;
    }

    if (selectedFileName == null || !StorageService.isValidPDFName(selectedFileName!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid PDF file!")),
      );
      setState(() => uploading = false);
      return;
    }

    if (selectedFileSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not determine file size!")),
      );
      setState(() => uploading = false);
      return;
    }

    final sizeParts = selectedFileSize!.split(' ');
    // We already validated at pick-time; skip parsing back to bytes here.
    // Proceed to upload.

    if (selectedBytes == null && selectedFile == null) {
      setState(() => uploading = false);
      return;
    }

    if (selectedBytes != null && !StorageService.isFileSizeValidBytes((selectedBytes!).length)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File size must be less than 10MB!")),
      );
      setState(() => uploading = false);
      return;
    }

    final downloadUrl = await StorageService.uploadPDF(
      subject: selectedSubject!,
      chapter: selectedChapter!,
      materialType: selectedMaterialType!,
      file: selectedFile, // used on mobile/desktop
      bytes: selectedBytes, // used on web
      fileNameOverride: selectedFileName,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF uploaded successfully!')),
    );

    setState(() {
      uploading = false;
      selectedFile = null;
      selectedBytes = null;
      selectedFileName = null;
      selectedFileSize = null;
    });
  }

  Future<void> _pickPDFFile() async {
    try {
      final picked = await StorageService.pickPDFAny();
      if (picked != null) {
        setState(() {
          selectedFile = picked['file'];
          selectedBytes = picked['bytes'];
          selectedFileName = picked['name'];
          final size = picked['size'] as int;
          selectedFileSize = StorageService.getFileSizeFromBytes(size);
        });
      }
    } catch (e) {
      setState(() {
        uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Study Material")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdown("Select Subject:", subjects, selectedSubject, (val) {
                setState(() => selectedSubject = val);
              }),
              const SizedBox(height: 10),
              _buildDropdown("Select Chapter:", chapters, selectedChapter, (val) {
                setState(() => selectedChapter = val);
              }),
              const SizedBox(height: 10),
              _buildDropdown("Material Type:", materialTypes, selectedMaterialType, (val) {
                setState(() => selectedMaterialType = val);
              }),
              const SizedBox(height: 10),
              _buildDropdown("Upload Type:", uploadTypes, selectedUploadType, (val) {
                setState(() {
                  selectedUploadType = val!;
                  selectedFile = null;
                  selectedFileSize = null;
                  _urlController.clear();
                });
              }),
              const SizedBox(height: 20),
              
              // Show different UI based on upload type
              if (selectedUploadType == 'URL Link') ...[
                _buildTextField(_urlController, 'Material URL', Icons.link),
              ] else ...[
                _buildFilePicker(),
                if (selectedFileName != null) ...[
                  const SizedBox(height: 10),
                  _buildFileInfo(),
                ],
              ],
              
              const SizedBox(height: 20),
              uploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveMaterial,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: Text(selectedUploadType == 'URL Link' ? "Save Link" : "Upload PDF"),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (selectedSubject != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewMaterialPage(subject: selectedSubject!),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select a subject to view materials!")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("View Uploaded Materials"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: value,
          hint: Text('Choose ${label.toLowerCase().replaceAll(":", "")}'),
          isExpanded: true,
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Paste URL here',
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: TextInputType.url,
    );
  }

  Widget _buildFilePicker() {
    return Card(
      child: InkWell(
        onTap: _pickPDFFile,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                Icons.cloud_upload,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 10),
              Text(
                selectedFileName == null ? 'Tap to select PDF file' : 'Tap to change PDF file',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Max file size: 10MB',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedFileName ?? 'selected.pdf',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Size: $selectedFileSize',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  selectedFile = null;
                  selectedFileSize = null;
                });
              },
              icon: const Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
