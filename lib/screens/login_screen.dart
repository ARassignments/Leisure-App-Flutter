import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isFormValid = false;
  bool _isLoading = false;
  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool get _isFormDisabled => _isLoading || !_isFormValid;

  TextInputType _keyboardType = TextInputType.text;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      _updateKeyboardType();
      _validateForm();
    });
    _passwordController.addListener(_validateForm);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateForm();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateKeyboardType() {
    final text = _emailController.text;
    final newType = text.contains('@')
        ? TextInputType.emailAddress
        : TextInputType.text;

    if (newType != _keyboardType) {
      setState(() => _keyboardType = newType);
    }
  }

  bool _validateCurrentForm() {
    final text = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final isEmail = text.contains('@');

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    final usernameRegex = RegExp(
      r'^(?=.*[a-zA-Z])(?=.*\d)(?!_)(?!.*__)[a-zA-Z0-9_]{3,20}(?<!_)$',
    );

    final isEmailOrUsernameValid = isEmail
        ? emailRegex.hasMatch(text)
        : usernameRegex.hasMatch(text);

    final isPasswordValid = password.isNotEmpty && password.length >= 8;

    return isEmailOrUsernameValid && isPasswordValid;
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _validateCurrentForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [_buildLoginForm()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      onChanged:
          _validateForm, // This will trigger validation on any form change
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(AppTheme.appLogo(context), height: 100, width: 100),
            SizedBox(height: 40),
            Text(
              "Login to Yet To Explore",
              style: AppTheme.textTitle(context),
              textAlign: TextAlign.start,
            ),

            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Email / Username*',
                hintText: 'e.g. david@example.com or david123',
                counter: const SizedBox.shrink(),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              keyboardType: _keyboardType,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email or username';
                }

                final isEmail = value.contains('@');

                // Email regex
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );

                // Username regex (letters, numbers, underscores, 3–20 chars)
                final usernameRegex = RegExp(
                  r'^(?=.*[a-zA-Z])(?=.*\d)(?!_)(?!.*__)[a-zA-Z0-9_]{3,20}(?<!_)$',
                );

                if (isEmail && !emailRegex.hasMatch(value)) {
                  return 'Please enter a valid email address';
                } else if (!isEmail && !usernameRegex.hasMatch(value)) {
                  return 'Username must be 3–20 characters (letters, numbers, _)';
                }
                return null;
              },
              maxLength: 40,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: InputDecoration(
                labelText: 'Password*',
                hintText: 'e.g. dav*****',
                counter: const SizedBox.shrink(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  splashRadius: 20, // Smaller tap area
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              style: AppInputDecoration.inputTextStyle(context),
              obscureText: _obscurePassword,
              obscuringCharacter: '•',
              keyboardType: TextInputType.visiblePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                } else if (value.length < 8) {
                  return 'Password must be at least 8 characters long';
                }
                return null;
              },
              maxLength: 20,
            ),

            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: AppTheme.checkBox(context),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                        // You can add additional logic here
                      },
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        'Remember Me',
                        style: AppTheme.textLabel(context),
                      ),
                    ),
                  ],
                ),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTheme.textLabel(context),
                    children: [
                      TextSpan(
                        text: 'Forgot Password?',
                        style: AppTheme.textLink(context),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  ForgotPasswordScreen(),
                              transitionsBuilder: (_, a, __, c) =>
                                  FadeTransition(opacity: a, child: c),
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            FlatButton(
              text: 'Continue',
              disabled: !_isFormValid || _isLoading,
              onPressed: (_isFormValid && !_isLoading)
                  ? () async {
                      if (!_validateCurrentForm())
                        return; // Use validation method
                      await _submitLoginForm();
                    }
                  : null,
              loading: _isLoading,
            ),
            SizedBox(height: 20),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppTheme.textLabel(context),
                children: [
                  TextSpan(text: 'Don’t have an account? '),
                  TextSpan(
                    text: 'Register',
                    style: AppTheme.textLink(context),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => SignupScreen(),
                          transitionsBuilder: (_, a, __, c) =>
                              FadeTransition(opacity: a, child: c),
                        ),
                      ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLoginForm() async {
    if (!_validateCurrentForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final formData = {
        'email': _emailController.text.trim(),
        'pwd': _passwordController.text.trim(),
      };

      // Call your API here
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        // Navigator.of(context).push(
        //   PageRouteBuilder(
        //     pageBuilder: (_, __, ___) => SignupScreen(
        //       phoneNumber: _contactController.text.trim(),
        //       countryCode: _selectedCountryCode.dialCode ?? '',
        //     ),
        //     transitionsBuilder: (_, a, __, c) =>
        //         FadeTransition(opacity: a, child: c),
        //   ),
        // );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
