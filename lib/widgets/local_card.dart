import 'package:flutter/material.dart';
import 'package:mapafit/models/local_model.dart';
import 'package:mapafit/pages/cadastrado/checkin_page.dart';
import 'package:mapafit/providers/user_provider.dart';
import 'package:provider/provider.dart';

class LocalCard extends StatelessWidget {
  final Local local;
  final VoidCallback onTap;

  const LocalCard({
    super.key,
    required this.local,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final userType = context.watch<UserProvider>().userType;

    return InkWell(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                local.nome,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      local.horariosFuncionamento ?? 'Horário não informado',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      local.endereco?.rua ?? 'Endereço não informado',
                      style: TextStyle(fontSize: 14.0, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              if (userType == UserType.loggedInUser && local.distancia != null && local.distancia! <= 2000)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckinPage(local: local),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF528265),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Check-in',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}