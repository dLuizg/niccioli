import 'package:flutter/material.dart';
import 'package:niccioli/views/widgets/notification_badge.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NotificacaoTela(),
    );
  }
}

// Criamos um StatefulWidget para conseguir manipular a lista
class NotificacaoTela extends StatefulWidget {
  const NotificacaoTela({super.key});

  @override
  State<NotificacaoTela> createState() => _NotificacaoTelaState();
}

class _NotificacaoTelaState extends State<NotificacaoTela> {
  // Lista de dados fictícios para as notificações
  List<Map<String, String>> notificacoes = [
    {
      "id": "1",
      "title": "O motorista iniciou a rota!",
      "message": "Fique atento, logo o motorista estará na sua porta!",
      "time": "Agora"
    },
    {
      "id": "2",
      "title": "Ônibus aproximando",
      "message": "Faltam 5 minutos para o ponto.",
      "time": "5 min"
    },
  ];

  // Função para deletar tudo
  void _excluirTodas() {
    setState(() {
      notificacoes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 25, 1, 70),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 25, 1, 70),
        elevation: 0,
        title: const Text(
          "Notificação",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        // BOTÃO DE EXCLUIR TUDO NA APPBAR
        actions: [
          if (notificacoes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () {
                // Mostra um aviso antes de apagar tudo
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Limpar tudo?"),
                    content: const Text("Deseja apagar todas as notificações?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Não")),
                      TextButton(
                        onPressed: () {
                          _excluirTodas();
                          Navigator.pop(ctx);
                        },
                        child: const Text("Sim"),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: notificacoes.isEmpty
          ? const Center(child: Text("Nenhuma notificação", style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: notificacoes.length,
              itemBuilder: (context, index) {
                final item = notificacoes[index];

                // OPÇÃO DE EXCLUIR UMA POR UMA (ARRASTANDO)
                return Dismissible(
                  key: Key(item['id']!), // Chave única para cada item
                  direction: DismissDirection.endToStart, // Arrastar da direita para esquerda
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    setState(() {
                      notificacoes.removeAt(index);
                    });
                  },
                  child: NotificationCard(
                    title: item['title']!,
                    message: item['message']!,
                    time: item['time']!,
                    icon: Icons.bus_alert,
                    iconColor: Colors.white,
                  ),
                );
              },
            ),
    );
  }
}