import 'package:app_hiker/components/code_input.dart';
import 'package:app_hiker/components/login_form.dart';
import 'package:app_hiker/components/submit_button.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/user_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RN17.6: the new e-mail is only applied after the code sent to the current e-mail is confirmed.
// Pops with true when the e-mail was changed.
class ChangeEmailSheet extends StatefulWidget {
  final String currentEmail;

  const ChangeEmailSheet({super.key, required this.currentEmail});

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  final _userService = UserService();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _errorMessage = 'Insira um email válido.');
      return;
    }
    if (email == widget.currentEmail) {
      setState(() => _errorMessage = 'O novo e-mail é igual ao atual.');
      return;
    }

    await _run(() async {
      await _userService.requestEmailChange(email);
      setState(() => _codeSent = true);
    });
  }

  Future<void> _confirmCode() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorMessage = 'Digite o código de 6 dígitos.');
      return;
    }

    await _run(() async {
      await _userService.confirmEmailChange(_codeController.text);
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
    } on SessionExpiredException {
      if (mounted) context.navigate('/login');
    } on UserException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Erro ao conectar com o servidor');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Alterar e-mail', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            _codeSent
                ? 'Enviamos um código para ${widget.currentEmail}. Digite-o para confirmar a troca para ${_emailController.text.trim()}.'
                : 'Por segurança, vamos enviar um código de verificação para o seu e-mail atual.',
            style: TextStyle(color: Pallete.whiteColor.withAlpha(180)),
          ),
          const SizedBox(height: 20),
          if (!_codeSent)
            LoginForm(
              hintText: 'Novo e-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icon(Icons.mail_outline, color: Pallete.whiteColor.withAlpha(180), size: 20),
            )
          else
            CodeInput(controller: _codeController),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Pallete.errorColor)),
          ],
          const SizedBox(height: 20),
          SubmitButton(
            label: _codeSent ? 'Confirmar' : 'Enviar código',
            isLoading: _isLoading,
            onPressed: _codeSent ? _confirmCode : _requestCode,
            horizontalPadding: 0,
          ),
          if (_codeSent)
            TextButton(
              onPressed: _isLoading ? null : _requestCode,
              child: const Text('Reenviar código', style: TextStyle(color: Pallete.whiteColor)),
            ),
        ],
      ),
    );
  }
}
