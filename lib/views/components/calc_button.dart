import 'package:flutter/material.dart';

enum CalcButtonVariant { number, operator, function, equals }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = CalcButtonVariant.number,
  });

  final String label;
  final VoidCallback onPressed;
  final CalcButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (variant) {
      CalcButtonVariant.number => (
          scheme.surfaceContainerHighest,
          scheme.onSurface
        ),
      CalcButtonVariant.operator => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer
        ),
      CalcButtonVariant.function => (scheme.surface, scheme.primary),
      CalcButtonVariant.equals => (scheme.primary, scheme.onPrimary),
    };
    return Padding(
      padding: const EdgeInsets.all(4),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 64),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
