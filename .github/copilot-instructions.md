# Copilot Instructions - EnglishVoiceAIClean

## Objetivo do Produto
Aplicativo de conversacao por voz com avatar que compreende e responde em `en-US` e `pt-BR`, com comportamento natural de assistente humano.

## Arquitetura Obrigatoria
Use esta estrutura para qualquer evolucao:

- `lib/features/voice_chat/presentation/`: telas, widgets e estados visuais
- `lib/features/voice_chat/application/`: orquestracao da conversa e regras de fluxo
- `lib/features/voice_chat/domain/`: entidades, enums e regras puras de negocio
- `lib/features/voice_chat/infrastructure/`: integracoes externas (STT, TTS, LLM, APIs)

## Regras de Conversacao Bilingue
- Sempre suportar `en_US` e `pt_BR`.
- Quando o modo for `auto`, tentar captacao em `en_US` e fallback em `pt_BR`.
- Detectar idioma da entrada para definir idioma da resposta.
- Responder no mesmo idioma do usuario, exceto quando ele pedir traducao ou troca de idioma.
- Se o usuario ficar em silencio por ciclos consecutivos de escuta, pausar a conversa automaticamente.
- Exibir acao clara para retomar a conversa apos pausa por inatividade.

## Regras de Avatar
- Avatar deve ter ao menos dois estados: `idle/listening` e `talking`.
- Trocar animacao conforme estado de TTS e STT.
- Nao ouvir enquanto o TTS estiver ativo para evitar eco.

## Regras de IA
- Prompt de sistema deve definir persona amigavel, objetiva e natural.
- Respostas curtas por padrao (1-4 frases), com tom conversacional humano.
- Se a entrada estiver em portugues, responder em portugues brasileiro.
- Se a entrada estiver em ingles, responder em ingles americano.
- Priorizar aprendizado de ingles: corrigir erros de forma gentil quando houver erro claro.
- Sempre manter a conversa ativa com uma pergunta curta de continuidade.
- Evitar markdown e listas na resposta falada para melhorar naturalidade do TTS.

## Padrao de Codigo
- Evitar logica de negocio em widgets.
- Evitar loop infinito sem cancelamento.
- Toda classe de servico externo deve ter interface clara e metodos assincronos.
- Incluir tratamento de erro com fallback amigavel para o usuario.

## Qualidade
Antes de finalizar alteracoes:
- garantir que imports antigos continuem funcionando (arquivos ponte quando necessario);
- validar que o fluxo voz -> IA -> voz nao bloqueia UI;
- validar comportamento em `en_US` e `pt_BR`.

## Nao Fazer
- Nao codificar idioma fixo unico.
- Nao acoplar STT, TTS e IA diretamente na tela.
- Nao remover estados de avatar durante a fala.
