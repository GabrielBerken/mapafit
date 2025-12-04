class Cidade {
  final int id;
  final String nome;

  Cidade({required this.id, required this.nome});

  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id'],
      nome: json['nome'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cidade && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}