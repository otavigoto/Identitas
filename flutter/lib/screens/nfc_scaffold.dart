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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Voltar',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Validar presença',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 32,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCFBE3),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: cardChild,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(height: 52, child: bottomButton),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NfcStatusCard extends StatelessWidget {
  const NfcStatusCard({
      super.key,
      required this.title,
      required this.subtitle,
      required this.icon,
      this.iconColor = const Color(0xFF1E1E1E),
  });

  final String title;
  final String subtitle;
  final Widget icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FF2E),
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: iconColor,
              fontSize: 20,
              height: 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF5C5B4D),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
    );
  }
}