import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shoppeeclone/house.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HouseDetailsPage extends StatefulWidget {
  final House house;
  final String documentId;

  const HouseDetailsPage({
    Key? key,
    required this.house,
    required this.documentId,
  }) : super(key: key);

  @override
  _HouseDetailsPageState createState() => _HouseDetailsPageState();
}

class _HouseDetailsPageState extends State<HouseDetailsPage> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  final CollectionReference<Map<String, dynamic>> housesCollection =
  FirebaseFirestore.instance.collection('rumah');
  String? userid;
  String contactO = '';
  bool haveRented = false;
  int? radioValue;
  int textFieldCount = 0;
  List<Widget> textFields = [];
  List<String> textFieldValues = [];
  List<String>? tenants = [];
  List<String> imagePaths = [];
  List<String> downloadURLs = [];

  @override
  void initState() {
    super.initState();
    checkstatus();
    getImagePaths();
    getContactNo();
  }

  void checkstatus() {
    if (currentUser != null) {
      setState(() {
        userid = currentUser!.uid;
      });
      DocumentReference documentRef =
      FirebaseFirestore.instance.collection('users').doc(userid);

      documentRef.get().then((DocumentSnapshot snapshot) {
        if (snapshot.exists) {
          var data = snapshot.data() as Map<String, dynamic>;
          var status = data['haveRent'] as bool;
          var gender = data['gender'] as String;
          if (status == true || gender != widget.house.prefergender) {
            setState(() {
              haveRented = true;
            });
          }
        } else {
          print('Document does not exist');
        }
      }).catchError((error) {
        print('Error getting document: $error');
      });
    }
  }

  Future<void> getImagePaths() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
    await housesCollection.doc(widget.documentId).get();

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

  Future<void> getContactNo() async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users') // Replace with your collection name
        .doc(widget.house.owner) // Replace with your document ID
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

  void haveRent() {
    if (haveRented == false) {
      int newQuota = widget.house.quota! - 1;

      FirebaseFirestore.instance
          .collection('rumah')
          .doc(widget.documentId)
          .update({
        'quota': newQuota,
        'tenant': FieldValue.arrayUnion([userid]),
      }).then((_) {
        setState(() {
          widget.house.quota = newQuota;
          rentAlone();
        });

        const snackBar = SnackBar(
          content: Text('You have rented the house!'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.pushReplacementNamed(context, '/StudentHomepage');
      }).catchError((error) {
        print('Error updating quota: $error');
      });
    }
  }

  void haveRentG() async {
    if (haveRented == false) {
      int newQuota = widget.house.quota! - 1;

      FirebaseFirestore.instance
          .collection('rumah')
          .doc(widget.documentId)
          .update({
        'quota': newQuota,
        'tenant': FieldValue.arrayUnion([userid]),
      });

      for (int i = 0; i < textFieldValues.length; i++) {
        String? uid = await getDocumentId(textFieldValues[i]);
        if (uid != null) {
          DocumentReference documentRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

          documentRef.get().then((DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              var data = snapshot.data() as Map<String, dynamic>;
              var status = data['haveRent'] as bool;
              var gender = data['gender'] as String;
              if (status == false && gender == widget.house.prefergender) {
                setState(() {
                  tenants!.add(uid);
                  newQuota--;
                });
              }
            } else {
              print('Document does not exist');
            }
          }).catchError((error) {
            print('Error getting document: $error');
          });
        }
      }

      FirebaseFirestore.instance
          .collection('rumah')
          .doc(widget.documentId)
          .update({
        'quota': newQuota,
        'tenant': FieldValue.arrayUnion(tenants!),
      }).then((_) {
        setState(() {
          widget.house.quota = newQuota;
          rentGroup();
        });

        const snackBar = SnackBar(
          content: Text('You have rented the house!'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Navigator.pushReplacementNamed(context, '/StudentHomepage');
      }).catchError((error) {
        print('Error updating quota: $error');
      });
    }
  }

  Future<String?> getDocumentId(String email) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final String documentId = snapshot.docs.first.id;
      print('Document ID found: $documentId');
      return documentId;
    }

    print('No matching document found for email: $email');
    return null;
  }

  void rentAlone() async {
    if (userid != null && currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userid).get();

      if (userSnapshot.exists) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userid)
            .update({'haveRent': true,}).then((value) {
          print('Document updated successfully!');
        }).catchError((error) {
          print('Failed to update document: $error');
        });
      }
    }
  }

  void rentGroup() async {
    if (userid != null && currentUser != null) {
      DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('users').doc(userid).get();

      if (userSnapshot.exists) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(userid)
            .update({'haveRent': true,}).then((value) {
          print('Document updated successfully!');
        }).catchError((error) {
          print('Failed to update document: $error');
        });
      }

      for (int i = 0; i < tenants!.length; i++) {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(tenants![i]).get();

        if (userSnapshot.exists) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(tenants![i])
              .update({'haveRent': true,}).then((value) {
            print('Document ${tenants![i]} updated successfully!');
          }).catchError((error) {
            print('Failed to update document: $error');
          });
        }
      }
    }
  }

  void generateTextFields() {
    setState(() {
      textFields.clear();
      textFieldValues.clear();
      for (int i = 0; i < textFieldCount; i++) {
        textFieldValues.add('');
        textFields.add(
          TextField(
            decoration: InputDecoration(
              labelText: 'Housemate ${i + 1} email',
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
                Icons.email,
                color: Colors.purple,
              ),
            ),
            onChanged: (value) {
              setState(() {
                textFieldValues[i] = value;
              });
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('House Details'),
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
                      trailing: Text(widget.house.name!),
                    ),
                    ListTile(
                      title: const Text('Type',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.house.type!),
                    ),
                    ListTile(
                      title: const Text('Monthly Payment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text('RM${widget.house.price!.toStringAsFixed(2)}'),
                    ),
                    ListTile(
                      title: const Text('District',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.house.district!),
                    ),
                    ListTile(
                      title: const Text('Preffered Gender',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.house.prefergender!),
                    ),
                    ListTile(
                      title: const Text('Quota',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text('${widget.house.quota!} person(s) more'),
                    ),
                    ListTile(
                      title: const Text('Last Rent Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(widget.house.lastdate!),
                    ),
                    ListTile(
                      title: const Text('Contact Person',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          )
                      ),
                      trailing: Text(contactO),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: !haveRented && widget.house.quota! > 0,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16.0),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  radioValue = 0;
                                  textFields.clear();
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: radioValue == 0 ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: radioValue == 0 ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
                                    width: 2.0,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 48.0,
                                      color: radioValue == 0 ? Colors.yellow : Colors.white,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Rent Alone',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: radioValue == 0 ? Colors.yellow : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16.0),
                          Flexible(
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  radioValue = 1;
                                });
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Enter number of people excluding you',
                                        style: TextStyle(
                                          fontSize: 15,
                                        ),
                                      ),
                                      content: TextField(
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {
                                            textFieldCount = int.tryParse(value) ?? 0;
                                          });
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancel'),
                                        ),
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
                                          onPressed: () {
                                            if (textFieldCount <= widget.house.quota!) {
                                              Navigator.of(context).pop();
                                              generateTextFields();
                                            }
                                          },
                                          child: const Text('OK'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: radioValue == 1 ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: radioValue == 1 ? Colors.deepPurpleAccent : Colors.deepPurpleAccent,
                                    width: 2.0,
                                  ),
                                ),
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.group,
                                      size: 48.0,
                                      color: radioValue == 1 ? Colors.yellow : Colors.white,
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      'Rent with Friends',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: radioValue == 1 ? Colors.yellow : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Column(
                children: textFields,
              ),
              const SizedBox(height: 16.0),
              Visibility(
                visible: !haveRented && widget.house.quota!>0,
                child: Center(
                  child: ElevatedButton(
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
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Are you sure want to rent this house?',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancel'),
                              ),
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
                                onPressed: () {
                                  if (radioValue == 1) {
                                    haveRentG();
                                  } else if (radioValue == 0) {
                                    haveRent();
                                  }
                                },
                                child: const Text('Confirm'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Rent'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}