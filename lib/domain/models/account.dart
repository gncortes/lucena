/// Como a pessoa entrou na conta.
enum AccountProvider { google, email }

/// A conta (opcional) de quem usa o app, pelo Firebase Auth.
class Account {
  const Account({
    required this.uid,
    required this.provider,
    this.email,
    this.name,
    this.photoUrl,
  });

  final String uid;
  final AccountProvider provider;
  final String? email;
  final String? name;
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is Account &&
      other.uid == uid &&
      other.provider == provider &&
      other.email == email &&
      other.name == name &&
      other.photoUrl == photoUrl;

  @override
  int get hashCode => Object.hash(uid, provider, email, name, photoUrl);
}

/// Por que a conta não deu certo. A tela escolhe o texto pelo motivo.
enum AccountFailure {
  /// Build sem Firebase (F-Droid, CI de PR) ou serviço fora do ar.
  unavailable,

  /// Sem internet.
  network,

  /// E-mail mal escrito.
  invalidEmail,

  /// Senha curta demais para criar a conta.
  weakPassword,

  /// E-mail ou senha errados (o Firebase não diz qual, de propósito).
  wrongCredentials,

  /// Já existe conta com esse e-mail.
  emailInUse,

  /// Muitas tentativas seguidas: esperar um pouco.
  tooManyAttempts,

  /// Apagar a conta pede um login recente.
  recentLoginRequired,

  /// Qualquer outro erro.
  unknown,
}

class AccountException implements Exception {
  const AccountException(this.failure);

  final AccountFailure failure;

  @override
  String toString() => 'AccountException($failure)';
}
