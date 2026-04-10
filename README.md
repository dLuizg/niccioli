# Niccioli - Gestão Inteligente de Transporte Universitário

O **Niccioli** é um ecossistema digital desenvolvido em Flutter para modernizar a gestão de transporte universitário fretado. O projeto foca em três pilares fundamentais: eficiência logística através de IA, engajamento em tempo real dos estudantes e segurança jurídica na formalização de contratos via GOV.br.

## 🚀 Principais Funcionalidades

### 1. Gestão de Presença Dinâmica
*   **Controle de Fluxo:** Alunos podem marcar status de "Vou" ou "Não Vou" diariamente.
*   **Reversibilidade:** Possibilidade de alterar a marcação até o horário de fechamento da rota.
*   **Sincronização em Tempo Real:** Atualização instantânea para o motorista via canais de presença.
*   **Motorista compartilha a localização em tempo real** Compartilhamento do lado do motorista para os alunos se prepararem para esperar a van / ônibus.
*   **Checkin no Transporte** O aplicativo também enviará notificações ao final da aula da faculdade perguntando se o aluno já está na van, no momento  que todos chegarem o motorista poderá partir, evitando de fazer uma "chamada" com a lista.

### 2. Otimização de Rotas com IA
*   **Algoritmo VRPPD:** Resolução do Problema de Roteamento de Veículos com Coleta e Entrega (Pickup and Delivery).
*   **Re-roteamento Dinâmico:** A IA reorganiza a sequência de paradas automaticamente conforme as confirmações ou cancelamentos do dia, minimizando o tempo de trajeto e consumo de combustível.

### 3. Formalização e Contratos
*   **Assinatura GOV.br:** Liberar o contrato através do aplicativo através de um .docx recomendando a assinatura através do GOV.br.
*   **Gestão de Documentos:** Armazenamento seguro de contratos e documentos obrigatórios (CNH, alvarás da EMTU/Prefeitura).

### 4. Comunicação e Notificações
*   **Lembretes Inteligentes:** Notificações push automáticas para que os alunos não esqueçam de confirmar a presença.
*   **Alertas de Proximidade:** Aviso ao estudante quando o veículo está indo ao ponto de embarque.

## 📂 Estrutura do Projeto

niccioli/
├── lib/
│   ├── modules/
│   │   ├── auth/          # Login e integração GOV.br
│   │   ├── attendance/    # Gestão de presença "Vou/Não Vou"
│   │   ├── contracts/     # Assinatura digital e PDF
│   │   └── route_map/     # Mapas e visualização da rota IA
│   ├── shared/            # Widgets e componentes reutilizáveis
│   └── main.dart
├── backend/               # Microserviço para a IA
└── README.md

## 📋 Pré-requisitos e Instalação

1.  **Ambiente Flutter:** Certifique-se de ter o Flutter SDK (v3.22+) instalado.
2.  **Configuração Supabase:** Crie um projeto no Supabase e configure as chaves `SUPABASE_URL` e `SUPABASE_ANON_KEY` no seu arquivo de ambiente.
3.  **Dependências:**
    ```bash
    flutter pub get
    ```
4.  **Execução:**
    ```bash
    flutter run
    ```

## ⚖️ Conformidade Legal

O aplicativo foi desenhado para atender às exigências da **Lei nº 14.063/2020** (Assinaturas Digitais) e às regulamentações de transporte fretado da **EMTU** e prefeituras locais, como a de São João da Boa Vista (Decreto nº 7.683/2024).