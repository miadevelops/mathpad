import 'package:flutter/material.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Results')),
      body: Center(
        child: Text(
          'Session Results',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
    );
  }
}
