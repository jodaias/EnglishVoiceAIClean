import 'package:flutter/material.dart';

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
              ElevatedButton.icon(
                onPressed: () => _openVoiceChat(context),
                icon: const Icon(Icons.mic),
                label: Text(
                  appText(
                    context,
                    en: 'Start Practice Session',
                    pt: 'Iniciar Sessao de Pratica',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
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
                    icon: Icons.insights_outlined,
                    title: appText(context,
                        en: 'Practice Hub', pt: 'Central de Pratica'),
                    subtitle: appText(context,
                        en: 'History and weekly stats',
                        pt: 'Historico e metricas semanais'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.practice),
                  ),
                  _QuickMenuCard(
                    icon: Icons.language_outlined,
                    title: appText(context,
                        en: 'Language Mode', pt: 'Modo de Idioma'),
                    subtitle: appText(context,
                        en: 'Auto, English, Portugues',
                        pt: 'Auto, Ingles, Portugues'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.language),
                  ),
                  _QuickMenuCard(
                    icon: Icons.tune_outlined,
                    title: appText(context,
                        en: 'Session Focus', pt: 'Foco da Sessao'),
                    subtitle: appText(context,
                        en: 'Travel, interview, routine...',
                        pt: 'Viagem, entrevista, rotina...'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(DashboardRoutes.session),
                  ),
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
