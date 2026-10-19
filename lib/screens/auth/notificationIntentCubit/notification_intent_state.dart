part of 'notification_intent_cubit.dart';

class NotificationIntentState extends Equatable {
  const NotificationIntentState({this.pending});

  final NotificationIntent? pending;

  @override
  List<Object?> get props => [pending];
}
