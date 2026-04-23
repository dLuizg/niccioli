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
      
    );
  }
}