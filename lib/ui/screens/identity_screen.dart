import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Center(
        child: Text(
          'Identity',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
