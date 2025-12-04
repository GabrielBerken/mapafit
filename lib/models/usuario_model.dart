import 'package:flutter/material.dart';
import 'package:mapafit/models/endereco_model.dart';
import 'package:mapafit/models/avaliacao_model.dart';

enum TipoUsuario { CADASTRADO, VISITANTE }

class Usuario {
  final int id;
  final String nome;
  final String email;
  final String? sexo;
  final String? telefone;
  final String? token;
  final String? fotoUrl;
  final String? idade;
  final Endereco? endereco;
  final TipoUsuario tipoUsuario;
  final List<Avaliacao> avaliacoes;
  final String? senha;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.sexo,
    this.telefone,
    this.token,
    this.fotoUrl,
    this.idade,
    this.endereco,
    required this.tipoUsuario,
    this.avaliacoes = const [],
    this.senha,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    var avaliacoesList = json['avaliacoes'] as List?;
    List<Avaliacao> parsedAvaliacoes = avaliacoesList != null
        ? avaliacoesList.map((i) => Avaliacao.fromJson(i)).toList()
        : [];

    String? fotoUrl = json['fotoUrl'];
    if (fotoUrl != null) {
      fotoUrl = fotoUrl.replaceFirst(':8080', ':8081');
    }

    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      sexo: json['sexo'],
      telefone: json['telefone'],
      token: json['token'],
      fotoUrl: fotoUrl,
      idade: json['idade'],
      // Trata o endereço nulo de forma segura
      endereco: json['endereco'] != null ? Endereco.fromJson(json['endereco']) : null,
      // Lógica de conversão de String para Enum mais robusta
      tipoUsuario: _tipoUsuarioFromString(json['tipoUsuario']),
      avaliacoes: parsedAvaliacoes,
      senha: json['senha'],
    );
  }

  // Converte o objeto Usuario para um mapa JSON.
  // Note que a senha e o token não são incluídos por segurança.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'nome': nome,
      'email': email,
      'sexo': sexo,
      'telefone': telefone,
      'idade': idade,
      'fotoUrl': fotoUrl,
      'endereco': endereco?.toJson(),
      'tipoUsuario': tipoUsuario.name,
      'senha': senha,
    };
    data.removeWhere((key, value) => value == null);
    debugPrint(data.toString());
    return data;
  }
  Usuario copyWith({
    String? nome,
    String? email,
    String? telefone,
  }) {
    return Usuario(
      id: id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      sexo: sexo,
      telefone: telefone ?? this.telefone,
      token: token,
      fotoUrl: fotoUrl,
      idade: idade,
      endereco: endereco,
      tipoUsuario: tipoUsuario,
      avaliacoes: avaliacoes,
      // A senha não é copiada para evitar enviá-la em atualizações.
    );
  }

}

// Função auxiliar para converter String em TipoUsuario de forma segura
TipoUsuario _tipoUsuarioFromString(String? tipo) {
  return TipoUsuario.values.firstWhere(
        (e) => e.name.toLowerCase() == tipo?.toLowerCase(),
    orElse: () => TipoUsuario.VISITANTE, // Valor padrão caso não encontre
  );
}
