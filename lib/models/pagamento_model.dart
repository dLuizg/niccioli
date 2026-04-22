enum StatusPagamento {pago, vencido, aVencer}

class PagamentoModel {
  final String id;
  final String descricao;
  final double valor;
  final DateTime dataVencimento;
  final StatusPagamento status;

  PagamentoModel({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    required this.status,
  });
}