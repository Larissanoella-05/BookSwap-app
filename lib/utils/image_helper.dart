import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Helper widget to display images from various sources
/// Handles: network URLs, base64 data URLs, and fallback placeholders
class BookCoverImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const BookCoverImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // If no image URL, show placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a base64 data URL
    if (imageUrl!.startsWith('data:image')) {
      return _buildBase64Image();
    }

    // Otherwise, treat as network URL
    return _buildNetworkImage();
  }

  /// Build placeholder widget
  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFF2C2855),
          child: const Icon(Icons.book, size: 60, color: Colors.white),
        );
  }

  /// Build image from base64 data URL
  Widget _buildBase64Image() {
    try {
      // Extract base64 string from data URL
      // Format: data:image/jpeg;base64,/9j/4AAQ...
      final base64String = imageUrl!.split(',')[1];
      final Uint8List bytes = base64Decode(base64String);

      Widget imageWidget = Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );

      if (borderRadius != null) {
        imageWidget = ClipRRect(
          borderRadius: borderRadius!,
          child: imageWidget,
        );
      }

      return imageWidget;
    } catch (e) {
      return _buildPlaceholder();
    }
  }

  /// Build image from network URL
  Widget _buildNetworkImage() {
    Widget imageWidget = Image.network(
      imageUrl!,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF2C2855)),
          ),
        );
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }
}
