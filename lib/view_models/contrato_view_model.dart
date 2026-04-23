import 'package:flutter/material.dart';
import 'package:niccioli/models/contrato_model.dart';

class ContratoViewModel {
  //DADOS MOCKADOS PARA SIMULAÇÃO
  //APAGAR DEPOIS DA IMPLEMENTAÇÃO DO BANCO DE DADOS
  //UM EXEMPLO PARA CADA STATUS DA BADGE DOS CONTRATOS
  List<ContratoModel> getContratosMockados(){
    return [
      ContratoModel(id: '1', 
        nomeEstudante: 'Andreas Pereira', 
        dataInicio: DateTime(2026, 01, 01), 
        dataFim: DateTime(2027, 01, 01), 
        valorMensal: 400, 
        status: StatusContrato.assinado
      ),
      ContratoModel(id: '2', 
        nomeEstudante: 'Breno Lopes', 
        dataInicio: DateTime(2026, 01, 01), 
        dataFim: DateTime(2027, 01, 01), 
        valorMensal: 400, 
        status: StatusContrato.ativo
      ),
      ContratoModel(id: '3', 
        nomeEstudante: 'Carlos Pereira', 
        dataInicio: DateTime(2025, 01, 01), 
        dataFim: DateTime(2026, 01, 01), 
        valorMensal: 400, 
        status: StatusContrato.expirado
      ),
      ContratoModel(id: '4', 
        nomeEstudante: 'Diego Souza', 
        dataInicio: DateTime(2026, 01, 01), 
        dataFim: DateTime(2027, 01, 01), 
        valorMensal: 400, 
        status: StatusContrato.pendente
      ),
      ContratoModel(id: '5', 
        nomeEstudante: 'Emiliano Martinez', 
        dataInicio: DateTime(2026, 01, 01), 
        dataFim: DateTime(2027, 01, 01), 
        valorMensal: 400, 
        status: StatusContrato.cancelado
      ),  
    ];
  }

  Color getStatusCor(StatusContrato status){
  //DEFINE A COR DA BADGE DE ACORDO COM O STATUS
    switch (status) {
      case StatusContrato.assinado:
        return const Color(0xFF4CAF50); //Verde
      case StatusContrato.ativo:
        return const Color(0xFF4CAF50); //Verde
      case StatusContrato.cancelado:
        return const Color(0xFFE53935); //Vermelho
      case StatusContrato.expirado:
        return const Color(0xFF757575); //Cinza
      case StatusContrato.pendente:
        return const Color(0xFFFFA000); //Laranja
    }
  }

  String getStatusString(StatusContrato status){
  //DEFINE A STRING QUE SERÁ UTILIZADA VISUALMENTE PARA O STATUS
    switch (status) {
      case StatusContrato.assinado:
        return 'Assinado';
      case StatusContrato.ativo:
        return 'Ativo';
      case StatusContrato.cancelado:
        return 'Cancelado';
      case StatusContrato.expirado:
        return 'Expirado';
      case StatusContrato.pendente:
        return 'Pendente';
    }
  }  
}