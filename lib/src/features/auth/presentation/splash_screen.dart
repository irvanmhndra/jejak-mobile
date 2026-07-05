import 'package:flutter/material.dart';

/// Shown while the persisted session is being restored, so no protected screen
/// mounts (or fires a request) before we know whether the user is signed in.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_run, size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
    );
  }
}
