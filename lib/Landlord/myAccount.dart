import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankingHomePage extends StatefulWidget {
  const BankingHomePage({super.key});

  @override
  _BankingHomePageState createState() => _BankingHomePageState();
}

class _BankingHomePageState extends State<BankingHomePage> with SingleTickerProviderStateMixin {
  final CollectionReference<Map<String, dynamic>> housesCollection = FirebaseFirestore.instance.collection('users');
  final iduser = FirebaseAuth.instance.currentUser!.uid;
  late AnimationController _animationController;
  late Animation<double> _animation;
  String accbal = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 25, end: 50).animate(_animationController);
    _animationController.repeat(reverse: true);
    getaccbal();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void getaccbal() {
    DocumentReference docRef = FirebaseFirestore.instance.collection('users').doc(iduser);
    docRef.get().then((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        var balance = snapshot.get('accBal');
        setState(() {
          accbal = balance.toStringAsFixed(2);
        });
      } else {
        print('Document does not exist');
      }
    }).catchError((error) {
      print('Error retrieving document: $error');
    });
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> transactionHistory() async {
    CollectionReference<Map<String, dynamic>> collectionReference =
    FirebaseFirestore.instance.collection('transaction');

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await collectionReference
        .where('status', isEqualTo: true)
        .where('receiver', isEqualTo: iduser)
        .get();
    return querySnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('Account Balance'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (BuildContext context, Widget? child) {
                  return Icon(
                    Icons.account_balance_wallet,
                    size: _animation.value,
                    color: Colors.green,
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Account Balance',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'RM$accbal',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0), // Set the desired border radius
                    ),
                  ),
                  minimumSize: MaterialStateProperty.all<Size>(
                    const Size(120.0, 40.0), // Set the desired width and height
                  ),
                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!),
                ),
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return Scaffold(
                          appBar: AppBar(
                            backgroundColor: Colors.deepPurpleAccent,
                            title: const Text('Transaction History'),
                          ),
                          body: FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                            future: transactionHistory(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(), // Display a loading indicator
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              } else if (snapshot.hasData) {
                                List<DocumentSnapshot<Map<String, dynamic>>> documents = snapshot.data!;
                                return ListView.builder(
                                  itemCount: documents.length,
                                  itemBuilder: (context, index) {
                                    Map<String, dynamic>? data = documents[index].data();
                                    return ListTile(
                                      title: Text('From: \n${data!['sender']}'),
                                      trailing: Text('RM${data['amount'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.green
                                        ),
                                      ),
                                    );
                                  },
                                );
                              } else {
                                return const Center(
                                  child: Text('No data available.'),
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('View Transactions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}