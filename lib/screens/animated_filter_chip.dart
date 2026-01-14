import 'package:flutter/material.dart';

class AnimatedFilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const AnimatedFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300]!,
          width: selected ? 2 : 1,
        ),
        color: selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.white,
      ),
      child: FilterChip(
        label: label,
        selected: selected,
        onSelected: onSelected,
        selectedColor: Colors.transparent,
        checkmarkColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}