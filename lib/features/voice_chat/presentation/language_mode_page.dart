import 'package:flutter/material.dart';

import 'app_text.dart';
import '../domain/entities/conversation_language.dart';
import '../infrastructure/local/local_user_preferences_repository.dart';
import 'responsive_content_shell.dart';
import 'voice_chat_page.dart';

class LanguageModePage extends StatefulWidget {
  const LanguageModePage({super.key});

  @override
  State<LanguageModePage> createState() => _LanguageModePageState();
}

class _LanguageModePageState extends State<LanguageModePage> {
  final LocalUserPreferencesRepository _preferencesRepository =
      LocalUserPreferencesRepository();

  ConversationLanguage _selected = ConversationLanguage.auto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final saved = await _preferencesRepository.getPreferredLanguage();
    if (!mounted) return;

    setState(() {
      _selected = saved;
      _isLoading = false;
    });
  }

  Future<void> _savePreference() async {
    await _preferencesRepository.savePreferredLanguage(_selected);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appText(
            context,
            en: 'Language preference saved.',
            pt: 'Preferencia de idioma salva.',
          ),
        ),
      ),
    );
  }

  void _openVoiceChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VoiceChatPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(appText(context, en: 'Language Mode', pt: 'Modo de Idioma')),
      ),
      body: ResponsiveContentShell.premium(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      appText(
                        context,
                        en: 'Choose how listening and responses should handle English and Portuguese.',
                        pt: 'Escolha como escuta e respostas devem lidar com ingles e portugues.',
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _LanguageOptionTile(
                    title: appText(context, en: 'Auto', pt: 'Auto'),
                    subtitle: appText(
                      context,
                      en: 'Start with English and fallback to Portuguese when needed.',
                      pt: 'Comeca com ingles e usa fallback para portugues quando necessario.',
                    ),
                    value: ConversationLanguage.auto,
                    isSelected: _selected == ConversationLanguage.auto,
                    onChanged: (value) {
                      setState(() {
                        _selected = value;
                      });
                    },
                  ),
                  _LanguageOptionTile(
                    title:
                        appText(context, en: 'English (US)', pt: 'Ingles (US)'),
                    subtitle: appText(
                      context,
                      en: 'Force session in English for focused practice.',
                      pt: 'Forca sessao em ingles para pratica focada.',
                    ),
                    value: ConversationLanguage.englishUs,
                    isSelected: _selected == ConversationLanguage.englishUs,
                    onChanged: (value) {
                      setState(() {
                        _selected = value;
                      });
                    },
                  ),
                  _LanguageOptionTile(
                    title: appText(context,
                        en: 'Portugues (BR)', pt: 'Portugues (BR)'),
                    subtitle: appText(
                      context,
                      en: 'Force session in Brazilian Portuguese.',
                      pt: 'Forca sessao em portugues brasileiro.',
                    ),
                    value: ConversationLanguage.portugueseBr,
                    isSelected: _selected == ConversationLanguage.portugueseBr,
                    onChanged: (value) {
                      setState(() {
                        _selected = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _savePreference,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(
                      appText(
                        context,
                        en: 'Save Language Preference',
                        pt: 'Salvar Preferencia de Idioma',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _openVoiceChat,
                    icon: const Icon(Icons.mic),
                    label: Text(
                      appText(
                        context,
                        en: 'Open Voice Chat',
                        pt: 'Abrir Chat de Voz',
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final ConversationLanguage value;
  final bool isSelected;
  final ValueChanged<ConversationLanguage> onChanged;

  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(value),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.18)
                : Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.white24,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? Colors.blueAccent : Colors.white70,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
