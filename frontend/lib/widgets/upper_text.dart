import 'package:flutter/material.dart';

/// Controla se o texto deve ser exibido em maiúsculas.
/// Envolva o AppShell com [UpperCaseScope.enabled] e o Login com [UpperCaseScope.disabled].
class UpperCaseScope extends InheritedWidget {
  final bool enabled;

  const UpperCaseScope({
    super.key,
    required this.enabled,
    required super.child,
  });

  static bool of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<UpperCaseScope>()
            ?.enabled ??
        false;
  }

  @override
  bool updateShouldNotify(UpperCaseScope old) => old.enabled != enabled;
}

/// Substitui o [Text] padrão aplicando toUpperCase() quando [UpperCaseScope] está ativo.
/// Use este widget em vez de [Text] em todo o app.
///
/// Uso: basta importar e usar `UT('texto')` ou `UpperText('texto')`.
class UpperText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const UpperText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    final upper = UpperCaseScope.of(context);
    return Text(
      upper ? data.toUpperCase() : data,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
