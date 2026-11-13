import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/widgets/z_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override ConsumerState<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends ConsumerState<AuthScreen> {
  final nickname = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  bool register = false, busy = false;
  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6 || (register && nickname.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos. A senha deve ter pelo menos 6 caracteres.'))); return;
    }
    setState(() => busy = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      if (register) {
        await repo.signUp(nickname.text, email.text, password.text);
      } else {
        await repo.signIn(email.text, password.text);
      }
      if (mounted) context.go('/splash');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível entrar: $e')));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    const Icon(Icons.shield_moon, size: 66, color: Color(0xFF9DBB73)),
    const SizedBox(height: 12), const Text('PROTOCOLO Z', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 3)),
    const SizedBox(height: 8), const Text('A rede de resistência começa aqui.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF91A095))),
    const SizedBox(height: 36), ZPanel(child: Column(children: [
      Text(register ? 'CRIAR SOBREVIVENTE' : 'ACESSAR A REDE', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      const SizedBox(height: 20),
      if (register) TextField(controller: nickname, decoration: const InputDecoration(labelText: 'Apelido')),
      if (register) const SizedBox(height: 12),
      TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail')),
      const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
      const SizedBox(height: 20), ElevatedButton(onPressed: busy ? null : submit, child: Text(busy ? 'AGUARDE...' : register ? 'CRIAR CONTA' : 'ENTRAR')),
      TextButton(onPressed: () => setState(() => register = !register), child: Text(register ? 'Já tenho uma conta' : 'Criar uma conta')),
    ])),
  ]))))));
}
