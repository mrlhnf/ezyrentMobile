import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class UpdateHousePage extends StatefulWidget {
  final Map<String, dynamic> houseData;

  const UpdateHousePage({super.key, required this.houseData});

  @override
  _UpdateHousePageState createState() => _UpdateHousePageState();
}

class _UpdateHousePageState extends State<UpdateHousePage> {
  List<XFile>? selectedImages;
  List<String> selectedImageNames = [];
  Map<String, dynamic>? selectedLocation;
  bool buttonClick = false;
  bool locationpick = false;
  DateTime? selectedDate;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    TextEditingController nameController = TextEditingController(text: widget.houseData['name']);
    TextEditingController priceController = TextEditingController(text: widget.houseData['price'].toString());
    TextEditingController quotaController = TextEditingController(text: widget.houseData['quota'].toString());
    TextEditingController typeController = TextEditingController(text: widget.houseData['type']);
    TextEditingController locationController = TextEditingController(text: widget.houseData['district']);
    TextEditingController genderController = TextEditingController(text: widget.houseData['preffered gender']);

    final List<DropdownMenuEntry<location>> locationEntries =
    <DropdownMenuEntry<location>>[];
    for (final location label in location.values) {
      locationEntries.add(
        DropdownMenuEntry<location>(
            value: label, label: label.name),
      );
    }

    final List<DropdownMenuEntry<Gender>> genderEntries =
    <DropdownMenuEntry<Gender>>[];
    for (final Gender label in Gender.values) {
      genderEntries
          .add(DropdownMenuEntry<Gender>(value: label, label: label.type));
    }

    final List<DropdownMenuEntry<Jenis>> typeEntries =
    <DropdownMenuEntry<Jenis>>[];
    for (final Jenis label in Jenis.values) {
      typeEntries
          .add(DropdownMenuEntry<Jenis>(value: label, label: label.jenis));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update House Information'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.deepPurpleAccent,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your house name';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Name',
                    hintText: 'Taman Merlimau Baru',
                    labelStyle: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.house,
                      color: Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownMenu<Jenis>(
                      controller: typeController,
                      label: const Text('Type',
                        style: TextStyle(color: Colors.deepPurpleAccent
                        ),
                      ),
                      dropdownMenuEntries: typeEntries,
                      inputDecorationTheme: const InputDecorationTheme(
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: priceController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your house price';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Monthly Payment',
                    labelStyle: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.monetization_on,
                      color: Colors.purple,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownMenu<location>(
                      controller: locationController,
                      label: const Text('Location',
                        style: TextStyle(color: Colors.deepPurpleAccent
                        ),
                      ),
                      dropdownMenuEntries: locationEntries,
                      inputDecorationTheme: const InputDecorationTheme(
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                    const SizedBox(width: 20),
                    DropdownMenu<Gender>(
                      controller: genderController,
                      label: const Text('Preferred Gender',
                        style: TextStyle(color: Colors.deepPurpleAccent
                        ),
                      ),
                      dropdownMenuEntries: genderEntries,
                      inputDecorationTheme: const InputDecorationTheme(
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: quotaController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter the maximum person in your house';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Maximum Person',
                    labelStyle: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.people_alt,
                      color: Colors.purple,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2025),
                        );

                        if (pickedDate != null) {
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.deepPurpleAccent,
                            width: 2.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Icon(
                          Icons.calendar_month,
                          size: 25.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(selectedDate != null
                        ? 'Selected Date: ${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}'
                        : 'Please select the last day to rent the house',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () async {
                        PermissionStatus status = await Permission.storage.request();
                        if (status.isGranted) {
                          List<XFile>? images = await ImagePicker().pickMultiImage();
                          setState(() {
                            selectedImages = images;
                            selectedImageNames = images.map((image) => image.name).toList();
                          });
                        } else {
                          print('Permission to get images is denied');
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.deepPurpleAccent,
                            width: 2.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Icon(
                          Icons.image,
                          size: 25.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (selectedImages != null && selectedImages!.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: selectedImages!.length,
                          itemBuilder: (BuildContext context, int index) {
                            XFile image = selectedImages![index];
                            String imageName = selectedImageNames[index];
                            return ListTile(
                              leading: Image.file(File(image.path)),
                              title: Text(
                                imageName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                        ),
                      )
                    else if (selectedImages == null || selectedImages!.isEmpty)
                      const Text(
                        'No image is selected',
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/map').then((returnedData) {
                          if (returnedData != null) {
                            print(returnedData);
                            setState(() {
                              selectedLocation = returnedData as Map<String, dynamic>?;
                              locationpick = true;
                            });
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.deepPurpleAccent,
                            width: 2.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: const Icon(
                          Icons.location_on,
                          size: 25.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (locationpick)
                      const Text(
                        'Location have been selected',
                        style: TextStyle(color: Colors.white),
                      )
                    else
                      const Text(
                        'No location selected',
                        style: TextStyle(color: Colors.white),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0), // Set the desired border radius
                          ),
                        ),
                        minimumSize: MaterialStateProperty.all<Size>(
                          const Size(120.0, 40.0), // Set the desired width and height
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!),
                      ),
                      child: const Text('Update'),
                      onPressed: () {
                        if(selectedDate == null || selectedImages == null || selectedLocation == null) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Registration Error'),
                                content: const Text('Please make sure that the last rent date, location and property images are inserted properly'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        else {
                          if (formKey.currentState!.validate()) {
                            formKey.currentState!.save();
                            setState(() {
                              buttonClick = true;
                            });

                            String name = nameController.text;
                            String type = typeController.text;
                            String location = locationController.text;
                            String gender = genderController.text;
                            double price = double.parse(priceController.text);
                            int quota = int.parse(quotaController.text);

                            Map<String, dynamic> updatedData = {
                              'name': name,
                              'type': type,
                              'location': location,
                              'gender': gender,
                              'price': price,
                              'quota': quota,
                              'max': quota,
                              'selectedImages': selectedImages,
                              'selectedLocation': selectedLocation,
                            };
                            Navigator.pop(context, updatedData);
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0), // Set the desired border radius
                          ),
                        ),
                        minimumSize: MaterialStateProperty.all<Size>(
                          const Size(120.0, 40.0), // Set the desired width and height
                        ),
                        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!),
                      ),
                      child: const Text('Cancel'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if(buttonClick == true){
      deleteOldImage();
    }
    super.dispose();
  }

  Future<void> deleteOldImage() async {
    for (String path in widget.houseData['images']) {
      try {
        Reference ref = FirebaseStorage.instance.ref().child(path);
        await ref.delete();
        print('Images deleted successfully');
      } catch (e) {
        print('Error deleting image at path $path: ${e.toString()}');
      }
    }
  }

}

enum location {

  jasin('Jasin'),
  srimendapat('Sri Mendapat'),
  merlimau('Merlimau'),
  serkam('Serkam');

  const location(this.name);
  final String name;
}

enum Gender {

  male('Male'),
  female('Female');

  const Gender(this.type);
  final String type;
}

enum Jenis {
  terrace('Terrace'),
  bungalow('Bungalow'),
  semiD('Semi-D'),
  flat('Flat');

  const Jenis(this.jenis);
  final String jenis;
}
