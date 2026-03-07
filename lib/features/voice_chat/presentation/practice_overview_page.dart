import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../application/app_feature_flags.dart';
import '../application/practice_hub_controller.dart';
import '../application/session_history_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';
import 'practice_hub_sheet.dart';
import 'responsive_content_shell.dart';

class PracticeOverviewPage extends StatefulWidget {
  const PracticeOverviewPage({super.key});

  @override
  State<PracticeOverviewPage> createState() => _PracticeOverviewPageState();
}

class _PracticeOverviewPageState extends State<PracticeOverviewPage> {
  late final PracticeHubController controller;

  @override
  void initState() {
    super.initState();
    final featureFlags = AppFeatureFlags.fromEnv(dotenv.env);
    final historyRepository = LocalSessionHistoryRepository();
    controller = PracticeHubController(
      repository: historyRepository,
      historyService: SessionHistoryService(),
      featureFlags: featureFlags,
    );
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appText(context, en: 'Practice Overview', pt: 'Visao de Pratica'),
        ),
      ),
      body: ResponsiveContentShell.premium(
        child: PracticeHubSheet(
          controller: controller,
          onOpenReadingListening: () {
            Navigator.of(context).pushNamed(DashboardRoutes.readingListening);
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.dashboard);
            return;
          }

          if (index == 2) {
            Navigator.of(context).pushReplacementNamed(DashboardRoutes.session);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_outlined),
            activeIcon: const Icon(Icons.dashboard),
            label: appText(context, en: 'Dashboard', pt: 'Dashboard'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.insights_outlined),
            activeIcon: const Icon(Icons.insights),
            label: appText(context, en: 'Practice', pt: 'Pratica'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: appText(context, en: 'Session', pt: 'Sessao'),
          ),
        ],
      ),
    );
  }
}
