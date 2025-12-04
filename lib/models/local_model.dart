import 'package:mapafit/models/endereco_model.dart';

class Local {
  final int id;
  final String nome;
  final bool aprovado;
  final Endereco? endereco; // Permite que o endereço seja nulo
  final int tipoAtividadeId;
  final int tipoAcessoId;
  final int? tipoLocalId;
  final String? horariosFuncionamento;
  final String? informacoesAdicionais;
  final double? distancia;

  Local({
    required this.id,
    required this.nome,
    required this.aprovado,
    this.endereco,
    required this.tipoAtividadeId,
    required this.tipoAcessoId,
    this.tipoLocalId,
    this.horariosFuncionamento,
    this.informacoesAdicionais,
    this.distancia,
  });

  factory Local.fromJson(Map<String, dynamic> json) {
    return Local(
      id: json['id'],
      nome: json['nome'],
      aprovado: json['aprovado'],
      // A MUDANÇA CRÍTICA ESTÁ AQUI:
      endereco: json['endereco'] != null
          ? Endereco.fromJson(json['endereco'])
          : null,
      tipoAtividadeId: json['tipoAtividadeId'],
      tipoAcessoId: json['tipoAcessoId'],
      tipoLocalId: json['tipoLocalId'],
      horariosFuncionamento: json['horariosFuncionamento'],
      informacoesAdicionais: json['informacoesAdicionais'],
      distancia: (json['distancia'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nome': nome,
      'aprovado': aprovado,
      'endereco': endereco?.toJson(),
      'tipoAtividadeId': tipoAtividadeId,
      'tipoAcessoId': tipoAcessoId,
      'tipoLocalId': tipoLocalId,
      'horariosFuncionamento': horariosFuncionamento,
      'informacoesAdicionais': informacoesAdicionais,
    };
    data.removeWhere((key, value) => value == null);
    return data;
  }
}