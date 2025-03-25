import 'package:flutter/material.dart';
import 'dart:convert';

class DogDetailScreen extends StatelessWidget {
  final String name;
  final String breed;
  final String age;
  final String gender;
  final String imageUrl;
  final String vaccines;
  final String certificate;
  final String behavior;
  final String description;

  const DogDetailScreen({
    super.key,
    required this.name,
    required this.breed,
    required this.age,
    required this.gender,
    required this.imageUrl,
    required this.vaccines,
    required this.certificate,
    required this.behavior,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    List<String> vaccineList = vaccines.split(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: TextStyle(
            fontSize: 24,
            color: Colors.brown[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.brown[700]),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet image
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(75),
                  border: Border.all(
                    color: Colors.brown.shade300,
                    width: 3,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: imageUrl.isNotEmpty
                      ? (imageUrl.startsWith('http')
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.pets,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            )
                          : Image.memory(
                              base64Decode(imageUrl.split(',').last),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.pets,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                            ))
                      : Icon(
                          Icons.pets,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Nombre
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Nombre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  name,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Raza
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Raza',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  breed,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Edad
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Edad',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$age años',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Sexo
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Sexo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  gender,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Vacunas
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Vacunas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: vaccineList.map((vaccine) => Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.brown.shade300, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        vaccine,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),

            // Certificado
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Certificado',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  certificate,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Comportamiento
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Comportamiento',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  behavior,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

            // Descripción
            Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.brown.shade300, width: 2),
              ),
              child: ListTile(
                title: Text(
                  'Descripción',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  description,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Color(0xFFF9F6E8),
    );
  }
}