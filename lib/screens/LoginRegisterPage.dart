import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sync_music/AdminPanel/AdminPage.dart';
import 'package:sync_music/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late bool isSignIn;
  bool isFormInteracted = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool agreedToTerms = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    isSignIn = true; // Initially, set it to sign in
  }

  String? validateEmail(String? value) {
    if (isFormInteracted && (value == null || value.isEmpty)) {
      return 'Please enter your email';
    }

    if (value != null && !value.isEmpty) {
      // Custom email format validation
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    return null;
  }

  String? validatePassword(String? value) {
    if (isSignIn && isFormInteracted) {
      // Only validate during registration
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
    }
    if (!isSignIn && isFormInteracted) {
      // Only validate during registration
      if (value == null || value.isEmpty) {
        return 'Please enter your password';
      }
      if (value.length < 6) {
        return 'Password must be at least 6 characters long';
      }
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!isSignIn) {
      // Only validate during registration
      if (isFormInteracted && confirmPasswordController.text.isEmpty) {
        return 'Please enter confirm password';
      }
      if (isFormInteracted &&
          (value == null || value.isEmpty || value.length < 6)) {
        return 'Password must be at least 6 characters long';
      }
      if (value != null && value != passwordController.text) {
        return 'Passwords do not match';
      }
    }
    return null;
  }

  void switchAuthMode() {
    setState(() {
      isSignIn = !isSignIn;
      // Clear text controllers when switching modes
      emailController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      isFormInteracted = false;
    });
  }

  Future<void> _submitForm() async {
    BuildContext currentContext = context; // Store the context

    setState(() {
      isFormInteracted = true;
    });

    try {
      // Validation check before submission
      if (validateEmail(emailController.text) != null) {
        // Display an error message for email validation
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter a valid email address.',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (isSignIn &&
          isFormInteracted &&
          (passwordController.text == null ||
              passwordController.text.isEmpty)) {
        // Display an error message for password validation during sign-in
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Please enter your password.',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      if (!isSignIn && validatePassword(passwordController.text) != null) {
        // Additional check for registration to validate password
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Password must be at least 6 characters long',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 236, 146, 3),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Additional check for registration to validate confirm password
      if (!isSignIn &&
          isFormInteracted &&
          (confirmPasswordController.text.isEmpty ||
              confirmPasswordController.text != passwordController.text)) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Passwords do not match',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 230, 15, 0),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // If all validations pass, proceed with authentication logic

      setState(() {
        isLoading = true; // Set loading state
      });

      if (isSignIn) {
        // Sign in logic
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // If successful, reset form interaction state
        setState(() {
          isFormInteracted = false;
        });

        // Check if the signed-in user has admin credentials
        if (isAdminUser(emailController.text, passwordController.text)) {
          // User is an admin, handle admin authentication
          // For example, navigate to the admin dashboard
          Navigator.pushReplacement(
            currentContext,
            MaterialPageRoute(builder: (context) {
              return AdminDashboard();
            }),
          );
        } else {
          // User is not an admin, navigate to the regular user screen
          Navigator.pushReplacement(
            currentContext,
            MaterialPageRoute(builder: (context) {
              return MyApp(userEmail: emailController.text);
            }),
          );
        }
      } else {
        // User does not exist, proceed with registration
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Store additional user data in Firestore
        await FirebaseFirestore.instance
            .collection('Authentication')
            .doc(userCredential.user!.uid)
            .set({
          'email': emailController.text,
          'password': passwordController.text,
          'confirm_pass': confirmPasswordController.text
          // Add more fields as needed
        });

        // Registration success message
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text(
              'Registered successfully! Now you can log in.',
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 255, 0),
                fontSize: 15,
              ),
            ),
            duration: Duration(seconds: 3),
          ),
        );

        // Clear text controllers
        emailController.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        // If successful, reset form interaction state
        setState(() {
          isFormInteracted = false;
        });

        // Navigate to the login screen after registration
        Navigator.pushReplacement(
          currentContext,
          MaterialPageRoute(builder: (context) {
            return AuthGate();
          }),
        );
      }
    } on FirebaseAuthException catch (error) {
      // Handle specific authentication errors
      String errorMessage =
          'Authentication failed. Please enter correct email or password';

      if (error.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (error.code == 'wrong-password') {
        errorMessage = 'Incorrect password.';
      } else if (error.code == 'email-already-in-use') {
        errorMessage =
            'Email is already registered. Please register with a different email.';
      }

      // Display error message to the user
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 230, 15, 0),
          content: Text(
            errorMessage,
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 228, 224, 224),
              fontSize: 15,
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      print("FirebaseAuthException: ${error.code}, ${error.message}");
    } catch (error) {
      // Handle other errors
      // Display a generic error message to the user
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(
          backgroundColor: Color.fromARGB(255, 230, 15, 0),
          content: Text(
            'An unexpected error occurred. Please try again later.',
            style: GoogleFonts.kanit(
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 228, 224, 224),
              fontSize: 15,
            ),
          ),
          duration: Duration(seconds: 3),
        ),
      );

      print("Error during authentication: $error");
    } finally {
      // Reset loading state
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isAdminUser(String email, String password) {
    // Check if the email and password combination is the admin's
    // You can customize this condition based on your requirements
    return email == 'vivekmakwana@gmail.com' && password == 'vivek_makwana_';
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    required String? Function(String?)? validator,
    required bool showPassword,
    required VoidCallback onTogglePassword,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !showPassword : false,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.transparent,
        prefixIcon: Icon(
          icon,
          color: Color.fromRGBO(111, 117, 138, 1),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                ),
                color: Color.fromRGBO(111, 117, 138, 1),
                onPressed: onTogglePassword,
              )
            : null,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
          ),
        ),
        errorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.red,
          ),
        ),
        errorText: validator != null ? validator(controller.text) : null,
        // Apply text color here
        hintStyle: TextStyle(
          color: Color.fromRGBO(111, 117, 138, 1),
        ),
      ),
      style: TextStyle(
        color: Color.fromRGBO(248, 248, 251, 1),
      ),
    );
  }

  Widget buildAgreementCheckbox() {
    return Row(
      children: [
        Checkbox(
          checkColor: Colors.white,
          activeColor: Colors.green,
          value: agreedToTerms,
          onChanged: (value) {
            setState(() {
              agreedToTerms = value ?? false;
            });
          },
        ),
        Text(
          'I agree to the terms and conditions',
          style: TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    String topMessage = isSignIn ? 'Sign In' : 'Register';

    return Scaffold(
      backgroundColor: Color(0xFF221e3b),
      body: SingleChildScrollView(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              // Image widget moved to the bottom of the stack
              Container(
                height: double.infinity,
                width: double.infinity,
                child: Image.network(
                  'https://images.unsplash.com/photo-1582220107107-590dc8b0fad3?q=80&w=1936&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
                  fit: BoxFit.fill,
                ),
              ),
              // Text fields and button overlaying the image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome To,',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        topMessage,
                        style: TextStyle(
                          color: Color(0xff6157ff),
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 50),
                      buildTextField(
                        controller: emailController,
                        hintText: 'Email',
                        icon: Icons.email,
                        validator: validateEmail,
                        showPassword: false,
                        onTogglePassword: () {},
                      ),
                      SizedBox(height: 25),
                      buildTextField(
                        controller: passwordController,
                        hintText: 'Password',
                        icon: Icons.lock,
                        isPassword: true,
                        validator: validatePassword,
                        showPassword: showPassword,
                        onTogglePassword: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                      if (!isSignIn) SizedBox(height: 25),
                      if (!isSignIn)
                        buildTextField(
                          controller: confirmPasswordController,
                          hintText: 'Confirm Password',
                          icon: Icons.lock,
                          isPassword: true,
                          validator: validateConfirmPassword,
                          showPassword: showConfirmPassword,
                          onTogglePassword: () {
                            setState(() {
                              showConfirmPassword = !showConfirmPassword;
                            });
                          },
                        ),
                      SizedBox(height: 20),
                      if (!isSignIn) buildAgreementCheckbox(),
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6.0),
                          gradient: LinearGradient(
                            begin: Alignment(-0.95, 0.0),
                            end: Alignment(1.0, 0.0),
                            colors: [Color(0xff6157ff), Color(0xffee49fd)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: isLoading
                                ? CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  )
                                : Text(
                                    isSignIn ? 'Sign In' : 'Register',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: switchAuthMode,
                        style: TextButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isSignIn
                                        ? "Don't have an account?"
                                        : 'Already have an account?',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    isSignIn
                                        ? 'Register here.'
                                        : 'Sign in here.',
                                    style: TextStyle(
                                      color: Colors.red,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
