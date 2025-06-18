import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../services/connection_service.dart';

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
                _buildSensorRow(
                  'Distance',
                  '${sensorData.distance.toStringAsFixed(1)} cm',
                  Icons.straighten,
                  _getDistanceColor(sensorData.distance),
                ),
                const SizedBox(height: 12),
                _buildSensorRow(
                  'Temperature',
                  '${sensorData.temperature.toStringAsFixed(1)} °C',
                  Icons.thermostat,
                  _getTemperatureColor(sensorData.temperature),
                ),
                const SizedBox(height: 12),
                _buildSensorRow(
                  'Pressure',
                  '${sensorData.pressure.toStringAsFixed(1)} hPa',
                  Icons.speed,
                  AppColors.accentColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${_formatTime(sensorData.timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        isConnected ? Icons.hourglass_empty : Icons.bluetooth_disabled,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConnected ? 'Waiting for sensor data...' : 'Not connected',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getDistanceColor(double distance) {
    if (distance < 10) {
      return Colors.red; // Danger - very close
    } else if (distance < 20) {
      return Colors.orange; // Warning - close
    } else {
      return Colors.green; // Safe distance
    }
  }

  Color _getTemperatureColor(double temperature) {
    if (temperature < 10) {
      return Colors.blue; // Cold
    } else if (temperature > 35) {
      return Colors.red; // Hot
    } else {
      return Colors.green; // Normal
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}';
  }
}
