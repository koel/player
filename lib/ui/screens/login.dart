import 'package:app/constants/dimens.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/utils/preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = new GlobalKey<FormState>();

  late String _email, _password;

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = Provider.of<AuthProvider>(context);

    var _attemptLogin = () {
      final form = formKey.currentState!;

      if (form.validate()) {
        form.save();
        auth.login(_email, _password);
      }
    };

    final koelHostField = TextFormField(
      keyboardType: TextInputType.url,
      onSaved: (value) => (new Preferences()).setHostUrl(value!),
      decoration: InputDecoration(hintText: "Koel's Host URL"),
    );

    final emailField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      onSaved: (value) => _email = value ?? '',
      decoration: InputDecoration(hintText: 'Email'),
    );

    final passwordField = TextFormField(
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      onSaved: (value) => _password = value ?? '',
      decoration: InputDecoration(hintText: 'Password'),
    );

    final submitButton = ElevatedButton(
      child: Text('Log In'),
      onPressed: _attemptLogin,
    );

    final loading = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        CircularProgressIndicator(),
        Text(" Authenticating. Please wait…"),
      ],
    );

    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: EdgeInsets.all(AppDimens.horizontalPadding),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...[
                  Image.asset(
                    'assets/images/logo.png',
                    width: 192,
                  ),
                  koelHostField,
                  emailField,
                  passwordField,
                  SizedBox(
                    width: double.infinity,
                    child: auth.loggedInStatus == Status.Authenticating
                        ? loading
                        : submitButton,
                  )
                ].expand(
                  (element) => [
                    element,
                    SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
