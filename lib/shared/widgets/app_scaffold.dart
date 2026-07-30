import 'app_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/app_router.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: actions,
        leading: showBackButton
            ? CupertinoButton(
                padding: const EdgeInsets.only(left: 8),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.home);
                  }
                },
                child: AppIcon(
                  Icons.arrow_back_ios_new_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              )
            : null,
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(child: child),
    );
  }
}
