import 'package:flutter/material.dart';

import 'core/responsive/responsive.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class GlobalEventsApp extends StatelessWidget {
  const GlobalEventsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Global Gather',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(Brightness.light),
      darkTheme: AppTheme.light(Brightness.dark),
      routerConfig: createAppRouter(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: Responsive.textScaler(context),
          ),
          child: child!,
        );
      },
    );
  }
}
