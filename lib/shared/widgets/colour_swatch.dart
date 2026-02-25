import 'package:flutter/material.dart';

/// A tappable circular colour swatch for the payment method form.
class ColourSwatch extends StatelessWidget {
  final String hexColour;
  final bool selected;
  final VoidCallback onTap;

  const ColourSwatch({
    super.key,
    required this.hexColour,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colour = _hexToColor(hexColour);
    return Semantics(
      label: 'Colour $hexColour',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: selected ? 40 : 34,
          height: selected ? 40 : 34,
          decoration: BoxDecoration(
            color: colour,
            shape: BoxShape.circle,
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface,
                    width: 2.5,
                  )
                : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colour.withAlpha(100),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: selected
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) {
    final code = hex.replaceAll('#', '');
    return Color(int.parse('FF$code', radix: 16));
  }
}
