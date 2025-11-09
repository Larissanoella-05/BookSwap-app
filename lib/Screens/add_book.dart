import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bookswap/Models/book.dart';
import 'package:bookswap/Services/book_providers.dart';
import 'package:bookswap/Layouts/bottom-navigation.dart';
import 'package:bookswap/Screens/home.dart';

class AddBook extends ConsumerStatefulWidget {
  final Book? book; // If provided, we're in edit mode
  
  const AddBook({super.key, this.book});

  @override
  ConsumerState<AddBook> createState() => _AddBookState();
}

class _AddBookState extends ConsumerState<AddBook> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  
  BookCondition _selectedCondition = BookCondition.good;
  File? _coverImage;
  String? _existingImageUrl; // For edit mode - store existing image URL
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool get _isEditMode => widget.book != null;

  @override
  void initState() {
    super.initState();
    // If in edit mode, populate fields with existing book data
    if (_isEditMode && widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _selectedCondition = widget.book!.condition;
      _existingImageUrl = widget.book!.coverImageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  /// Pick image from device gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress image to reduce upload size
      );

      if (image != null) {
        setState(() {
          _coverImage = File(image.path);
        });
      }
      // If image is null, user cancelled - no error needed
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to pick image';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant photo library access in Settings.';
        } else if (e.toString().contains('platform')) {
          errorMessage = 'Image picker not available. Please restart the app.';
        } else {
          errorMessage = 'Failed to pick image: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImage = File(image.path);
        });
      }
      // If image is null, user cancelled - no error needed
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to take photo';
        if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please grant camera access in Settings.';
        } else if (e.toString().contains('platform')) {
          errorMessage = 'Camera not available. Please restart the app.';
        } else {
          errorMessage = 'Failed to take photo: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Show image source selection dialog
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Submit the form to create or update a book
  Future<void> _submitForm() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if image is selected (required for new books, optional for edits)
    if (!_isEditMode && _coverImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a cover image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bookService = ref.read(bookServiceProvider);
      
      if (_isEditMode && widget.book != null) {
        // Update existing book
        await bookService.updateBook(
          bookId: widget.book!.id,
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: _selectedCondition,
          coverImageFile: _coverImage, // Optional - only if user changed image
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back
          Navigator.pop(context);
        }
      } else {
        // Create new book
        if (_coverImage == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a cover image'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }

        await bookService.createBook(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          condition: _selectedCondition,
          coverImageFile: _coverImage!,
        );

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book added successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate back to home
          Navigator.pop(context);
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Failed to update book: $e' : 'Failed to add book: $e'),
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
    // Get current selected tab index, default to 0 (Browse)
    final selectedIndex = ref.watch(selectedTabIndexProvider);
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 5, 22, 46),
        title: Text(
          _isEditMode ? 'Edit Book' : 'Post a Book',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: const Color.fromARGB(255, 250, 174, 22)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover Image Section
                    const Text(
                      'Cover Image',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: _coverImage == null && _existingImageUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Tap to add cover image',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _coverImage != null
                                    ? Image.file(
                                        _coverImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : Image.network(
                                        _existingImageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.broken_image, size: 60, color: Colors.grey),
                                              SizedBox(height: 10),
                                              Text(
                                                'Image not available',
                                                style: TextStyle(color: Colors.grey),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: const TextStyle(color: Colors.black87),
                        prefixIcon: const Icon(Icons.title, color: Colors.black87),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 231, 101, 1),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a book title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Author Field
                    TextFormField(
                      controller: _authorController,
                      decoration: InputDecoration(
                        labelText: 'Author',
                        labelStyle: const TextStyle(color: Colors.black87),
                        prefixIcon: const Icon(Icons.person, color: Colors.black87),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 231, 101, 1),
                            width: 2,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the author name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Condition Dropdown
                    const Text(
                      'Condition',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: DropdownButtonFormField<BookCondition>(
                        value: _selectedCondition,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.book, color: Colors.black87),
                        ),
                        items: BookCondition.values.map((condition) {
                          return DropdownMenuItem<BookCondition>(
                            value: condition,
                            child: Text(condition.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCondition = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color.fromARGB(255, 250, 174, 22),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isEditMode ? 'Update Book' : 'Post',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigation(
        context,
        selectedIndex: selectedIndex,
            ),
    );
  }
}

