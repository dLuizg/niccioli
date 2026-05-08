@startuml
title UC01 - Realizar Login e Acesso Social

start
:Usuario abre a tela de login;
:Escolhe login tradicional ou social;

if (Primeiro acesso?) then (sim)
  :Solicitar escolha de perfil;
  :Solicitar dados complementares;
endif

:Enviar credenciais ou token ao sistema;

if (Credenciais validas?) then (sim)
  :Identificar perfil do usuario;
  if (Perfil Aluno?) then (sim)
    :Redirecionar para dashboard do aluno;
  else (motorista)
    :Redirecionar para dashboard do motorista;
  endif
else (nao)
  :Exibir erro de autenticacao;
endif

stop
@enduml

@startuml
title UC02 - Gerenciar Presenca Diaria

start
:Aluno acessa a tela de presenca;

if (Contrato ativo?) then (sim)
  if (Dentro do horario limite?) then (sim)
    :Aluno informa ida;
    :Aluno informa volta;
    :Sistema registra timestamp;
    :Atualizar lista do motorista em tempo real;
  else (nao)
    :Bloquear alteracao;
    :Exibir mensagem para contatar o motorista;
  endif
else (nao)
  :Exibir restricao por contrato inativo;
endif

stop
@enduml

@startuml
title UC03 - Gerenciar Perfil e Veiculo

start
:Usuario acessa configuracoes de perfil;

if (Usuario logado?) then (sim)
  :Editar dados cadastrais;
  if (Perfil Motorista?) then (sim)
    :Informar ou editar modelo da van;
    :Informar ou editar placa da van;
  else (nao)
  endif
  :Salvar alteracoes no banco de dados;
  :Exibir perfil atualizado;
else (nao)
  :Redirecionar para login;
endif

stop
@enduml

@startuml
title UC04 - Solicitar Ponto Alternativo

start
:Aluno acessa opcao Ponto Alternativo;

if (Ponto previamente validado?) then (sim)
  :Aluno envia localizacao;
  :Sistema notifica o motorista na proxima parada;
  :Motorista visualiza o ponto no mapa;
  if (Motorista aprova?) then (sim)
    :Notificar aluno sobre aprovacao;
  else (nao)
    :Notificar aluno sobre recusa;
  endif
else (nao)
  :Exibir mensagem de ponto invalido;
endif

stop
@enduml

@startuml
title UC05 - Monitoramento e Geofencing

start
:Motorista inicia a rota no app;

if (Localizacao ativa?) then (sim)
  :Sistema monitora posicao da van;
  if (Van entrou no raio de 50m?) then (sim)
    :Disparar notificacao para o aluno;
    :Registrar horario de chegada no ponto;
  else (nao)
    :Continuar monitoramento da rota;
  endif
else (nao)
  :Solicitar ativacao da localizacao;
endif

stop
@enduml

@startuml
title UC06 - Gestao Financeira e Contrato

start
:Motorista acessa gestao financeira;

if (Contrato anexado?) then (sim)
  :Motorista anexa ou envia PDF do contrato;
  :Aluno visualiza os termos;
  if (Aluno aceita os termos?) then (sim)
    :Registrar aceite do aluno;
    :Motorista confere extrato bancario externo;
    if (Pagamento confirmado?) then (sim)
      :Marcar aluno como Pago;
    else (nao)
      :Marcar aluno como Inadimplente;
    endif
  else (nao)
    :Manter contrato pendente;
  endif
else (nao)
  :Solicitar anexo do contrato;
endif

stop
@enduml

@startuml
title UC07 - Solicitar Exclusao de Conta

start
:Usuario acessa solicitacao de exclusao;

if (Usuario logado?) then (sim)
  :Usuario confirma pedido de exclusao;
  :Sistema verifica status financeiro e contratual;
  if (Ha pendencias?) then (sim)
    :Impedir exclusao;
    :Exibir mensagem para contatar administrador;
  else (nao)
    :Apagar ou anonimizar dados;
    :Encerrar vinculo com o sistema;
  endif
else (nao)
  :Redirecionar para login;
endif

stop
@enduml

@startuml
title UC08 - Consultar Assistente de IA

start
:Motorista acessa assistente de IA;

if (Presencas do dia processadas?) then (sim)
  :Motorista pergunta por voz ou texto;
  :IA consulta alunos confirmados;
  :IA consulta pontos padrao;
  :IA consulta pontos alternativos aprovados;
  :Sistema ordena a rota sugerida;
  :Exibir lista de pontos otimizada;
else (nao)
  :Solicitar processamento das presencas do dia;
endif

stop
@enduml

@startuml
title UC09 - Informar Paradeiro da Van

start
:Motorista informa destino atual da van;
:Sistema atualiza paradeiro;
:Alunos recebem notificacao;
:Alunos se dirigem ate a van;

if (Todos os alunos do ponto estao na van?) then (sim)
  :Autorizar motorista a partir;
else (nao)
  :Bloquear partida do ponto;
  :Aguardar alunos previstos;
endif

stop
@enduml

@startuml
title UC10 - Pegar a Van em Ponto Diferente na Saida

start
:Sistema verifica paradeiro atual da van;

if (Van ainda passara pelo novo ponto?) then (sim)
  :Liberar opcao de alterar entrada;
  :Aluno escolhe novo ponto de entrada;
  :Sistema registra alteracao;
  :Aluno recebe notificacao do paradeiro da van;
  if (Alunos do ponto estao na van?) then (sim)
    :Autorizar motorista a partir;
  else (nao)
    :Aguardar alunos do ponto;
  endif
else (nao)
  :Bloquear alteracao de entrada;
  :Exibir pontos ainda disponiveis;
endif

stop
@enduml
