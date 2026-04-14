## Regra de Negócio (RN) – Niciolli

### RN01 — Confirmação de Presença

* **Prazo Limite:** O aluno deve confirmar sua presença ou ausência para o trajeto (Ida/Volta) até um horário limite estipulado pelo administrador (ex: até as 17:00 para o turno da noite).
* **Status Padrão:** Caso o aluno não se manifeste até o horário limite, o sistema deve assumir um status padrão (ex: "Não comparecerá") para não prejudicar a rota do motorista.
* **Alteração de Fluxo:** O sistema só deve permitir a alteração do status após o prazo limite mediante autorização direta do motorista ou administrador via chat/chamada.

### RN02 — Inteligência de Rota (Assistente de IA)
* **Priorização:** A sequência de busca sugerida pela IA (RF05) deve priorizar o menor tempo de percurso, considerando apenas os alunos que confirmaram presença no **RF04**.
* **Capacidade do Veículo:** O sistema não deve permitir que o número de presenças confirmadas exceda a capacidade de assentos registrados para o veículo daquela rota.

### RN03 — Assinatura de Contrato e Acesso
* **Bloqueio por Pendência:** Alunos que não assinaram o contrato digital (conforme lembrete do RF04) podem ter seu acesso à confirmação de presença bloqueado após um período de carência de X dias.
* **Validade Jurídica:** O sistema deve registrar o IP, data e hora no momento da aceitação do contrato para fins de auditoria e validade legal.

### RN04 — Gestão de Dados e LGPD
* **Exclusão de Dados:** Ao solicitar a exclusão definitiva (RNF06), o sistema deve anonimizar os dados em relatórios históricos (CSV/PDF) para manter a integridade financeira do administrador, mas remover qualquer identificação pessoal (Nome, CPF, Telefone) do banco de dados ativo.
* **Retenção de Logs:** Os logs de presença (RNF09) devem ser armazenados por no mínimo 6 meses para fins de prestação de contas, sendo apagados automaticamente após esse período, salvo disposição contrária em contrato.

### RN05 — Funcionamento Offline
* **Sincronização de Dados:** Caso o motorista registre uma presença ou alteração em modo offline (RNF08), o sistema deve realizar o "merge" (sincronização) dos dados assim que detectar uma conexão estável, priorizando sempre a marcação mais recente com timestamp.

### RN06 — Controle de passageiros
* **Liberação de retorno:** Os alunos só poderão fazer checkin na van na saída da faculdade caso tenho dado retorno positivo sobre o retorno dentro do aplicativo.
* **Autorização para retorno:** O motorista só poderá dar início ao retorno para a cidade de origem após a aula com a presença de todos os alunos ou após dez minutos após o horário do término da aula.
