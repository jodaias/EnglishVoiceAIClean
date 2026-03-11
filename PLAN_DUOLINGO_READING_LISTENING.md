# Plano: Reading & Listening estilo Duolingo

## Visao Geral

Transformar o modulo de Reading & Listening atual (quiz linear de multipla escolha com 12 exercicios estaticos) em uma experiencia gamificada e progressiva inspirada no Duolingo, com variedade de tipos de exercicio, sistema de XP/vidas, trilha de aprendizado estruturada e feedback animado.

---

## 1. Analise do Estado Atual

### O que existe hoje

- **12 exercicios estaticos** em catalogo hardcoded
- **Tipo unico**: leitura de texto + pergunta de multipla escolha (4 opcoes)
- **2 niveis**: Beginner e Intermediate (filtro manual)
- **Funcionalidades**: ouvir audio (TTS), ler em voz alta (STT + accuracy), salvar sessao
- **Progressao**: linear (exercicio 1 ao 12), sem desbloqueio ou prerequisito
- **Gamificacao**: apenas sugestao de subir nivel apos 2 sessoes >=80%
- **UI**: lista sequencial com radio buttons, card de resumo no final

### O que falta para parecer Duolingo

| Aspecto            | Atual                | Duolingo                         |
| ------------------ | -------------------- | -------------------------------- |
| Tipos de exercicio | 1 (multipla escolha) | 8-10 tipos variados              |
| Estrutura          | Lista plana          | Trilha com unidades/licoes       |
| Gamificacao        | Quase nenhuma        | XP, vidas, streaks, ranking      |
| Feedback visual    | Texto verde/vermelho | Animacoes, sons, cores vibrantes |
| Progressao         | Manual               | Desbloqueio progressivo          |
| Repeticao espacada | Nao tem              | Revisao inteligente              |
| Conteudo           | 12 exercicios fixos  | Centenas, gerados ou curados     |

---

## 2. Novos Tipos de Exercicio

### 2.1 `listenAndSelect` — Ouca e Selecione

- Toca um audio (TTS) sem mostrar texto
- Usuario escolhe entre 4 opcoes escritas qual corresponde ao que ouviu
- Treina: compreensao auditiva pura

### 2.2 `listenAndType` — Ouca e Digite

- Toca um audio (TTS)
- Usuario digita o que ouviu (campo de texto livre)
- Validacao: comparacao fuzzy (tolerancia Levenshtein existente)
- Treina: dictation, spelling

### 2.3 `fillInTheBlank` — Complete a Frase

- Mostra frase com `___` no lugar de 1-2 palavras
- 3-4 opcoes de palavras para preencher
- Treina: vocabulario, gramatica contextual

### 2.4 `wordOrder` — Ordene as Palavras

- Mostra frase embaralhada em chips arrastáveis/clicáveis
- Usuario monta a frase na ordem correta
- Treina: estrutura de frase, sintaxe

### 2.5 `translate` — Traduza a Frase

- Mostra frase em PT-BR, pede traducao para EN-US (ou vice-versa)
- Pode ser digitada ou montada com word bank (chips)
- Validacao fuzzy com variantes aceitas
- Treina: traducao ativa, vocabulario

### 2.6 `matchPairs` — Conecte os Pares

- 4-6 pares de palavras/frases (EN <-> PT-BR)
- Usuario conecta clicando nos pares correspondentes
- Treina: vocabulario, associacao rapida

### 2.7 `speakTheSentence` — Fale a Frase (ja existe parcialmente)

- Mostra frase escrita
- Usuario fala em voz alta
- Avalia pronuncia com accuracy existente
- Treina: pronuncia, fluencia oral

### 2.8 `trueOrFalse` — Verdadeiro ou Falso

- Mostra afirmacao sobre um texto/audio curto
- Usuario marca True ou False
- Treina: compreensao rapida, atencao a detalhes

### 2.9 `selectTheImage` (futuro)

- Mostra audio ou palavra, usuario seleciona imagem correspondente
- Requer banco de imagens — baixa prioridade

### Novo Enum de Tipos

```dart
enum ExerciseType {
  multipleChoice,      // existente
  listenAndSelect,
  listenAndType,
  fillInTheBlank,
  wordOrder,
  translate,
  matchPairs,
  speakTheSentence,
  trueOrFalse,
}
```

---

## 3. Trilha de Aprendizado (Learning Path)

### 3.1 Estrutura hierarquica

```
LearningPath
  └── Unit (tema: "At the Airport", "Daily Routine", "At Work"...)
       └── Lesson (5-8 exercicios mistos por licao)
            └── Exercise (tipo variado)
```

### 3.2 Domain Entities novas

```dart
/// Unidade tematica com multiplas licoes
class LearningUnit {
  final String id;
  final String titleEn;
  final String titlePt;
  final String iconAsset;        // icone do tema
  final int orderIndex;          // posicao na trilha
  final DifficultyLevel difficulty;
  final List<Lesson> lessons;
}

/// Licao com mix de exercicios
class Lesson {
  final String id;
  final String unitId;
  final int orderIndex;
  final List<LessonExercise> exercises;  // 5-8 exercicios mistos
}

/// Exercicio dentro de uma licao (polimórfico por tipo)
class LessonExercise {
  final String id;
  final ExerciseType type;
  final DifficultyLevel difficulty;
  final Map<String, dynamic> content;  // conteudo especifico por tipo
  // Helpers tipados para cada tipo de exercicio
}
```

### 3.3 Progressao e Desbloqueio

```dart
/// Progresso do usuario por unidade/licao
class UserProgress {
  final Map<String, UnitProgress> units;  // unitId -> progress
}

class UnitProgress {
  final String unitId;
  final Map<String, LessonProgress> lessons;
  final bool isUnlocked;
  final int crowns;  // 0-5, quantas vezes completou
}

class LessonProgress {
  final String lessonId;
  final bool isCompleted;
  final int bestScore;       // porcentagem
  final int xpEarned;
  final DateTime? completedAt;
  final int attempts;
}
```

### 3.4 Regras de desbloqueio

- Unidade 1, Licao 1: sempre desbloqueada
- Proxima licao desbloqueia ao completar a anterior com >=60%
- Proxima unidade desbloqueia ao completar todas as licoes da unidade anterior
- Revisao: qualquer licao completada pode ser refeita para mais XP (com rendimento decrescente)

---

## 4. Sistema de Gamificacao

### 4.1 XP (Experience Points)

- Cada exercicio correto: **10 XP**
- Bonus por acerto na primeira tentativa: **+5 XP**
- Bonus por licao perfeita (100%): **+20 XP**
- Bonus por pronuncia >= 90%: **+10 XP**
- XP por sessao salvo no `PracticeSessionRecord`

### 4.2 Vidas (Hearts)

- Usuario comeca com **5 vidas** por sessao de licao
- Cada erro consome 1 vida
- 0 vidas = sessao encerrada, pode recomecar
- Vidas recarregam apos cooldown (ex: 30 min) ou ao praticar revisao
- Opcional: desativar vidas para modo relaxado nas configuracoes

### 4.3 Streaks (ja existe parcialmente)

- Integrar streak existente do `PracticeHubController` com as licoes
- "Completar ao menos 1 licao por dia" mantem o streak
- Mostrar streak prominente na tela da trilha

### 4.4 Crowns por Unidade

- Cada unidade pode ser completada multiplas vezes
- 1a vez = 1 coroa, 2a vez exercicios mais dificeis = 2 coroas, ate 5
- Niveis de coroa aumentam dificuldade (menos opcoes, mais digitacao, mais audio)

### 4.5 Persistencia

- Salvar `UserProgress`, XP total, vidas e streak via Hive (repositorio existente)
- Novo box Hive: `learningProgressBox`

---

## 5. UI/UX Estilo Duolingo

### 5.1 Tela da Trilha (LearningPathPage)

- Scroll vertical com "bolhas" conectadas por linhas
- Cada bolha = 1 licao (icone da unidade + status)
- Cores: cinza (bloqueado), azul (disponível), dourado (completado), estrela (perfeito)
- Header fixo: avatar + XP total + streak + vidas
- Unidades separadas por banners tematicos

### 5.2 Tela de Licao (LessonPage)

- Barra de progresso no topo (fina, colorida, avanca a cada exercicio)
- Botao X para sair (com confirmacao "Voce perdera o progresso")
- Exibicao de vidas no topo-direita
- Area central: exercicio renderizado por tipo
- Botao inferior grande: "CHECK" / "VERIFICAR"
- Feedback pos-resposta:
  - Correto: fundo verde suave + texto "Correto!" + som de acerto
  - Incorreto: fundo vermelho suave + resposta correta exibida + som de erro
  - Botao "CONTINUE" para avancar

### 5.3 Widgets por Tipo de Exercicio

| Tipo               | Widget                                            |
| ------------------ | ------------------------------------------------- |
| `multipleChoice`   | RadioButtons com cards coloridos                  |
| `listenAndSelect`  | Botao play grande + opcoes em cards               |
| `listenAndType`    | Botao play + TextField com hint                   |
| `fillInTheBlank`   | Texto com gap + chips selecionaveis               |
| `wordOrder`        | Chips draggaveis em duas areas (banco + resposta) |
| `translate`        | Frase origem + word bank OU TextField             |
| `matchPairs`       | Grid 2 colunas com selecao highlight              |
| `speakTheSentence` | Frase + botao microfone + accuracy visual         |
| `trueOrFalse`      | Afirmacao + dois botoes grandes True/False        |

### 5.4 Tela de Resumo (LessonSummaryPage)

- Animacao de XP ganho (contagem animada)
- Score: "X/Y corretas"
- Accuracy media de pronuncia (se houve exercicios de fala)
- Botao "Continue" volta para trilha
- Se licao perfeita: animacao especial de celebracao
- Se desbloqueou nova unidade: banner de conquista

### 5.5 Paleta de Cores e Design

- Verde principal: acerto, progresso, botao primario
- Vermelho suave: erro
- Azul: disponivel, interativo
- Dourado: completado, estrela, XP
- Cinza: bloqueado
- Fundo: branco/creme limpo
- Tipografia: bold para titulos, regular para corpo
- Bordas arredondadas em todos os cards

### 5.6 Sons e Haptics

- Som de acerto (curto, satisfatorio)
- Som de erro (curto, nao punitivo)
- Som de licao completa (celebracao)
- Haptic feedback leve em selecoes
- Assets: `assets/audio/correct.mp3`, `assets/audio/wrong.mp3`, `assets/audio/complete.mp3`

---

## 6. Conteudo: Estrategia de Geracao

### 6.1 Fase 1 — Catalogo Curado (manual)

- Expandir de 12 para ~60-80 exercicios organizados em 8-10 unidades
- Cada unidade: 2-3 licoes, cada licao 5-8 exercicios mistos
- Manter bilingue (EN + PT-BR) em todo conteudo
- Temas sugeridos para unidades iniciais:

| #   | Unidade         | Tema                         | Dificuldade  |
| --- | --------------- | ---------------------------- | ------------ |
| 1   | Greetings       | Cumprimentos e apresentacoes | Beginner     |
| 2   | At a Cafe       | Pedir comida e bebida        | Beginner     |
| 3   | Getting Around  | Direcoes e transporte        | Beginner     |
| 4   | Daily Routine   | Rotina diaria                | Beginner     |
| 5   | Shopping        | Compras e precos             | Beginner     |
| 6   | At the Airport  | Viagem e aeroporto           | Intermediate |
| 7   | At Work         | Reunioes e escritorio        | Intermediate |
| 8   | Health & Doctor | Saude e consultas            | Intermediate |
| 9   | Making Plans    | Planos e convites            | Intermediate |
| 10  | Telling Stories | Narrativas e passado         | Intermediate |

### 6.2 Fase 2 — Geracao por IA (Gemini)

- Usar Gemini API (ja integrada) para gerar exercicios novos sob demanda
- Prompt estruturado: tema, tipo de exercicio, dificuldade, idioma
- Validacao automatica antes de exibir (formato, numero de opcoes, resposta valida)
- Cache local dos exercicios gerados (Hive)
- Permite conteudo infinito sem curadoria manual

### 6.3 Fase 3 — Repeticao Espacada

- Rastrear exercicios errados pelo usuario
- Reinserir exercicios errados em licoes futuras com frequencia decrescente
- Algoritmo simples: errou → volta em 1 dia, errou de novo → volta em 1 dia, acertou → volta em 3 dias, acertou → volta em 7 dias, acertou → removido da fila

---

## 7. Arquitetura Tecnica

### 7.1 Novos Arquivos — Domain

```
lib/features/voice_chat/domain/entities/
  ├── exercise_type.dart              // enum ExerciseType
  ├── lesson_exercise.dart            // novo modelo polimorfico
  ├── lesson.dart                     // agrupamento de exercicios
  ├── learning_unit.dart              // unidade tematica
  ├── user_progress.dart              // progresso do usuario
  ├── unit_progress.dart              // progresso por unidade
  ├── lesson_progress.dart            // progresso por licao
  └── xp_reward.dart                  // regras de XP
```

### 7.2 Novos Arquivos — Application

```
lib/features/voice_chat/application/
  ├── learning_path_controller.dart    // orquestra trilha, desbloqueio, XP
  ├── lesson_controller.dart           // orquestra exercicios dentro de licao
  ├── lesson_content_catalog.dart      // catalogo expandido (substitui reading_listening_catalog)
  ├── exercise_validator.dart          // valida respostas por tipo
  ├── xp_calculator.dart              // calcula XP ganho
  ├── hearts_manager.dart             // gerencia vidas
  └── spaced_repetition_service.dart  // fila de revisao (fase 3)
```

### 7.3 Novos Arquivos — Infrastructure

```
lib/features/voice_chat/infrastructure/
  ├── local/
  │   └── local_learning_progress_repository.dart  // Hive para progresso
  └── ai/
      └── exercise_generator_service.dart          // gera exercicios via Gemini (fase 2)
```

### 7.4 Novos Arquivos — Presentation

```
lib/features/voice_chat/presentation/
  ├── learning_path_page.dart          // tela da trilha com bolhas
  ├── lesson_page.dart                 // tela de licao (fluxo de exercicios)
  ├── lesson_summary_page.dart         // resumo pos-licao
  ├── widgets/
  │   ├── exercise_multiple_choice.dart
  │   ├── exercise_listen_and_select.dart
  │   ├── exercise_listen_and_type.dart
  │   ├── exercise_fill_blank.dart
  │   ├── exercise_word_order.dart
  │   ├── exercise_translate.dart
  │   ├── exercise_match_pairs.dart
  │   ├── exercise_speak_sentence.dart
  │   ├── exercise_true_false.dart
  │   ├── progress_bar_widget.dart
  │   ├── hearts_display.dart
  │   ├── xp_counter_widget.dart
  │   ├── lesson_node_widget.dart      // bolha na trilha
  │   └── feedback_overlay.dart        // overlay verde/vermelho pos-resposta
  └── learning_path_theme.dart         // cores e estilos do modulo
```

### 7.5 Rotas Novas

```dart
'/learning-path'      // tela da trilha
'/lesson/:unitId/:lessonId'  // tela de licao
'/lesson-summary'     // resumo pos-licao
```

### 7.6 Migracao da Pagina Atual

- `reading_listening_page.dart` se torna deprecated
- Link no menu aponta para `/learning-path`
- Catalogo antigo pode ser convertido em exercicios `multipleChoice` na Unidade 1
- Manter arquivo ponte para nao quebrar imports existentes

---

## 8. Plano de Sprints

### Sprint 1 — Fundacoes (Domain + Infra)

**Objetivo**: modelagem de dados e persistencia

- [x] Criar `ExerciseType` enum
- [x] Criar `LessonExercise` com content tipado por tipo
- [x] Criar `Lesson` e `LearningUnit`
- [x] Criar `UserProgress`, `UnitProgress`, `LessonProgress`
- [x] Criar `XpReward` com regras de calculo
- [x] Implementar `LocalLearningProgressRepository` (Hive)
- [x] Testes unitarios para todas as entities
- [x] Testes para repositorio de progresso

### Sprint 2 — Catalogo e Validacao

**Objetivo**: conteudo inicial e logica de validacao de respostas

- [x] Criar `ExerciseValidator` para cada tipo de exercicio
- [x] Expandir catalogo: Unidade 1 "Greetings" (3 licoes, ~18 exercicios mistos)
- [x] Expandir catalogo: Unidade 2 "At a Cafe" (3 licoes, ~18 exercicios mistos)
- [x] Criar `XpCalculator`
- [x] Criar `HeartsManager`
- [x] Testes para validator, calculator e hearts
- [x] Testes para catalogo (cobertura de tipos)

### Sprint 3 — Lesson Controller

**Objetivo**: orquestracao do fluxo de licao

- [ ] Criar `LessonController` com ValueNotifiers
  - exercicio atual, resposta selecionada, feedback, vidas, XP, progresso
- [ ] Implementar fluxo: exibir → responder → feedback → proximo → resumo
- [ ] Integrar TTS para exercicios de audio
- [ ] Integrar STT para exercicios de fala
- [ ] Salvar progresso ao finalizar licao
- [ ] Testes completos do controller

### Sprint 4 — Learning Path Controller

**Objetivo**: orquestracao da trilha

- [ ] Criar `LearningPathController`
  - unidades, estado de desbloqueio, XP total, streak
- [ ] Implementar logica de desbloqueio progressivo
- [ ] Implementar calculo de crowns
- [ ] Integrar com `PracticeHubController` existente
- [ ] Testes para desbloqueio e progressao

### Sprint 5 — UI: Widgets de Exercicio

**Objetivo**: renderizar cada tipo de exercicio

- [ ] `ExerciseMultipleChoice` — redesign com cards coloridos
- [ ] `ExerciseListenAndSelect` — play button + opcoes
- [ ] `ExerciseListenAndType` — play + text field
- [ ] `ExerciseFillBlank` — texto com gap + chips
- [ ] `ExerciseWordOrder` — chips draggaveis (usar `Wrap` + `GestureDetector` ou `ReorderableListView`)
- [ ] `ExerciseTranslate` — frase + word bank
- [ ] `ExerciseMatchPairs` — grid interativo
- [ ] `ExerciseSpeakSentence` — frase + mic + accuracy bar
- [ ] `ExerciseTrueFalse` — dois botoes grandes
- [ ] `FeedbackOverlay` — fundo verde/vermelho animado
- [ ] `ProgressBarWidget` — barra fina no topo
- [ ] `HeartsDisplay` — icones de coracao

### Sprint 6 — UI: Lesson Page

**Objetivo**: tela principal de licao

- [ ] `LessonPage` com fluxo completo
  - progress bar, vidas, area de exercicio, botao CHECK/CONTINUE
- [ ] Renderizar exercicio correto baseado em `ExerciseType`
- [ ] Animacoes de transicao entre exercicios
- [ ] Feedback visual pos-resposta (overlay)
- [ ] `LessonSummaryPage` com animacao de XP e score
- [ ] Testes de widget para lesson page

### Sprint 7 — UI: Learning Path Page

**Objetivo**: tela da trilha

- [ ] `LearningPathPage` com scroll de bolhas conectadas
- [ ] `LessonNodeWidget` com estados (locked, available, completed, perfect)
- [ ] Banners de unidade entre grupos de bolhas
- [ ] Header com XP, streak, vidas
- [ ] Navegacao: tocar bolha → abre licao
- [ ] Integrar com rotas existentes e dashboard
- [ ] Testes de widget para trilha

### Sprint 8 — Conteudo Expandido

**Objetivo**: mais unidades

- [ ] Unidades 3-5 (Beginner): Getting Around, Daily Routine, Shopping
- [ ] Unidades 6-8 (Intermediate): Airport, At Work, Health
- [ ] Unidades 9-10 (Intermediate): Making Plans, Telling Stories
- [ ] Revisao de qualidade bilingue em todo conteudo
- [ ] Testes de integridade do catalogo

### Sprint 9 — Sons e Polish

**Objetivo**: experiencia sensorial

- [ ] Adicionar sons de acerto/erro/completo (assets audio)
- [ ] Haptic feedback em selecoes
- [ ] Animacoes de celebracao (Lottie) em licao perfeita
- [ ] Polir transicoes e micro-interacoes
- [ ] Dark mode support para telas novas
- [ ] Responsividade em diferentes tamanhos de tela

### Sprint 10 — Geracao por IA (Fase 2)

**Objetivo**: conteudo infinito

- [ ] `ExerciseGeneratorService` usando Gemini API
- [ ] Prompts estruturados para cada tipo de exercicio
- [ ] Validacao automatica da resposta gerada
- [ ] Cache local de exercicios gerados
- [ ] "Licao Surpresa" no hub: licao gerada on-the-fly por tema
- [ ] Testes para gerador e validacao

### Sprint 11 — Repeticao Espacada (Fase 3)

**Objetivo**: revisao inteligente

- [ ] `SpacedRepetitionService` com fila de revisao
- [ ] Rastrear exercicios errados com timestamps
- [ ] Inserir exercicios de revisao em licoes futuras
- [ ] "Revisao Diaria" como tipo de sessao no hub
- [ ] Testes para algoritmo de espacamento

### Sprint 12 — Integracao e Migracao

**Objetivo**: substituir pagina antiga

- [ ] Migrar link do dashboard para `/learning-path`
- [ ] Converter exercicios antigos do catalogo para formato novo
- [ ] Deprecar `reading_listening_page.dart` (manter como redirect)
- [ ] Atualizar `PracticeHubSheet` para refletir novo modulo
- [ ] Testes de integracao end-to-end
- [x] Atualizar NEXT_STEPS.md

---

## 9. Riscos e Mitigacoes

| Risco                                 | Mitigacao                                                 |
| ------------------------------------- | --------------------------------------------------------- |
| Muito conteudo manual                 | Fase 2 com geracao por IA resolve escalabilidade          |
| Drag-and-drop complexo em Flutter web | Usar chips clicaveis como fallback, drag apenas em mobile |
| Performance com muitas animacoes      | Lazy loading de unidades, limitar Lottie simultaneos      |
| Exercicios gerados por IA com erros   | Validacao automatica + opcao de reportar exercicio        |
| Migracao quebrar fluxo existente      | Arquivo ponte + redirect, testes de regressao             |
| Escopo grande demais                  | Sprints independentes, cada um entrega valor incremental  |

---

## 10. Metricas de Sucesso

- **Engajamento**: usuarios completam >= 3 licoes por semana
- **Retencao**: streak medio >= 5 dias
- **Aprendizado**: score medio sobe entre Unidade 1 e Unidade 5
- **Variedade**: usuarios interagem com >= 4 tipos de exercicio por sessao
- **Pronuncia**: accuracy media de speakTheSentence melhora ao longo do tempo

---

## 11. Prioridade de Implementacao (MVP)

Se for implementar incrementalmente, a ordem de maior valor eh:

1. **Sprint 1** (Domain) — base para tudo
2. **Sprint 2** (Catalogo + Validacao) — conteudo minimo jogavel
3. **Sprint 3** (Lesson Controller) — fluxo funcional
4. **Sprint 5** (Widgets) — UI dos exercicios
5. **Sprint 6** (Lesson Page) — tela jogavel completa
6. **Sprint 7** (Learning Path) — trilha visual
7. **Sprint 4** (Learning Path Controller) — progressao automatica
8. **Sprint 9** (Polish) — experiencia premium
9. **Sprint 8** (Conteudo) — expansao
10. **Sprint 10** (IA) — escala
11. **Sprint 11** (Repeticao) — retencao de longo prazo
12. **Sprint 12** (Migracao) — limpeza final

**MVP jogavel**: Sprints 1-3 + 5-6 (5 sprints) entregam uma licao funcional com tipos variados de exercicio, XP e vidas. Ja seria uma experiencia dramaticamente melhor que o atual.

---

_Criado em: 2026-03-11_
_Baseado na analise do modulo reading_listening atual do EnglishVoiceAIClean_
