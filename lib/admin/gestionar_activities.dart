import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modificar_actividad.dart';
import 'crear_actividad.dart';
import 'participaciones.dart'; // Importa la ventana de participantes

class GestionarActivities extends StatefulWidget {

  final String adminId;

  GestionarActivities({
    required this.adminId
  });
  @override
  _BuscarActividadPageState createState() => _BuscarActividadPageState();
}

class _BuscarActividadPageState extends State<GestionarActivities> {
  final TextEditingController _idController = TextEditingController();
  Map<String, dynamic>? actividad;
  String _resultado = '';

  Future<void> _buscarActividadPorId() async {
    String idActividad = _idController.text.trim();

    if (idActividad.isEmpty) {
      setState(() {
        _resultado = 'Por favor, ingresa un ID de documento';
      });
      return;
    }

    try {
      DocumentSnapshot actividadSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(idActividad)
          .get();

      if (actividadSnapshot.exists) {
        setState(() {
          actividad = actividadSnapshot.data() as Map<String, dynamic>?;
          _resultado = 'Actividad encontrada';
        });
      } else {
        setState(() {
          actividad = null;
          _resultado = 'No se encontró ninguna actividad con este ID';
        });
      }
    } catch (e) {
      setState(() {
        _resultado = 'Error al buscar la actividad: $e';
      });
    }
  }

  String _formatearFechaHora(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime dateTime = timestamp.toDate();
    String formattedDate = '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    String amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    String formattedTime = '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
    return '$formattedDate - $formattedTime';
  }

  void _verActividad() async {
  if (actividad != null) {
    bool? wasDeleted = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModificarActividad(
          actividadId: _idController.text.trim(),
          actividadData: actividad!,
          onDelete: () {
              setState(() {
                actividad = null;
                _idController.clear();
              });
            },
        ),
      ),
    );

    // Si la actividad fue eliminada, limpiar el buscador y la tarjeta
    if (wasDeleted == true) {
      setState(() {
        actividad = null;
        _idController.clear();
        _resultado = '';
      });
    }
  }
}

  void _verParticipantes() {
    if (actividad != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Participaciones(
            idActividad: _idController.text.trim(),
            //actividadData: actividad!,
          ),
        ),
      );
    }
  }

  void _crearNuevaActividad() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearActividad(
          adminId: widget.adminId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar Actividad'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: InputDecoration(labelText: 'ID de la Actividad'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _buscarActividadPorId,
              child: Text('Buscar'),
            ),
            SizedBox(height: 16),
            Text(_resultado),
            SizedBox(height: 16),
            if (actividad != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nombre: ${actividad!['nombre'] ?? 'N/A'}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fecha y Hora: ${_formatearFechaHora(actividad!['fechaHora'])}',
                      ),
                      Text('Categoría: ${actividad!['categoria'] ?? 'N/A'}'),
                      Text('Valor: ${actividad!['valor'] ?? 'N/A'} horas'),
                      Text('Estado: ${actividad!['estado'] ?? 'N/A'}'),
                      Text('Lugar: ${actividad!['lugar'] ?? 'N/A'}'),
                      Text('ID: ${actividad!['idActividad'] ?? 'N/A'}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _verActividad,
                        child: Text('Ver'),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _verParticipantes,
                        child: Text('Participaciones'), // Botón para ver participantes
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _crearNuevaActividad,
              child: Text('Crear Nueva Actividad'),
            ),
          ],
        ),
      ),
    );
  }
}
