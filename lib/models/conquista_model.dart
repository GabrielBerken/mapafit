class Conquista {
  final int id;
  final String titulo;
  final String descricao;
  final String icone; // Nome do ícone para mapeamento futuro

  Conquista({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
  });

  factory Conquista.fromJson(Map<String, dynamic> json) {
    return Conquista(
      id: json['id'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      icone: json['icone'],
    );
  }
}