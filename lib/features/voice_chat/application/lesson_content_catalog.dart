import '../domain/entities/exercise_type.dart';
import '../domain/entities/learning_unit.dart';
import '../domain/entities/lesson.dart';
import '../domain/entities/lesson_exercise.dart';
import '../domain/entities/reading_listening_exercise.dart';

class LessonContentCatalog {
  List<LearningUnit> loadDefaultUnits() {
    return <LearningUnit>[
      LearningUnit(
        id: 'unit_greetings',
        titleEn: 'Greetings',
        titlePt: 'Cumprimentos',
        iconAsset: 'assets/images/scenes/studio_scene.png',
        orderIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
        lessons: <Lesson>[
          Lesson(
            id: 'lesson_greetings_1',
            unitId: 'unit_greetings',
            orderIndex: 0,
            exercises: <LessonExercise>[
              _optionExercise(
                id: 'g_1_1',
                type: ExerciseType.multipleChoice,
                promptEn: 'Good morning! How are you?',
                promptPt: 'Bom dia! Como voce esta?',
                optionsEn: const <String>[
                  'I am fine, thanks.',
                  'Blue.',
                  'Tomorrow.'
                ],
                optionsPt: const <String>[
                  'Estou bem, obrigado.',
                  'Azul.',
                  'Amanha.'
                ],
                correctOptionIndex: 0,
              ),
              _optionExercise(
                id: 'g_1_2',
                type: ExerciseType.listenAndSelect,
                promptEn: 'Nice to meet you.',
                promptPt: 'Prazer em conhecer voce.',
                optionsEn: const <String>[
                  'Nice to meet you.',
                  'See you yesterday.',
                  'Where is my bag?'
                ],
                optionsPt: const <String>[
                  'Prazer em conhecer voce.',
                  'Te vejo ontem.',
                  'Onde esta minha bolsa?'
                ],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'g_1_3',
                type: ExerciseType.listenAndType,
                promptEn: 'Type what you hear: Hello, my name is Anna.',
                promptPt: 'Digite o que voce ouviu: Ola, meu nome e Anna.',
                acceptedAnswers: const <String>[
                  'Hello my name is Anna',
                  'Hello, my name is Anna'
                ],
              ),
              _wordOrderExercise(
                id: 'g_1_4',
                promptEn: 'Order the words to greet politely.',
                promptPt: 'Ordene as palavras para cumprimentar com educacao.',
                correctTokens: const <String>['good', 'afternoon', 'everyone'],
              ),
              _trueFalseExercise(
                id: 'g_1_5',
                promptEn: 'True or false: "Good evening" is used at night.',
                promptPt:
                    'Verdadeiro ou falso: "Good evening" e usado a noite.',
                correctAnswer: true,
              ),
              _speakExercise(
                id: 'g_1_6',
                promptEn: 'Say: Nice to meet you, I am Carlos.',
                promptPt: 'Fale: Prazer em conhecer voce, eu sou Carlos.',
                referenceText: 'Nice to meet you I am Carlos',
              ),
            ],
          ),
          Lesson(
            id: 'lesson_greetings_2',
            unitId: 'unit_greetings',
            orderIndex: 1,
            exercises: <LessonExercise>[
              _optionExercise(
                id: 'g_2_1',
                type: ExerciseType.fillInTheBlank,
                promptEn: 'Complete: ___ evening, teacher.',
                promptPt: 'Complete: ___ evening, teacher.',
                optionsEn: const <String>['Good', 'Soon', 'Late'],
                optionsPt: const <String>['Good', 'Soon', 'Late'],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'g_2_2',
                type: ExerciseType.translate,
                promptEn: 'Translate: Bom te ver novamente.',
                promptPt: 'Traduza: Bom te ver novamente.',
                acceptedAnswers: const <String>['Good to see you again'],
              ),
              _matchPairsExercise(
                id: 'g_2_3',
                promptEn: 'Match each greeting.',
                promptPt: 'Conecte cada cumprimento.',
                pairs: const <String, String>{
                  'good morning': 'bom dia',
                  'good night': 'boa noite',
                  'see you later': 'ate mais',
                },
              ),
              _optionExercise(
                id: 'g_2_4',
                type: ExerciseType.listenAndSelect,
                promptEn: 'How was your day?',
                promptPt: 'Como foi seu dia?',
                optionsEn: const <String>[
                  'How was your day?',
                  'Where is your day?',
                  'How old are day?'
                ],
                optionsPt: const <String>[
                  'Como foi seu dia?',
                  'Onde esta seu dia?',
                  'Quantos anos dia?'
                ],
                correctOptionIndex: 0,
              ),
              _trueFalseExercise(
                id: 'g_2_5',
                promptEn: 'True or false: "See you later" is a farewell.',
                promptPt: 'Verdadeiro ou falso: "See you later" e despedida.',
                correctAnswer: true,
              ),
              _speakExercise(
                id: 'g_2_6',
                promptEn: 'Say: Good evening, nice to see you again.',
                promptPt: 'Fale: Good evening, nice to see you again.',
                referenceText: 'Good evening nice to see you again',
              ),
            ],
          ),
          Lesson(
            id: 'lesson_greetings_3',
            unitId: 'unit_greetings',
            orderIndex: 2,
            exercises: <LessonExercise>[
              _textExercise(
                id: 'g_3_1',
                type: ExerciseType.listenAndType,
                promptEn: 'Type what you hear: See you tomorrow at school.',
                promptPt:
                    'Digite o que voce ouviu: Vejo voce amanha na escola.',
                acceptedAnswers: const <String>['See you tomorrow at school'],
              ),
              _wordOrderExercise(
                id: 'g_3_2',
                promptEn: 'Order: you / later / see',
                promptPt: 'Ordene: you / later / see',
                correctTokens: const <String>['see', 'you', 'later'],
              ),
              _optionExercise(
                id: 'g_3_3',
                type: ExerciseType.multipleChoice,
                promptEn: 'Choose a polite opening.',
                promptPt: 'Escolha uma abertura educada.',
                optionsEn: const <String>[
                  'Excuse me, can I ask?',
                  'Give me that now.',
                  'No way.'
                ],
                optionsPt: const <String>[
                  'Com licenca, posso perguntar?',
                  'Me de isso agora.',
                  'De jeito nenhum.'
                ],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'g_3_4',
                type: ExerciseType.translate,
                promptEn: 'Translate: Ate logo, tenha um bom dia.',
                promptPt: 'Traduza: Ate logo, tenha um bom dia.',
                acceptedAnswers: const <String>[
                  'See you later have a good day',
                  'See you later, have a good day'
                ],
              ),
              _matchPairsExercise(
                id: 'g_3_5',
                promptEn: 'Match phrase and meaning.',
                promptPt: 'Conecte frase e significado.',
                pairs: const <String, String>{
                  'how are you': 'como voce esta',
                  'goodbye': 'tchau',
                  'long time no see': 'quanto tempo',
                },
              ),
              _trueFalseExercise(
                id: 'g_3_6',
                promptEn: 'True or false: "Hello" is informal only.',
                promptPt: 'Verdadeiro ou falso: "Hello" e apenas informal.',
                correctAnswer: false,
              ),
            ],
          ),
        ],
      ),
      LearningUnit(
        id: 'unit_cafe',
        titleEn: 'At a Cafe',
        titlePt: 'Na Cafeteria',
        iconAsset: 'assets/images/scenes/city_scene.png',
        orderIndex: 1,
        difficulty: ReadingListeningDifficulty.beginner,
        lessons: <Lesson>[
          Lesson(
            id: 'lesson_cafe_1',
            unitId: 'unit_cafe',
            orderIndex: 0,
            exercises: <LessonExercise>[
              _optionExercise(
                id: 'c_1_1',
                type: ExerciseType.multipleChoice,
                promptEn: 'I would like a small coffee, please.',
                promptPt: 'Eu gostaria de um cafe pequeno, por favor.',
                optionsEn: const <String>[
                  'A small coffee',
                  'A train ticket',
                  'A hospital bed'
                ],
                optionsPt: const <String>[
                  'Um cafe pequeno',
                  'Uma passagem de trem',
                  'Uma cama de hospital'
                ],
                correctOptionIndex: 0,
              ),
              _optionExercise(
                id: 'c_1_2',
                type: ExerciseType.listenAndSelect,
                promptEn: 'Can I have the menu, please?',
                promptPt: 'Posso ver o cardapio, por favor?',
                optionsEn: const <String>[
                  'Can I have the menu, please?',
                  'Can I have your shoes?',
                  'Can I have your car?'
                ],
                optionsPt: const <String>[
                  'Posso ver o cardapio, por favor?',
                  'Posso ver seus sapatos?',
                  'Posso ver seu carro?'
                ],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'c_1_3',
                type: ExerciseType.listenAndType,
                promptEn: 'Type: One cappuccino with oat milk.',
                promptPt: 'Digite: Um cappuccino com leite de aveia.',
                acceptedAnswers: const <String>['One cappuccino with oat milk'],
              ),
              _optionExercise(
                id: 'c_1_4',
                type: ExerciseType.fillInTheBlank,
                promptEn: 'Complete: I will pay by ___.',
                promptPt: 'Complete: I will pay by ___.',
                optionsEn: const <String>['card', 'banana', 'window'],
                optionsPt: const <String>['card', 'banana', 'window'],
                correctOptionIndex: 0,
              ),
              _wordOrderExercise(
                id: 'c_1_5',
                promptEn: 'Order: like / tea / would / I',
                promptPt: 'Ordene: like / tea / would / I',
                correctTokens: const <String>['i', 'would', 'like', 'tea'],
              ),
              _speakExercise(
                id: 'c_1_6',
                promptEn: 'Say: Could I get a table for two?',
                promptPt: 'Fale: Could I get a table for two?',
                referenceText: 'Could I get a table for two',
              ),
            ],
          ),
          Lesson(
            id: 'lesson_cafe_2',
            unitId: 'unit_cafe',
            orderIndex: 1,
            exercises: <LessonExercise>[
              _textExercise(
                id: 'c_2_1',
                type: ExerciseType.translate,
                promptEn: 'Translate: Quero um suco de laranja sem gelo.',
                promptPt: 'Traduza: Quero um suco de laranja sem gelo.',
                acceptedAnswers: const <String>[
                  'I want an orange juice without ice',
                  'I would like an orange juice without ice'
                ],
              ),
              _matchPairsExercise(
                id: 'c_2_2',
                promptEn: 'Match cafe terms.',
                promptPt: 'Conecte termos da cafeteria.',
                pairs: const <String, String>{
                  'bill': 'conta',
                  'table': 'mesa',
                  'waiter': 'garcom',
                },
              ),
              _trueFalseExercise(
                id: 'c_2_3',
                promptEn: 'True or false: "To go" means take-away.',
                promptPt: 'Verdadeiro ou falso: "To go" significa para viagem.',
                correctAnswer: true,
              ),
              _optionExercise(
                id: 'c_2_4',
                type: ExerciseType.listenAndSelect,
                promptEn: 'Do you have any vegan desserts?',
                promptPt: 'Voce tem sobremesas veganas?',
                optionsEn: const <String>[
                  'Do you have any vegan desserts?',
                  'Do you have any phones?',
                  'Do you have a bus?'
                ],
                optionsPt: const <String>[
                  'Voce tem sobremesas veganas?',
                  'Voce tem telefones?',
                  'Voce tem um onibus?'
                ],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'c_2_5',
                type: ExerciseType.listenAndType,
                promptEn: 'Type: The espresso is too bitter for me.',
                promptPt: 'Digite: O espresso esta amargo demais para mim.',
                acceptedAnswers: const <String>[
                  'The espresso is too bitter for me'
                ],
              ),
              _optionExercise(
                id: 'c_2_6',
                type: ExerciseType.fillInTheBlank,
                promptEn: 'Complete: Could you bring the ___, please?',
                promptPt: 'Complete: Could you bring the ___, please?',
                optionsEn: const <String>['bill', 'cloud', 'helmet'],
                optionsPt: const <String>['bill', 'cloud', 'helmet'],
                correctOptionIndex: 0,
              ),
            ],
          ),
          Lesson(
            id: 'lesson_cafe_3',
            unitId: 'unit_cafe',
            orderIndex: 2,
            exercises: <LessonExercise>[
              _wordOrderExercise(
                id: 'c_3_1',
                promptEn: 'Order: order / I / ready / to / am',
                promptPt: 'Ordene: order / I / ready / to / am',
                correctTokens: const <String>[
                  'i',
                  'am',
                  'ready',
                  'to',
                  'order'
                ],
              ),
              _speakExercise(
                id: 'c_3_2',
                promptEn: 'Say: I would like this sandwich without cheese.',
                promptPt: 'Fale: I would like this sandwich without cheese.',
                referenceText: 'I would like this sandwich without cheese',
              ),
              _optionExercise(
                id: 'c_3_3',
                type: ExerciseType.multipleChoice,
                promptEn: 'Which response is polite to call the waiter?',
                promptPt: 'Qual resposta e educada para chamar o garcom?',
                optionsEn: const <String>[
                  'Excuse me, could you help me?',
                  'Come here now!',
                  'You there!'
                ],
                optionsPt: const <String>[
                  'Com licenca, voce pode me ajudar?',
                  'Venha aqui agora!',
                  'Ei, voce!'
                ],
                correctOptionIndex: 0,
              ),
              _textExercise(
                id: 'c_3_4',
                type: ExerciseType.translate,
                promptEn: 'Translate: A conta, por favor.',
                promptPt: 'Traduza: A conta, por favor.',
                acceptedAnswers: const <String>[
                  'The bill please',
                  'The check please'
                ],
              ),
              _matchPairsExercise(
                id: 'c_3_5',
                promptEn: 'Match phrase to intent.',
                promptPt: 'Conecte frase com intencao.',
                pairs: const <String, String>{
                  'for here': 'consumir no local',
                  'to go': 'para viagem',
                  'sparkling water': 'agua com gas',
                },
              ),
              _trueFalseExercise(
                id: 'c_3_6',
                promptEn:
                    'True or false: "Refill" means more of the same drink.',
                promptPt:
                    'Verdadeiro ou falso: "Refill" significa mais da mesma bebida.',
                correctAnswer: true,
              ),
            ],
          ),
        ],
      ),
    ];
  }

  LessonExercise _optionExercise({
    required String id,
    required ExerciseType type,
    required String promptEn,
    required String promptPt,
    required List<String> optionsEn,
    required List<String> optionsPt,
    required int correctOptionIndex,
  }) {
    return LessonExercise(
      id: id,
      type: type,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'optionsEn': optionsEn,
        'optionsPt': optionsPt,
        'correctOptionIndex': correctOptionIndex,
      },
    );
  }

  LessonExercise _textExercise({
    required String id,
    required ExerciseType type,
    required String promptEn,
    required String promptPt,
    required List<String> acceptedAnswers,
  }) {
    return LessonExercise(
      id: id,
      type: type,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'acceptedAnswers': acceptedAnswers,
      },
    );
  }

  LessonExercise _wordOrderExercise({
    required String id,
    required String promptEn,
    required String promptPt,
    required List<String> correctTokens,
  }) {
    return LessonExercise(
      id: id,
      type: ExerciseType.wordOrder,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'correctTokens': correctTokens,
      },
    );
  }

  LessonExercise _matchPairsExercise({
    required String id,
    required String promptEn,
    required String promptPt,
    required Map<String, String> pairs,
  }) {
    return LessonExercise(
      id: id,
      type: ExerciseType.matchPairs,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'correctPairs': pairs,
      },
    );
  }

  LessonExercise _speakExercise({
    required String id,
    required String promptEn,
    required String promptPt,
    required String referenceText,
  }) {
    return LessonExercise(
      id: id,
      type: ExerciseType.speakTheSentence,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'referenceText': referenceText,
        'minAccuracy': 85,
      },
    );
  }

  LessonExercise _trueFalseExercise({
    required String id,
    required String promptEn,
    required String promptPt,
    required bool correctAnswer,
  }) {
    return LessonExercise(
      id: id,
      type: ExerciseType.trueOrFalse,
      difficulty: ReadingListeningDifficulty.beginner,
      content: <String, dynamic>{
        'promptEn': promptEn,
        'promptPt': promptPt,
        'correctAnswer': correctAnswer,
      },
    );
  }
}
