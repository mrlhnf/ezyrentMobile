import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shoppeeclone/Landlord/Housedetail.dart';
import 'package:shoppeeclone/Landlord/registration.dart';
import 'package:shoppeeclone/Landlord/myAccount.dart';
import 'package:shoppeeclone/profile.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class HouseRentalHomePage extends StatefulWidget {
  const HouseRentalHomePage({super.key});

  @override
  State<HouseRentalHomePage> createState() => _HouseRentalHomePageState();
}

class _HouseRentalHomePageState extends State<HouseRentalHomePage> {
  final CollectionReference<Map<String, dynamic>> housesCollection =
  FirebaseFirestore.instance.collection('rumah');
  List<XFile>? gambar;
  Map<String, dynamic>? maplokasi;
  String emeluser = '';
  Set<Marker> markers = {}; // Set to store the markers for house locations

  @override
  void initState() {
    super.initState();
    useremail();
  }

  void useremail() {
    final iduser = FirebaseAuth.instance.currentUser!.uid;
    DocumentReference docRef = FirebaseFirestore.instance.collection('users').doc(iduser);

    docRef.get().then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        // Document exists, retrieve field value
        var fieldValue = snapshot.get('email') as String;
        setState(() {
          emeluser = fieldValue;
        });
      } else {
        // Document does not exist
        print('Document does not exist');
      }
    }).catchError((error) {
      // Handle any errors that occurred
      print('Error retrieving document: $error');
    });
  }

  void _showHouseLocation(LatLng houseLocation, String id) {
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
                      target: houseLocation,
                      zoom: 15.0,
                    ),
                    markers: <Marker>{
                      Marker(
                        markerId: MarkerId(id),
                        position: houseLocation,
                      ),
                    },
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

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    var profilepic = 'images/anon.png';

    User? user = FirebaseAuth.instance.currentUser;
    String? userId = user?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('House Rental'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewHouseRegistrationPage()),
              ).then((returnedData) {
                if (returnedData != null) {
                  String name = returnedData['name'];
                  String type = returnedData['type'];
                  double price = returnedData['price'];
                  String location = returnedData['location'];
                  String gender = returnedData['gender'];
                  String date = returnedData['date'];
                  int quota = returnedData['quota'];
                  gambar = returnedData['selectedImages'];
                  maplokasi = returnedData['selectedLocation'];
                  registerHouse(name, type, price, location, gender, date, quota, gambar, maplokasi);
                }
              });
            },
          ),

        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: housesCollection
            .where('owner', isEqualTo: userId)
            .where('status', isEqualTo: true)
            .snapshots(),

        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          List<QueryDocumentSnapshot<Map<String, dynamic>>> houseDocs = snapshot.data!.docs;

          return SingleChildScrollView(
            child: Container(
              color: Colors.deepPurpleAccent,
              height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 15,
              child: ListView.builder(
                itemCount: houseDocs.length,
                itemBuilder: (BuildContext context, int index) {
                  Map<String, dynamic> houseData = houseDocs[index].data();
                  String houseId = houseDocs[index].id;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => myHouse(
                            houseData: houseData,
                            houseId: houseId,
                          ),
                        ),
                      );
                    },
                    child:
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white, // Set the background color to white
                          border: Border.all(
                            color: Colors.grey,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(houseData['name']),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      if(houseData['type'] == 'Terrace')
                                        IconButton(
                                          icon: const Icon(Icons.home),
                                          onPressed: () {},
                                        ),
                                      if(houseData['type'] == 'Bungalow')
                                        IconButton(
                                          icon: const Icon(Icons.villa),
                                          onPressed: () {},
                                        ),
                                      if(houseData['type'] == 'Flat')
                                        IconButton(
                                          icon: const Icon(Icons.apartment),
                                          onPressed: () {},
                                        ),
                                      if(houseData['type'] == 'Semi-D')
                                        IconButton(
                                          icon: const Icon(Icons.holiday_village),
                                          onPressed: () {},
                                        ),
                                      Text(
                                        'RM' + houseData['price'].toStringAsFixed(0),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 5),
                                Text(
                                  '${houseData['quota']}/${houseData['max']}',
                                  style: const TextStyle(
                                    fontSize: 12, // Set the desired font size here
                                  ),
                                ),
                                if(houseData['preffered gender'] == 'Male')
                                  IconButton(
                                    color: Colors.blueAccent,
                                    icon: const Icon(Icons.man),
                                    onPressed: () {},
                                  ),
                                if(houseData['preffered gender'] == 'Female')
                                  IconButton(
                                    color: Colors.pinkAccent,
                                    icon: const Icon(Icons.woman),
                                    onPressed: () {},
                                  ),
                                IconButton(
                                  color: Colors.red,
                                  icon: const Icon(Icons.location_on),
                                  onPressed: () {
                                    Map<String, dynamic> mapField =
                                    houseData['location'];
                                    _showHouseLocation(
                                      LatLng(mapField['lat'], mapField['lng']),
                                      houseId,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: const Text(''),
                    accountEmail: Text(emeluser),
                    currentAccountPicture: GestureDetector(
                      child: CircleAvatar(
                        backgroundImage: AssetImage(profilepic),
                      ),
                      onTap: () {
                        final iduser = FirebaseAuth.instance.currentUser!.uid;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePage(userId: iduser),
                          ),
                        );
                      },
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                  ListTile(
                    title: const Text('My Account'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BankingHomePage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.logout),
                color: Colors.red,
                onPressed: _signOut,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> registerHouse(
      String name, String type, double price, String location, String gender,
      String date, int quota, List<XFile>? images, Map<String, dynamic>? selectedLocation,
      ) async {
    User? user = FirebaseAuth.instance.currentUser;
    List<String> tenant = [];

    if (user != null) {
      String uid = user.uid;

      // Upload images to Firebase Storage
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
      await housesCollection.add({
        'name': name,
        'type': type,
        'price': price,
        'status' : false,
        'openRent' : true,
        'tenant' : tenant,
        'quota': quota,
        'lastDate': date,
        'max': quota,
        'district': location,
        'preffered gender': gender,
        'owner': uid,
        'images': imageURLs,
        'location': selectedLocation, // Use the converted locationData
      });
    } else {
      print('No user is currently signed in.');
    }
  }

  Future<void> deleteHouse(String houseId) async {
    await housesCollection.doc(houseId).delete();
  }

}