import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerEvidencias extends StatefulWidget {
  @override
  _AdminEvidenciasPageState createState() => _AdminEvidenciasPageState();
}

class _AdminEvidenciasPageState extends State<VerEvidencias> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener evidencias desde Firestore
  Future<Map<String, List<Map<String, dynamic>>>> _getEvidencias() async {
    QuerySnapshot snapshot = await _firestore.collection('evidencias').get();

    Map<String, List<Map<String, dynamic>>> groupedEvidencias = {};
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String idActividad = data['idActividad'];
      if (!groupedEvidencias.containsKey(idActividad)) {
        groupedEvidencias[idActividad] = [];
      }
      groupedEvidencias[idActividad]!.add(data);
    }

    return groupedEvidencias;
  }

  Future<Map<String, String>> _getEstudianteDetalles(String matricula) async {
    try {
      var docSnapshot = await _firestore.collection('students').doc(matricula).get();
      if (docSnapshot.exists) {
        var estudiante = docSnapshot.data() as Map<String, dynamic>;
        return {
          'nombre': estudiante['nombre'] ?? 'Nombre no disponible',
          'primerApellido': estudiante['primerApellido'] ?? 'Primer apellido no disponible',
          'segundoApellido': estudiante['segundoApellido'] ?? 'Segundo apellido no disponible',
        };
      }
    } catch (e) {
      print('Error al obtener los detalles del estudiante: $e');
    }
    return {
      'nombre': 'Estudiante no encontrado',
      'primerApellido': 'No disponible',
      'segundoApellido': 'No disponible',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidencias de Estudiantes'),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _getEvidencias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar evidencias'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay evidencias registradas'));
          } else {
            var evidencias = snapshot.data!;

            return ListView(
              children: evidencias.keys.map((idActividad) {
                return Card(
                  child: ExpansionTile(
                    title: Text('Actividad: $idActividad'),
                    children: evidencias[idActividad]!.map((evidencia) {
                      String matricula = evidencia['matricula'] ?? 'Sin matrícula';
                      String url = evidencia['url'] ?? '';
                      return FutureBuilder<Map<String, String>>(
                        future: _getEstudianteDetalles(matricula),
                        builder: (context, detallesSnapshot) {
                          if (detallesSnapshot.connectionState == ConnectionState.waiting) {
                            return ListTile(
                              title: Text('Cargando detalles...'),
                            );
                          } else if (detallesSnapshot.hasError) {
                            return ListTile(
                              title: Text('Error al obtener los detalles'),
                            );
                          } else {
                            var detalles = detallesSnapshot.data!;
                            String nombre = detalles['nombre'] ?? 'Nombre no disponible';
                            String primerApellido = detalles['primerApellido'] ?? 'Primer apellido no disponible';
                            String segundoApellido = detalles['segundoApellido'] ?? 'Segundo apellido no disponible';

                            return ListTile(
                              title: Row(
                                children: [
                                  Text('Estudiante: $nombre $primerApellido $segundoApellido \n$matricula'),
                                ],
                              ),
                              subtitle: url.isNotEmpty
                                  ? InkWell(
                                      onTap: () {
                                        // Abrir la imagen en el navegador
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            content: Image.network(url),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Ver evidencia',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    )
                                  : Text('No hay evidencia subida'),
                            );
                          }
                        },
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }
}
