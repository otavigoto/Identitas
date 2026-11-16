import 'package:flutter/material.dart';

Route<bool> nfcRoute(Widget page) {
  return PageRouteBuilder<bool>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => page,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.of(context).disableAnimations) {
        return child;
      }

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class NfcScaffold extends StatelessWidget {
  const NfcScaffold({
    super.key,
    required this.cardChild,
    this.bottomButton,
  });

  final Widget cardChild;
  final Widget? bottomButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
                minWidth: constraints.maxWidth,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Validar presença',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCFBE3),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: cardChild,
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      SizedBox(height: 48, child: bottomButton),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}