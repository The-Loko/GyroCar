import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../widgets/sensor_display_widget.dart';
import '../widgets/directional_control_widget.dart';
import '../services/connection_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<CarControlProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Status bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Connection settings button
                      IconButton(
                        onPressed: () => _showConnectionDialog(context, provider),
                        icon: const Icon(
                          Icons.settings,
                          color: Color(0xFF8E8E93),
                          size: 24,
                        ),
                      ),
                      // Status dots
                      Row(
                        children: [
                          _buildStatusDot(
                            provider.connectionStatus == ConnectionStatus.connected,
                          ),
                          const SizedBox(width: 8),
                          _buildStatusDot(provider.isControlActive),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Sensor values section
                  const SensorDisplayWidget(),
                  
                  const Spacer(),
                  
                  // Controls section
                  Row(
                    children: [
                      // Directional controls
                      const Expanded(
                        child: DirectionalControlWidget(),
                      ),
                      
                      const SizedBox(width: 30),
                      
                      // Power button
                      Column(
                        children: [
                          _buildPowerButton(provider),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool isActive) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
      ),
    );
  }

  Widget _buildPowerButton(CarControlProvider provider) {
    return SizedBox(
      width: 80,
      height: 44,
      child: ElevatedButton(
        onPressed: () {
          if (provider.connectionStatus == ConnectionStatus.connected) {
            provider.toggleControl();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: provider.isControlActive 
              ? const Color(0xFF34C759) 
              : const Color(0xFFFF3B30),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          elevation: 0,
        ),
        child: Text(
          provider.isControlActive ? 'ON' : 'OFF',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(BuildContext context, CarControlProvider provider) {
    showDialog(
      context: context,
      builder: (context) => _ConnectionDialog(provider: provider),
    );
  }
}

class _ConnectionDialog extends StatefulWidget {
  final CarControlProvider provider;

  const _ConnectionDialog({required this.provider});

  @override
  State<_ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<_ConnectionDialog> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '80');
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1C1C1E),
      title: const Text(
        'Connection Settings',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connection status
          Container(
            padding: const EdgeInsets.all(12),            decoration: BoxDecoration(
              color: widget.provider.connectionStatus == ConnectionStatus.connected
                  ? const Color(0xFF34C759).withValues(alpha: 0.1)
                  : const Color(0xFFFF3B30).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.provider.connectionStatus == ConnectionStatus.connected
                      ? Icons.wifi
                      : Icons.wifi_off,
                  color: widget.provider.connectionStatus == ConnectionStatus.connected
                      ? const Color(0xFF34C759)
                      : const Color(0xFFFF3B30),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.provider.connectionStatus == ConnectionStatus.connected
                      ? 'Connected'
                      : 'Disconnected',
                  style: TextStyle(
                    color: widget.provider.connectionStatus == ConnectionStatus.connected
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // IP Address field
          TextField(
            controller: _ipController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'ESP32 IP Address',
              labelStyle: TextStyle(color: Color(0xFF8E8E93)),
              hintText: '192.168.1.100',
              hintStyle: TextStyle(color: Color(0xFF8E8E93)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF38383A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF007AFF)),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Port field
          TextField(
            controller: _portController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Port',
              labelStyle: TextStyle(color: Color(0xFF8E8E93)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF38383A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF007AFF)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.provider.connectionStatus == ConnectionStatus.connected)        TextButton(
          onPressed: () async {
            await widget.provider.disconnect();
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
            child: const Text(
              'Disconnect',
              style: TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF8E8E93)),
          ),
        ),
        TextButton(
          onPressed: _isConnecting ? null : _connect,
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                  ),
                )
              : const Text(
                  'Connect',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
        ),
      ],
    );
  }

  Future<void> _connect() async {
    if (_ipController.text.isEmpty) return;

    setState(() {
      _isConnecting = true;
    });

    try {
      final success = await widget.provider.connectWifi(
        _ipController.text,
        int.tryParse(_portController.text) ?? 80,
      );      if (mounted) {
        if (success) {
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to connect'),
              backgroundColor: Color(0xFFFF3B30),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }
}
