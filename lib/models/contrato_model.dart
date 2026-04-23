enum StatusContrato {assinado, cancelado, pendente, expirado, ativo}

class ContratoModel{
  final String id;
  final String nomeEstudante;
  final DateTime dataInicio;
  final DateTime dataFim;
  final double valorMensal;
  final StatusContrato status;

  ContratoModel({
    required this.id,
    required this.nomeEstudante,
    required this.dataInicio,
    required this.dataFim,
    required this.valorMensal,
    required this.status,
  });
}