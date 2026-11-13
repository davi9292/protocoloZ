# Protocolo Z — Flutter + Supabase

Aplicativo de sobrevivência multiplayer. O backend é a autoridade para inventário, reputação, facção, expedições, confirmações e trocas.

## Requisitos

- Flutter 3.24+ / Dart 3.4+
- Projeto Supabase
- Android Studio ou VS Code com extensão Flutter

## Configurar o Supabase

1. Crie um projeto em https://supabase.com.
2. Abra **SQL Editor** e execute, nesta ordem:
   - `supabase/001_schema.sql`
   - `supabase/002_security_rpc.sql`
   - `supabase/003_storage_realtime.sql`
3. Em **Authentication → URL Configuration**, ajuste as URLs conforme o ambiente de testes.
4. Em **Database → Replication**, confirme `horde_alerts` e `trades` na publicação `supabase_realtime`.
5. Em **Storage**, confirme o bucket `player-media`.
6. Copie a Project URL e a chave pública `anon` (ou publishable key compatível). Nunca use `service_role` no app.

## Executar

No terminal, na pasta do projeto:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://nzpespvxaqvxtqsrpvmu.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im56cGVzcHZ4YXF2eHRxc3Jwdm11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ1NDcxMTYsImV4cCI6MjExMDEyMzExNn0.110QGEpqjZZsRMhoQ0oY4E13ckvvLN8rG-61MAHCqas
```

Não coloque credenciais reais em arquivos versionados. `.env.example` é apenas um modelo de referência; o app lê `--dart-define`.

## Estrutura

- `lib/core`: tema, configuração, roteamento, providers e componentes.
- `lib/data/repositories`: acesso ao Supabase isolado das telas.
- `lib/features`: telas por funcionalidade.
- `supabase`: schema, RLS, RPC, Storage, Realtime e dados iniciais.

Riverpod mantém os estados consultados e invalida os providers após ações. GoRouter usa `StatefulShellRoute` para a navegação persistente e redireciona conforme autenticação e escolha de facção.

## Segurança e regras

A chave `service_role` não é necessária no cliente. RLS está habilitada em todas as tabelas. O cliente não recebe permissão de escrita direta no inventário, reputação, facção, trocas ou confirmações. As operações protegidas passam por RPC `SECURITY DEFINER`, validando `auth.uid()`.

| Ação | Reputação |
|---|---:|
| Expedição concluída | +10 |
| Abrigo cadastrado | +15 |
| Troca concluída | +20 para cada jogador |
| Alerta confirmado por dois jogadores | +25 para o autor |

Expedições duram entre 1 e 3 minutos para facilitar a demonstração. Trocas expiram em 24 horas e alertas em 30 minutos, pelo relógio do banco.

## Demonstração com dois jogadores

1. Crie duas contas em dispositivos/emuladores diferentes.
2. Jogador A escolhe Sentinelas; jogador B escolhe Errantes.
3. A cadastra um abrigo com visibilidade `faction`. B não deve conseguir consultá-lo.
4. A inicia uma expedição, encerra o app, reabre e coleta após o prazo.
5. B cria um alerta; A consulta/recebe o registro e confirma. Uma segunda conta diferente também confirma para disparar os +25 ao autor.
6. A cria uma proposta de troca direcionada ao UUID de B; B aceita pela RPC `respond_trade(p_trade_id, 'accept')`.
7. Verifique que updates diretos em `inventory` e nas colunas `reputation`/`faction_id` de `profiles` são negados.
8. Confira rankings, perfil e inventário após entrar novamente.

## Observações importantes de integração

- A URL do mapa usa OpenStreetMap. Em produção, respeite a política de uso dos tiles e configure identificação adequada do aplicativo.
- A localização do mapa inicia em uma posição de demonstração; o usuário pode usar GPS ou tocar no mapa para selecionar manualmente.
- O app usa Storage para upload de avatar e imagem de abrigo.
- Para ações de troca, use `respond_trade` via RPC para aceitar/recusar/cancelar. A tela de lista é a área de consulta das propostas.
- As políticas SQL devem ser revisadas no painel do Supabase após execução, especialmente caso o projeto já tenha policies/publication anteriores.

## Limitações desta entrega

O ambiente de geração não possui Flutter/Dart instalado nem credenciais de um projeto Supabase. Portanto, não foi possível executar `flutter analyze`, compilar no Android/iOS, aplicar as migrations em uma instância real ou validar o Realtime entre dois dispositivos. O código e os scripts foram preparados para configuração e validação local; não declare a integração como testada antes de executar os passos acima.
