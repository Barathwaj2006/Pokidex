import 'package:flutter/material.dart';

class BandConfigRow extends StatelessWidget {
  final String bandName;
  final Color bandColor;
  final double amplitude;
  final double frequency;
  final double minFreq;
  final double maxFreq;
  final double maxAmplitude;
  final ValueChanged<double> onAmplitudeChanged;
  final ValueChanged<double> onFrequencyChanged;

  const BandConfigRow({
    super.key,
    required this.bandName,
    required this.bandColor,
    required this.amplitude,
    required this.frequency,
    required this.minFreq,
    required this.maxFreq,
    this.maxAmplitude = 100.0,
    required this.onAmplitudeChanged,
    required this.onFrequencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: bandColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                bandName,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: bandColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${minFreq.toStringAsFixed(1)}–${maxFreq.toStringAsFixed(0)} Hz',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _SliderRow(
            label: 'Amplitude',
            value: amplitude,
            min: 0,
            max: maxAmplitude,
            unit: 'uV',
            color: bandColor,
            onChanged: onAmplitudeChanged,
          ),
          const SizedBox(height: 4),
          _SliderRow(
            label: 'Frequency',
            value: frequency,
            min: minFreq,
            max: maxFreq,
            unit: 'Hz',
            color: bandColor,
            onChanged: onFrequencyChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${value.toStringAsFixed(1)} $unit',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}