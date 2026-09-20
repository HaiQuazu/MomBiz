import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../services/auth_service.dart';
import '../../theme/app_icons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  String? _errorMessage;

  bool get _busy => _isLoading || _isGoogleLoading;

  String _text({required String en, required String km}) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return languageCode == 'km' ? km : en;
  }

  bool get _isKhmer => Localizations.localeOf(context).languageCode == 'km';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_busy) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _messageForFirebaseError(error.code);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _text(
          en: 'Something went wrong. Please try again.',
          km: 'មានបញ្ហាមួយបានកើតឡើង។ សូមព្យាយាមម្តងទៀត។',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<void> _loginWithGoogle() async {
    if (_busy) {
      return;
    }

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService.instance.signInWithGoogle();
    } on GoogleSignInException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.code == GoogleSignInExceptionCode.canceled) {
        return;
      }

      setState(() {
        _errorMessage = _messageForGoogleError(error);
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _messageForFirebaseError(error.code);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _text(
          en: 'Unable to sign in with Google. Please try again.',
          km: 'មិនអាចចូលដោយប្រើ Google បានទេ។ សូមព្យាយាមម្តងទៀត។',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  // ============================================================
  // GOOGLE ERROR MESSAGE
  // ============================================================

  String _messageForGoogleError(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return _text(
          en: 'Google sign-in is not configured correctly yet.',
          km: 'ការចូលដោយប្រើ Google មិនទាន់បានកំណត់ត្រឹមត្រូវទេ។',
        );

      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return _text(
          en: 'Google sign-in could not open. Please try again.',
          km: 'មិនអាចបើកការចូលដោយប្រើ Google បានទេ។ សូមព្យាយាមម្តងទៀត។',
        );

      default:
        return _text(
          en: 'Unable to sign in with Google. Please try again.',
          km: 'មិនអាចចូលដោយប្រើ Google បានទេ។ សូមព្យាយាមម្តងទៀត។',
        );
    }
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _messageForFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return _text(
          en: 'The email address is not valid.',
          km: 'អាសយដ្ឋានអ៊ីមែលមិនត្រឹមត្រូវទេ។',
        );

      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return _text(
          en: 'Email or password is incorrect.',
          km: 'អ៊ីមែល ឬ ពាក្យសម្ងាត់មិនត្រឹមត្រូវទេ។',
        );

      case 'user-disabled':
        return _text(
          en: 'This account has been disabled.',
          km: 'គណនីនេះត្រូវបានបិទ។',
        );

      case 'too-many-requests':
        return _text(
          en: 'Too many attempts. Please try again later.',
          km: 'មានការព្យាយាមច្រើនពេក។ សូមព្យាយាមម្តងទៀតពេលក្រោយ។',
        );

      case 'network-request-failed':
        return _text(
          en: 'No internet connection. Please try again.',
          km: 'គ្មានការតភ្ជាប់អ៊ីនធឺណិត។ សូមព្យាយាមម្តងទៀត។',
        );

      case 'operation-not-allowed':
        return _text(
          en: 'This sign-in method is not enabled yet.',
          km: 'វិធីចូលនេះមិនទាន់បានបើកប្រើទេ។',
        );

      case 'google-missing-id-token':
        return _text(
          en: 'Google sign-in could not be completed.',
          km: 'មិនអាចបញ្ចប់ការចូលដោយប្រើ Google បានទេ។',
        );

      default:
        return _text(
          en: 'Unable to sign in. Please try again.',
          km: 'មិនអាចចូលបានទេ។ សូមព្យាយាមម្តងទៀត។',
        );
    }
  }

  // ============================================================
  // BRAND HEADER
  // ============================================================

  Widget _buildBrandHeader(
    ThemeData theme,
    ColorScheme colors, {
    bool compact = false,
  }) {
    final iconSize = compact ? 68.0 : 82.0;

    final titleWeight = _isKhmer ? FontWeight.w600 : FontWeight.w700;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------------------------------------
          // LOGO
          // ------------------------------------------------
          Container(
            width: iconSize,
            height: iconSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(compact ? 22 : 25),
            ),
            child: Icon(
              AppIcons.storefront,
              size: compact ? 32 : 38,
              color: colors.onPrimaryContainer,
            ),
          ),

          SizedBox(height: compact ? 12 : 18),

          // ------------------------------------------------
          // APP NAME
          // ------------------------------------------------
          Text(
            'MomBiz',
            textAlign: TextAlign.center,
            style: compact
                ? theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: titleWeight,
                    letterSpacing: _isKhmer ? null : -0.8,
                  )
                : theme.textTheme.displaySmall?.copyWith(
                    fontWeight: titleWeight,
                    letterSpacing: _isKhmer ? null : -1,
                  ),
          ),

          const SizedBox(height: 4),

          // ------------------------------------------------
          // SUBTITLE
          // ------------------------------------------------
          Text(
            _text(
              en: 'Your business, organized simply.',
              km: 'រៀបចំអាជីវកម្មរបស់អ្នកឱ្យសាមញ្ញ។',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGIN CARD
  // ============================================================

  Widget _buildLoginCard(ThemeData theme, ColorScheme colors) {
    final titleWeight = _isKhmer ? FontWeight.w600 : FontWeight.w700;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Form(
        key: _formKey,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =================================================
              // TITLE
              // =================================================
              Text(
                _text(en: 'Welcome back', km: 'សូមស្វាគមន៍មកវិញ'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: titleWeight,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                _text(
                  en: 'Sign in to continue to MomBiz.',
                  km: 'ចូលដើម្បីបន្តប្រើ MomBiz។',
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // EMAIL
              // =================================================
              TextFormField(
                controller: _emailController,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: _text(en: 'Email', km: 'អ៊ីមែល'),
                  prefixIcon: const Icon(AppIcons.email, size: 21),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';

                  if (email.isEmpty) {
                    return _text(
                      en: 'Please enter your email.',
                      km: 'សូមបញ្ចូលអ៊ីមែល។',
                    );
                  }

                  if (!email.contains('@')) {
                    return _text(
                      en: 'Please enter a valid email.',
                      km: 'សូមបញ្ចូលអ៊ីមែលត្រឹមត្រូវ។',
                    );
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              // =================================================
              // PASSWORD
              // =================================================
              TextFormField(
                controller: _passwordController,
                enabled: !_busy,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                onFieldSubmitted: (_) {
                  if (!_busy) {
                    _login();
                  }
                },
                decoration: InputDecoration(
                  labelText: _text(en: 'Password', km: 'ពាក្យសម្ងាត់'),
                  prefixIcon: const Icon(AppIcons.lock, size: 21),
                  suffixIcon: IconButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? AppIcons.visibility
                          : AppIcons.visibilityOff,
                      size: 21,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return _text(
                      en: 'Please enter your password.',
                      km: 'សូមបញ្ចូលពាក្យសម្ងាត់។',
                    );
                  }

                  return null;
                },
              ),

              // =================================================
              // ERROR MESSAGE
              // =================================================
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: colors.errorContainer.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        AppIcons.error,
                        size: 20,
                        color: colors.onErrorContainer,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // =================================================
              // SIGN IN
              // =================================================
              SizedBox(
                height: 54,
                child: FilledButton(
                  onPressed: _busy ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_text(en: 'Sign in', km: 'ចូល')),
                ),
              ),

              const SizedBox(height: 18),

              // =================================================
              // DIVIDER
              // =================================================
              Row(
                children: [
                  const Expanded(child: Divider()),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      _text(en: 'or', km: 'ឬ'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 18),

              // =================================================
              // GOOGLE SIGN IN
              // =================================================
              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _busy ? null : _loginWithGoogle,
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            Flexible(
                              child: Text(
                                _text(
                                  en: 'Continue with Google',
                                  km: 'បន្តជាមួយ Google',
                                ),
                                textAlign: TextAlign.center,
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: keyboardOpen
            ? _buildKeyboardLayout(theme, colors)
            : _buildNormalLayout(theme, colors),
      ),
    );
  }

  // ============================================================
  // NORMAL LAYOUT
  // ============================================================

  Widget _buildNormalLayout(ThemeData theme, ColorScheme colors) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Keep MomBiz near the top.
                _buildBrandHeader(theme, colors),

                // This spacing was already working well.
                const SizedBox(height: 38),

                _buildLoginCard(theme, colors),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // KEYBOARD OPEN LAYOUT
  // ============================================================

  Widget _buildKeyboardLayout(ThemeData theme, ColorScheme colors) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
          child: _buildBrandHeader(theme, colors, compact: true),
        ),

        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Center(child: _buildLoginCard(theme, colors)),
          ),
        ),
      ],
    );
  }
}
