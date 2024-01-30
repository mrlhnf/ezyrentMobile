import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shoppeeclone/Landlord/update.dart';
import 'package:carousel_slider/carousel_slider.dart';

class myHouse extends StatefulWidget {

  final Map<String, dynamic> houseData;
  final String houseId;

  const myHouse({
    Key? key,
    required this.houseData,
    required this.houseId,
  }) : super(key: key);

  @override
  _myHouseState createState() => _myHouseState();
}

class _myHouseState extends State<myHouse> {

  final CollectionReference<Map<String, dynamic>> housesCollection =
  FirebaseFirestore.instance.collection('rumah');
  List<XFile>? selectedImages;
  Map<String, dynamic>? selectedLocation;
  List<Map<String,dynamic>> tenantDataList = [];
  List<String> imagePaths = [];
  List<String> downloadURLs = [];
  bool status = true;

  @override
  void initState() {
    super.initState();
    fetchTenantData();
    getImagePaths();
    checkAvailability();
  }

  Future<void> getImagePaths() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await housesCollection.doc(widget.houseId).get();

    List<dynamic> pathList = snapshot.get('images');
    setState(() {
      imagePaths = List<String>.from(pathList);
    });

    await getDownloadURLs(imagePaths);
  }

  Future<void> getDownloadURLs(List<String> imagePaths) async {
    for (String path in imagePaths) {
      try {
        Reference ref = FirebaseStorage.instance.ref().child(path);
        String downloadURL = await ref.getDownloadURL();
        setState(() {
          downloadURLs.add(downloadURL);
        });
      } catch (e) {
        print('Error getting download URL for $path: ${e.toString()}');
      }
    }
  }

  Future<void> checkAvailability() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await housesCollection.doc(widget.houseId).get();

    bool openclose = snapshot.get('openRent');
    setState(() {
      status = openclose;
    });
  }

  Future<void> closeHouse() async {
      housesCollection.doc(widget.houseId).update({
        'quota': 0,
        'openRent' : false,
      }).then((value) {
        print('House had been closed');
      }).catchError((error) {
        print('Failed to close house: $error');
      });
  }

  Future<void> openHouse() async {
    List<dynamic> num = widget.houseData['tenant'];
    housesCollection.doc(widget.houseId).update({
      'quota': widget.houseData['max'] - num.length,
      'openRent' : true,
    }).then((value) {
      print('House had been opened');
    }).catchError((error) {
      print('Failed to open house: $error');
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('House Details'),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) {
                    return Scaffold(
                      appBar: AppBar(
                        title: const Text('List of Tenant'),
                        backgroundColor: Colors.deepPurpleAccent,
                      ),
                      body: ListView.builder(
                        itemCount: tenantDataList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('${tenantDataList[index]['nama1']} ${tenantDataList[index]['nama2']}'),
                            subtitle: Text(tenantDataList[index]['phoneNumber']),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.update),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UpdateHousePage(houseData: widget.houseData)),
              ).then((returnedData) {
                if (returnedData != null) {
                  String name = returnedData['name'];
                  String type = returnedData['type'];
                  double price = returnedData['price'];
                  String location = returnedData['location'];
                  String gender = returnedData['gender'];
                  int quota = returnedData['quota'];
                  selectedImages = returnedData['selectedImages'];
                  selectedLocation = returnedData['selectedLocation'];
                  updateHouse(name, type, price, location, gender, quota, selectedImages, selectedLocation);
                  Navigator.pushReplacementNamed(context, '/OwnerHomepage');
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmation'),
                    content: const Text('Are you sure you want to delete this house?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                        },
                      ),
                      TextButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          deleteHouse(widget.houseId);
                          Navigator.pushReplacementNamed(context, '/OwnerHomepage');
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),

        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.deepPurpleAccent, // Set the desired background color here
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                color: Colors.black, // Set the desired background color here
                child: CarouselSlider(
                  options: CarouselOptions(
                    height: 200, // Set the desired height of the container
                    autoPlay: true, // Enable auto-play
                    enlargeCenterPage: true, // Enable center image enlargement
                  ),
                  items: downloadURLs.map((image) {
                    return Container(
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 2.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Name',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.houseData['name']),
                    ),
                    ListTile(
                      title: const Text('Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.houseData['type']),
                    ),
                    ListTile(
                      title: const Text('Monthly Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text('RM' + widget.houseData['price'].toStringAsFixed(2)),
                    ),
                    ListTile(
                      title: const Text('District',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.houseData['district']),
                    ),
                    ListTile(
                      title: const Text('Preffered Gender',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.houseData['preffered gender']),
                    ),
                    ListTile(
                      title: const Text('Quota',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text('${widget.houseData['quota']} person(s) more'),
                    ),
                    ListTile(
                      title: const Text('Last Rent Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.houseData['lastDate']),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmation'),
                            content: Text(status ? 'Are you sure you want to close house rent session?'
                                : 'Are you sure you want to open house rent session?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton(
                                child: const Text('Confirm'),
                                onPressed: () {
                                  setState(() {
                                    if(status == true){
                                      status == false;
                                      closeHouse();
                                    }
                                    else{
                                      status == true;
                                      openHouse();
                                    }
                                  });
                                  Navigator.pushReplacementNamed(context, '/OwnerHomepage');
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    style: status
                        ? ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // Set the desired border radius
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size(120.0, 40.0), // Set the desired width and height
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.red),
                    )
                        : ButtonStyle(
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0), // Set the desired border radius
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all<Size>(
                        const Size(120.0, 40.0), // Set the desired width and height
                      ),
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    child: Text(
                      status ? 'Close Rent Session' : 'Open Rent Session',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> updateHouse(
      String name, String type, double price, String location, String gender,
      int quota, List<XFile>? images, Map<String, dynamic>? selectedLocation,
      ) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String uid = user.uid;

      List<String> imageURLs = [];
      if (images != null && images.isNotEmpty) {
        for (XFile imageFile in images) {
          String imagePath = 'rumah/$uid/${DateTime.now().microsecondsSinceEpoch}.jpg';
          Reference ref = FirebaseStorage.instance.ref().child(imagePath);
          UploadTask uploadTask = ref.putFile(File(imageFile.path));
          await uploadTask.whenComplete(() => null);
          imageURLs.add(imagePath);
        }
      }

      housesCollection.doc(widget.houseId).update({
        'name': name,
        'type': type,
        'price': price,
        'quota': quota,
        'max': quota,
        'district': location,
        'preffered gender': gender,
        'images': imageURLs,
        'location': selectedLocation, // Use the converted locationData
      }).then((value) {
        print('Document updated successfully!');
      }).catchError((error) {
        print('Failed to update document: $error');
      });
    }
  }

  Future<void> deleteHouse(String houseId) async {
    await housesCollection.doc(houseId).delete();
  }

  Future<void> fetchTenantData() async {
    try {
      final List<dynamic> tenants = widget.houseData['tenant'];

      final List<Future<DocumentSnapshot>> futures = tenants.map((tenantId) =>
          FirebaseFirestore.instance.collection('users').doc(tenantId).get()).toList();

      final List<DocumentSnapshot> snapshots = await Future.wait(futures);

      for (final snapshot in snapshots) {
        if (snapshot.exists) {
          final Map<String, dynamic>? tenantData = snapshot.data() as Map<String, dynamic>?;
          if (tenantData != null) {
            final Map<String, dynamic>? name =
            tenantData['name'] as Map<String, dynamic>?;

            setState(() {
              if (name != null) {
                tenantDataList.add({
                  'nama1': name['FirstName'] as String,
                  'nama2': name['LastName'] as String,
                  'phoneNumber': tenantData['phoneNumber'] as String,
                });
              }
            });
          } else {
            print('Field not found:');
          }
        } else {
          print('Document does not exist');
        }
      }
    } catch (e) {
      print('Error fetching tenant data: $e');
    }
  }

}