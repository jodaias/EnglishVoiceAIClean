import 'package:flutter/material.dart';

import '../application/session_history_service.dart';
import '../infrastructure/local/local_session_history_repository.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';
import 'responsive_content_shell.dart';
import 'voice_chat_page.dart';

class InitialDashboardPage extends StatelessWidget {
  const InitialDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
            appText(context, en: 'English Voice AI', pt: 'English Voice AI')),
      ),
      body: SafeArea(
        child: ResponsiveContentShell.premium(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF266B6E), Color(0xFF1D3A55)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appText(context,
                          en: 'Welcome back!', pt: 'Bem-vindo de volta!'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appText(
                        context,
                        en: 'Practice speaking every day with short voice sessions and quick feedback.',
                        pt: 'Pratique fala todos os dias com sessoes curtas e feedback rapido.',
                      ),
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const _StreakBanner(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _openVoiceChat(context),
                      icon: const Icon(Icons.mic),
                      label: Text(
                        appText(
                          context,
                          en: 'Voice Chat',
                          pt: 'Chat de Voz',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(context)
                          .pushNamed(DashboardRoutes.videoCall),
                      icon: const Icon(Icons.videocam),
                      label: Text(
                        appText(
                          context,
                          en: 'Video Call',
                          pt: 'Videochamada',
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: const Color(0xFF1D5C6E),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SectionTitle(
                  title: appText(context, en: 'Quick Menu', pt: 'Menu Rapido')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickMenuCard(
                    icon: Icons.chat_bubble_outline,
                    title:
                        appText(context, en: 'Voice Chat', pt: 'Chat de Voz'),
                    subtitle: appText(context,
                        en: 'Talk in EN-US / PT-BR',
                        pt: 'Converse em EN-US / PT-BR'),
                    onTap: () => _openVoiceChat(context),
                  ),
                  _QuickMenuCard(
                    icon: Icons.videocam_outlined,
                    title:
                        appText(context, en: 'Video Call', pt: 'Videochamada'),
                    subtitle: appText(context,
                        en: 'Immersive AI conversation',
                        pt: 'Conversa imersiva com IA'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.videoCall),
                  ),
                  _QuickMenuCard(
                    icon: Icons.insights_outlined,
                    title: appText(context,
                        en: 'Practice Hub', pt: 'Central de Prática'),
                    subtitle: appText(context,
                        en: 'History and weekly stats',
                        pt: 'Histórico e metricas semanais'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.practice),
                  ),
                  _QuickMenuCard(
                    icon: Icons.language_outlined,
                    title: appText(context,
                        en: 'Language Mode', pt: 'Modo de Idioma'),
                    subtitle: appText(context,
                        en: 'Auto, English, Português',
                        pt: 'Auto, Inglês, Português'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.language),
                  ),
                  _QuickMenuCard(
                    icon: Icons.school_outlined,
                    title: appText(context,
                        en: 'Learning Path', pt: 'Trilha de Aprendizado'),
                    subtitle: appText(context,
                        en: 'Units, bubbles and progressive unlock',
                        pt: 'Unidades, bolhas e desbloqueio progressivo'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.learningPath),
                  ),
                  _QuickMenuCard(
                    icon: Icons.history_outlined,
                    title: appText(context,
                        en: 'Session History', pt: 'Histórico de Sessoes'),
                    subtitle: appText(context,
                        en: 'Search and filter past sessions',
                        pt: 'Buscar e filtrar sessoes anteriores'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.sessionHistory),
                  ),
                  _QuickMenuCard(
                    icon: Icons.tune_outlined,
                    title:
                        appText(context, en: 'Settings', pt: 'Configurações'),
                    subtitle: appText(context,
                        en: 'Language, scene and AI options',
                        pt: 'Idioma, cena e opções de IA'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.settings),
                  )
                ],
              ),
              const SizedBox(height: 14),
              _SectionTitle(
                  title: appText(context, en: 'Suggestion', pt: 'Sugestao')),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  appText(
                    context,
                    en: 'Keep sessions short: 5-10 minutes with 1 focus per day usually gives the best consistency.',
                    pt: 'Mantenha sessoes curtas: 5-10 minutos com 1 foco por dia costuma trazer melhor consistencia.',
                  ),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.of(context)
                .pushReplacementNamed(DashboardRoutes.practice);
            return;
          }

          if (index == 2) {
            Navigator.of(context).pushReplacementNamed(DashboardRoutes.settings);
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
            label: appText(context, en: 'Practice', pt: 'Prática'),
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

  void _openVoiceChat(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VoiceChatPage()));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }
}

class _QuickMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakBanner extends StatefulWidget {
  const _StreakBanner();

  @override
  State<_StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends State<_StreakBanner> {
  int? _streakDays;
  int? _activeDays;
  List<bool> _weekActivity = List.filled(7, false);

  @override
  void initState() {
    super.initState();
    _loadStreak();
  }

  Future<void> _loadStreak() async {
    final repo = LocalSessionHistoryRepository();
    final sessions = await repo.getSessions();
    final service = SessionHistoryService();
    final now = DateTime.now();
    final snapshot = service.buildWeeklySnapshot(
      sessions: sessions,
      now: now,
    );

    final today = DateTime(now.year, now.month, now.day);
    final activeDates = sessions
        .map((s) => DateTime(s.endedAt.year, s.endedAt.month, s.endedAt.day))
        .toSet();
    final week = <bool>[];
    for (var i = 6; i >= 0; i--) {
      week.add(activeDates.contains(today.subtract(Duration(days: i))));
    }

    if (mounted) {
      setState(() {
        _streakDays = snapshot.currentStreakDays;
        _activeDays = snapshot.activeDays;
        _weekActivity = week;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_streakDays == null) {
      return const SizedBox.shrink();
    }

    final streakColor =
        _streakDays! >= 3 ? Colors.orange.shade300 : Colors.white70;

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(Icons.local_fire_department, color: streakColor, size: 22),
              const SizedBox(width: 6),
              Text(
                appText(
                  context,
                  en: '$_streakDays-day streak',
                  pt: 'Sequência de $_streakDays dias',
                ),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: streakColor,
                ),
              ),
              const Spacer(),
              Text(
                appText(
                  context,
                  en: '$_activeDays/7 active',
                  pt: '$_activeDays/7 ativos',
                ),
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final dayLabel = _weekdayLabel(context, i);
              final active = _weekActivity[i];
              return Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active ? Colors.green.shade400 : Colors.white12,
                    ),
                    child: active
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dayLabel,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _weekdayLabel(BuildContext context, int index) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - index));
    const enDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const ptDays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];
    final isPortuguese = Localizations.localeOf(context).languageCode == 'pt';
    final labels = isPortuguese ? ptDays : enDays;
    return labels[(day.weekday - 1) % 7];
  }
}
