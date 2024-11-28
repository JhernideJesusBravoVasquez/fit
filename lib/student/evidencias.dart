import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';


class Evidencias extends StatefulWidget {
  final String studentMatricula;

  Evidencias({required this.studentMatricula});

  @override
  _EvidenciasPageState createState() => _EvidenciasPageState();
}

class _EvidenciasPageState extends State<Evidencias> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Future<List<Map<String, dynamic>>> _getFilteredActivities() async {
    QuerySnapshot participacionesSnapshot = await _firestore
        .collection('participaciones')
        .where('matricula', isEqualTo: widget.studentMatricula)
        .get();

    List<Map<String, dynamic>> activitiesWithEvidence = [];
    List<Map<String, dynamic>> activitiesWithoutEvidence = [];

    for (var doc in participacionesSnapshot.docs) {
      String idActividad = doc['idActividad'];
      var activityDoc = await _firestore.collection('activities').doc(idActividad).get();

      if (activityDoc.exists) {
        // Verificar si existe evidencia para esta actividad
        QuerySnapshot evidenceSnapshot = await _firestore
            .collection('evidencias')
            .where('idActividad', isEqualTo: idActividad)
            .where('matricula', isEqualTo: widget.studentMatricula)
            .get();

        if (evidenceSnapshot.docs.isNotEmpty) {
          activitiesWithEvidence.add({
            'id': idActividad,
            'nombre': activityDoc['nombre'] ?? 'Sin nombre',
            'hasEvidence': true,
          });
        } else {
          activitiesWithoutEvidence.add({
            'id': idActividad,
            'nombre': activityDoc['nombre'] ?? 'Sin nombre',
            'hasEvidence': false,
          });
        }
      }
    }

    return [...activitiesWithoutEvidence, ...activitiesWithEvidence];
  }

  Future<void> _uploadImage(String idActividad) async {
    Uint8List? fileBytes;

    // Detectar si estamos en web o móvil
    if (kIsWeb) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.bytes != null) {
        fileBytes = result.files.single.bytes;
      }
    } else {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        fileBytes = await File(pickedFile.path).readAsBytes();
      }
    }

    if (fileBytes != null) {
      try {
        // Generar ruta del archivo
        String filePath =
            'evidencias/$idActividad/${widget.studentMatricula}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        UploadTask uploadTask = _storage.ref(filePath).putData(fileBytes);

        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Crear ID personalizado para el documento
        String documentId = '$idActividad-${widget.studentMatricula}';

        // Guardar URL de la evidencia en Firestore
        await _firestore.collection('evidencias').doc(documentId).set({
          'idActividad': idActividad,
          'matricula': widget.studentMatricula,
          'url': downloadUrl,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evidencia subida exitosamente')),
        );

        // Refrescar la lista después de subir la evidencia
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir evidencia: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidencias de Actividades'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getFilteredActivities(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar actividades'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay actividades registradas'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var activity = snapshot.data![index];
                String activityId = activity['id'];
                String activityName = activity['nombre'];
                bool hasEvidence = activity['hasEvidence'] ?? false;

                return Card(
                  child: ListTile(
                    title: Text(activityName),
                    subtitle: hasEvidence ? Text('Evidencia subida') : Text('Sin evidencia'),
                    trailing: hasEvidence
                        ? null
                        : ElevatedButton(
                            onPressed: () => _uploadImage(activityId),
                            child: Text('Subir'),
                          ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
