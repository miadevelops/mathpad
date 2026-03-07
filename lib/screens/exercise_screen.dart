import 'package:flutter/material.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Exercise',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}
