import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class SelectRolePageG extends StatefulWidget {
  const SelectRolePageG({
    Key? key,
  }) : super(key: key);

  @override
  State<SelectRolePageG> createState() => _SelectRolePageGState();
}

class _SelectRolePageGState extends State<SelectRolePageG> {
  final TextEditingController roleController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final studentID = TextEditingController();
  final ICnum = TextEditingController();
  final phoneNum = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  RoleLabel? selectedRole;
  GenderLabel? selectedGender;
  String? chosenRole;
  String? chosenGender;
  String? userId;
  String? userEmail;
  String? userName;

  @override
  void dispose() {
    roleController.dispose();
    genderController.dispose();
    studentID.dispose();
    ICnum.dispose();
    phoneNum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    void signOut() async {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }

    final List<DropdownMenuEntry<RoleLabel>> colorEntries =
    <DropdownMenuEntry<RoleLabel>>[];
    for (final RoleLabel icon in RoleLabel.values) {
      colorEntries.add(
        DropdownMenuEntry<RoleLabel>(
            value: icon, label: icon.label),
      );
    }

    final List<DropdownMenuEntry<GenderLabel>> iconEntries =
    <DropdownMenuEntry<GenderLabel>>[];
    for (final GenderLabel icon in GenderLabel.values) {
      iconEntries
          .add(DropdownMenuEntry<GenderLabel>(value: icon, label: icon.label));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup your Account'),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            children: <Widget>[
              const SizedBox(height: 10),
              TextFormField(
                controller: phoneNum,
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
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    DropdownMenu<RoleLabel>(
                      initialSelection: RoleLabel.landlord,
                      controller: roleController,
                      label: const Text('Role',
                        style: TextStyle(color: Colors.purple),
                      ),
                      dropdownMenuEntries: colorEntries,
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 2.0), // Set the desired border color here
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      onSelected: (RoleLabel? role) {
                        setState(() {
                          selectedRole = role;
                          chosenRole = selectedRole!.label;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    DropdownMenu<GenderLabel>(
                      initialSelection: GenderLabel.male,
                      controller: genderController,
                      enableFilter: true,
                      leadingIcon: const Icon(Icons.search, color: Colors.purple,),
                      label: const Text('Gender',
                        style: TextStyle(color: Colors.purple),
                      ),
                      dropdownMenuEntries: iconEntries,
                      inputDecorationTheme: InputDecorationTheme(
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black, width: 2.0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 5.0),
                      ),
                      onSelected: (GenderLabel? icon) {
                        setState(() {
                          selectedGender = icon;
                          chosenGender = selectedGender!.label;
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (selectedRole != null && selectedGender != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Row(
                        children: [
                          Icon(
                            selectedGender?.icon,
                          ),
                          Icon(
                            selectedRole?.icon,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                const Text('Please select a role and a gender.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 10),
              Visibility(
                visible: selectedRole == RoleLabel.student,
                child: TextFormField(
                  controller: studentID,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your student ID';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Student ID',
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
                      Icons.perm_contact_cal_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              Visibility(
                visible: selectedRole == RoleLabel.landlord,
                child: TextFormField(
                  controller: ICnum,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your IC number';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'IC Number',
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
                      Icons.perm_contact_cal_outlined,
                      color: Colors.purple,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 10),
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
                onPressed: () {
                  if (selectedRole != null) {
                    String nofon = phoneNum.text;
                    if(chosenRole! == 'Landlord') {
                      String noic = ICnum.text;
                      _saveRoleAndNavigate(context, chosenRole!, chosenGender!, nofon, noic );
                    }
                    else if(chosenRole! == 'Student') {
                      String studentid = studentID.text;
                      _saveRoleAndNavigate(context, chosenRole!, chosenGender!, nofon, studentid);
                    }
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveRoleAndNavigate(BuildContext context, String role, String gender, String fonnum, String identity) async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      if(role == 'Landlord'){
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await _auth.signInWithCredential(credential);

          final String? email = userCredential.user!.email;
          final String? namauser = userCredential.user!.displayName;
          final String userid = userCredential.user!.uid;
          print('Signed up with Google and UID: $email $userid');
          print('Welcome: $namauser');

          setState(() {
            userEmail = email;
            userId = userid;
            userName = namauser;
          });
        } catch (e) {
          print('Error signing in with Google: $e');
        }
        try {
          List<String> nameParts = userName!.split(' ');

          String namafirst = nameParts.first; // First name
          String namasecond = nameParts.last; // Last name
          final name = {
            'FirstName': namafirst,
            'LastName': namasecond,
          };
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({
            'role': role,
            'email': userEmail,
            'gender': gender,
            'name' : name,
            'accBal' : 0,
            'phoneNumber' : fonnum,
            'IC number' : identity,
            'signInMethod' : 'Google',
          });

          // Navigate to the home page or any other screen
          Navigator.pushReplacementNamed(context, '/OwnerHomepage');
        } catch (e) {
          print('Error saving role: $e');
        }
      }

      else if(role == 'Student'){
        try {
          final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
          final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          final UserCredential userCredential = await _auth.signInWithCredential(credential);

          final String? email = userCredential.user!.email;
          final String? namauser = userCredential.user!.displayName;
          final String userid = userCredential.user!.uid;
          print('Signed up with Google and UID: $email $userid');

          setState(() {
            userEmail = email;
            userId = userid;
            userName = namauser;

          });
        } catch (e) {
          print('Error signing in with Google: $e');
        }
        try {
          List<String> nameParts = userName!.split(' ');

          String namafirst = nameParts.first; // First name
          String namasecond = nameParts.last; // Last name
          final name = {
            'FirstName': namafirst,
            'LastName': namasecond,
          };
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .set({
            'role': role,
            'email': userEmail,
            'gender': gender,
            'haveRent': false,
            'name' : name,
            'phoneNumber' : fonnum,
            'Student ID' : identity,
            'signInMethod' : 'Google',
          });

          // Navigate to the home page or any other screen
          Navigator.pushReplacementNamed(context, '/StudentHomepage');
        } catch (e) {
          print('Error saving role: $e');
        }
      }
    }
  }
}

enum RoleLabel {

  landlord('Landlord', Icons.house),
  student('Student', Icons.school);

  const RoleLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum GenderLabel {

  male('Male', Icons.man),
  female('Female', Icons.woman);

  const GenderLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}
