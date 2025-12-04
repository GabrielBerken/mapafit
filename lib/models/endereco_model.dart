class Endereco {
  final int id;
  final String? rua;
  final String? cidade;
  final String? estado;
  final int? numero;
  final String? cep;
  final double? latitude;
  final double? longitude;

  Endereco({
    required this.id,
    this.rua,
    this.cidade,
    this.estado,
    this.numero,
    this.cep,
    this.latitude,
    this.longitude,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      id: json['id'],
      rua: json['rua'],
      cidade: json['cidade'],
      estado: json['estado'],
      numero: json['numero'],
      cep: json['cep'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rua': rua,
      'cidade': cidade,
      'estado': estado,
      'numero': numero,
      'cep': cep,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}