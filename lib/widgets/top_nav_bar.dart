import 'package:flutter/material.dart';
import '../controllers/card_controller.dart';
import 'package:provider/provider.dart';

class TopNavBar extends StatelessWidget {
  const TopNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CardController>();
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      elevation: 1,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Tooltip(
                message: 'Back',
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: ctrl.canGoBack ? context.read<CardController>().prev : null,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    ctrl.total == 0 ? 'No cards' : 'Card ${ctrl.index + 1} of ${ctrl.total}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              Tooltip(
                message: 'Forward',
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: ctrl.canGoForward ? context.read<CardController>().next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
