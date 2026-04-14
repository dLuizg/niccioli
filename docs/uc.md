# Casos de Uso do Sistema Niccioli

## UC01 — Realizar Login e Acesso Social
**Ator Principal:** Usuário (Aluno ou Motorista)
**Objetivo:** Permitir acesso seguro via e-mail/senha ou provedores externos.
**Pré-condições:** App instalado e conexão com internet.
**Pós-condições:** Sessão iniciada com token JWT (conforme RNF02).

**Fluxo Principal:**
1. O usuário escolhe entre Login Tradicional ou Social (Google/Apple).
2. O sistema valida as credenciais ou o token do provedor.
3. O sistema identifica o perfil (Aluno/Motorista) e redireciona para o dashboard específico.

**Fluxos Alternativos:**
- **A1 — Primeiro Acesso:** O sistema solicita a escolha de perfil e preenchimento de dados complementares.

---

## UC02 — Gerenciar Presença Diária (Check-in)
**Ator Principal:** Aluno
**Objetivo:** Informar se utilizará o transporte na ida, volta ou ambos.
**Pré-condições:** Aluno estar com contrato ativo.
**Pós-condições:** Lista do motorista atualizada em tempo real.

**Fluxo Principal:**
1. O aluno acessa a tela de presença.
2. O aluno marca "Sim" ou "Não" para o trajeto de Ida e de Volta.
3. O sistema registra o timestamp e atualiza a lista de passageiros do motorista.

**Fluxos Alternativos:**
- **A1 — Fora do Horário Limite:** O sistema bloqueia a alteração e exibe mensagem para contatar o motorista diretamente.

---

## UC03 — Gerenciar Perfil e Veículo
**Ator Principal:** Usuário
**Objetivo:** Manter dados cadastrais e informações da Van atualizados.
**Pré-condições:** Usuário logado.
**Pós-condições:** Banco de dados atualizado.

**Fluxo Principal:**
1. O usuário edita seus dados (nome, foto, ponto padrão).
2. **Se Motorista:** O usuário informa/edita a placa e modelo da Van atual.
3. O sistema salva as alterações.

---

## UC04 — Solicitar Ponto Alternativo
**Ator Principal:** Aluno / **Ator Secundário:** Motorista
**Objetivo:** Permitir que o aluno peça para ser pego fora do ponto padrão.
**Pré-condições:** Existir uma rota ativa para o dia.

**Fluxo Principal:**
1. O aluno seleciona a opção "Ponto Alternativo" e envia a localização.
2. O motorista recebe uma notificação na próxima parada.
3. O motorista visualiza o ponto no mapa e seleciona **"Aprovar"** ou **"Negar"**.
4. O aluno é notificado da decisão.

---

## UC05 — Monitoramento e Geofencing (Automático)
**Ator Principal:** Motorista / **Ator Secundário:** Aluno
**Objetivo:** Notificar a chegada e registrar atrasos automaticamente via GPS.
**Pré-condições:** Motorista com localização do celular ativa.

**Fluxo Principal:**
1. O motorista inicia a rota no App.
2. Ao entrar no raio de 50m (Geofencing) do ponto de um aluno, o sistema dispara notificação "O motorista está chegando" para o aluno.
3. O sistema registra automaticamente o horário de chegada no ponto para fins de log de atrasos.

---

## UC06 — Gestão Financeira e Contrato
**Ator Principal:** Motorista / **Ator Secundário:** Aluno
**Objetivo:** Controlar pagamentos e assinaturas de forma manual.
**Pré-condições:** Contrato anexado no sistema.

**Fluxo Principal:**
1. O motorista anexa o PDF do contrato para o aluno.
2. O aluno visualiza e aceita os termos.
3. Mensalmente, o motorista marca manualmente o status de "Pago" ou "Inadimplente" para cada aluno após conferir seu extrato bancário externo.

---

## UC07 — Solicitar Exclusão de Conta (LGPD)
**Ator Principal:** Usuário
**Objetivo:** Encerrar o vínculo com o sistema e apagar dados.
**Pré-condições:** Usuário logado.

**Fluxo Principal:**
1. O usuário solicita a exclusão da conta.
2. O sistema verifica o status financeiro/contratual.
3. Se não houver pendências, os dados são apagados/anonimizados.

**Fluxos Alternativos:**
- **A1 — Pendência Financeira:** O sistema impede a exclusão e exibe mensagem: "Conta com contrato ativo ou pendência financeira. Contate o administrador".

---

## UC08 — Consultar Assistente de IA (Gestão)
**Ator Principal:** Motorista
**Objetivo:** Obter a melhor sequência de busca baseada nas confirmações.
**Pré-condições:** Presenças do dia já processadas.

**Fluxo Principal:**
1. O motorista pergunta via voz ou texto: "Qual a rota de hoje?".
2. A IA cruza os dados de: Alunos Confirmados + Pontos Padrão + Pontos Alternativos Aprovados.
3. O sistema exibe a lista ordenada dos pontos para otimizar o trajeto.

---

### O que foi corrigido aqui?
1.  **Eliminação da Entidade "Van":** Agora é apenas um campo no perfil do motorista (UC03).
2.  **Poder de Veto:** O motorista agora decide sobre o ponto alternativo (UC04).
3.  **Trava de Segurança:** A exclusão de conta respeita a regra de quitação (UC07).
4.  **Automação:** Substituímos o registro manual de atraso pelo **Geofencing** (UC05), que é muito mais preciso e seguro para quem dirige.
5.  **Validação Manual:** O fluxo financeiro reflete a realidade de que o motorista olha o extrato e dá "baixa" no app (UC06).

Deseja que eu gere os diagramas ou prossiga para a definição das tabelas do Banco de Dados?