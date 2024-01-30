import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shoppeeclone/Student/Housedetail.dart';
import 'package:shoppeeclone/Student/myHouse.dart';
import 'package:shoppeeclone/profile.dart';
import 'package:shoppeeclone/house.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class studenthomepage extends StatefulWidget {
  const studenthomepage({super.key});

  @override
  State<studenthomepage> createState() => _studenthomepageState();
}

class _studenthomepageState extends State<studenthomepage> {
  final CollectionReference<Map<String, dynamic>> housesCollection = FirebaseFirestore.instance.collection('rumah');
  bool ascendingOrder = true;
  bool buttonclicked = false;
  String selectedData = '';
  String emeluser = '';
  Set<Marker> markers = {}; // Set to store the markers for house locations
  LatLng? currentlocation ;
  List<House> houses = []; // Replace this with your list of House objects

  @override
  void initState() {
    super.initState();
    createObject();
    useremail();
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void filterByDistrict(String district) {
    setState(() {
      selectedData = district;
    });
  }

  void filterByHouseType(String houseType) {
    setState(() {
      selectedData = houseType;
    });
  }

  Future<void> createObject() async{
    setState(() {
      houses.clear();
      markers.clear();
    });
    try {
      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await FirebaseFirestore.instance.collection('rumah').get();
      if (querySnapshot.docs.isNotEmpty) {
        for (QueryDocumentSnapshot<Map<String, dynamic>> documentSnapshot in querySnapshot.docs) {
          House house = House.fromFirestore(documentSnapshot);
          houses.add(house);
        }
      }
      await _getUserLocation();
    } catch (error) {
      print('Failed to create object data: $error');
    }
    return Future.delayed(const Duration(seconds: 1));
  }

  Future <void> _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Check if location services are enabled
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return;
      }

      // Check for location permission
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied, we cannot request permissions.');
        return;
      }

      if (permission == LocationPermission.denied) {
        // Request location permission
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          print('Location permissions are denied (actual value: $permission).');
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        currentlocation = userLocation;
      });

      print('User Location: $userLocation');

      for (var house in houses) {
        if (house.location != null) {
          final houseLocation = LatLng(house.location!['lat'], house.location!['lng']);
          markers = Set<Marker>.from(houses.map((house) {
            Map<String, dynamic> location = house.location!;
            return Marker(
              markerId: MarkerId(house.objectId!),
              position: LatLng(location['lat'], location['lng']),
            );
          }));
          List<dynamic>? distanceTime = await fetchDistanceData(userLocation, houseLocation);
          if (distanceTime != null) {
            // Update the properties of the House object
            house.distanceTime = distanceTime;
          } else {
            print('Failed to fetch distance data');
          }
        }
      }

      setState(() {
        houses.sort((a, b) {
          if (a.distanceTime != null && b.distanceTime != null) {
            String distanceStringA = a.distanceTime![0].replaceAll(RegExp(r'[^0-9.]'), '');
            String distanceStringB = b.distanceTime![0].replaceAll(RegExp(r'[^0-9.]'), '');

            try {
              double distanceA = double.parse(distanceStringA);
              double distanceB = double.parse(distanceStringB);

              // Compare the distances in ascending order
              return distanceA.compareTo(distanceB);
            } catch (e) {
              print('Error parsing distances: $e');
              return 0;
            }
          } else {
            return 0;
          }
        });
      });
        } catch (error) {
      print('Failed to retrieve user location: $error');
    }
    return Future.delayed(const Duration(seconds: 1));
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

  Future<List<dynamic>?> fetchDistanceData(LatLng userLocation, LatLng houseLocation) async {
    //final apiKey = '';
    const apiKey = '';
    final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${userLocation.latitude},${userLocation.longitude}&destinations=${houseLocation.latitude},${houseLocation.longitude}&key=$apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final elements = data['rows'][0]['elements'];
        if (elements[0]['status'] == 'OK') {
          final distance = elements[0]['distance']['text'];
          final duration = elements[0]['duration']['text'];
          print('Distance: $distance');
          print('Duration: $duration');

          List<dynamic> jarakmasa = [distance, duration];

          return jarakmasa;
        } else {
          print('Failed to fetch distance data. Element status: ${elements[0]['status']}');
        }
      } else {
        print('Failed to fetch distance data. API status: ${data['status']}');
      }
    } else {
      print('Failed to fetch distance data. Status code: ${response.statusCode}');
    }
    return null;
  }

  void _showHouseLocation(LatLng houseLocation, String info) {
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
                    markers: markers,
                  ),
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8), // Add some spacing between the icon and text
                    Text(
                      info,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )

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

  @override
  Widget build(BuildContext context) {
    var profilepic = 'images/anon.png';

    if (buttonclicked == true) {
      houses.sort((a, b) {
        double priceA = a.price!.toDouble();
        double priceB = b.price!.toDouble();
        if (ascendingOrder) {
          return priceA.compareTo(priceB);
        } else {
          return priceB.compareTo(priceA);
        }
      });
    } else {
      houses.sort((a, b) {
        if (a.distanceTime != null && b.distanceTime != null) {
          String distanceStringA = a.distanceTime?[0].replaceAll(RegExp(r'[^0-9.]'), '');
          String distanceStringB = b.distanceTime?[0].replaceAll(RegExp(r'[^0-9.]'), '');

          try {
            double distanceA = double.parse(distanceStringA);
            double distanceB = double.parse(distanceStringB);

            // Compare the distances in ascending order
            return distanceA.compareTo(distanceB);
          } catch (e) {
            print('Error parsing distances: $e');
            return 0;
          }
        } else {
          return 0;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('List of House'),
        actions: [
          IconButton(
            icon: Icon(ascendingOrder ? Icons.trending_up : Icons.trending_down),
            onPressed: () {
              setState(() {
                ascendingOrder = !ascendingOrder;
                buttonclicked = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.location_searching),
            onPressed: () {
              setState(() {
                buttonclicked = false;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.deepPurpleAccent,
          height: MediaQuery.of(context).size.height - AppBar().preferredSize.height - 15,
          child: RefreshIndicator(
            onRefresh: createObject,
            triggerMode: RefreshIndicatorTriggerMode.onEdge,
            child: ListView.builder(
              itemCount: houses.length,
              itemBuilder: (BuildContext context, int index) {
                if (houses[index].status == true) {
                  if (selectedData.isNotEmpty &&
                      (houses[index].type! == selectedData ||
                          houses[index].district! == selectedData)) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HouseDetailsPage(
                              house: houses[index],
                              documentId: houses[index].objectId!,
                            ),
                          ),
                        );
                      },
                      child: Padding(
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
                                    Text(houses[index].name!),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if(houses[index].type! == 'Terrace')
                                          IconButton(
                                            icon: const Icon(Icons.home),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Bungalow')
                                          IconButton(
                                            icon: const Icon(Icons.villa),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Flat')
                                          IconButton(
                                            icon: const Icon(Icons.apartment),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Semi-D')
                                          IconButton(
                                            icon: const Icon(Icons.holiday_village),
                                            onPressed: () {},
                                          ),
                                        Text(
                                          'RM${houses[index].price!.toStringAsFixed(0)}',
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
                                    '${houses[index].quota!}/${houses[index].max!}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  if(houses[index].prefergender! == 'Male')
                                    IconButton(
                                      color: Colors.blueAccent,
                                      icon: const Icon(Icons.man),
                                      onPressed: () {},
                                    ),
                                  if(houses[index].prefergender! == 'Female')
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
                                      houses[index].location!;
                                      _showHouseLocation(
                                        LatLng(mapField['lat'], mapField['lng']),
                                        houses[index].distanceTime.toString(),
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
                  } else if (selectedData.isNotEmpty &&
                      (houses[index].type! != selectedData ||
                          houses[index].district! != selectedData)) {
                    return Container();
                  } else {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HouseDetailsPage(
                              house: houses[index],
                              documentId: houses[index].objectId!,
                            ),
                          ),
                        );
                      },
                      child: Padding(
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
                                    Text(houses[index].name!),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if(houses[index].type! == 'Terrace')
                                          IconButton(
                                            icon: const Icon(Icons.home),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Bungalow')
                                          IconButton(
                                            icon: const Icon(Icons.villa),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Flat')
                                          IconButton(
                                            icon: const Icon(Icons.apartment),
                                            onPressed: () {},
                                          ),
                                        if(houses[index].type! == 'Semi-D')
                                          IconButton(
                                            icon: const Icon(Icons.holiday_village),
                                            onPressed: () {},
                                          ),
                                        Text(
                                          'RM${houses[index].price!.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
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
                                    '${houses[index].quota!}/${houses[index].max!}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  if(houses[index].prefergender! == 'Male')
                                    IconButton(
                                      color: Colors.blueAccent,
                                      icon: const Icon(Icons.man),
                                      onPressed: () {},
                                    ),
                                  if(houses[index].prefergender! == 'Female')
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
                                      houses[index].location!;
                                      _showHouseLocation(
                                        LatLng(mapField['lat'], mapField['lng']),
                                        houses[index].distanceTime.toString(),
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
                  }
                } else {
                  return Container(); // Return an empty container for items with false status
                }
              },
            ),
          ),
        ),
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
                    title: const Text('My House'),
                    onTap: () {
                      final iduser = FirebaseAuth.instance.currentUser!.uid;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => rumahku(userid: iduser),
                        ),
                      );
                    },
                  ),
                  ExpansionTile(
                    title: const Text('Filter by District'),
                    children: [
                      ListTile(
                        title: const Text('Merlimau'),
                        onTap: () {
                          filterByDistrict('Merlimau');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Sri Mendapat'),
                        onTap: () {
                          filterByDistrict('Sri Mendapat');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Serkam'),
                        onTap: () {
                          filterByDistrict('Serkam');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        title: const Text('Jasin'),
                        onTap: () {
                          filterByDistrict('Jasin');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: const Text('Filter by House Type'),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.home), // Add the icon here
                        title: const Text('Terrace'),
                        onTap: () {
                          filterByHouseType('Terrace');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.villa), // Add the icon here
                        title: const Text('Bungalow'),
                        onTap: () {
                          filterByHouseType('Bungalow');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.apartment), // Add the icon here
                        title: const Text('Flat'),
                        onTap: () {
                          filterByHouseType('Flat');
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.holiday_village), // Add the icon here
                        title: const Text('Semi-D'),
                        onTap: () {
                          filterByHouseType('Semi-D');
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  ListTile(
                    title: const Text(
                      'Clear Filter',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        selectedData = '';
                      });
                      Navigator.pop(context);
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
}
