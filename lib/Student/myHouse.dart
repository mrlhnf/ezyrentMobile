import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';

class rumahku extends StatefulWidget {

  final String userid;

  const rumahku({
    Key? key,
    required this.userid,
  }) : super(key: key);

  @override
  _rumahkuState createState() => _rumahkuState();
}

class _rumahkuState extends State<rumahku> {
  final CollectionReference<Map<String, dynamic>> housesCollection = FirebaseFirestore.instance.collection('rumah');
  String myhouseID = '';
  String landlord = '';
  String contactO = '';
  double hargaRmh = 0;
  bool rentstatus = false;
  LatLng? lokasirumah;
  List<String> housemateku = [];
  List<Map<String,dynamic>> datahousemateku = [];
  List<String> imagePaths = [];
  List<String> downloadURLs = [];
  List<XFile>? selectedImages;
  List<String> selectedImageNames = [];

  @override
  void initState() {
    super.initState();
    findhouseid();
  }

  Future<void> findhouseid() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('rumah')
          .where('tenant', arrayContains: widget.userid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String documentID = snapshot.docs.first.id;
        if (documentID.isNotEmpty) {
          myhouseID = documentID;
          await getImagePaths(myhouseID);

          final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await housesCollection.doc(documentID).get();

          if (snapshot.exists) {
            final data = snapshot.data();
            if (data != null) {
              final lating = data['location'];
              final owner = data['owner'] as String;
              final price = data['price'];
              final openrent = data['openRent'];
              final ahlirumah = data['tenant'] as List<dynamic>;

              housemateku = ahlirumah.map((dynamic item) => item.toString()).toList();
              lokasirumah = LatLng(lating['lat'], lating['lng']);
              rentstatus = openrent;
              landlord = owner;
              hargaRmh = price;

              await getContactNo();
            }
          }
          await infoahlirumah();
        } else {
          print('Invalid document ID');
        }
      } else {
        print('No matching document found');
      }
    } catch (error) {
      print('Error retrieving document ID: $error');
    }
  }

  Future<void> getContactNo() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users') // Replace with your collection name
        .doc(landlord) // Replace with your document ID
        .get();

    if (snapshot.exists) {
      String contactNo = snapshot.data()!['phoneNumber'];
      setState(() {
        contactO = contactNo;
      });
    } else {
      print('Document does not exist');
    }
  }

  Future<void> getImagePaths(String docid) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await housesCollection.doc(docid).get();

    List<dynamic> pathList = snapshot.get('images');
    imagePaths = List<String>.from(pathList);

    await getDownloadURLs(imagePaths);
  }

  Future<void> getDownloadURLs(List<String> imagePaths) async {
    for (String path in imagePaths) {
      try {
        Reference ref = FirebaseStorage.instance.ref().child(path);
        String downloadURL = await ref.getDownloadURL();
        downloadURLs.add(downloadURL);
      } catch (e) {
        print('Error getting download URL for $path: ${e.toString()}');
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await housesCollection
        .doc(myhouseID)
        .get();

    return snapshot;
  }

  Future<void> infoahlirumah() async {
    try {
      final List<String> tenants = housemateku;

      final List<Future<DocumentSnapshot>> ahli = tenants.map((tenantId) =>
          FirebaseFirestore.instance.collection('users').doc(tenantId).get()).toList();

      final List<DocumentSnapshot> snapshots = await Future.wait(ahli);

      for (final snapshot in snapshots) {
        if (snapshot.exists) {
          final Map<String, dynamic>? tenantData = snapshot.data() as Map<String, dynamic>?;
          if (tenantData != null) {
            final Map<String, dynamic>? name =
            tenantData['name'] as Map<String, dynamic>?;

            if (name != null) {
              datahousemateku.add({
                'nama1': name['FirstName'] as String,
                'nama2': name['LastName'] as String,
                'phoneNumber': tenantData['phoneNumber'] as String,
              });
            }
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

  void carilokasi() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('House Location'),
          content: SizedBox(
            height: 200.0,
            width: 200.0,
            child: Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: lokasirumah!,
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('My House Location'),
                        position: lokasirumah!,
                      ),
                    },
                    //Text(info),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void continuerent() async {
    DocumentSnapshot<Map<String, dynamic>> userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(widget.userid).get();

    if (userSnapshot.exists) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userid)
          .update({'haveRent': false,}).then((value) {
        print('Document updated successfully!');
      }).catchError((error) {
        print('Failed to update document: $error');
      });
    }

    FirebaseFirestore.instance
        .collection('rumah')
        .doc(myhouseID)
        .get()
        .then((documentSnapshot) {
      if (documentSnapshot.exists) {
        int currentValue = documentSnapshot.data()?['quota'] ?? 0;
        int newValue = currentValue + 1;

        Map<String, dynamic> updatedData = {
          'quota': newValue,
          'tenant': FieldValue.arrayRemove([widget.userid]),
        };

        FirebaseFirestore.instance
            .collection('rumah')
            .doc(myhouseID)
            .update(updatedData)
            .then((value) {
          print('Fields updated successfully!');
        })
            .catchError((error) {
          print('Failed to update fields: $error');
        });
      }
    })
        .catchError((error) {
      print('Failed to retrieve document: $error');
    });
  }

  Future<void> payRent() async {
    PermissionStatus status = await Permission.storage.request();
    if (status.isGranted) {
      List<XFile>? images = await ImagePicker().pickMultiImage();
      setState(() {
        selectedImages = images;
        selectedImageNames = images.map((image) => image.name).toList();
      });

      if(selectedImages!.isNotEmpty){
        double splitbil = hargaRmh/housemateku.length;
        String bundar = splitbil.toStringAsFixed(2);
        double gajiku = double.parse(bundar);

        CollectionReference payment = FirebaseFirestore.instance.collection('transaction');
        User? user = FirebaseAuth.instance.currentUser;

        payment.add({
          'sender': user!.uid,
          'receiver': landlord,
          'amount': gajiku,
          'proof': '',
          'status': false,
        }).then((DocumentReference document) async {
          const snackBar = SnackBar(
            content: Text('You have succesfully made the payment!'),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          print('Transaction added with ID: ${document.id}');
          List<String> imageURLs = [];
          for (XFile imageFile in selectedImages!) {
            String imagePath = 'transaction/${document.id}/${DateTime.now().microsecondsSinceEpoch}.jpg';
            Reference ref = FirebaseStorage.instance.ref().child(imagePath);
            UploadTask uploadTask = ref.putFile(File(imageFile.path));
            await uploadTask.whenComplete(() => null);
            imageURLs.add(imagePath);
          }
          DocumentReference documentRef = FirebaseFirestore.instance.collection('transaction').doc(document.id);
          documentRef.update({
            'proof': imageURLs,
          });
          print('Transaction added with ID: ${document.id}');
        })
            .catchError((error) {
          print('Error adding transaction: $error');
        });
        Navigator.pushReplacementNamed(context, '/StudentHomepage');
      }
    } else {
      print('Permission to get images is denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (myhouseID.isEmpty) {
      return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.deepPurpleAccent,
            title: const Text('My House Detail'),
          ),
          body: Container(
            color: Colors.deepPurpleAccent,
          )
      );
    }
    else{
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurpleAccent,
          title: const Text('My House Detail'),
          actions: [
            IconButton(
              icon: const Icon(Icons.people),
              color: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return Scaffold(
                        appBar: AppBar(
                          backgroundColor: Colors.deepPurpleAccent,
                          title: const Text('My Housemates'),
                        ),
                        body: ListView.builder(
                          itemCount: housemateku.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text('${datahousemateku[index]['nama1']} ${datahousemateku[index]['nama2']}'),
                              subtitle: Text(datahousemateku[index]['phoneNumber']),
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
              icon: const Icon(Icons.location_on),
              color: Colors.red,
              onPressed: () async {
                carilokasi();
              },
            ),
          ],
        ),
        body: Container(
          color: Colors.deepPurpleAccent,
          child: Center(
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: getDocument(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return const CircularProgressIndicator();
                } else {
                  if (snapshot.hasData && snapshot.data != null) {
                    var data = snapshot.data!.data();
                    var daerah = data?['district'];
                    var nama = data?['name'];
                    var gender = data?['preffered gender'];
                    var harga = data?['price'];
                    var kuota = data?['quota'];
                    var jenis = data?['type'];
                    var ahlirmh = data?['tenant'] as List<dynamic>;
                    double splitbil = harga/ahlirmh.length;
                    String bundar = splitbil.toStringAsFixed(2);

                    return SingleChildScrollView(
                      child: Container(
                        color: Colors.deepPurpleAccent,
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
                                    title: const Text('Name:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text(nama),
                                  ),
                                  ListTile(
                                    title: const Text('District:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text(daerah),
                                  ),
                                  ListTile(
                                    title: const Text('Price:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text('RM' + harga.toStringAsFixed(2)),
                                  ),
                                  ListTile(
                                    title: const Text('Type:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text(jenis),
                                  ),
                                  ListTile(
                                    title: const Text('Quota:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text('$kuota person(s) more'),
                                  ),
                                  ListTile(
                                    title: const Text('Preferred Gender:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text(gender),
                                  ),
                                  ListTile(
                                    title: const Text('Contact Person:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                    trailing: Text(contactO),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 16.0),
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Confirmation'),
                                                content: const Text('Are you sure you want to stop renting the house?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    child: const Text('Cancel'),
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog
                                                    },
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      continuerent(); // Proceed with extending the rental period
                                                      Navigator.pushReplacementNamed(context, '/StudentHomepage');
                                                    },
                                                    style: ButtonStyle(
                                                      backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!), // Set the background color to red
                                                      textStyle: MaterialStateProperty.all<TextStyle>(const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Set the text style
                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10), // Set the border radius
                                                        ),
                                                      ),
                                                      padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), // Set the padding
                                                    ),
                                                    child: const Text('Confirm'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.delete_rounded),
                                        label: const Text('Stop Rent'),
                                        style: ButtonStyle(
                                          backgroundColor: MaterialStateProperty.all<Color>(Colors.red), // Set the background color to orange
                                          padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(12)),
                                          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                            RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(15), // Set the border radius
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Visibility(
                                        visible: rentstatus == false,
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: const Text('Confirmation'),
                                                  content: Text.rich(
                                                    TextSpan(
                                                      text: 'Total Amount to be Paid: ',
                                                      style: const TextStyle(fontSize: 15),
                                                      children: [
                                                        TextSpan(
                                                          text: 'RM$bundar',
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        const TextSpan(
                                                          text: '\nPlease insert proof of payment',
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      child: const Text('Cancel'),
                                                      onPressed: () {
                                                        Navigator.of(context).pop(); // Close the dialog
                                                      },
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        payRent();
                                                      },
                                                      style: ButtonStyle(
                                                        backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!), // Set the background color to green
                                                        textStyle: MaterialStateProperty.all<TextStyle>(const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), // Set the text style
                                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                          RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(10), // Set the border radius
                                                          ),
                                                        ),
                                                        padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), // Set the padding
                                                      ),
                                                      child: const Text('Pay'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          icon: const Icon(Icons.payment),
                                          label: const Text('Pay Rent'),
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all<Color>(Colors.green), // Set the background color to blue
                                            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.all(12)),
                                            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                              RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(15), // Set the border radius
                                              ),
                                            ),// Set the padding
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const Text('Document not found');
                  }
                }
              },
            ),
          ),
        ),
      );
    }
  }
}
