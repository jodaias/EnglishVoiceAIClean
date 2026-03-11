import 'package:english_voice_ai_clean/features/voice_chat/domain/entities/conversation_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../application/app_feature_flags.dart';
import '../application/practice_hub_controller.dart';
import '../application/session_history_service.dart';
import '../domain/entities/practice_session_record.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import 'app_text.dart';
import 'responsive_content_shell.dart';

class SessionHistoryPage extends StatefulWidget {
  const SessionHistoryPage({super.key});

  @override
  State<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends State<SessionHistoryPage> {
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
          appText(
            context,
            en: 'Session History',
            pt: 'Histórico de Sessoes',
          ),
        ),
      ),
      body: ResponsiveContentShell.premium(
        child: ValueListenableBuilder<bool>(
          valueListenable: controller.isLoadingNotifier,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchField(context),
                    const SizedBox(height: 10),
                    _buildDateRangeChips(context),
                    const SizedBox(height: 10),
                    _buildFocusDropdown(context),
                    const SizedBox(height: 12),
                    Expanded(child: _buildSessionList(context)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextFormField(
      initialValue: controller.sessionSearchQueryNotifier.value,
      onChanged: controller.setSessionSearchQuery,
      decoration: InputDecoration(
        hintText: appText(
          context,
          en: 'Search by focus or feedback note...',
          pt: 'Buscar por foco ou nota de feedback...',
        ),
        prefixIcon: const Icon(Icons.search),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _buildDateRangeChips(BuildContext context) {
    return ValueListenableBuilder<SessionDateRange>(
      valueListenable: controller.sessionDateRangeNotifier,
      builder: (context, selected, _) {
        return Wrap(
          spacing: 8,
          children: [
            _dateChip(
              context: context,
              selected: selected,
              value: SessionDateRange.allTime,
              label: appText(context, en: 'All time', pt: 'Todo periodo'),
            ),
            _dateChip(
              context: context,
              selected: selected,
              value: SessionDateRange.last7Days,
              label: appText(context, en: 'Last 7 days', pt: 'Ultimos 7 dias'),
            ),
            _dateChip(
              context: context,
              selected: selected,
              value: SessionDateRange.last30Days,
              label:
                  appText(context, en: 'Last 30 days', pt: 'Ultimos 30 dias'),
            ),
          ],
        );
      },
    );
  }

  Widget _dateChip({
    required BuildContext context,
    required SessionDateRange selected,
    required SessionDateRange value,
    required String label,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == value,
      onSelected: (_) => controller.setSessionDateRange(value),
    );
  }

  Widget _buildFocusDropdown(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: controller.sessionFocusFilterNotifier,
      builder: (context, selectedFocus, _) {
        final options = controller.availableFocusFilters();
        final items = <DropdownMenuItem<String?>>[
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              appText(context, en: 'All focus areas', pt: 'Todos os focos'),
            ),
          ),
          ...options.map(
            (focus) => DropdownMenuItem<String?>(
              value: focus,
              child: Text(focus),
            ),
          ),
        ];

        return DropdownButtonFormField<String?>(
          value: selectedFocus,
          items: items,
          onChanged: controller.setSessionFocusFilter,
          decoration: InputDecoration(
            labelText:
                appText(context, en: 'Focus filter', pt: 'Filtro de foco'),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        );
      },
    );
  }

  Widget _buildSessionList(BuildContext context) {
    return ValueListenableBuilder<List<PracticeSessionRecord>>(
      valueListenable: controller.filteredSessionsNotifier,
      builder: (context, sessions, _) {
        if (sessions.isEmpty) {
          return Center(
            child: Text(
              appText(
                context,
                en: 'No sessions match this filter yet.',
                pt: 'Nenhuma sessao corresponde ao filtro ainda.',
              ),
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        return ListView.separated(
          itemCount: sessions.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Colors.white12),
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionTile(session: session);
          },
        );
      },
    );
  }
}

class _SessionTile extends StatelessWidget {
  final PracticeSessionRecord session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final minutes = (session.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (session.elapsedSeconds % 60).toString().padLeft(2, '0');
    final month = session.endedAt.month.toString().padLeft(2, '0');
    final day = session.endedAt.day.toString().padLeft(2, '0');
    final hour = session.endedAt.hour.toString().padLeft(2, '0');
    final minute = session.endedAt.minute.toString().padLeft(2, '0');
    final dateStr = '$day/$month/${session.endedAt.year} $hour:$minute';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  session.practiceFocus,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                session.language.label,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 28),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Text(
                '$minutes:$seconds',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(width: 12),
              Text(
                appText(
                  context,
                  en: '${session.userTurns} turns',
                  pt: '${session.userTurns} turnos',
                ),
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
          if (session.feedback.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                session.feedback,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.white38),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

