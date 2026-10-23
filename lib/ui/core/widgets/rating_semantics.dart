import 'package:flutter/widgets.dart';
import 'package:lucena_ui/lucena_ui.dart';

import '../l10n/l10n.dart';

/// O rating e a variação para o leitor de tela.
String ratingSemantics(BuildContext context, int rating, int change) =>
    context.l10n.reportRating(rating, signedChange(change));
