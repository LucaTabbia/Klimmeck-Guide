part of 'legal_consent_cubit.dart';

class LegalConsentState extends Equatable {
  const LegalConsentState({this.isAccepted = false});

  final bool isAccepted;

  @override
  List<Object?> get props => [isAccepted];
}
