## Requisitos Não Funcionais (RNF) – Niciolli

### RNF01 — Eficiência de Desempenho: 

O sistema deve carregar a lista diária em até 2 segundos em conexões 4G estáveis.

### RNF02 — Segurança de Dados: 

As senhas devem ser armazenadas com hash Argon2 ou bcrypt. Toda comunicação entre App, Nuvem e Hardware deve utilizar TLS 1.3.

### RNF03 — Alta Disponibilidade: 

O sistema deve garantir um uptime de 99.9% em regime 24/7, garantindo que possa ser usado mesmo aos finais de semana para motivos de gerenciamento.

### RNF04 — Escalabilidade: 

O backend deve suportar o processamento simultâneo de dados de todos os alunos sem aumento na latência de resposta.

### RNF05 — Portabilidade: 

O aplicativo deve ser funcional em Android (8.0+) e (futuramente) em navegadores modernos (Web) e dispositivos IOS, mantendo a consistência visual.

### RNF06 — Conformidade Legal: 

O sistema deve seguir rigorosamente a LGPD, permitindo que o usuário solicite a exclusão definitiva de todos os seus dados a qualquer momento.

### RNF07 — Manutenibilidade: 

O código-fonte deve seguir a arquitetura MVVM (Mobile) e Clean Architecture (Backend), com cobertura de testes unitários superior a 70%.

### RNF08 — Resiliência de Software: 

Na falta de internet, o dispositivo deve permitir que a última atualização da lista seja vista, mesmo que o dispositivo esteja offline.

### RNF09 — Auditabilidade (Logs): 

Devem ser registrados logs de quais alunos preencheram as informações de presença para a van na faculdade (Ida e vinda).