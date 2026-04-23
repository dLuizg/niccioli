import 'package:flutter/material.dart';
import 'package:niccioli/models/pagamento_model.dart';

class PagamentoViewModel {
  //DADOS MOCKADOS PARA SIMULAÇÃO
  //APAGAR DEPOIS DA IMPLEMENTAÇÃO DO BANCO DE DADOS
  //UM EXEMPLO PARA CADA STATUS DA BADGE DOS PAGAMENTOS
  List<PagamentoModel> getPagamentosMockados() {
    return [
      PagamentoModel(
        id: '1', 
        descricao: 'Mensalidade Março', 
        valor: 400, 
        dataVencimento: DateTime(2026, 20, 03), 
        status: StatusPagamento.pago
      ),
      PagamentoModel(
        id: '2', 
        descricao: 'Mensalidade Abril', 
        valor: 400, 
        dataVencimento: DateTime(2026, 20, 04), 
        status: StatusPagamento.vencido
      ),
      PagamentoModel(
        id: '3', 
        descricao: 'Mensalidade Maio', 
        valor: 400, 
        dataVencimento: DateTime(2026, 20, 05), 
        status: StatusPagamento.aVencer
      ),
    ];
  }

  Color getStatusCor(StatusPagamento status){
  //DEFINE A COR DA BADGE DE ACORDO COM O STATUS
    switch (status) {
      case StatusPagamento.pago:
        return const Color(0xFF4CAF50); //Verde
      case StatusPagamento.vencido:
        return const Color(0xFFE53935); //Vermelho
      case StatusPagamento.aVencer:
        return const Color(0xFFFFA000); //Laranja
    }
  }

  String getStatusString(StatusPagamento status){
  //DEFINE A STRING QUE SERÁ UTILIZADA VISUALMENTE PARA O STATUS
    switch (status) {
      case StatusPagamento.pago:
        return 'Pago';
      case StatusPagamento.vencido:
        return 'Vencido';
      case StatusPagamento.aVencer:
        return 'A Vencer';
    }
  }
}