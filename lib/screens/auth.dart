import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_chat/widget/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class Authentication extends StatefulWidget {
  const Authentication({super.key});

  @override
  State<Authentication> createState() => _AthenticationState();
}

class _AthenticationState extends State<Authentication> {
  final _form = GlobalKey<FormState>();
  bool isLogin = true;

  String enteredEmail = '';
  String enteredPassword = '';
  String enteredUserName = '';
  File? selectedImage;
  bool isAuthenticating = false;

  void onSubmit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid || selectedImage == null && !isLogin) {
      return;
    }

    _form.currentState!.save();
    try {
      setState(() {
        isAuthenticating = true;
      });
      if (isLogin) {
        // add login details here
        await _firebase.signInWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
      } else {
        final userCrendential = await _firebase.createUserWithEmailAndPassword(
          email: enteredEmail,
          password: enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCrendential.user!.uid}.jpg');
        await storageRef.putFile(selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCrendential.user!.uid)
            .set({
          'username': enteredUserName,
          'email': enteredEmail,
          'image_url': imageUrl,
        });
      }
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? "Registration failed."),
        ),
      );
      setState(() {
        isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: const EdgeInsets.only(
                    top: 30,
                    bottom: 20,
                    right: 20,
                    left: 20,
                  ),
                  child: Image.asset(
                    'assets/images/chat.png',
                    width: 150,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Card(
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 30,
                        bottom: 20,
                        right: 20,
                        left: 20,
                      ),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _form,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isLogin)
                                UserImagePicker(
                                  onPickedImage: (pickedImage) {
                                    selectedImage = pickedImage;
                                  },
                                ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Email Address',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter create email address';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  enteredEmail = value!;
                                },
                              ),
                              if (!isLogin)
                                TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: 'Username'),
                                  enableSuggestions: false,
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value.trim().length < 4) {
                                      return 'Please enter at least 4 characters';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    enteredUserName = value!;
                                  },
                                ),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                ),
                                keyboardType: TextInputType.emailAddress,
                                obscureText: true,
                                validator: (value) {
                                  if (value!.isEmpty || value.length <= 6) {
                                    return 'Please enter correct password';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  enteredPassword = value!;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              if (isAuthenticating)
                                CircularProgressIndicator.adaptive(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                ),
                              if (!isAuthenticating)
                                ElevatedButton(
                                  onPressed: onSubmit,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white),
                                  child: Text(isLogin ? 'LogIn' : 'Sign Up'),
                                ),
                              if (!isAuthenticating)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isLogin = !isLogin;
                                    });
                                  },
                                  child: Text(
                                    isLogin
                                        ? 'create new account'
                                        : 'Already have account',
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
