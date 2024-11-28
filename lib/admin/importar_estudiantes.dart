import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.io) 'dart:io';


class ImportarEstudiantes extends StatefulWidget {
  @override
  _ImportarEstudiantes createState() => _ImportarEstudiantes();
}

class _ImportarEstudiantes extends State<ImportarEstudiantes> {
  String _statusMessage = '';

  Future<void> _importarEstudiantesDeCsv() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        Uint8List? fileBytes;

        if(result.files.first.bytes != null){
          fileBytes = result.files.first.bytes;
        }else if (!kIsWeb && result.files.first.path != null){
          final file = File(result.files.first.path!);
          fileBytes = await file.readAsBytes();
        }

        if (fileBytes != null) {
          final csvContent = utf8.decode(fileBytes);
          List<String> rows = csvContent.split('\n');
          StringBuffer errorMessages = StringBuffer();
          bool allImportsSuccessful = true;

          // Validación y registro
          for (int i = 1; i < rows.length; i++) {
            if (rows[i].trim().isEmpty) continue;

            List<String> row = rows[i].split(',');
            if (row.length < 7 || row.any((field) => field.trim().isEmpty)) {
              errorMessages.writeln("Fila ${i + 1}: campos vacíos.");
              allImportsSuccessful = false;
              continue;
            }

            String matricula = row[0].trim();
            String nombre = row[1].trim();
            String primerApellido = row[2].trim();
            String segundoApellido = row[3].trim();
            String correo = row[4].trim();
            String telefono = row[5].trim();
            String carrera = row[6].trim();

            // Validaciones
            if (!RegExp(r'^\d{6}$').hasMatch(matricula)) {
              errorMessages.writeln("Fila ${i + 1}: Matrícula debe ser numérica de 6 dígitos.");
              allImportsSuccessful = false;
              continue;
            }

            if (!RegExp(r'^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$').hasMatch(nombre)) {
              errorMessages.writeln("Fila ${i + 1}: Nombre contiene caracteres no válidos.");
              allImportsSuccessful = false;
              continue;
            }

            if (!RegExp(r'^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$').hasMatch(primerApellido)) {
              errorMessages.writeln("Fila ${i + 1}: Primer Apellido contiene caracteres no válidos.");
              allImportsSuccessful = false;
              continue;
            }

            if (!RegExp(r'^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$').hasMatch(segundoApellido)) {
              errorMessages.writeln("Fila ${i + 1}: Segundo Apellido contiene caracteres no válidos.");
              allImportsSuccessful = false;
              continue;
            }

            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(correo)) {
              errorMessages.writeln("Fila ${i + 1}: Correo electrónico no válido.");
              allImportsSuccessful = false;
              continue;
            }

            if (!RegExp(r'^\d{10}$').hasMatch(telefono)) {
              errorMessages.writeln("Fila ${i + 1}: Teléfono debe ser numérico de 10 dígitos.");
              allImportsSuccessful = false;
              continue;
            }

            // Verificar si el estudiante ya existe en Firebase
            var estudianteDoc = await FirebaseFirestore.instance.collection('students').doc(matricula).get();
            if (!estudianteDoc.exists) {
              try {
                await FirebaseFirestore.instance.collection('students').doc(matricula).set({
                  'nombre': nombre,
                  'primerApellido': primerApellido,
                  'segundoApellido': segundoApellido,
                  'correo': correo,
                  'matricula': matricula,
                  'telefono': telefono,
                  'carrera': carrera,
                });

                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                  email: correo,
                  password: matricula,
                );
              } on FirebaseAuthException catch (e) {
                errorMessages.writeln("Fila ${i + 1}: Error al crear usuario - ${e.message}");
                allImportsSuccessful = false;
              }
            } else {
              errorMessages.writeln("Fila ${i + 1}: La matrícula ya está registrada.");
              allImportsSuccessful = false;
            }
          }

          // Mostrar mensaje de éxito o error
          setState(() {
            _statusMessage = allImportsSuccessful
                ? 'Estudiantes importados exitosamente.'
                : 'Errores encontrados:\n$errorMessages';
          });
        }
      } else {
        setState(() {
          _statusMessage = 'No se seleccionó ningún archivo.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al importar estudiantes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Importar Estudiantes desde CSV'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _statusMessage.contains('Error') ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _importarEstudiantesDeCsv,
              child: Text('Seleccionar archivo CSV e importar'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
