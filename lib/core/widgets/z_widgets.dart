import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title; final Widget? trailing;
  @override Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, letterSpacing: 1.4, color: ZColors.muted, fontWeight: FontWeight.w800)), if (trailing != null) trailing!],
  );
}

class ZPanel extends StatelessWidget {
  const ZPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child; final EdgeInsets padding;
  @override Widget build(BuildContext context) => Container(
    padding: padding, decoration: BoxDecoration(
      color: ZColors.surface, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: ZColors.line),
    ), child: child,
  );
}

class FactionBadge extends StatelessWidget {
  const FactionBadge({super.key, required this.name, required this.symbol, required this.color});
  final String name, symbol, color;
  @override Widget build(BuildContext context) {
    final parsed = Color(int.tryParse(color.replaceFirst('#', '0xFF')) ?? 0xFF9DBB73);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: parsed.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: parsed.withValues(alpha: 0.45)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(symbol), const SizedBox(width: 6), Text(name, style: TextStyle(color: parsed, fontWeight: FontWeight.w800, fontSize: 11))]),
    );
  }
}

class ItemTile extends StatelessWidget {
  const ItemTile({super.key, required this.name, required this.icon, required this.category, required this.quantity});
  final String name, icon, category; final int quantity;
  @override Widget build(BuildContext context) => ZPanel(child: Row(children: [
    Container(width: 44, height: 44, alignment: Alignment.center, decoration: BoxDecoration(color: ZColors.surface2, borderRadius: BorderRadius.circular(12)), child: Text(icon, style: const TextStyle(fontSize: 22))),
    const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(category, style: const TextStyle(color: ZColors.muted, fontSize: 11)),
    ])),
    Text('x$quantity', style: const TextStyle(color: ZColors.green, fontWeight: FontWeight.w900, fontSize: 16)),
  ]));
}

class ShelterCard extends StatelessWidget {
  const ShelterCard({super.key, required this.name, required this.description, required this.capacity, required this.visibility});
  final String name, description, visibility; final int capacity;
  @override Widget build(BuildContext context) => ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.home_work_outlined, color: ZColors.green), const SizedBox(width: 8), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w800))), Text('$capacity vagas', style: const TextStyle(color: ZColors.muted, fontSize: 11))]),
    const SizedBox(height: 8), Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ZColors.muted)),
    const SizedBox(height: 8), Text(visibility == 'faction' ? 'ABRIGO DA FACÇÃO' : 'ABRIGO PÚBLICO', style: const TextStyle(color: ZColors.green, fontSize: 10, fontWeight: FontWeight.w900)),
  ]));
}

class TradeCard extends StatelessWidget {
  const TradeCard({super.key, required this.title, required this.status, required this.subtitle});
  final String title, status, subtitle;
  @override Widget build(BuildContext context) => ZPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))), Chip(label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 9)), visualDensity: VisualDensity.compact)]),
    Text(subtitle, style: const TextStyle(color: ZColors.muted, fontSize: 12)),
  ]));
}

class HordeAlertBanner extends StatelessWidget {
  const HordeAlertBanner({super.key, required this.description, required this.intensity});
  final String description, intensity;
  @override Widget build(BuildContext context) => ZPanel(child: Row(children: [
    const Icon(Icons.warning_amber_rounded, color: ZColors.red, size: 28), const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('HORDA • ${intensity.toUpperCase()}', style: const TextStyle(color: ZColors.red, fontWeight: FontWeight.w900, fontSize: 11)),
      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
    ])),
  ]));
}

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.endsAt});
  final DateTime endsAt;
  @override State<CountdownTimer> createState() => _CountdownTimerState();
}
class _CountdownTimerState extends State<CountdownTimer> {
  late Timer timer; Duration remaining = Duration.zero;
  @override void initState() { super.initState(); _tick(); timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick()); }
  void _tick() { if (!mounted) return; setState(() { remaining = widget.endsAt.difference(DateTime.now().toUtc()); if (remaining.isNegative) remaining = Duration.zero; }); }
  @override void dispose() { timer.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => Text('${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}', style: const TextStyle(color: ZColors.green, fontSize: 25, fontWeight: FontWeight.w900, fontFeatures: []));
}
