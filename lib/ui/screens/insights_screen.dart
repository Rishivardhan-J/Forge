import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Center(
        child: Text(
          'Insights',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
