import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/realtime/pusher_service.dart';
import '../../core/logger/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/keyboard_dismiss.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../navigation/app_launch_transition.dart';
import '../app/analytics/analytics_page.dart';
import '../app/calendar/calendar_page.dart';
import '../app/home/home_page.dart';
import '../app/posts/posts_page.dart';
import 'tab_cubit.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    PusherRealtimeService().connectIfLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TabCubit(),
      child: const _MainShellBody(),
    );
  }
}

class _MainShellBody extends StatelessWidget {
  const _MainShellBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TabCubit, int>(
      builder: (context, tab) {
        return KeyboardDismissScope(
          child: Scaffold(
          backgroundColor: AppColors.gray50,
          body: IndexedStack(
            index: tab,
            children: const [
              HomePage(),
              PostsPage(),
              CalendarPage(),
              AnalyticsPage(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            activeIndex: tab,
            onTab: (i) {
              KeyboardDismiss.hide(context);
              AppLogger.event('shell_tab', {'index': i});
              context.read<TabCubit>().setTab(i);
            },
            onCreate: (sourceCtx) {
              KeyboardDismiss.hide(context);
              AppLogger.navigation('shell', 'create');
              sourceCtx.pushFromSource('/create', borderRadius: 28);
            },
          ),
        ),
        );
      },
    );
  }
}
