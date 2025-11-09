// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';

/// Screen to edit an existing book listing
class EditBookScreen extends StatefulWidget {
  final Book book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _swapForController;

  // Services
  final ImagePicker _imagePicker = ImagePicker();

  // State variables
  late String _selectedCondition;
  File? _selectedImage;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _imageChanged = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing book data
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _swapForController = TextEditingController(text: widget.book.swapFor);
    _selectedCondition = widget.book.condition;
    _currentImageUrl = widget.book.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _swapForController.dispose();
    super.dispose();
  }

  /// Showing image source options
  Future<void> _showImageSourceOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Change Book Cover',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(
                    Icons.folder_open,
                    color: Color(0xFF2C2855),
                  ),
                  title: const Text('Files'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromFiles();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Picking image from camera/gallery
  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  /// Picking image from files
  Future<void> _pickImageFromFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'],
        allowMultiple: false,
        allowCompression: true,
        dialogTitle: 'Select Book Cover Image',
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _imageChanged = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
      }
    }
  }

  /// Getting default book cover
  String _getDefaultBookCover(String title) {
    final colors = [
      '1a472a/ffffff',
      '2c2855/ffffff',
      '8b4513/ffffff',
      '0f4c75/ffffff',
      'c44569/ffffff',
      '227c9d/ffffff',
    ];

    final colorIndex = title.length % colors.length;
    final color = colors[colorIndex];
    final encodedTitle = Uri.encodeComponent(
      title.length > 20 ? '📚 Book' : title,
    );

    return 'https://via.placeholder.com/400x600/$color?text=$encodedTitle';
  }

  /// Submitting form and updating book
  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context references before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _currentImageUrl ?? '';

      // If user changed the image, compress and convert to base64
      if (_imageChanged && _selectedImage != null) {
        // Read image bytes
        final bytes = await _selectedImage!.readAsBytes();

        // Decode image
        img.Image? image = img.decodeImage(bytes);

        if (image != null) {
          // Resize image if too large (max 800x800 to stay within Firestore limits)
          if (image.width > 800 || image.height > 800) {
            image = img.copyResize(
              image,
              width: image.width > image.height ? 800 : null,
              height: image.height > image.width ? 800 : null,
            );
          }

          // Compress image as JPEG with 70% quality
          final compressedBytes = img.encodeJpg(image, quality: 70);

          // Convert to base64
          final base64Image = base64Encode(compressedBytes);
          imageUrl = 'data:image/jpeg;base64,$base64Image';
        } else {
          // Fallback if image decode fails
          final base64Image = base64Encode(bytes);
          imageUrl = 'data:image/jpeg;base64,$base64Image';
        }
      } else if (_currentImageUrl == null || _currentImageUrl!.isEmpty) {
        // No image - use default
        imageUrl = _getDefaultBookCover(_titleController.text.trim());
      }

      // Update book in Firestore using Provider
      final bookProvider = context.read<BookProvider>();
      await bookProvider.updateBook(
        bookId: widget.book.id,
        updates: {
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'condition': _selectedCondition,
          'swapFor': _swapForController.text.trim(),
          'imageUrl': imageUrl,
        },
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Book updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop(); // Go back
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Book'),
        backgroundColor: const Color(0xFF2C2855),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image preview and change button
            Center(
              child: Column(
                children: [
                  // Display current or new image
                  Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _selectedImage != null
                          ? Image.file(_selectedImage!, fit: BoxFit.cover)
                          : _currentImageUrl != null &&
                                _currentImageUrl!.isNotEmpty
                          ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF2C2855),
                              child: const Icon(
                                Icons.book,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showImageSourceOptions,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2C2855),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Book Title *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter book title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Author field
            TextFormField(
              controller: _authorController,
              decoration: const InputDecoration(
                labelText: 'Author *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter author name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Condition dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
              items: ['New', 'Like New', 'Good', 'Used'].map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Swap for field
            TextFormField(
              controller: _swapForController,
              decoration: const InputDecoration(
                labelText: 'What do you want to swap for? *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.swap_horiz),
                hintText: 'e.g., Data Structures book',
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter what you want to swap for';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Update button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C2855),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  : const Text(
                      'Update Book',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
