import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/car_control_provider.dart';
import '../utils/constants.dart';

class DirectionalControlWidget extends StatelessWidget {
  const DirectionalControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarControlProvider>(context, listen: false);

    Widget buildButton({required IconData icon, required double x, required double y}) {
      return GestureDetector(
        onTapDown: (_) {
          provider.updateJoystickPosition(x, y);
        },
        onTapUp: (_) {
          provider.updateJoystickPosition(0, 0);
        },
        onTapCancel: () {
          provider.updateJoystickPosition(0, 0);
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.accentColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.secondaryColor),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildButton(icon: Icons.arrow_upward, x: 0, y: -1),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildButton(icon: Icons.arrow_back, x: -1, y: 0),
            const SizedBox(width: 16),
            buildButton(icon: Icons.arrow_forward, x: 1, y: 0),
          ],
        ),
        const SizedBox(height: 8),
        buildButton(icon: Icons.arrow_downward, x: 0, y: 1),
      ],
    );
  }
}
