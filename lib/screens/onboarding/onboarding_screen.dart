import 'package:flutter/material.dart';
import 'page_one.dart';
import 'page_two.dart';
import 'page_three.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: const [
          OnboardingPageOne(),
          OnboardingPageTwo(),
          OnboardingPageThree(),
        ],
      ),
    );
  }
}
