import 'package:flutter/material.dart';

import '../application/practice_hub_controller.dart';
import '../application/session_history_service.dart';
import '../domain/entities/daily_challenge.dart';
import '../domain/entities/daily_challenge_history.dart';
import '../domain/entities/practice_session_record.dart';
import 'app_text.dart';

class PracticeHubSheet extends StatelessWidget {
  final PracticeHubController controller;
  final VoidCallback? onOpenReadingListening;

  const PracticeHubSheet({
    super.key,
    required this.controller,
    this.onOpenReadingListening,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appText(context, en: 'Practice Hub', pt: 'Central de Pratica'),
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                appText(
                  context,
                  en: 'Track progress, complete today\'s challenge, and review previous sessions.',
                  pt: 'Acompanhe progresso, conclua o desafio de hoje e revise sessoes anteriores.',
                ),
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: controller.isLoadingNotifier,
                builder: (context, isLoading, _) {
                  if (isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadingListeningCard(context),
                      const SizedBox(height: 12),
                      _buildDailyChallengeCard(context),
                      const SizedBox(height: 12),
                      _buildProgressCard(context),
                      const SizedBox(height: 12),
                      _buildHistoryCard(context),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingListeningCard(BuildContext context) {
    return _PanelCard(
      title: appText(
        context,
        en: 'Reading + Listening Lab',
        pt: 'Laboratorio de Leitura + Audicao',
      ),
      icon: Icons.headphones,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appText(
              context,
              en: 'Train comprehension with short guided audios and instant answer checks.',
              pt: 'Treine compreensao com audios curtos guiados e verificacao imediata de resposta.',
            ),
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: onOpenReadingListening,
            icon: const Icon(Icons.play_circle_outline),
            label: Text(
              appText(
                context,
                en: 'Start reading + listening',
                pt: 'Iniciar leitura + audicao',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context) {
    return ValueListenableBuilder<DailyChallenge?>(
      valueListenable: controller.dailyChallengeNotifier,
      builder: (context, challenge, _) {
        if (challenge == null) {
          return const SizedBox.shrink();
        }

        final isLocked =
            controller.featureFlags.premiumDailyChallengePlusEnabled == false;

        return _PanelCard(
          title: appText(context, en: 'Daily Challenge', pt: 'Desafio Diario'),
          icon: Icons.flag_circle,
          child: ValueListenableBuilder<DailyChallengeHistory>(
            valueListenable: controller.dailyChallengeHistoryNotifier,
            builder: (context, history, _) {
              final last7 = history.completedInLastDays(
                now: DateTime.now(),
                days: 7,
              );
              final streak = history.currentStreakDays(DateTime.now());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${challenge.targetMinutes} min - ${challenge.topic}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.isCompleted
                        ? appText(
                            context,
                            en: 'Completed today. Great consistency.',
                            pt: 'Concluido hoje. Excelente consistencia.',
                          )
                        : appText(
                            context,
                            en: 'Complete this micro-goal to strengthen your speaking routine.',
                            pt: 'Conclua este micro-objetivo para fortalecer sua rotina de fala.',
                          ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appText(
                      context,
                      en: 'Challenge history: $last7/7 days, current streak ${streak}d.',
                      pt: 'Historico do desafio: $last7/7 dias, sequencia atual ${streak}d.',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: challenge.isCompleted
                            ? null
                            : () => controller.markDailyChallengeCompleted(),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          challenge.isCompleted
                              ? appText(context, en: 'Done', pt: 'Concluido')
                              : appText(
                                  context,
                                  en: 'Mark as done',
                                  pt: 'Marcar como concluido',
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isLocked)
                        Chip(
                          avatar: Icon(Icons.lock, size: 16),
                          label: Text(
                            appText(
                              context,
                              en: 'Daily Plus locked',
                              pt: 'Daily Plus bloqueado',
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(BuildContext context) {
    return ValueListenableBuilder<WeeklyProgressSnapshot?>(
      valueListenable: controller.weeklySnapshotNotifier,
      builder: (context, snapshot, _) {
        if (snapshot == null) {
          return const SizedBox.shrink();
        }

        final premiumLocked =
            controller.featureFlags.premiumInsightsEnabled == false;

        return _PanelCard(
          title:
              appText(context, en: 'Weekly Progress', pt: 'Progresso Semanal'),
          icon: Icons.insights,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: appText(context, en: 'Minutes', pt: 'Minutos'),
                      value: '${snapshot.practicedMinutes}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: appText(context,
                          en: 'Active days', pt: 'Dias ativos'),
                      value: '${snapshot.activeDays}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: appText(context, en: 'Streak', pt: 'Sequencia'),
                      value: '${snapshot.currentStreakDays}d',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: appText(context,
                          en: 'Consistency', pt: 'Consistencia'),
                      value: '${snapshot.consistencyPercent}%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appText(
                    context,
                    en: 'Most used focus: ${snapshot.mostUsedFocus}',
                    pt: 'Foco mais usado: ${snapshot.mostUsedFocus}',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  appText(
                    context,
                    en: 'Consistency status: ${snapshot.consistencyLabel}',
                    pt: 'Status de consistencia: ${_consistencyPt(snapshot.consistencyLabel)}',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              if (premiumLocked)
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      avatar: Icon(Icons.lock, size: 16),
                      label: Text(appText(
                        context,
                        en: 'Premium insights locked',
                        pt: 'Insights premium bloqueados',
                      )),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryCard(BuildContext context) {
    return _PanelCard(
      title:
          appText(context, en: 'Previous Sessions', pt: 'Sessoes Anteriores'),
      icon: Icons.history,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            initialValue: controller.sessionSearchQueryNotifier.value,
            onChanged: controller.setSessionSearchQuery,
            decoration: InputDecoration(
              hintText: appText(
                context,
                en: 'Search by focus or feedback note',
                pt: 'Buscar por foco ou nota de feedback',
              ),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String?>(
            valueListenable: controller.sessionFocusFilterNotifier,
            builder: (context, selectedFocus, _) {
              final options = controller.availableFocusFilters();
              final items = <DropdownMenuItem<String?>>[
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(appText(
                    context,
                    en: 'All focus areas',
                    pt: 'Todos os focos',
                  )),
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
                  labelText: appText(
                    context,
                    en: 'Focus filter',
                    pt: 'Filtro de foco',
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<SessionDateRange>(
            valueListenable: controller.sessionDateRangeNotifier,
            builder: (context, selectedRange, _) {
              return Wrap(
                spacing: 8,
                children: [
                  _dateRangeChip(
                    context: context,
                    selected: selectedRange,
                    value: SessionDateRange.allTime,
                    label: appText(context, en: 'All time', pt: 'Todo periodo'),
                  ),
                  _dateRangeChip(
                    context: context,
                    selected: selectedRange,
                    value: SessionDateRange.last7Days,
                    label: appText(context,
                        en: 'Last 7 days', pt: 'Ultimos 7 dias'),
                  ),
                  _dateRangeChip(
                    context: context,
                    selected: selectedRange,
                    value: SessionDateRange.last30Days,
                    label: appText(context,
                        en: 'Last 30 days', pt: 'Ultimos 30 dias'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<PracticeSessionRecord>>(
            valueListenable: controller.filteredSessionsNotifier,
            builder: (context, sessions, _) {
              if (sessions.isEmpty) {
                return Text(
                  appText(
                    context,
                    en: 'No sessions match this filter yet.',
                    pt: 'Nenhuma sessao corresponde ao filtro ainda.',
                  ),
                  style: const TextStyle(color: Colors.white70),
                );
              }

              return Column(
                children: sessions.take(20).map((session) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.play_circle_outline),
                    title: Text(session.practiceFocus),
                    subtitle: Text(
                      appText(
                        context,
                        en: '${_formatDateTime(session.endedAt)} - ${_formatDuration(session.elapsedSeconds)} - ${session.userTurns} turns',
                        pt: '${_formatDateTime(session.endedAt)} - ${_formatDuration(session.elapsedSeconds)} - ${session.userTurns} turnos',
                      ),
                    ),
                  );
                }).toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  String _consistencyPt(String englishLabel) {
    switch (englishLabel) {
      case 'Excellent consistency':
        return 'Consistencia excelente';
      case 'Good consistency':
        return 'Boa consistencia';
      case 'Building consistency':
        return 'Construindo consistencia';
      default:
        return 'Comece com sessoes curtas diarias';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }

  String _formatDateTime(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month ${value.year} $hour:$minute';
  }

  Widget _dateRangeChip({
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
}

class _PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _PanelCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
