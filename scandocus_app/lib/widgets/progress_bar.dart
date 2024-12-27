import 'package:flutter/material.dart';

/// This is the [ProgressIndicatorExample] widget, which uses Flutter's Material library
/// to display a progress indicator to the user, showing the loading status of something
/// It is a stateful widget, meaning the widget can have states that change over time
class ProgressIndicatorExample extends StatefulWidget {
  const ProgressIndicatorExample({super.key});

  @override
  State<ProgressIndicatorExample> createState() =>
      _ProgressIndicatorExampleState();
}

class _ProgressIndicatorExampleState extends State<ProgressIndicatorExample>
    with TickerProviderStateMixin {
  /// AnimationController to control the progress animation
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      // Initialize the AnimationController with a duration of 5 seconds
      // and the current widget as the TickerProvider using 'vsync: this'
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        // Update the UI whenever the animation value changes
        setState(() {});
      });
    // Start the animation and repeat it in reverse mode
    controller.repeat(reverse: true);
    super.initState();
  }

  // Dispose of the AnimationController to free resources
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Display a LinearProgressIndicator to show the progress visually
        SizedBox(
          height: 6.0,
          child: LinearProgressIndicator(
            value: controller.value,
            semanticsLabel: 'Text wird gescannt...',
          ),
        ),
      ],
    );
  }
}
