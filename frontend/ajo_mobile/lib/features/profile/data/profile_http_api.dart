import '../../../core/network/api_client.dart';
import '../../home/models/user_profile.dart';

class KycRequirements {
  const KycRequirements({
    required this.nextStep,
    required this.bvnVerified,
    required this.walletProvisioned,
    required this.walletStatus,
    required this.bannerTitle,
    required this.bannerMessage,
  });

  final String nextStep;
  final bool bvnVerified;
  final bool walletProvisioned;
  final String walletStatus;
  final String? bannerTitle;
  final String? bannerMessage;

  factory KycRequirements.fromJson(Map<String, dynamic> json) {
    return KycRequirements(
      nextStep: json['next_step']?.toString() ?? 'verify_bvn',
      bvnVerified: json['bvn_verified'] == true,
      walletProvisioned: json['wallet_provisioned'] == true,
      walletStatus: json['wallet_status']?.toString() ?? 'not_started',
      bannerTitle: json['banner_title']?.toString(),
      bannerMessage: json['banner_message']?.toString(),
    );
  }
}

class KycStatusSnapshot {
  const KycStatusSnapshot({
    this.kycId,
    this.walletId,
    required this.status,
    required this.bvnVerified,
    required this.walletProvisioned,
    required this.walletStatus,
    required this.nextStep,
  });

  final String? kycId;
  final String? walletId;
  final String status;
  final bool bvnVerified;
  final bool walletProvisioned;
  final String walletStatus;
  final String nextStep;

  factory KycStatusSnapshot.fromJson(Map<String, dynamic> json) {
    return KycStatusSnapshot(
      kycId: json['kyc_id']?.toString(),
      walletId: json['wallet_id']?.toString(),
      status: json['status']?.toString() ?? 'not_started',
      bvnVerified: json['bvn_verified'] == true,
      walletProvisioned: json['wallet_provisioned'] == true,
      walletStatus: json['wallet_status']?.toString() ?? 'not_started',
      nextStep: json['next_step']?.toString() ?? 'verify_bvn',
    );
  }
}

class BankStatementSummary {
  const BankStatementSummary({
    required this.averageBalance,
    required this.totalCredit,
    required this.totalDebit,
  });

  final double averageBalance;
  final double totalCredit;
  final double totalDebit;

  factory BankStatementSummary.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
    return BankStatementSummary(
      averageBalance: toDouble(json['average_balance']),
      totalCredit: toDouble(json['total_credit']),
      totalDebit: toDouble(json['total_debit']),
    );
  }
}

class ProfileHttpApi {
  ProfileHttpApi({required this.client});

  final ApiClient client;

  Future<UserProfile> getMe() async {
    final res = await client.getJson('/user/me');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /user/me response', body: res);
    }
    return UserProfile.fromJson(res);
  }

  Future<WalletInfo> provisionWallet() async {
    final res = await client.postJsonNoBody('/wallet/provision');
    return WalletInfo.fromJson(res);
  }

  /// Authoritative wallet record (balance, account details). Throws [ApiException]
  /// with status 404 if the user has no wallet yet.
  Future<WalletInfo> getWallet() async {
    final res = await client.getJson('/wallet');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /wallet response', body: res);
    }
    return WalletInfo.fromJson(res);
  }

  /// Credits the authenticated user's wallet (simulated / internal funding).
  Future<WalletFundTransaction> fundWallet({
    required double amount,
    required String reference,
    String? description,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'reference': reference,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final res = await client.postJson('/wallet/fund', body: body);
    return WalletFundTransaction.fromJson(res);
  }

  Future<KycRequirements> getKycRequirements() async {
    final res = await client.getJson('/kyc/requirements');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /kyc/requirements response', body: res);
    }
    return KycRequirements.fromJson(res);
  }

  Future<KycStatusSnapshot> getKycStatus() async {
    final res = await client.getJson('/kyc/status');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /kyc/status response', body: res);
    }
    return KycStatusSnapshot.fromJson(res);
  }

  Future<void> verifyBvn(String bvn) async {
    await client.postJson('/kyc/verify-bvn', body: <String, dynamic>{'bvn': bvn});
  }

  Future<BankStatementSummary> generateBankStatement() async {
    final res = await client.postJsonNoBody('/kyc/bank-statement');
    return BankStatementSummary.fromJson(res);
  }

  Future<BankStatementSummary> getBankStatement() async {
    final res = await client.getJson('/kyc/bank-statement');
    if (res is! Map<String, dynamic>) {
      throw ApiException('Invalid /kyc/bank-statement response', body: res);
    }
    return BankStatementSummary.fromJson(res);
  }
}
