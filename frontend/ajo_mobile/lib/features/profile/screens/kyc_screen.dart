import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';
import '../../../core/widgets/ajo_gradient_button.dart';
import '../../../core/widgets/ajo_nav_bar.dart';
import '../data/profile_http_api.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point – 3-step KYC wizard + live requirements /status monitoring
// ─────────────────────────────────────────────────────────────────────────────

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  /// 0 = BVN (+ wallet when needed)  |  1 = Bank Statement  |  2 = Trust Score
  int _step = 0;

  KycRequirements? _requirements;
  KycStatusSnapshot? _kycStatus;
  BankStatementSummary? _statement;

  bool _loading = true;
  bool _walletSubmitting = false;
  String? _error;
  bool _didApplyInitialStep = false;

  Timer? _statusPoll;

  void _goToStep(int step) => setState(() => _step = step);

  static int _initialStep(KycRequirements r, BankStatementSummary? statement) {
    if (r.nextStep == 'completed' && statement != null) return 2;
    if (r.nextStep == 'completed') return 1;
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _statusPoll = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted || _loading) return;
      _refreshKycMonitors(silent: true);
    });
  }

  @override
  void dispose() {
    _statusPoll?.cancel();
    super.dispose();
  }

  Future<void> _refreshKycMonitors({required bool silent}) async {
    try {
      final results = await Future.wait([
        profileHttpApi.getKycRequirements(),
        profileHttpApi.getKycStatus(),
      ]);
      if (!mounted) return;
      setState(() {
        _requirements = results[0] as KycRequirements;
        _kycStatus = results[1] as KycStatusSnapshot;
        _error = null;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final futures = await Future.wait([
        profileHttpApi.getKycRequirements(),
        profileHttpApi.getKycStatus(),
      ]);
      final requirements = futures[0] as KycRequirements;
      final status = futures[1] as KycStatusSnapshot;
      BankStatementSummary? statement;
      try {
        statement = await profileHttpApi.getBankStatement();
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _requirements = requirements;
        _kycStatus = status;
        _statement = statement;
        if (!silent) _loading = false;
      });

      if (!_didApplyInitialStep) {
        _didApplyInitialStep = true;
        if (!mounted) return;
        setState(() => _step = _initialStep(requirements, statement));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        if (!silent) _loading = false;
      });
    }
  }

  Future<void> _provisionWallet() async {
    setState(() => _walletSubmitting = true);
    try {
      await profileHttpApi.provisionWallet();
      await _load(silent: true);
      await _refreshKycMonitors(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _walletSubmitting = false);
    }
  }

  void _onDone() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    if (_loading && _requirements == null) {
      final cs = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: cs.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded,
                          color: cs.onSurface, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Trust & Identity',
                        style: AppTypography.titleLg(cs.onSurface),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
            ],
          ),
        ),
      );
    }

    final req = _requirements;
    final st = _kycStatus;

    return switch (_step) {
      0 => _BvnStep(
          requirements: req,
          kycStatus: st,
          walletSubmitting: _walletSubmitting,
          topError: _error,
          onPullRefresh: () => _load(silent: true),
          onProvisionWallet: _provisionWallet,
          onContinueToStatement: () => _goToStep(1),
          onAfterBvnSubmit: () => _load(silent: true),
        ),
      1 => _BankStatementStep(
          requirements: req,
          onBack: () => _goToStep(0),
          onAnalysed: (statement) {
            setState(() {
              _statement = statement;
              _step = 2;
            });
            _refreshKycMonitors(silent: true);
          },
        ),
      _ => _TrustScoreStep(
          statement: _statement,
          requirements: req,
          onBack: () => _goToStep(1),
          onDone: _onDone,
        ),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared scaffold wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _KycScaffold extends StatelessWidget {
  const _KycScaffold({
    required this.child,
    this.showNavBar = false,
    this.activeTab = AjoTab.account,
    this.floatingButton,
    this.bottomContent,
  });

  final Widget child;
  final bool showNavBar;
  final AjoTab activeTab;
  final Widget? floatingButton;
  final Widget? bottomContent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      bottomNavigationBar: showNavBar ? AjoNavBar(active: activeTab) : null,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: child),
            if (floatingButton != null || bottomContent != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ?bottomContent,
                    if (floatingButton != null) ...[
                      const SizedBox(height: 12),
                      floatingButton!,
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared app bar
// ─────────────────────────────────────────────────────────────────────────────

class _KycAppBar extends StatelessWidget {
  const _KycAppBar({required this.title, this.onBack});
  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: cs.onSurface, size: 20),
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              title,
              style: AppTypography.titleLg(cs.onSurface),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.security_rounded, color: cs.primary, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BVN monitoring banner (requirements + /kyc/status)
// ─────────────────────────────────────────────────────────────────────────────

class _BvnStatusMonitor extends StatelessWidget {
  const _BvnStatusMonitor({
    required this.requirements,
    required this.kycStatus,
  });

  final KycRequirements? requirements;
  final KycStatusSnapshot? kycStatus;

  String get _headline {
    final verified = requirements?.bvnVerified == true ||
        kycStatus?.bvnVerified == true;
    if (verified) return 'BVN verified';
    return 'BVN not verified yet';
  }

  String get _detail {
    final st = kycStatus?.status ?? '…';
    final next = requirements?.nextStep ?? kycStatus?.nextStep ?? '…';
    final w = kycStatus?.walletStatus ?? requirements?.walletStatus ?? '…';
    return 'KYC record: $st · Next: $next · Wallet: $w';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ok = requirements?.bvnVerified == true ||
        kycStatus?.bvnVerified == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ok
            ? cs.primary.withValues(alpha: 0.08)
            : cs.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok
              ? cs.primary.withValues(alpha: 0.35)
              : cs.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                ok ? Icons.verified_rounded : Icons.sync_rounded,
                color: ok ? cs.primary : cs.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _headline,
                  style: AppTypography.titleSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _detail,
            style: AppTypography.bodySm(cs.onSurfaceVariant),
          ),
          if (requirements?.bannerMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              requirements!.bannerMessage!,
              style: AppTypography.labelSm(cs.primary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 – BVN Verification (+ wallet provisioning when required)
// ─────────────────────────────────────────────────────────────────────────────

class _BvnStep extends StatefulWidget {
  const _BvnStep({
    required this.requirements,
    required this.kycStatus,
    required this.walletSubmitting,
    required this.topError,
    required this.onPullRefresh,
    required this.onProvisionWallet,
    required this.onContinueToStatement,
    required this.onAfterBvnSubmit,
  });

  final KycRequirements? requirements;
  final KycStatusSnapshot? kycStatus;
  final bool walletSubmitting;
  final String? topError;
  final Future<void> Function() onPullRefresh;
  final VoidCallback onProvisionWallet;
  final VoidCallback onContinueToStatement;
  final Future<void> Function() onAfterBvnSubmit;

  @override
  State<_BvnStep> createState() => _BvnStepState();
}

class _BvnStepState extends State<_BvnStep> {
  final TextEditingController _ctrl = TextEditingController();
  bool _submitting = false;

  bool get _bvnDone =>
      widget.requirements?.bvnVerified == true ||
      widget.kycStatus?.bvnVerified == true;

  bool get _needsWallet {
    final n = widget.requirements?.nextStep ?? widget.kycStatus?.nextStep;
    return _bvnDone &&
        (n == 'provision_wallet' || n == 'retry_wallet_provisioning');
  }

  bool get _walletReady =>
      widget.requirements?.walletProvisioned == true ||
      widget.kycStatus?.walletProvisioned == true;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_ctrl.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('BVN must be 11 digits')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await profileHttpApi.verifyBvn(_ctrl.text.trim());
      await widget.onAfterBvnSubmit();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _primaryLabel {
    if (!_bvnDone) return 'Verify BVN';
    if (_needsWallet) {
      return widget.requirements?.nextStep == 'retry_wallet_provisioning'
          ? 'Retry wallet provisioning'
          : 'Provision wallet';
    }
    return 'Continue to bank statement';
  }

  Future<void> _onPrimary() async {
    if (!_bvnDone) {
      await _verify();
      return;
    }
    if (_needsWallet) {
      widget.onProvisionWallet();
      return;
    }
    widget.onContinueToStatement();
  }

  bool get _primaryLoading =>
      _submitting || (_needsWallet && widget.walletSubmitting);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _KycScaffold(
      floatingButton: AjoGradientButton(
        label: _primaryLabel,
        suffixIcon: Icons.arrow_forward_rounded,
        isLoading: _primaryLoading,
        onPressed: _primaryLoading ? null : _onPrimary,
      ),
      bottomContent: _SecurityFooter(cs: cs),
      child: RefreshIndicator(
        onRefresh: widget.onPullRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _KycAppBar(title: 'Trust & Identity'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.topError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          widget.topError!,
                          style: AppTypography.bodySm(cs.error),
                        ),
                      ),
                    _BvnStatusMonitor(
                      requirements: widget.requirements,
                      kycStatus: widget.kycStatus,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'STEP 1 OF 3',
                      style: AppTypography.labelSm(cs.primary).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Secure Your\nCollective Identity.',
                      style: AppTypography.headlineLg(cs.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Ajo requires your Bank Verification Number to ensure every '
                      'member of the savings pool is verified and trusted.',
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),
                    _InfoCard(
                      icon: Icons.lock_rounded,
                      title: 'Encrypted Data',
                      body:
                          'Your BVN is never stored on our servers in plain text.',
                      accentColor: cs.primary,
                    ),
                    const SizedBox(height: 14),
                    _InfoCard(
                      icon: Icons.verified_user_rounded,
                      title: 'Identity Check',
                      body: 'We only use this to confirm your legal name and DOB.',
                      accentColor: Colors.lightBlueAccent,
                    ),
                    const SizedBox(height: 28),
                    if (!_bvnDone)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ENTER 11-DIGIT BVN',
                              style: AppTypography.labelSm(cs.onSurfaceVariant)
                                  .copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _ctrl,
                              keyboardType: TextInputType.number,
                              maxLength: 11,
                              style: AppTypography.titleLg(cs.onSurface),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: cs.surfaceContainerHigh
                                    .withValues(alpha: 0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: Icon(Icons.dialpad_rounded,
                                    color: cs.onSurfaceVariant),
                                hintText: '• • • • • • • • • • •',
                                hintStyle: AppTypography.titleMd(
                                    cs.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_rounded,
                                      color: cs.primary, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: AppTypography.bodySm(
                                            cs.onSurfaceVariant),
                                        children: [
                                          const TextSpan(text: 'Dial '),
                                          TextSpan(
                                            text: '*565*0#',
                                            style:
                                                AppTypography.bodySm(cs.primary)
                                                    .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700),
                                          ),
                                          const TextSpan(
                                            text:
                                                ' on your registered mobile number '
                                                "if you've forgotten your BVN.",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: cs.primary, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _walletReady
                                    ? 'Identity verified. You can continue to bank statement analysis.'
                                    : 'Identity verified. Finish wallet setup below when you are ready, then continue.',
                                style: AppTypography.bodyMd(cs.onSurface),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_needsWallet) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.account_balance_wallet_rounded,
                                  color: cs.primary, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.requirements?.bannerMessage ??
                                      'Provision your wallet to receive payouts.',
                                  style: AppTypography.bodyMd(cs.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 – Bank Statement Analysis
// ─────────────────────────────────────────────────────────────────────────────

class _BankStatementStep extends StatefulWidget {
  const _BankStatementStep({
    required this.requirements,
    required this.onAnalysed,
    required this.onBack,
  });

  final KycRequirements? requirements;
  final ValueChanged<BankStatementSummary> onAnalysed;
  final VoidCallback onBack;

  @override
  State<_BankStatementStep> createState() => _BankStatementStepState();
}

class _BankStatementStepState extends State<_BankStatementStep> {
  bool _submitting = false;
  bool _analysing = false;
  double _incomeProgress = 0.0;

  final List<String> _uploadedFiles = ['OCT_23.PDF', 'NOV_23.PDF'];

  Future<void> _analyseStatement() async {
    final ok = widget.requirements?.bvnVerified == true;
    if (ok == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Complete BVN verification before analysis.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _analysing = true;
      _incomeProgress = 0.0;
    });

    final ticker = Stream.periodic(const Duration(milliseconds: 60), (i) => i)
        .take(20);
    await for (final _ in ticker) {
      if (!mounted) return;
      setState(() => _incomeProgress = (_incomeProgress + 0.05).clamp(0, 0.85));
    }

    try {
      final statement = await profileHttpApi.generateBankStatement();
      if (!mounted) return;
      setState(() => _incomeProgress = 1.0);
      await Future.delayed(const Duration(milliseconds: 400));
      widget.onAnalysed(statement);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _analysing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return _KycScaffold(
      showNavBar: true,
      activeTab: AjoTab.account,
      floatingButton: AjoGradientButton(
        label: 'Analyze Statement',
        suffixIcon: Icons.bar_chart_rounded,
        isLoading: _submitting,
        onPressed: _submitting ? null : _analyseStatement,
      ),
      bottomContent: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.labelSm(cs.onSurfaceVariant),
            children: [
              const TextSpan(text: 'By clicking Analyze, you agree to our '),
              TextSpan(
                text: 'Financial Privacy Policy',
                style: AppTypography.labelSm(cs.primary),
              ),
              const TextSpan(
                  text: '. Data is encrypted and deleted after analysis.'),
            ],
          ),
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _KycAppBar(title: 'Trust & Identity', onBack: widget.onBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VERIFICATION STEP 2 OF 3',
                    style: AppTypography.labelSm(cs.primary).copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Bank Statement\n',
                          style: AppTypography.headlineLg(cs.onSurface),
                        ),
                        TextSpan(
                          text: 'Analysis',
                          style: AppTypography.headlineLg(cs.primary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To secure your placement in high-yield Ajo pools, we need '
                    'to verify your financial consistency over the last 6 months.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  _LinkBankCard(cs: cs),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR UPLOAD MANUALLY',
                          style: AppTypography.labelSm(cs.onSurfaceVariant)
                              .copyWith(letterSpacing: 1.1),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _UploadPdfCard(
                    cs: cs,
                    uploadedFiles: _uploadedFiles,
                    onAddMore: () {},
                  ),
                  const SizedBox(height: 24),
                  _AnalysisStatusCard(
                    cs: cs,
                    incomeProgress: _incomeProgress,
                    analysing: _analysing,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 – Trust Score result
// ─────────────────────────────────────────────────────────────────────────────

class _TrustScoreStep extends StatelessWidget {
  const _TrustScoreStep({
    required this.statement,
    required this.requirements,
    required this.onDone,
    required this.onBack,
  });

  final BankStatementSummary? statement;
  final KycRequirements? requirements;
  final VoidCallback onDone;
  final VoidCallback onBack;

  int get _trustScore {
    if (statement == null) return 780;
    final ratio =
        (statement!.totalCredit / (statement!.totalDebit + 1)).clamp(0, 2);
    return (600 + (ratio * 180)).round().clamp(300, 1000);
  }

  String get _label {
    if (_trustScore >= 750) return 'EXCELLENT';
    if (_trustScore >= 600) return 'GOOD';
    return 'FAIR';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreRatio = _trustScore / 1000.0;
    final kycComplete = requirements?.nextStep == 'completed';

    return _KycScaffold(
      showNavBar: true,
      activeTab: AjoTab.account,
      floatingButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AjoGradientButton(
            label: 'Continue to Dashboard',
            suffixIcon: Icons.arrow_forward_rounded,
            onPressed: onDone,
          ),
          if (!kycComplete) ...[
            const SizedBox(height: 10),
            Text(
              'Finish wallet setup from the previous step if payouts are pending.',
              style: AppTypography.labelSm(cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Share My Achievement',
              style: AppTypography.titleSm(cs.primary),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _KycAppBar(title: 'Trust & Identity', onBack: onBack),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.celebration_rounded,
                          color: Colors.amberAccent, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TrustScoreGauge(
                      score: _trustScore,
                      ratio: scoreRatio,
                      cs: cs,
                      label: _label),
                  const SizedBox(height: 24),
                  Text(
                    'Level Up! 🚀',
                    style: AppTypography.headlineMd(cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your financial integrity is outstanding. You\'re now eligible '
                    'for premium savings pools with lower entry barriers.',
                    style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Expanded(child: Divider(color: cs.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'SCORE BREAKDOWN',
                            style: AppTypography.labelSm(cs.onSurfaceVariant)
                                .copyWith(letterSpacing: 1.2),
                          ),
                        ),
                        Expanded(child: Divider(color: cs.outlineVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BreakdownCard(
                    icon: Icons.fingerprint_rounded,
                    title: 'BVN verification',
                    body:
                        'Identity confirmed through official government databases.',
                    badge: (requirements?.bvnVerified == true) ? 'MATCHED' : 'PENDING',
                    badgeColor: cs.primary,
                    progress: (requirements?.bvnVerified == true) ? 1.0 : 0.35,
                    showBar: true,
                    cs: cs,
                  ),
                  const SizedBox(height: 12),
                  _BreakdownCard(
                    icon: Icons.account_balance_rounded,
                    title: 'Income stability',
                    body:
                        'Analysis of monthly cash flow patterns over 6 months.',
                    badge: 'CONSISTENT',
                    badgeColor: cs.primary,
                    progress: 0.82,
                    showBar: true,
                    cs: cs,
                  ),
                  const SizedBox(height: 12),
                  _SavingsHistoryCard(cs: cs),
                  const SizedBox(height: 16),
                  _BoostCard(cs: cs),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: accentColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.titleSm(cs.onSurface)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: AppTypography.bodySm(cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkBankCard extends StatelessWidget {
  const _LinkBankCard({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_rounded,
                  color: cs.onSurface, size: 28),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RECOMMENDED',
                  style: AppTypography.labelSm(cs.primary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Link Bank Account',
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Instant verification via secure Open Banking. No passwords stored.',
              style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Connect via Interswitch',
                      style: AppTypography.titleSm(cs.onSurface)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.open_in_new_rounded,
                      color: cs.onSurface, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadPdfCard extends StatelessWidget {
  const _UploadPdfCard({
    required this.cs,
    required this.uploadedFiles,
    required this.onAddMore,
  });
  final ColorScheme cs;
  final List<String> uploadedFiles;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.upload_file_rounded, color: cs.onSurface, size: 26),
          ),
          const SizedBox(height: 12),
          Text('Upload PDF Statements',
              style: AppTypography.titleMd(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Drag and drop your last 6 months of statements here. Max 10MB per file.',
            style: AppTypography.bodySm(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in uploadedFiles) _FileChip(name: f, cs: cs),
              GestureDetector(
                onTap: onAddMore,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: cs.primary.withValues(alpha: 0.50)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: cs.primary, size: 16),
                      const SizedBox(width: 4),
                      Text('ADD MORE',
                          style: AppTypography.labelSm(cs.primary).copyWith(
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.cs});
  final String name;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_rounded, color: cs.primary, size: 14),
          const SizedBox(width: 6),
          Text(name,
              style: AppTypography.labelSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AnalysisStatusCard extends StatelessWidget {
  const _AnalysisStatusCard({
    required this.cs,
    required this.incomeProgress,
    required this.analysing,
  });
  final ColorScheme cs;
  final double incomeProgress;
  final bool analysing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Analysis Status',
                  style: AppTypography.titleSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(
                analysing ? 'RUNNING AI MODELS' : 'READY',
                style: AppTypography.labelSm(cs.primary).copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProgressRow(
            label: 'INCOME CONSISTENCY',
            progress: incomeProgress,
            trailing: incomeProgress > 0
                ? '${(incomeProgress * 100).round()}% COMPLETE'
                : null,
            cs: cs,
          ),
          const SizedBox(height: 12),
          _ProgressRow(
            label: 'SPENDING HABIT MAPPING',
            progress: 0,
            trailing: incomeProgress > 0 ? 'WAITING...' : null,
            cs: cs,
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.progress,
    required this.cs,
    this.trailing,
  });
  final String label;
  final double progress;
  final ColorScheme cs;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTypography.labelSm(cs.onSurfaceVariant).copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            if (trailing != null)
              Text(trailing!,
                  style: AppTypography.labelSm(cs.primary)
                      .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHigh,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}

class _TrustScoreGauge extends StatelessWidget {
  const _TrustScoreGauge({
    required this.score,
    required this.ratio,
    required this.cs,
    required this.label,
  });
  final int score;
  final double ratio;
  final ColorScheme cs;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _GaugePainter(
              ratio: ratio,
              trackColor: cs.surfaceContainerHigh,
              fillColor: cs.primary,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('YOUR TRUST SCORE',
                  style: AppTypography.labelSm(cs.onSurfaceVariant)
                      .copyWith(letterSpacing: 1.0)),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$score',
                      style: AppTypography.headlineLg(cs.onSurface).copyWith(
                          fontSize: 52, fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: '/1000',
                      style: AppTypography.bodyMd(cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(label,
                      style: AppTypography.labelSm(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: cs.primary, size: 14),
                  const SizedBox(width: 4),
                  Text('+12 pts',
                      style: AppTypography.labelSm(cs.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({
    required this.ratio,
    required this.trackColor,
    required this.fillColor,
  });
  final double ratio;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = math.pi * 0.75;
    const sweepMax = math.pi * 1.5;

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = fillColor
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepMax, false, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweepMax * ratio, false, fill);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.ratio != ratio;
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.badge,
    required this.badgeColor,
    required this.progress,
    required this.showBar,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String body;
  final String badge;
  final Color badgeColor;
  final double progress;
  final bool showBar;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: cs.primary, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(badge,
                    style: AppTypography.labelSm(badgeColor)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTypography.titleSm(cs.onSurface)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body, style: AppTypography.bodySm(cs.onSurfaceVariant)),
          if (showBar) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: cs.surfaceContainerHigh,
                color: cs.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavingsHistoryCard extends StatelessWidget {
  const _SavingsHistoryCard({required this.cs});
  final ColorScheme cs;

  static const List<double> _bars = [0.5, 0.65, 0.72, 0.80, 0.88, 0.94];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Savings history',
                  style: AppTypography.titleSm(cs.onSurface)
                      .copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('94%',
                      style: AppTypography.titleMd(cs.primary)
                          .copyWith(fontWeight: FontWeight.w800)),
                  Text('RELIABILITY\nRATE',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)
                          .copyWith(fontSize: 9, height: 1.2),
                      textAlign: TextAlign.right),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Participation and reliability in communal pools.',
              style: AppTypography.bodySm(cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _bars
                  .map(
                    (h) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: h,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostCard extends StatelessWidget {
  const _BoostCard({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lightbulb_rounded, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boost your score further',
                    style: AppTypography.titleSm(cs.onSurface)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Completing a 30-day savings cycle without missing a contribution '
                  'will add approximately 45 points to your score.',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: cs.onSurfaceVariant, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Your financial data is protected by bank-grade security standards (AES-256).',
            style: AppTypography.labelSm(cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
