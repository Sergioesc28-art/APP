import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CreatePetScreen extends StatefulWidget {
  final String? petId;

  const CreatePetScreen({super.key, this.petId});

  @override
  _CreatePetScreenState createState() => _CreatePetScreenState();
}

class _CreatePetScreenState extends State<CreatePetScreen> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  bool _hasNewImage = false;
  
  // Controllers for the form fields
  final _nombreController = TextEditingController();
  final _caracteristicasController = TextEditingController();
  
  // Predefined options
  final List<String> _availableVacunas = ['Rabia', 'Parvovirus', 'Moquillo', 'Leptospirosis', 'Bordetella'];
  final List<String> _certificadoOptions = ['No tiene', 'Certificado básico', 'Certificado completo', 'Certificado internacional'];
  final List<String> _comportamientoOptions = ['Dócil', 'Juguetón', 'Protector', 'Nervioso', 'Tranquilo', 'Sociable'];
  final List<String> _edadOptions = ['Menos de 1 año', '1-3 años', '4-7 años', '8-12 años', 'Más de 12 años'];
  final Map<String, List<String>> _razasByType = {
    'Perro': ['Labrador', 'Pastor Alemán', 'Bulldog', 'Chihuahua', 'Pitbull', 'Golden Retriever', 'Mestizo'],
    'Gato': ['Persa', 'Siamés', 'Maine Coon', 'Bengalí', 'Ragdoll', 'Mestizo'],
    'Otro': ['Conejo', 'Hámster', 'Cobayo', 'Tortuga', 'Ave']
  };
  
  String _selectedSexo = 'M';
  String _selectedEdad = 'Menos de 1 año';
  String _selectedPetType = 'Perro';
  String _selectedRaza = 'Labrador';
  String _selectedCertificado = 'No tiene';
  String _selectedComportamiento = 'Dócil';
  
  bool _isLoading = false;
  bool _isEditing = false;
  String? _userId;
  File? _petImage;
  String? _existingImageUrl;
  List<String> _selectedVacunas = [];
  List<String> _imagesList = [];
  
  @override
  void initState() {
    super.initState();
    _getUserId();
    if (widget.petId != null) {
      _isEditing = true;
      _loadPetData();
    }
  }
  
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('userId');
    });
  }
  
  Future<void> _loadPetData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _supabase
          .from('mascotas')
          .select()
          .eq('id', widget.petId!)
          .single();
          
      setState(() {
        _nombreController.text = response['nombre'] ?? '';
        
        // Handle edad
        final edad = response['edad']?.toString() ?? '';
        if (edad.isNotEmpty) {
          int edadNum = int.tryParse(edad) ?? 0;
          if (edadNum < 1) {
            _selectedEdad = 'Menos de 1 año';
          } else if (edadNum >= 1 && edadNum <= 3) {
            _selectedEdad = '1-3 años';
          } else if (edadNum >= 4 && edadNum <= 7) {
            _selectedEdad = '4-7 años';
          } else if (edadNum >= 8 && edadNum <= 12) {
            _selectedEdad = '8-12 años';
          } else {
            _selectedEdad = 'Más de 12 años';
          }
        }
        
        // Handle raza based on type
        final raza = response['raza'] ?? '';
        for (var type in _razasByType.keys) {
          if (_razasByType[type]!.contains(raza)) {
            _selectedPetType = type;
            _selectedRaza = raza;
            break;
          }
        }
        if (_selectedRaza.isEmpty) {
          _selectedRaza = _razasByType[_selectedPetType]!.first;
        }
        
        _selectedSexo = response['sexo'] ?? 'M';
        
        // Handle vacunas as array
        if (response['vacunas'] != null) {
          final vacunas = List<String>.from(response['vacunas']);
          _selectedVacunas = vacunas.where((v) => _availableVacunas.contains(v)).toList();
        }
        
        _caracteristicasController.text = response['caracteristicas'] ?? '';
        
        // Handle certificado
        _selectedCertificado = response['certificado'] ?? 'No tiene';
        if (!_certificadoOptions.contains(_selectedCertificado)) {
          _selectedCertificado = _certificadoOptions.first;
        }
        
        // Handle comportamiento
        _selectedComportamiento = response['comportamiento'] ?? 'Dócil';
        if (!_comportamientoOptions.contains(_selectedComportamiento)) {
          _selectedComportamiento = _comportamientoOptions.first;
        }
        
        // Handle fotos as array
        if (response['fotos'] != null && (response['fotos'] as List).isNotEmpty) {
          _imagesList = List<String>.from(response['fotos']);
          _existingImageUrl = _imagesList.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los datos de la mascota: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      if (kIsWeb) {
        // For web: Read as bytes directly
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _petImage = null; // Not using File object on web
          _hasNewImage = true;
        });
      } else {
        // For mobile: Use File
        setState(() {
          _petImage = File(image.path);
          _imageBytes = null;
          _hasNewImage = true;
        });
      }
    }
  }

  Future<String> _getImageBase64() async {
    if (_hasNewImage) {
      if (kIsWeb && _imageBytes != null) {
        // Web platform: use bytes directly
        return 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
      } else if (_petImage != null) {
        // Mobile platform: read from file
        final bytes = await _petImage!.readAsBytes();
        return 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
    }
    return '';
  }
  
  int _getEdadValue(String edadRange) {
    switch (edadRange) {
      case 'Menos de 1 año':
        return 0;
      case '1-3 años':
        return 2;
      case '4-7 años':
        return 5;
      case '8-12 años':
        return 10;
      case 'Más de 12 años':
        return 13;
      default:
        return 0;
    }
  }
  
  Future<void> _savePet() async {
    if (_formKey.currentState!.validate() && _userId != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Process images
        List<String> updatedImages = [..._imagesList];
        
        // If we have a new image, add it to the list
        if (_hasNewImage) {
          final newImageBase64 = await _getImageBase64();
          if (newImageBase64.isNotEmpty) {
            updatedImages.add(newImageBase64);
          }
        }
        
        // Ensure we have at least one image
        if (updatedImages.isEmpty && _existingImageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Por favor, selecciona una imagen de tu mascota')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        // If we have an existing image but no new ones, add it to the list
        if (updatedImages.isEmpty && _existingImageUrl != null) {
          updatedImages.add(_existingImageUrl!);
        }
        
        final petData = {
          'nombre': _nombreController.text,
          'edad': _getEdadValue(_selectedEdad),
          'raza': _selectedRaza,
          'sexo': _selectedSexo,
          'vacunas': _selectedVacunas,
          'caracteristicas': _caracteristicasController.text,
          'certificado': _selectedCertificado,
          'comportamiento': _selectedComportamiento,
          'fotos': updatedImages,
          'id_usuario': _userId,
        };
        
        if (_isEditing) {
          await _supabase
              .from('mascotas')
              .update(petData)
              .eq('id', widget.petId!);
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mascota actualizada correctamente')),
          );
        } else {
          await _supabase
              .from('mascotas')
              .insert(petData);
              
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mascota registrada correctamente')),
          );
        }
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la mascota: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar mascota' : 'Registrar mascota'),
        backgroundColor: Colors.brown[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pet image
                    Center(
                      child: Stack(
                        children: [
                          Container(
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
                            child: _buildPetImage(),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.brown[700],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Nombre
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.pets),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa el nombre de tu mascota';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    
                    // Tipo de Mascota selector
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.category, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Tipo de Mascota:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedPetType,
                              isExpanded: true,
                              underline: Container(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedPetType = newValue!;
                                  _selectedRaza = _razasByType[_selectedPetType]!.first;
                                });
                              },
                              items: _razasByType.keys
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Raza dropdown based on selected pet type
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Raza:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedRaza,
                              isExpanded: true,
                              underline: Container(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRaza = newValue!;
                                });
                              },
                              items: _razasByType[_selectedPetType]!
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Edad dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.date_range, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Edad:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedEdad,
                              isExpanded: true,
                              underline: Container(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedEdad = newValue!;
                                });
                              },
                              items: _edadOptions
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Sexo
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pets, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Sexo:', style: TextStyle(fontSize: 16)),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Radio<String>(
                                  value: 'M',
                                  groupValue: _selectedSexo,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSexo = value!;
                                    });
                                  },
                                ),
                                Text('Macho'),
                                Radio<String>(
                                  value: 'F',
                                  groupValue: _selectedSexo,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSexo = value!;
                                    });
                                  },
                                ),
                                Text('Hembra'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Vacunas checkboxes
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services, color: Colors.grey),
                              SizedBox(width: 10),
                              Text('Vacunas:', style: TextStyle(fontSize: 16)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 0.0,
                            children: _availableVacunas.map((String vacuna) {
                              return FilterChip(
                                label: Text(vacuna),
                                selected: _selectedVacunas.contains(vacuna),
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedVacunas.add(vacuna);
                                    } else {
                                      _selectedVacunas.remove(vacuna);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Características
                    
                    
                    // Certificado dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Certificado:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedCertificado,
                              isExpanded: true,
                              underline: Container(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCertificado = newValue!;
                                });
                              },
                              items: _certificadoOptions
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    
                    // Comportamiento dropdown
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('Comportamiento:', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 10),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedComportamiento,
                              isExpanded: true,
                              underline: Container(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedComportamiento = newValue!;
                                });
                              },
                              items: _comportamientoOptions
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    TextFormField(
                      controller: _caracteristicasController,
                      decoration: InputDecoration(
                        labelText: 'Características',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor, ingresa las características de tu mascota';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    // Save button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePet,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.brown[700],
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Actualizar mascota' : 'Registrar mascota',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      backgroundColor: Color(0xFFF9F6E8),
    );
  }
  
  Widget _buildPetImage() {
    if (_hasNewImage) {
      if (kIsWeb && _imageBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
          ),
        );
      } else if (_petImage != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: Image.file(
            _petImage!,
            fit: BoxFit.cover,
          ),
        );
      }
    }
    
    if (_existingImageUrl != null) {
      if (_existingImageUrl!.startsWith('data:image')) {
        // It's a base64 image
        return ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: Image.memory(
            base64Decode(_existingImageUrl!.split(',').last),
            fit: BoxFit.cover,
          ),
        );
      } else {
        // It's a URL
        return ClipRRect(
          borderRadius: BorderRadius.circular(75),
          child: Image.network(
            _existingImageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.pets,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
        );
      }
    }
    
    return Icon(
      Icons.pets,
      size: 80,
      color: Colors.grey[400],
    );
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _caracteristicasController.dispose();
    super.dispose();
  }
}