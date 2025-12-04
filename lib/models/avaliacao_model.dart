class Avaliacao {
  final int id;
  final int localId;
  final String? comentario;
  final double? nota;
  final String nomeLocal;

  Avaliacao({
    required this.id,
    required this.localId,
    this.comentario,
    this.nota,
    required this.nomeLocal,
  });

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['id'],
      localId: json['local']?['id'] ?? 0, // Pega o ID do local, com um fallback
      comentario: json['comentario'],
      nota: (json['nota'] as num?)?.toDouble(),
      nomeLocal: json['local']?['nome'] ?? 'Local Desconhecido',
    );
  }
}