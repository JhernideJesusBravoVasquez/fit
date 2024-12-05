import 'file_saver_stub.dart'
    if (dart.library.io) 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

class VerSolicitudesConstancia extends StatefulWidget {
  @override
  _VerSolicitudesConstanciaState createState() =>
      _VerSolicitudesConstanciaState();
}

class _VerSolicitudesConstanciaState extends State<VerSolicitudesConstancia> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Solicitudes de Constancia'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('solicitudes_constancia')
            .where('estado', isEqualTo: 'pendiente')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No hay solicitudes pendientes.'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic> solicitudData =
                  doc.data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('students')
                    .doc(solicitudData['matricula'])
                    .get(),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Cargando información del estudiante...'),
                    );
                  }

                  if (!studentSnapshot.hasData ||
                      !studentSnapshot.data!.exists) {
                    return ListTile(
                      title: Text(
                          'Estudiante no encontrado para la matrícula ${solicitudData['matricula']}'),
                    );
                  }

                  Map<String, dynamic> studentData =
                      studentSnapshot.data!.data() as Map<String, dynamic>;

                  return Card(
                    child: ListTile(
                      title: Text(
                          'Nombre: ${studentData['nombre']} ${studentData['primerApellido']} ${studentData['segundoApellido']}'),
                      subtitle: Text(
                          'Matrícula: ${solicitudData['matricula']} | Fecha de Solicitud: ${_formatearFecha(solicitudData['fechaSolicitud'])}'),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            _emitirConstancia(solicitudData, doc.id),
                        child: Text('Emitir Constancia'),
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _formatearFecha(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  Future<void> _emitirConstancia(
      Map<String, dynamic> solicitudData, String solicitudId) async {
    try {
      DocumentSnapshot studentSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .doc(solicitudData['matricula'])
          .get();

      if (!studentSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se encontró el estudiante.')),
        );
        return;
      }

      Map<String, dynamic> studentData =
          studentSnapshot.data() as Map<String, dynamic>;

      // Cargar imágenes
      final logoUabjo = await rootBundle.load('assets/logo_uabjo.png');
      final logoIdiomas = await rootBundle.load('assets/logo_idiomas.png');

      // Generar el PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Esquinas superiores
                pw.Positioned(
                  top: 10,
                  left: 10,
                  child: pw.Image(
                    pw.MemoryImage(logoUabjo.buffer.asUint8List()),
                    width: 50,
                  ),
                ),
                pw.Positioned(
                  top: 10,
                  right: 10,
                  child: pw.Image(
                    pw.MemoryImage(logoIdiomas.buffer.asUint8List()),
                    width: 50,
                  ),
                ),
                // Contenido principal
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'UNIVERSIDAD AUTÓNOMA BENITO JUÁREZ DE OAXACA',
                        style: pw.TextStyle(
                            fontSize: 14, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'FACULTAD DE IDIOMAS SEDE TEHUANTEPEC',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Otorga la presente',
                        style: pw.TextStyle(fontSize: 14),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'CONSTANCIA',
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'Al C. ${studentData['nombre']} ${studentData['primerApellido']} ${studentData['segundoApellido']}, '
                        'alumno de la LICENCIATURA EN ENSEÑANZA DE IDIOMAS.',
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Por haber cubierto las 200 horas extracurriculares que se requiere como requisito '
                        'para poder realizar los trámites administrativos y académicos en esta facultad.',
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Se expide la presente para los usos legales y administrativos a que haya lugar en '
                        'Santo Domingo Tehuantepec Oaxaca a los ${DateTime.now().day} días del mes de '
                        '${DateTime.now().month} de ${DateTime.now().year}.',
                        textAlign: pw.TextAlign.justify,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'ATENTAMENTE',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 30),
                      pw.Text(
                        'LIC. LEONARDO VASQUEZ CRUZ',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'COORDINADOR DE FORMACIÓN INTEGRAL DE LA FACULTAD DE IDIOMAS CAMPUS TEHUANTEPEC',
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        'AV. UNIVERSIDAD S/N CINCO SEÑORES, C.P. 68120, OAXACA DE JUAREZ, OAX. MEXICO.',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'TEL. DIRECCIÓN: 01 951 5 11 30 22, SEDE C.U. 01 951 572 52 16, SEDE BURGOA 01 951 514 00 49.',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.Text(
                        'www.idiomas.uabjo.mx',
                        style: pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Guardar el PDF
      await guardarPdf(pdf, 'Constancia_${studentData['matricula']}.pdf');

      // Actualizar el estado de la solicitud a 'emitida'
      await FirebaseFirestore.instance
          .collection('solicitudes_constancia')
          .doc(solicitudId)
          .update({'estado': 'emitida'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Constancia emitida correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al emitir la constancia: $e')),
      );
    }
  }
}
