import 'package:flutter/material.dart';

class PointageScreen extends StatelessWidget {
  const PointageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mes pointages',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Historique de vos présences',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            const SizedBox(height: 20),

            // Filtres
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'Ce mois',
                    items:
                        [
                              'Aujourd\'hui',
                              'Cette semaine',
                              'Ce mois',
                              'Cette année',
                            ]
                            .map(
                              (String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      labelText: 'Période',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: 'Tous',
                    items: ['Tous', 'Présent', 'Retard', 'Absent']
                        .map(
                          (String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Liste des pointages
            Expanded(
              child: ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return _buildPointageCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointageCard(int index) {
    final List<Map<String, dynamic>> pointages = [
      {
        'date': 'Aujourd\'hui',
        'arrivee': '08:30',
        'depart': '17:45',
        'status': 'Présent',
        'color': Colors.green,
      },
      {
        'date': 'Hier',
        'arrivee': '08:45',
        'depart': '17:30',
        'status': 'Retard',
        'color': Colors.orange,
      },
      {
        'date': '12/11/2024',
        'arrivee': '08:15',
        'depart': '18:00',
        'status': 'Présent',
        'color': Colors.green,
      },
      {
        'date': '11/11/2024',
        'arrivee': '--:--',
        'depart': '--:--',
        'status': 'Absent',
        'color': Colors.red,
      },
    ];

    final pointage = pointages[index % pointages.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: pointage['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            pointage['status'] == 'Présent'
                ? Icons.check_circle
                : pointage['status'] == 'Retard'
                ? Icons.access_time
                : Icons.cancel,
            color: pointage['color'],
          ),
        ),
        title: Text(
          pointage['date'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.login, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Arrivée: ${pointage['arrivee']}'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.logout, size: 16, color: Colors.grey),
                const SizedBox(width: 5),
                Text('Départ: ${pointage['depart']}'),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            pointage['status'],
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: pointage['color'],
        ),
      ),
    );
  }
}
