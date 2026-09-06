import 'package:flutter/material.dart';
import '../../shared/widgets/floating_nav_bar.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Builder(
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: FloatingNavBar.contentInset(context),
          ),
          child: child,
        ),
      ),
      bottomNavigationBar: const FloatingNavBar(),
    );
  }
}
