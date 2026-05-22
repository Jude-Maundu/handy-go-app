import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/location_provider.dart';
import 'job_searching_screen.dart';
import '../../services/notification_service.dart';
import '../../services/tomtom_service.dart';
import '../../services/validators.dart';
import '../../services/toast_service.dart';

class RequestFundiScreen extends StatefulWidget {
  const RequestFundiScreen({super.key});

  @override
  State<RequestFundiScreen> createState() => _RequestFundiScreenState();
}

class _RequestFundiScreenState extends State<RequestFundiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _useCurrentLocation = false;
  final List<XFile> _images = [];
  bool _uploading = false;

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
    {'name': 'Painting', 'icon': Icons.format_paint},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Carpentry', 'icon': Icons.carpenter},
    {'name': 'Gardening', 'icon': Icons.grass},
    {'name': 'Roofing', 'icon': Icons.roofing},
    {'name': 'Masonry', 'icon': Icons.construction},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 70, limit: 5 - _images.length);
    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _images.add(picked));
  }

  Future<List<String>> _uploadPhotos(String jobId) async {
    final storage = FirebaseStorage.instance;
    final urls = <String>[];
    for (int i = 0; i < _images.length; i++) {
      final img = _images[i];
      final ext = img.name.split('.').last;
      final ref = storage.ref('job_photos/$jobId/photo_$i.$ext');
      await ref.putFile(File(img.path));
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final location = context.read<LocationProvider>();
    final jobs = context.read<JobProvider>();

    final uid = auth.currentUserId;
    if (uid == null) return;

    final loc = _useCurrentLocation && location.hasLocation
        ? location.currentAddress ?? _locationController.text.trim()
        : _locationController.text.trim();

    setState(() => _uploading = true);

    // Use timestamp as storage folder — actual Firestore ID is assigned by createJob()
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    List<String> photoUrls = [];
    if (_images.isNotEmpty) {
      try {
        photoUrls = await _uploadPhotos(jobId);
      } catch (e) {
        if (mounted) {
          AppToast.show(context, 'Photo upload failed: $e', isError: true);
        }
      }
    }

    // Geocode typed address so fundis get GPS coords for navigation
    double? lat = _useCurrentLocation ? location.latitude : null;
    double? lng = _useCurrentLocation ? location.longitude : null;
    if (!_useCurrentLocation && loc.isNotEmpty) {
      final coords = await TomTomService.geocode(loc);
      if (coords != null) { lat = coords.latitude; lng = coords.longitude; }
    }

    final ok = await jobs.createJob(
      title: _titleController.text.trim(),
      category: _selectedCategory,
      description: _descController.text.trim(),
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      location: loc,
      clientId: uid,
      clientName: auth.userName ?? 'Client',
      clientPhone: auth.phone,
      latitude: lat,
      longitude: lng,
      photoUrls: photoUrls,
    );

    setState(() => _uploading = false);
    if (!mounted) return;
    if (ok) {
      final jobId = jobs.lastCreatedJobId;
      if (jobId != null) {
        NotificationService.notifyFundis(
          jobTitle: _titleController.text.trim(),
          jobId: jobId,
          category: _selectedCategory,
          location: loc,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => JobSearchingScreen(jobId: jobId)),
        );
      } else {
        Navigator.pop(context);
      }
    } else {
      AppToast.show(context, jobs.jobsError ?? 'Failed to post job.', isError: true);
    }
  }

  void _showPhotoOptions() {
    if (_images.length >= 5) {
      AppToast.show(context, 'Maximum 5 photos allowed', isError: true);
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AC.surface(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AC.div(context), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () { Navigator.pop(context); _pickFromCamera(); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () { Navigator.pop(context); _pickImages(); },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    final location = context.watch<LocationProvider>();
    final jobs = context.watch<JobProvider>();
    final busy = jobs.isJobsLoading || _uploading;

    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('Post a Job'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AC.surface(context), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppColors.textPrimary),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category picker
              _label('Service Type'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? accent : AC.input(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData, size: 16, color: selected ? Colors.black : AC.textSec(context)),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: selected ? Colors.black : AC.text(context),
                              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Job title
              _label('Job Title'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: AC.text(context)),
                decoration: _inputDec('e.g. Fix leaking kitchen pipe', accent),
                validator: Validators.jobTitle,
              ),
              const SizedBox(height: 16),

              // Description
              _label('Description'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                style: TextStyle(color: AC.text(context)),
                decoration: _inputDec('Describe the problem in detail...', accent),
                validator: Validators.jobDescription,
              ),
              const SizedBox(height: 16),

              // Photos
              _label('Photos (optional)'),
              const SizedBox(height: 4),
              Text('Add up to 5 photos to help fundis understand the job', style: TextStyle(color: AC.textSec(context), fontSize: 12)),
              const SizedBox(height: 10),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add photo button
                    if (_images.length < 5)
                      GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          width: 80, height: 80,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: AC.input(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, color: accent, size: 22),
                              const SizedBox(height: 4),
                              Text('Add', style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    // Selected images
                    ..._images.asMap().entries.map((entry) {
                      final i = entry.key;
                      final img = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(image: FileImage(File(img.path)), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: 2, right: 12,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(i)),
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 13),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location
              _label('Location'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                enabled: !_useCurrentLocation,
                style: TextStyle(color: AC.text(context)),
                decoration: _inputDec('Enter your address', accent),
                validator: _useCurrentLocation ? null : Validators.location,
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() => _useCurrentLocation = !_useCurrentLocation);
                  if (!_useCurrentLocation) return;
                  if (!location.hasLocation) context.read<LocationProvider>().getCurrentLocation();
                },
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _useCurrentLocation ? accent : Colors.transparent,
                        border: Border.all(color: _useCurrentLocation ? accent : AppColors.textSecondary, width: 1.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: _useCurrentLocation ? const Icon(Icons.check, size: 13, color: Colors.black) : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      location.hasLocation
                          ? 'Use my location: ${location.currentAddress?.split(',').first ?? 'Current location'}'
                          : 'Use my current location',
                      style: TextStyle(color: AC.text(context), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              _label('Budget (KES)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AC.text(context)),
                decoration: _inputDec('e.g. 1500', accent).copyWith(
                  prefixText: 'KES ',
                  prefixStyle: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
                validator: Validators.budget,
              ),
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: busy
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
                            const SizedBox(width: 10),
                            Text(_uploading ? 'Uploading photos...' : 'Posting...', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          ],
                        )
                      : const Text('Post Job', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Nearby fundis will be notified instantly.',
                  style: TextStyle(color: AC.textSec(context), fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
  );

  InputDecoration _inputDec(String hint, Color accent) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.inputFill,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: accent, width: 1.5)),
  );
}
