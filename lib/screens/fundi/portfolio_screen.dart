import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../config/flavor_config.dart';
import '../../providers/auth_provider.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  List<String> _photoUrls = [];
  bool _loading = true;
  bool _uploading = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = context.read<AuthProvider>().currentUserId;
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (_uid == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
      final urls = (doc.data()?['portfolioUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (mounted) setState(() { _photoUrls = urls; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    List<XFile> files = [];

    if (source == ImageSource.gallery) {
      files = await picker.pickMultiImage(imageQuality: 75, limit: 10 - _photoUrls.length);
    } else {
      final f = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
      if (f != null) files = [f];
    }
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    await _uploadFiles(files);
    setState(() => _uploading = false);
  }

  Future<void> _uploadFiles(List<XFile> files) async {
    final newUrls = <String>[];
    for (final f in files) {
      try {
        final ref = FirebaseStorage.instance
            .ref('portfolio/$_uid/${DateTime.now().millisecondsSinceEpoch}_${f.name}');
        await ref.putFile(File(f.path));
        newUrls.add(await ref.getDownloadURL());
      } catch (_) {}
    }
    if (newUrls.isEmpty || !mounted) return;

    final updated = [..._photoUrls, ...newUrls];
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .update({'portfolioUrls': updated});
    setState(() => _photoUrls = updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${newUrls.length} photo${newUrls.length != 1 ? 's' : ''} uploaded'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _delete(String url) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Remove this photo from your portfolio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await FirebaseStorage.instance.refFromURL(url).delete();
    } catch (_) {}

    final updated = _photoUrls.where((u) => u != url).toList();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .update({'portfolioUrls': updated});
    setState(() => _photoUrls = updated);
  }

  @override
  Widget build(BuildContext context) {
    final accent = FlavorConfig.instance.primaryColor;
    return Scaffold(
      backgroundColor: AC.bg(context),
      appBar: AppBar(
        backgroundColor: AC.bg(context),
        title: const Text('My Portfolio'),
        actions: [
          if (!_uploading)
            PopupMenuButton<ImageSource>(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              tooltip: 'Add photos',
              onSelected: _pick,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: ImageSource.gallery,
                  child: Row(children: [
                    Icon(Icons.photo_library_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Choose from gallery'),
                  ]),
                ),
                PopupMenuItem(
                  value: ImageSource.camera,
                  child: Row(children: [
                    Icon(Icons.camera_alt_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Take a photo'),
                  ]),
                ),
              ],
            ),
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _photoUrls.isEmpty
              ? _EmptyState(accent: accent, onAdd: () => _pick(ImageSource.gallery))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Text('${_photoUrls.length} photo${_photoUrls.length != 1 ? 's' : ''}',
                              style: TextStyle(color: AC.textSec(context), fontSize: 13)),
                          const Spacer(),
                          Text('Long-press to remove',
                              style: TextStyle(color: AC.textSec(context), fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _photoUrls.length,
                        itemBuilder: (context, i) => _PortfolioTile(
                          url: _photoUrls[i],
                          onDelete: () => _delete(_photoUrls[i]),
                          onTap: () => _showFullscreen(context, i),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  void _showFullscreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenViewer(urls: _photoUrls, initialIndex: initialIndex),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final Color accent;
  final VoidCallback onAdd;
  const _EmptyState({required this.accent, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 72, color: AC.textSec(context).withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('No portfolio photos yet',
                style: TextStyle(color: AC.text(context), fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Show clients your best work.\nAdd photos of completed jobs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AC.textSec(context), fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.black),
              label: const Text('Add Photos', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  final String url;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _PortfolioTile({required this.url, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null
              ? child
              : Container(
                  color: AC.surface(context),
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                    ),
                  ),
                ),
          errorBuilder: (ctx, err, st) => Container(
            color: AC.surface(context),
            child: const Icon(Icons.broken_image_outlined,
                color: AppColors.textSecondary, size: 28),
          ),
        ),
      ),
    );
  }
}

class _FullscreenViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;
  const _FullscreenViewer({required this.urls, required this.initialIndex});

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_current + 1} / ${widget.urls.length}',
            style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _ctrl,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _current = i),
        itemBuilder: (_, i) => InteractiveViewer(
          child: Center(
            child: Image.network(
              widget.urls[i],
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}
