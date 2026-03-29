import '../auth/auth_session.dart';
import '../network/api_client.dart';
import '../../features/auth/data/auth_http_api.dart';
import '../../features/pools/data/groups_http_api.dart';
import '../../features/profile/data/profile_http_api.dart';

final apiClient = ApiClient(session: AuthSession.instance);

final authHttpApi = AuthHttpApi(client: apiClient);
final groupsHttpApi = GroupsHttpApi(client: apiClient);
final profileHttpApi = ProfileHttpApi(client: apiClient);

