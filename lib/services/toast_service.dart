import 'package:flutter/material.dart';

class AppToast {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _Toast(
        message: message,
        isError: isError,
        isSuccess: isSuccess,
        onDone: () {
          if (entry.mounted) entry.remove();
        },
        duration: duration,
      ),
    );
    overlay.insert(entry);
  }
}

class _Toast extends StatefulWidget {
  final String message;
  final bool isError;
  final bool isSuccess;
  final VoidCallback onDone;
  final Duration duration;

  const _Toast({
    required this.message,
    required this.isError,
    required this.isSuccess,
    required this.onDone,
    required this.duration,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(widget.duration - const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.reverse().then((_) => widget.onDone());
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _bgColor {
    if (widget.isError) return const Color(0xFFD32F2F);
    if (widget.isSuccess) return const Color(0xFF388E3C);
    return const Color(0xFF323232);
  }

  IconData get _icon {
    if (widget.isError) return Icons.error_outline;
    if (widget.isSuccess) return Icons.check_circle_outline;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).viewInsets.bottom + 80,
      left: 24,
      right: 24,
      child: FadeTransition(
        opacity: _opacity,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
