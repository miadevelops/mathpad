import 'package:flutter/material.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure')),
      body: Center(
        child: Text(
          'Session Config',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}
