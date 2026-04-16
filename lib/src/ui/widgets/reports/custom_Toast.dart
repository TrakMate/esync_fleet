import 'package:flutter/material.dart';
import '../../../utils/appColors.dart';

class CustomToast {
  static OverlayEntry? _currentToast;

  static void show({
    required BuildContext context,
    required String message,
    ToastType type = ToastType.info,
    double progress = 0,
  }) {
    _remove();

    final overlayState = Overlay.of(context);
    if (overlayState == null) {
      _fallbackToast(message, type);
      return;
    }

    _currentToast = OverlayEntry(
      builder:
          (context) =>
              _ToastWidget(message: message, type: type, progress: progress),
    );
    overlayState.insert(_currentToast!);

    if (type != ToastType.loading) {
      Future.delayed(const Duration(seconds: 3), () {
        _remove();
      });
    }
  }

  static void _fallbackToast(String message, ToastType type) {}

  static void _remove() {
    _currentToast?.remove();
    _currentToast = null;
  }
}

enum ToastType { success, error, info, loading }

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final double progress;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.progress,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor() {
    switch (widget.type) {
      case ToastType.success:
        return tGreen;
      case ToastType.error:
        return tRed;
      case ToastType.loading:
        return tBlue;
      default:
        return const Color(0xFF333333);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.loading:
        return Icons.cloud_download_outlined;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Positioned(
      top: screenHeight * 0.01,
      right: 16,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _animation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                minWidth: 200,
                maxWidth: screenWidth * 0.4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIcon(), color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.type == ToastType.loading &&
                      widget.progress > 0) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        value: widget.progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(widget.progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
