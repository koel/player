import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    Key? key,
    required this.onPressed,
    this.loading = false,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          iconColor: Colors.black87,
          disabledIconColor: Colors.black38,
          elevation: 0,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SpinKitThreeBounce(color: Colors.black54, size: 16)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/google_logo.png',
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.high,
                    gaplessPlayback: true,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Sign in with Google',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
