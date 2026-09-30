import 'package:app_hiker/components/login_form.dart';
import 'package:app_hiker/components/submit_button.dart';
import 'package:app_hiker/src/services/api_client.dart';
import 'package:app_hiker/src/services/user_service.dart';
import 'package:app_hiker/src/utils/pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

// RN17.5: the current password is required to set a new one. Pops with true on success.
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _userService = UserService();
  final _senhaAtualController = TextEditingController();
  final _senhaNovaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _showSenha = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _senhaAtualController.dispose();
    _senhaNovaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  String? _validate() {
    final senha = _senhaNovaController.text;
    if (_senhaAtualController.text.isEmpty) return 'Informe sua senha atual.';
    if (senha.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(senha) ||
        !RegExp(r'[a-z]').hasMatch(senha) ||
        !RegExp(r'\d').hasMatch(senha) ||
        !RegExp(r'[^A-Za-z0-9]').hasMatch(senha)) {
      return 'A senha precisa ter no mínimo 8 caracteres, 1 maiúscula, 1 minúscula, 1 número e 1 símbolo.';
    }
    if (senha != _confirmarSenhaController.text) return 'As senhas não coincidem.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    setState(() => _errorMessage = error);
    if (error != null) return;

    setState(() => _isLoading = true);
    try {
      await _userService.changePassword(
        senhaAtual: _senhaAtualController.text,
        senhaNova: _senhaNovaController.text,
      );
      if (mounted) Navigator.of(context).pop(true);
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

  Widget _icon(IconData icon) => Icon(icon, color: Pallete.whiteColor.withAlpha(180), size: 20);

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      icon: _icon(_showSenha ? Icons.visibility_off_outlined : Icons.visibility_outlined),
      onPressed: () => setState(() => _showSenha = !_showSenha),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Alterar senha', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          LoginForm(
            hintText: 'Senha atual',
            obscureText: !_showSenha,
            controller: _senhaAtualController,
            prefixIcon: _icon(Icons.lock_outline),
            suffixIcon: toggle,
          ),
          const SizedBox(height: 12),
          LoginForm(
            hintText: 'Nova senha',
            obscureText: !_showSenha,
            controller: _senhaNovaController,
            prefixIcon: _icon(Icons.lock_reset),
            suffixIcon: toggle,
          ),
          const SizedBox(height: 12),
          LoginForm(
            hintText: 'Confirmar nova senha',
            obscureText: !_showSenha,
            controller: _confirmarSenhaController,
            prefixIcon: _icon(Icons.lock_reset),
            suffixIcon: toggle,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Pallete.errorColor)),
          ],
          const SizedBox(height: 20),
          SubmitButton(label: 'Alterar senha', isLoading: _isLoading, onPressed: _submit, horizontalPadding: 0),
        ],
      ),
    );
  }
}
