import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/shared/components/title_badge.dart';

/// Il badge del titolo [title], ovunque sia disegnato.
Finder findTitleBadge(TitleType title) => find.byWidgetPredicate(
  (widget) => widget is TitleBadge && widget.title == title,
);
