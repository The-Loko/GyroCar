import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';

class SensorDisplayWidget extends StatelessWidget {
  const SensorDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CarControlProvider>(
      builder: (context, provider, child) {
        final sensorData = provider.lastSensorData;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildParameter(
              value: sensorData?.distance?.toString() ?? '125',
              label: 'cm',
            ),
            _buildParameter(
              value: sensorData?.temperature?.toString() ?? '24',
              label: '°C',
            ),
            _buildParameter(
              value: sensorData?.pressure?.toString() ?? '1013',
              label: 'hPa',
            ),
          ],
        );
      },
    );
  }

  Widget _buildParameter({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF8E8E93),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
