import 'package:flutter/material.dart';

/// Cheap, dependency-free "pulsing placeholder" loading effect — a single
/// shared AnimationController driving opacity, not a shimmer package, so it
/// stays light on low-end devices.
class _Pulse extends StatefulWidget {
  final Widget child;

  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(opacity: 0.5 + (_controller.value * 0.35), child: child),
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry radius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.radius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    return _Pulse(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: radius,
        ),
      ),
    );
  }
}

/// Mimics the Home screen's list-card shape while requests are first loading.
class SkeletonRequestList extends StatelessWidget {
  final int count;

  const SkeletonRequestList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 140, height: 15),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 90 + (index % 3) * 20, height: 12),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SkeletonBox(width: 64, height: 22, radius: BorderRadius.all(Radius.circular(20))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mimics the New Price Offer form's shape while master data (customers,
/// price lists, items) is first loading — same pulsing-card language as
/// SkeletonRequestList/SkeletonDetail, instead of a bare spinner.
class SkeletonOfferForm extends StatelessWidget {
  const SkeletonOfferForm({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 16),
                SkeletonBox(height: 48, radius: BorderRadius.all(Radius.circular(12))),
                SizedBox(height: 12),
                SkeletonBox(height: 48, radius: BorderRadius.all(Radius.circular(12))),
                SizedBox(height: 12),
                SkeletonBox(height: 48, radius: BorderRadius.all(Radius.circular(12))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const SkeletonBox(width: 100, height: 16),
        const SizedBox(height: 12),
        for (int i = 0; i < 3; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 60 + (i % 2) * 20, height: 14),
                  const SizedBox(height: 12),
                  const SkeletonBox(height: 48, radius: BorderRadius.all(Radius.circular(12))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 48, radius: const BorderRadius.all(Radius.circular(12)))),
                      const SizedBox(width: 10),
                      Expanded(child: SkeletonBox(height: 48, radius: const BorderRadius.all(Radius.circular(12)))),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Mimics the Request Detail screen's shape while it's first loading.
class SkeletonDetail extends StatelessWidget {
  const SkeletonDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            SkeletonBox(width: 120, height: 20),
            SkeletonBox(width: 70, height: 22, radius: BorderRadius.all(Radius.circular(20))),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: List.generate(
                4,
                (i) => Padding(
                  padding: EdgeInsets.only(bottom: i == 3 ? 0 : 12),
                  child: Row(
                    children: [
                      const SkeletonBox(width: 90, height: 12),
                      const SizedBox(width: 12),
                      Expanded(child: SkeletonBox(height: 12, width: 100 + i * 15)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 80, height: 16),
        const SizedBox(height: 12),
        for (int i = 0; i < 2; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 160, height: 14),
                  SizedBox(height: 8),
                  SkeletonBox(width: 200, height: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
