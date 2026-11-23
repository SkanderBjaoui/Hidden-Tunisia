import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../services/app_exception.dart';
import '../utils/app_colors.dart';
import '../widgets/auth_layout.dart' show FormErrorBox;
import '../widgets/custom_button.dart';
import '../widgets/rating_stars.dart';

/// Form that lets the logged-in user add a new place. The place is saved in
/// Supabase and the optional photo is uploaded to Supabase Storage.
class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  // The key gives access to the form so we can call validate().
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageController = TextEditingController();
  final _picker = ImagePicker();

  PlaceCategory? _category;
  XFile? _pickedImage; // photo chosen from the gallery / camera
  int _rating = 0;
  bool _ratingError = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String? _required(String? value, String message) =>
      (value == null || value.trim().isEmpty) ? message : null;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600, // keeps uploads small
        imageQuality: 85,
      );
      if (file != null) setState(() => _pickedImage = file);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the photo picker.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _chooseImageSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _ratingError = _rating == 0);
    if (!valid || _rating == 0) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final provider = context.read<PlaceProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      // The form only asks for a city, so we convert it to coordinates (API).
      final (lat, lng) = await provider.geocodeCity(_cityController.text);
      await provider.addPlace(
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category!,
        rating: _rating,
        latitude: lat,
        longitude: lng,
        imageUrl: _imageController.text.trim(),
        image: _pickedImage,
      );
      messenger.showSnackBar(
        const SnackBar(content: Text('Place added successfully. Thank you!')),
      );
      navigator.pop();
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add a Place'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.forest,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share a hidden gem with other travellers.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              if (_error != null) FormErrorBox(message: _error!),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Place name', Icons.place_rounded),
                validator: (v) {
                  if (_required(v, 'Please enter the place name') != null) {
                    return 'Please enter the place name';
                  }
                  if (v!.trim().length < 3) return 'The name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                  'Location / city',
                  Icons.location_city_rounded,
                ),
                validator: (v) => _required(v, 'Please enter a city'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _decoration('Description', Icons.notes_rounded),
                validator: (v) {
                  if (_required(v, 'Please add a description') != null) {
                    return 'Please add a description';
                  }
                  if (v!.trim().length < 20) {
                    return 'Describe it in at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PlaceCategory>(
                initialValue: _category,
                decoration: _decoration('Category', Icons.category_rounded),
                items: PlaceCategory.values
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (v) => v == null ? 'Please choose a category' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Photo (optional)',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _buildPhotoPicker(),
              if (_pickedImage == null) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageController,
                  keyboardType: TextInputType.url,
                  decoration: _decoration(
                    'or paste an image URL',
                    Icons.link_rounded,
                  ),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return null; // optional field
                    final uri = Uri.tryParse(value);
                    final ok =
                        uri != null &&
                        (uri.scheme == 'http' || uri.scheme == 'https') &&
                        uri.host.isNotEmpty;
                    return ok
                        ? null
                        : 'Enter a valid link starting with http(s)://';
                  },
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Your rating',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              RatingStars(
                rating: _rating.toDouble(),
                size: 40,
                onChanged: (value) => setState(() {
                  _rating = value;
                  _ratingError = false;
                }),
              ),
              if (_ratingError)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please choose a rating from 1 to 5',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 28),
              CustomButton(
                label: 'Submit place',
                icon: Icons.check_circle_rounded,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Preview of the chosen photo, or a button to choose one.
  Widget _buildPhotoPicker() {
    final image = _pickedImage;
    if (image == null) {
      return OutlinedButton.icon(
        onPressed: _saving ? null : _chooseImageSource,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Add a photo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(
            File(image.path),
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 6,
          right: 6,
          child: IconButton.filled(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
            ),
            tooltip: 'Remove photo',
            onPressed: _saving
                ? null
                : () => setState(() => _pickedImage = null),
            icon: const Icon(Icons.close_rounded, color: AppColors.forest),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );
}
