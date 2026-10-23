import 'package:lucena/data/repositories/account/mail_app_repository.dart';

/// Com ou sem app de e-mail; conta quantas vezes abriu.
class FakeMailAppRepository implements MailAppRepository {
  FakeMailAppRepository({this.installed = true});

  bool installed;
  int opened = 0;

  @override
  Future<bool> available() async => installed;

  @override
  Future<void> open() async => opened++;
}
