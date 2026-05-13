import 'package:flutter/material.dart';
import 'package:niccioli/app/pages/perfil/profile_detail_layout.dart';
import 'package:niccioli/app/theme/app_colors.dart';
import 'package:niccioli/app/views/widgets/notification_card.dart';
import 'package:niccioli/app/widgets/notification_button.dart';

class NotificacaoTela extends StatefulWidget {
  const NotificacaoTela({super.key, this.showProfileNavigation = false});

  final bool showProfileNavigation;

  @override
  State<NotificacaoTela> createState() => _NotificacaoTelaState();
}

class _NotificacaoTelaState extends State<NotificacaoTela> {
  final List<Map<String, String>> notificacoes = [
    {
      'id': '1',
      'title': 'O motorista iniciou a rota!',
      'message': 'Fique atento, logo o motorista estara na sua porta!',
      'time': 'Agora',
    },
    {
      'id': '2',
      'title': 'Onibus aproximando',
      'message': 'Faltam 5 minutos para o ponto.',
      'time': '5 min',
    },
  ];

  void _excluirTodas() {
    setState(() {
      notificacoes.clear();
    });
  }

  void _dismissNotification(String id) {
    setState(() {
      notificacoes.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showProfileNavigation) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          title: const Text(
            'Notificacao',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (notificacoes.isNotEmpty)
              BotaoLimparNotificacoes(onConfirmar: _excluirTodas),
          ],
        ),
        body: _NotificationList(
          notificacoes: notificacoes,
          onDismissed: _dismissNotification,
        ),
      );
    }

    return ProfileDetailScaffold(
      headerLabel: 'NOTIFICACAO',
      contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (notificacoes.isNotEmpty)
                BotaoLimparNotificacoes(onConfirmar: _excluirTodas),
            ],
          ),
          const SizedBox(height: 24),
          if (notificacoes.isEmpty)
            const SizedBox(
              height: 300,
              child: Center(
                child: Text(
                  'Nenhuma notificacao',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            for (final item in notificacoes)
              _NotificationDismissibleItem(
                key: ValueKey(item['id']),
                item: item,
                onDismissed: () => _dismissNotification(item['id']!),
              ),
        ],
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.notificacoes,
    required this.onDismissed,
  });

  final List<Map<String, String>> notificacoes;
  final ValueChanged<String> onDismissed;

  @override
  Widget build(BuildContext context) {
    if (notificacoes.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma notificacao',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemCount: notificacoes.length,
      itemBuilder: (context, index) {
        final item = notificacoes[index];
        return _NotificationDismissibleItem(
          item: item,
          onDismissed: () => onDismissed(item['id']!),
        );
      },
    );
  }
}

class _NotificationDismissibleItem extends StatelessWidget {
  const _NotificationDismissibleItem({
    super.key,
    required this.item,
    required this.onDismissed,
  });

  final Map<String, String> item;
  final VoidCallback onDismissed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: AppColors.white),
      ),
      onDismissed: (_) => onDismissed(),
      child: NotificationCard(
        title: item['title']!,
        message: item['message']!,
        time: item['time']!,
        icon: Icons.bus_alert,
        iconColor: AppColors.white,
      ),
    );
  }
}
