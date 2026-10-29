import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

/// Sessione del GM (10-CONTEXT D-01): solo UX, il BE verifica il ruolo (ADMIN-07).
bool isInnkeeperSession(AuthState state) =>
    state is AuthAuthenticated && state.user.role == RoleType.innkeeper;
