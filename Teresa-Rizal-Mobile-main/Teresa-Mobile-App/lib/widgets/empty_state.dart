import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/soft_widget.dart';

/// Mirrors `resources/views/components/ui/empty-state.blade.php`.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.description,
    this.action,
    this.padding = const EdgeInsets.symmetric(vertical: 56, horizontal: AppSpacing.xxl),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Icon(icon, size: 28, color: SoftColors.muted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SoftColors.ink),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: SoftColors.muted),
            ),
          ],
          if (action != null) ...[const SizedBox(height: AppSpacing.xl), action!],
        ],
      ),
    );
  }
}

/// A shimmering skeleton block, mirroring the Web Admin's `.skeleton` class
/// (used while mock data "loads" on screen entry, matching the Web Admin's
/// deliberate skeleton-then-content pattern on e.g. citizen/dashboard.blade.php).
class SkeletonBox extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const SkeletonBox({super.key, required this.height, this.width, this.radius = 12});

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1 + _controller.value * 2, 0),
              end: Alignment(1 + _controller.value * 2, 0),
              colors: const [AppColors.slate100, AppColors.slate200, AppColors.slate100],
            ),
          ),
        );
      },
    );
  }
}

/// A centered error state with a retry action — used when a mock/local
/// operation is simulated to fail (e.g. validation, forced demo error).
class ErrorState extends StatelessWidget {
  final String title;
  final String? description;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.title, this.description, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.rose50, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: const Icon(Icons.error_outline_rounded, size: 28, color: AppColors.rose600),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: SoftColors.ink),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: SoftColors.muted),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}
