import 'package:app/constants/constants.dart';
import 'package:app/exceptions/exceptions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

enum _CodeMode { totp, recovery }

class TwoFactorChallengeScreen extends StatefulWidget {
  static const routeName = '/two-factor-challenge';

  final String host;
  final String email;
  final String loginToken;

  const TwoFactorChallengeScreen({
    Key? key,
    required this.host,
    required this.email,
    required this.loginToken,
  }) : super(key: key);

  @override
  _TwoFactorChallengeScreenState createState() =>
      _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState extends State<TwoFactorChallengeScreen> {
  late final AuthProvider _auth;
  var _mode = _CodeMode.totp;
  var _code = '';
  var _verifying = false;
  var _totpResetToken = 0;

  @override
  void initState() {
    super.initState();
    _auth = context.read();
  }

  void _switchMode(_CodeMode mode) {
    setState(() {
      _mode = mode;
      _code = '';
    });
  }

  Future<void> showErrorDialog(BuildContext context, {String? message}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          message ?? 'There was a problem verifying the code. Please try again.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> verify() async {
    final code = _code.trim();
    if (code.isEmpty || _verifying) return;

    var successful = false;
    setState(() => _verifying = true);

    try {
      await _auth.completeTwoFactorChallenge(
        loginToken: widget.loginToken,
        code: code,
      );
      await _auth.tryGetAuthUser();
      successful = true;
    } on HttpResponseException catch (error) {
      _resetTotpInput();
      await showErrorDialog(
        context,
        message: error.response.statusCode == 401
            ? 'Invalid authentication code.'
            : null,
      );
    } catch (error) {
      _resetTotpInput();
      await showErrorDialog(context);
    } finally {
      setState(() => _verifying = false);
    }

    if (successful) {
      preferences.host = widget.host;
      preferences.userEmail = widget.email;
      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(DataLoadingScreen.routeName);
    }
  }

  void _resetTotpInput() {
    setState(() {
      _code = '';
      _totpResetToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.hPadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ...[
                    Text(
                      'Two-Factor Authentication',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (_mode == _CodeMode.totp)
                      ..._buildTotpInput()
                    else
                      ..._buildRecoveryInput(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: _verifying
                            ? const SpinKitThreeBounce(
                                color: Colors.white,
                                size: 16,
                              )
                            : const Text('Verify'),
                        onPressed: _verifying ? null : verify,
                      ),
                    ),
                    _FooterButton(
                      label: _mode == _CodeMode.totp
                          ? 'Use a recovery code'
                          : 'Use authenticator code instead',
                      onPressed: _verifying
                          ? null
                          : () => _switchMode(
                                _mode == _CodeMode.totp
                                    ? _CodeMode.recovery
                                    : _CodeMode.totp,
                              ),
                    ),
                    _FooterButton(
                      label: 'Back to login',
                      onPressed: _verifying
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ].expand((widget) => [widget, const SizedBox(height: 16)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTotpInput() {
    return [
      const Text(
        'Enter the code from your authenticator app.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      OneTimeCodeInput(
        key: ValueKey(_totpResetToken),
        onChanged: (value) => _code = value,
        onCompleted: (value) {
          _code = value;
          verify();
        },
      ),
    ];
  }

  List<Widget> _buildRecoveryInput() {
    return [
      const Text(
        'Enter one of your recovery codes.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
      TextField(
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.go,
        style: const TextStyle(fontFamily: 'monospace', letterSpacing: 2),
        inputFormatters: [_UpperCaseFormatter()],
        onChanged: (value) => _code = value,
        onSubmitted: (_) => verify(),
        decoration: const InputDecoration(
          hintText: 'Recovery code',
        ),
      ),
    ];
  }
}

class _FooterButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _FooterButton({Key? key, required this.label, this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
