import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification.dart';

void main() {
  const notification = KGNotification(title: 'T', description: 'D');

  test('is equal to another notification with the same content', () {
    expect(notification, const KGNotification(title: 'T', description: 'D'));
  });

  test('differs when the title differs', () {
    expect(
      notification,
      isNot(const KGNotification(title: 'Other', description: 'D')),
    );
  });

  test('is built from json', () {
    expect(
      KGNotification.fromJson({'title': 'T', 'description': 'D'}),
      notification,
    );
  });

  test('serialises to json', () {
    expect(notification.toJson(), {'title': 'T', 'description': 'D'});
  });
}
