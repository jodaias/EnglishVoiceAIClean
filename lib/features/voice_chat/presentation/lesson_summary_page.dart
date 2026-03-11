import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../application/lesson_controller.dart';
import 'app_text.dart';
import 'dashboard_routes.dart';

class LessonSummaryPage extends StatelessWidget {
  final LessonSessionSummary summary;

  const LessonSummaryPage({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final title = appText(
      context,
      en: summary.isPassed ? 'Lesson completed' : 'Lesson finished',
      pt: summary.isPassed ? 'Licao concluida' : 'Licao encerrada',
    );

    return Scaffold(
      appBar: AppBar(
        title:
            Text(appText(context, en: 'Lesson summary', pt: 'Resumo da licao')),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: summary.isPassed
                        ? const [Color(0xFF1B5E20), Color(0xFF2E7D32)]
                        : const [Color(0xFF4E342E), Color(0xFF6D4C41)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 14),
              _SummaryRow(
                label: appText(context,
                    en: 'Correct answers', pt: 'Respostas corretas'),
                value: '${summary.correctAnswers}/${summary.totalExercises}',
              ),
              _SummaryRow(
                label: appText(context, en: 'Score', pt: 'Pontuacao'),
                value: '${summary.scorePercent}%',
              ),
              _SummaryRow(
                label: appText(context,
                    en: 'Remaining hearts', pt: 'Vidas restantes'),
                value: '${summary.remainingHearts}',
              ),
              const SizedBox(height: 14),
              Text(
                appText(context, en: 'XP gained', pt: 'XP ganho'),
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: summary.earnedXp),
                duration: const Duration(milliseconds: 650),
                builder: (context, value, _) {
                  return Text(
                    '+$value XP',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFD54F),
                    ),
                  );
                },
              ),
              if (summary.isPassed && summary.scorePercent == 100) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.45)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        appText(
                          context,
                          en: 'Perfect lesson!',
                          pt: 'Licao perfeita!',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 90,
                        child: Lottie.asset(
                          'assets/lottie/robot_talking.json',
                          repeat: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    DashboardRoutes.dashboard,
                    (route) => false,
                  );
                },
                child: Text(appText(context, en: 'Continue', pt: 'Continuar')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
