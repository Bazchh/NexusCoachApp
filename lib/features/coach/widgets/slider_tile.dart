import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';

class SliderTile extends StatelessWidget {
  const SliderTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.border,
          min: min,
          max: max,
          divisions: divisions,
          label: label,
        ),
      ],
    );
  }
}
