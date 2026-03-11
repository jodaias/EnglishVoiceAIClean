import '../domain/entities/reading_listening_exercise.dart';

class ReadingListeningCatalog {
  List<ReadingListeningExercise> loadDefault() {
    return const <ReadingListeningExercise>[
      ReadingListeningExercise(
        id: 'airport_gate',
        titleEn: 'At the airport',
        titlePt: 'No aeroporto',
        readingTextEn:
            'Excuse me, could you tell me where gate twelve is? My flight starts boarding in fifteen minutes.',
        readingTextPt:
            'Com licença, você poderia me dizer onde fica o portão doze? Meu voo começa o embarque em quinze minutos.',
        questionEn: 'What does the speaker need right now?',
        questionPt: 'O que a pessoa precisa agora?',
        optionsEn: <String>[
          'Find the departure gate',
          'Change the flight date',
          'Buy a bus ticket',
        ],
        optionsPt: <String>[
          'Encontrar o portão de embarque',
          'Trocar a data do voo',
          'Comprar uma passagem de ônibus',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'coffee_shop',
        titleEn: 'Coffee shop order',
        titlePt: 'Pedido na cafeteria',
        readingTextEn:
            'Hi, can I get a large cappuccino with oat milk and no sugar, please?',
        readingTextPt:
            'Oi, posso pegar um cappuccino grande com leite de aveia e sem açúcar, por favor?',
        questionEn: 'How does the customer want the drink?',
        questionPt: 'Como o cliente quer a bebida?',
        optionsEn: <String>[
          'Large, with oat milk, no sugar',
          'Small, regular milk, extra sugar',
          'Large, with soy milk, extra foam',
        ],
        optionsPt: <String>[
          'Grande, com leite de aveia e sem açúcar',
          'Pequeno, leite comum e com açúcar extra',
          'Grande, com leite de soja e espuma extra',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'team_meeting',
        titleEn: 'Team meeting',
        titlePt: 'Reuniao de equipe',
        readingTextEn:
            'I finished the design draft yesterday, and I will share it with the team right after lunch.',
        readingTextPt:
            'Eu terminei o rascunho do design ontem e vou compartilhar com a equipe logo após o almoço.',
        questionEn: 'When will the design draft be shared?',
        questionPt: 'Quando o rascunho sera compartilhado?',
        optionsEn: <String>[
          'Right after lunch',
          'Early tomorrow morning',
          'Before breakfast today',
        ],
        optionsPt: <String>[
          'Logo após o almoço',
          'Amanhã cedo',
          'Antes do café da manha de hoje',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.intermediate,
      ),
      ReadingListeningExercise(
        id: 'doctor_visit',
        titleEn: 'Doctor appointment',
        titlePt: 'Consulta médica',
        readingTextEn:
            'I have had a sore throat for three days, and it gets worse at night.',
        readingTextPt:
            'Estou com dor de garganta ha três dias e piora durante a noite.',
        questionEn: 'What symptom is described?',
        questionPt: 'Qual sintoma foi descrito?',
        optionsEn: <String>[
          'A sore throat',
          'A strong back pain',
          'A skin allergy',
        ],
        optionsPt: <String>[
          'Dor de garganta',
          'Dor forte nas costas',
          'Alergia na pele',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'weekend_plan',
        titleEn: 'Weekend plan',
        titlePt: 'Plano para o fim de semana',
        readingTextEn:
            'If the weather is good on Saturday, we are going hiking near the lake.',
        readingTextPt:
            'Se o tempo estiver bom no sábado, vamos fazer trilha perto do lago.',
        questionEn: 'What is the weekend activity?',
        questionPt: 'Qual e a atividade do fim de semana?',
        optionsEn: <String>[
          'Go hiking near the lake',
          'Visit a museum downtown',
          'Stay home all day',
        ],
        optionsPt: <String>[
          'Fazer trilha perto do lago',
          'Visitar um museu no centro',
          'Ficar em casa o dia todo',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.intermediate,
      ),
      ReadingListeningExercise(
        id: 'hotel_checkin',
        titleEn: 'Hotel check-in',
        titlePt: 'Check-in no hotel',
        readingTextEn:
            'Good evening. I have a reservation under the name Johnson for two nights. Could I also get a room with a view of the city?',
        readingTextPt:
            'Boa noite. Tenho uma reserva no nome Johnson para duas noites. Seria possível um quarto com vista para a cidade?',
        questionEn: 'What does the guest request besides the reservation?',
        questionPt: 'O que o hóspede pede alem da reserva?',
        optionsEn: <String>[
          'A room with a city view',
          'A late checkout',
          'An extra bed',
        ],
        optionsPt: <String>[
          'Um quarto com vista para a cidade',
          'Um checkout tardio',
          'Uma cama extra',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'grocery_shopping',
        titleEn: 'Grocery shopping',
        titlePt: 'Compras no supermercado',
        readingTextEn:
            'We need eggs, bread, and orange juice. Oh, and grab some bananas if they look fresh.',
        readingTextPt:
            'Precisamos de ovos, pao e suco de laranja. Ah, e pegue algumas bananas se estiverem frescas.',
        questionEn: 'What is the condition for buying bananas?',
        questionPt: 'Qual e a condição para comprar bananas?',
        optionsEn: <String>[
          'They must look fresh',
          'They must be on sale',
          'They must be organic',
        ],
        optionsPt: <String>[
          'Devem estar frescas',
          'Devem estar em promoção',
          'Devem ser orgânicas',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'job_interview',
        titleEn: 'Job interview',
        titlePt: 'Entrevista de emprego',
        readingTextEn:
            'I worked as a software developer for three years, and I am looking for a role where I can lead a small team.',
        readingTextPt:
            'Trabalhei como desenvolvedor de software por três anos e estou procurando uma vaga onde eu possa liderar uma equipe pequena.',
        questionEn: 'What kind of role is the person looking for?',
        questionPt: 'Que tipo de vaga a pessoa esta procurando?',
        optionsEn: <String>[
          'A team leadership position',
          'A remote freelance contract',
          'An entry-level internship',
        ],
        optionsPt: <String>[
          'Uma posição de liderança de equipe',
          'Um contrato freelance remoto',
          'Um estágio de nível iniciante',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.intermediate,
      ),
      ReadingListeningExercise(
        id: 'weather_chat',
        titleEn: 'Weather chat',
        titlePt: 'Conversa sobre o tempo',
        readingTextEn:
            'It has been raining all week, but the forecast says it will be sunny this weekend. Perfect for a barbecue!',
        readingTextPt:
            'Choveu a semana inteira, mas a previsão diz que vai fazer sol neste fim de semana. Perfeito para um churrasco!',
        questionEn: 'What is the weather expected to be this weekend?',
        questionPt: 'Como deve ficar o tempo neste fim de semana?',
        optionsEn: <String>[
          'Sunny',
          'Rainy and cold',
          'Cloudy with strong wind',
        ],
        optionsPt: <String>[
          'Ensolarado',
          'Chuvoso e frio',
          'Nublado com vento forte',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'restaurant_complaint',
        titleEn: 'Restaurant complaint',
        titlePt: 'Reclamação no restaurante',
        readingTextEn:
            'Excuse me, I ordered the grilled salmon twenty minutes ago and it still has not arrived. Could you check on that for me?',
        readingTextPt:
            'Com licença, eu pedi o salmão grelhado há vinte minutos e ainda não chegou. Poderia verificar para mim?',
        questionEn: 'What is the customer complaining about?',
        questionPt: 'Sobre o que o cliente esta reclamando?',
        optionsEn: <String>[
          'The food is taking too long',
          'The food was cold',
          'The bill is wrong',
        ],
        optionsPt: <String>[
          'A comida esta demorando demais',
          'A comida estava fria',
          'A conta esta errada',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'giving_directions',
        titleEn: 'Giving directions',
        titlePt: 'Dando direções',
        readingTextEn:
            'Go straight for two blocks, then turn left at the pharmacy. The library will be on your right, next to the park.',
        readingTextPt:
            'Siga reto por dois quarteirões, depois vire a esquerda na farmacia. A biblioteca vai estar a sua direita, ao lado do parque.',
        questionEn: 'Where is the library?',
        questionPt: 'Onde fica a biblioteca?',
        optionsEn: <String>[
          'On the right, next to the park',
          'Behind the pharmacy',
          'Across from the bus station',
        ],
        optionsPt: <String>[
          'A direita, ao lado do parque',
          'Atrás da farmacia',
          'Em frente a rodoviária',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.beginner,
      ),
      ReadingListeningExercise(
        id: 'phone_call_reschedule',
        titleEn: 'Rescheduling by phone',
        titlePt: 'Remarcando por telefone',
        readingTextEn:
            'Hi, I am calling to reschedule my appointment from Thursday to Friday afternoon. Would three o\'clock work?',
        readingTextPt:
            'Oi, estou ligando para remarcar minha consulta de quinta-feira para sexta-feira a tarde. Três horas seria possível?',
        questionEn: 'What time does the caller suggest?',
        questionPt: 'Que horario o interlocutor sugere?',
        optionsEn: <String>[
          'Three o\'clock on Friday',
          'Thursday morning',
          'Five o\'clock on Saturday',
        ],
        optionsPt: <String>[
          'Três horas na sexta',
          'Quinta-feira de manha',
          'Cinco horas no sábado',
        ],
        correctOptionIndex: 0,
        difficulty: ReadingListeningDifficulty.intermediate,
      ),
    ];
  }
}
