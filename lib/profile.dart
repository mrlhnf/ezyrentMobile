import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _editMode = false;
  String signinmethod = '';
  final formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    checkSignUpMethod();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> checkSignUpMethod() async {
    try {
      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      DocumentReference documentRef = usersCollection.doc(widget.userId);
      DocumentSnapshot snapshot = await documentRef.get();

      if (snapshot.exists) {
        String method = snapshot.get('signInMethod');
        setState(() {
          signinmethod = method;
        });
      } else {
        print('Document does not exist!');
      }
    } catch (e) {
      print('Error retrieving data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              if (_editMode) {
                _showConfirmationDialog();
              } else {
                setState(() {
                  _editMode = true;
                });
              }
            },
            icon: Icon(_editMode ? Icons.check : Icons.edit),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == null || !snapshot.data!.exists) {
            return const Text('User data not found');
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          var name = userData['name'] as Map<String, dynamic>;
          var profilePictureUrl = 'images/anon.png';

          _firstNameController.text = name['FirstName'] ?? '';
          _lastNameController.text = name['LastName'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneNumberController.text = userData['phoneNumber'] ?? '';

          return SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(profilePictureUrl),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _editMode
                          ? Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'First Name',
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
                              Icons.account_circle,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      )
                          : Text(name['FirstName'] ?? ''),
                      const SizedBox(width: 5),
                      _editMode
                          ? Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Last Name',
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
                              Icons.account_circle,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      )
                          : Text(name['LastName'] ?? ''),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        ListTile(
                          title: Visibility(
                            visible: !_editMode, // Show the Text widget when _editMode is false
                            child: const Text('Email'),
                          ),
                          subtitle: _editMode
                              ? TextFormField(
                            controller: _emailController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Email',
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
                          )
                              : Text(userData['email'] ?? ''),
                        ),
                        if(userData['role'] == "Landlord")
                        Visibility(
                          visible: !_editMode,
                          child: ListTile(
                            title: const Text('IC Number'),
                            subtitle: Text(userData['IC number'] ?? ''),
                          ),
                        )
                        else if(userData['role'] == "Student")
                          Visibility(
                            visible: !_editMode,
                            child: ListTile(
                              title: const Text('Student ID'),
                              subtitle: Text(userData['Student ID']),
                            ),
                          ),
                        Visibility(
                          visible: _editMode,
                          child: const SizedBox(height: 16),
                        ),
                        ListTile(
                          title: Visibility(
                            visible: !_editMode, // Show the Text widget when _editMode is false
                            child: const Text('Phone Number'),
                          ),
                          subtitle: _editMode
                              ? TextFormField(
                            controller: _phoneNumberController,
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
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
                                Icons.phone,
                                color: Colors.purple,
                              ),
                            ),
                          )
                              : Text(userData['phoneNumber'] ?? ''),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: const SizedBox(height: 16),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: ListTile(
                            subtitle: TextFormField(
                              controller: _currentPasswordController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Current Passowrd',
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
                                  Icons.password,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: const SizedBox(height: 16),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: ListTile(
                            subtitle: TextFormField(
                              controller: _newPasswordController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'New Passowrd',
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
                                  Icons.password,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: const SizedBox(height: 16),
                        ),
                        Visibility(
                          visible: _editMode && signinmethod=='Firebase',
                          child: ListTile(
                            subtitle: TextFormField(
                              controller: _confirmNewPasswordController,
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                else if (value != _newPasswordController.text) {
                                  return 'Password do not match';
                                }
                                return null;
                              },
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Confirm Passowrd',
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
                                  Icons.password,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: _editMode,
                          child: const SizedBox(height: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
                },
      ),
    );
  }

  void _showConfirmationDialog() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirmation'),
            content: const Text('Do you want to save the changes?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  setState(() {
                    _editMode = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  _updateUserProfile();
                  setState(() {
                    _editMode = false;
                  });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  }

  void _updateUserProfile() async {
    try {
      var updatedData = {
        'name': {
          'FirstName': _firstNameController.text,
          'LastName': _lastNameController.text,
        },
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      User? user = _auth.currentUser;
      await user!.updateEmail(_emailController.text);

      AuthCredential credentials = EmailAuthProvider.credential(
        email: _emailController.text,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credentials);
      await user.updatePassword(_newPasswordController.text);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update(updatedData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile.'),
        ),
      );
    }
  }
}