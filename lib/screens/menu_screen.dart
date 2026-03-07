import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'MathPad',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
    );
  }
}
