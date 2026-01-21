import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'package:app12/pages/home_page.dart'; // Import the HomePage

class LoginSignupPage extends StatefulWidget {
  const LoginSignupPage({super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> {
  bool showLogin = true;

  // Controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController(); // signup only
  final passwordController = TextEditingController();
  final familyCodeController = TextEditingController(); // login only

  String selectedRole = ""; // homeowner or member

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------ FAMILY CODE GENERATOR ------------------
  String generateFamilyCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)])
        .join();
  }

  // ------------------ POPUP ------------------
  void showErrorPopup(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showInfoPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ------------------ LOGIN ------------------
  Future<void> login() async {
    try {
      String username = usernameController.text.trim();
      String password = passwordController.text.trim();
      String enteredFamilyCode = familyCodeController.text.trim();

      if (username.isEmpty || password.isEmpty || enteredFamilyCode.isEmpty) {
        showErrorPopup("All fields are required");
        return;
      }

      QuerySnapshot snapshot = await _db
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (snapshot.docs.isEmpty) {
        showErrorPopup("Username not found");
        return;
      }

      var userData = snapshot.docs.first.data() as Map<String, dynamic>;
      String email = userData["email"];
      String storedFamilyCode = userData["familyCode"] ?? "";

      // Check family code only for members
      if (userData["role"] == "member" && enteredFamilyCode != storedFamilyCode) {
        showErrorPopup("Incorrect family code");
        return;
      }

      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        // Navigate to HomePage with username
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(username: username),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          showErrorPopup("Incorrect password");
        } else {
          showErrorPopup("Login error: ${e.message}");
        }
      }
    } catch (e) {
      showErrorPopup(e.toString());
    }
  }

  // ------------------ SIGNUP ------------------
  Future<void> signup() async {
    try {
      if (selectedRole.isEmpty) {
        showErrorPopup("Please select a role");
        return;
      }

      String username = usernameController.text.trim();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();

      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        showErrorPopup("All fields are required");
        return;
      }

      if (password.length < 6) {
        showErrorPopup("Password must be at least 6 characters");
        return;
      }

      String familyCode = selectedRole == "homeowner" ? generateFamilyCode() : "";

      UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _db.collection("users").doc(user.user!.uid).set({
        "username": username,
        "email": email,
        "familyCode": familyCode,
        "role": selectedRole,
        "createdAt": DateTime.now(),
      });

      if (selectedRole == "homeowner") {
        showInfoPopup("Family Code Generated", "Your family code is: $familyCode");
      } else {
        showInfoPopup("Success", "Account created successfully!");
      }
    } catch (e) {
      showErrorPopup(e.toString());
    }
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                showLogin ? "Welcome Back" : "Create Account",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 25),
              inputField(controller: usernameController, label: "Username"),
              const SizedBox(height: 15),
              if (!showLogin)
                inputField(controller: emailController, label: "Email"),
              if (!showLogin) const SizedBox(height: 15),
              inputField(controller: passwordController, label: "Password", obscure: true),
              const SizedBox(height: 15),
              if (showLogin)
                inputField(controller: familyCodeController, label: "Family Code"),
              if (showLogin) const SizedBox(height: 20),
              if (!showLogin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    roleChip("homeowner"),
                    roleChip("member"),
                  ],
                ),
              if (!showLogin) const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showLogin ? login : signup,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(showLogin ? "Login" : "Create Account", style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => showLogin = !showLogin),
                  child: Text(
                    showLogin ? "Don't have an account? Sign up" : "Already have an account? Login",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ WIDGETS ------------------
  Widget inputField({required TextEditingController controller, required String label, bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget roleChip(String role) {
    final bool active = selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(role.toUpperCase(), style: TextStyle(color: active ? Colors.white : Colors.black54, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
