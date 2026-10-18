import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_back_button.dart';
import '../data/auth_repository.dart';
import '../data/demo_session_repository.dart';

class EmailConfirmationPage extends ConsumerStatefulWidget {
  const EmailConfirmationPage({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailConfirmationPage> createState() =>
      _EmailConfirmationPageState();
}

class _EmailConfirmationPageState
    extends ConsumerState<EmailConfirmationPage> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final email = _email.text.trim();
    final code = _code.text.trim();
    if (Validators.email(email) != null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _error = 'Informe um e-mail válido e o código de 6 dígitos.';
        _message = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(demoSessionRepositoryProvider).end();
      ref.invalidate(demoSessionProvider);
      await ref
          .read(authRepositoryProvider)
          .verifyEmail(email: email, code: code);
      if (mounted) context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is AppException
            ? error.message
            : 'Não foi possível confirmar o e-mail. Confira o código e tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final email = _email.text.trim();
    if (Validators.email(email) != null) {
      setState(() {
        _error = 'Informe o e-mail usado para criar a conta.';
        _message = null;
      });
      return;
    }
    setState(() {
      _resending = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).resendVerification(email);
      if (mounted) {
        setState(() => _message =
            'Se a conta estiver aguardando confirmação, um novo código foi enviado.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is AppException
            ? error.message
            : 'Não foi possível solicitar outro código. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/login'),
        title: const Text('Confirme seu e-mail'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Enviamos um código de 6 dígitos para confirmar a criação da sua conta.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    labelText: 'Código de confirmação',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Text(_message!, textAlign: TextAlign.center),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _loading ? null : _confirm,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Confirmar e entrar'),
                ),
                TextButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Enviando...' : 'Enviar outro código'),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Voltar para entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
