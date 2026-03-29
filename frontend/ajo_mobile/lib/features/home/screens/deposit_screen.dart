import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/api_repositories.dart';
import '../../../core/theme/theme.dart';

// --- Entry Point --------------------------------------------------------------

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _displayAmount = '0.00';

  static const _quickOptions = [
    _QuickOption(label: 'STANDARD', amount: 5000),
    _QuickOption(label: 'GROWTH', amount: 10000),
    _QuickOption(label: 'PREMIUM', amount: 20000),
    _QuickOption(label: 'EXECUTIVE', amount: 50000),
  ];

  void _onQuickSelect(int amount) {
    setState(() {
      _displayAmount =
          amount.toStringAsFixed(2).replaceAllMapped(
                RegExp(r'\B(?=(\d{3})+(?!\d))'),
                (_) => ',',
              );
      _amountController.text = amount.toStringAsFixed(2);
    });
  }

  bool get _hasAmount {
    final raw = double.tryParse(_amountController.text);
    return raw != null && raw > 0;
  }

  void _proceed() {
    if (!_hasAmount) return;
    final amount = double.parse(_amountController.text);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DepositMethodScreen(amount: amount),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Deposit Funds', style: AppTypography.titleMd(cs.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      backgroundColor: cs.surfaceContainer,
      body: SafeArea(
        child: Column(
          children: [


            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -- Heading --
                    Text(
                      'TRANSACTION',
                      style: AppTypography.labelSm(cs.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter Amount',
                      style: AppTypography.displaySm(cs.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Set the capital for your next collective savings pool.',
                      style: AppTypography.bodySm(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 28),

                    // -- Amount Input Card --
                    _AmountInputCard(
                      controller: _amountController,
                      displayAmount: _displayAmount,
                      onChanged: (val) {
                        final cleaned = val.replaceAll(',', '');
                        final parsed = double.tryParse(cleaned);
                        setState(() {
                          if (parsed != null) {
                            _displayAmount = parsed
                                .toStringAsFixed(2)
                                .replaceAllMapped(
                                  RegExp(r'\B(?=(\d{3})+(?!\d))'),
                                  (_) => ',',
                                );
                          } else {
                            _displayAmount = '0.00';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 28),

                    // -- Quick Select --
                    Text(
                      'QUICK SELECT',
                      style: AppTypography.labelSm(cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.8,
                      children: _quickOptions
                          .map((o) => _QuickSelectCard(
                                option: o,
                                onTap: () => _onQuickSelect(o.amount),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 24),

                    // -- Daily Limit Info --
                    _DailyLimitBanner(),
                    const SizedBox(height: 32),

                    // -- Proceed Button --
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _hasAmount ? _proceed : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          disabledBackgroundColor:
                              cs.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Proceed to Confirmation',
                              style: AppTypography.labelLg(cs.onPrimary),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // -- Security note --
                    Center(
                      child: Text(
                        'SECURE 256-BIT AES ENCRYPTION',
                        style: AppTypography.labelSm(cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Amount Input Card --------------------------------------------------------

class _AmountInputCard extends StatelessWidget {
  const _AmountInputCard({
    required this.controller,
    required this.displayAmount,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String displayAmount;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CURRENCY: NGN (₦)',
                style: AppTypography.labelSm(cs.onSurfaceVariant),
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('₦', style: AppTypography.displayMd(cs.primary)),
              const SizedBox(width: 4),
              Container(
                  width: 2,
                  height: 48,
                  color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  style: AppTypography.displayMd(
                      cs.onSurface.withValues(alpha: 0.35)),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: AppTypography.displayMd(
                        cs.onSurface.withValues(alpha: 0.25)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
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

// --- Quick Select -------------------------------------------------------------

class _QuickOption {
  const _QuickOption({required this.label, required this.amount});
  final String label;
  final int amount;
}

class _QuickSelectCard extends StatelessWidget {
  const _QuickSelectCard({required this.option, required this.onTap});
  final _QuickOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.label,
              style: AppTypography.labelSm(cs.onSurfaceVariant),
            ),
            const SizedBox(height: 6),
            Text(
              '₦${option.amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}',
              style: AppTypography.titleLg(cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Daily Limit Banner -------------------------------------------------------

class _DailyLimitBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.15),
            ),
            child: Icon(Icons.info_outline_rounded,
                color: cs.primary, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Limit Check',
                    style: AppTypography.titleSm(cs.onSurface)),
                const SizedBox(height: 2),
                Text(
                  'Deposit limit: ₦500,000. Increase in Settings.',
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

// --- Deposit Method Screen ----------------------------------------------------

class DepositMethodScreen extends StatefulWidget {
  const DepositMethodScreen({super.key, required this.amount});
  final double amount;

  @override
  State<DepositMethodScreen> createState() => _DepositMethodScreenState();
}

class _DepositMethodScreenState extends State<DepositMethodScreen> {
  bool _busy = false;

  static const _methods = [
    _DepositMethod(
      icon: Icons.account_balance_outlined,
      title: 'Bank Transfer',
      subtitle: 'Secure transfer from any local or international bank account.',
    ),
    _DepositMethod(
      icon: Icons.credit_card_outlined,
      title: 'Credit/Debit Card',
      subtitle: 'Instant funding via Visa, Mastercard, or Verve.',
    ),
    _DepositMethod(
      icon: Icons.dialpad_outlined,
      title: 'USSD',
      subtitle: 'Quick deposit using your mobile network shortcode.',
    ),
  ];

  Future<void> _fund(_DepositMethod method) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ref =
        'AJO-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(900000) + 100000}';
    try {
      final tx = await profileHttpApi.fundWallet(
        amount: widget.amount,
        reference: ref,
        description: 'Deposit via ${method.title}',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DepositSuccessScreen(
            amount: tx.amount,
            method: method.title,
            reference: tx.reference,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
        title: Text('Deposit Funds', style: AppTypography.titleMd(cs.onSurface)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text('Ajo', style: AppTypography.titleLg(cs.primary)),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STEP 1 OF 2',
                    style: AppTypography.labelSm(cs.onSurfaceVariant)),
                const SizedBox(height: 6),
                Text('Choose Method',
                    style: AppTypography.displaySm(cs.onSurface)),
                const SizedBox(height: 8),
                Text(
                  'Select a channel to confirm. Your wallet is credited immediately for demo funding.',
                  style: AppTypography.bodySm(cs.onSurfaceVariant),
                ),
                const SizedBox(height: 28),
                ..._methods.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MethodCard(
                        method: m,
                        enabled: !_busy,
                        onTap: () => _fund(m),
                      ),
                    )),
                const Spacer(),
                _SecureTransactionBanner(),
              ],
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: AbsorbPointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x33000000)),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DepositMethod {
  const _DepositMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.method,
    required this.onTap,
    this.enabled = true,
  });
  final _DepositMethod method;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(method.icon, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.title,
                      style: AppTypography.titleSm(cs.onSurface)),
                  const SizedBox(height: 4),
                  Text(method.subtitle,
                      style: AppTypography.bodySm(cs.onSurfaceVariant)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant, size: 20),
          ],
        ),
      ),
      ),
    );
  }
}

class _SecureTransactionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SECURE TRANSACTION',
                    style: AppTypography.labelSm(cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'All deposits are processed through PCI-DSS compliant gateways. '
                  'Your financial data is encrypted and never stored on our servers.',
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

// --- Deposit Success Screen ---------------------------------------------------

class DepositSuccessScreen extends StatelessWidget {
  const DepositSuccessScreen({
    super.key,
    required this.amount,
    required this.method,
    required this.reference,
  });

  final double amount;
  final String method;
  final String reference;

  String get _formattedAmount {
    final fixed = amount.toStringAsFixed(2);
    final parts = fixed.split('.');
    final intFormatted = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '₦$intFormatted.${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        backgroundColor: cs.surfaceContainer,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.menu_rounded, color: cs.onSurface, size: 24),
            const SizedBox(width: 12),
            Text('Ajo', style: AppTypography.titleLg(cs.primary)),
            const Spacer(),
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2A2A2A),
              ),
              child: Icon(Icons.person, color: cs.onSurface, size: 20),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          children: [
            // -- Success Icon --
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF27AE60),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.black, size: 36),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Deposit Successful',
                style: AppTypography.displaySm(cs.onSurface)),
            const SizedBox(height: 8),
            Text(
              'Your funds are now available in your vault.',
              style: AppTypography.bodySm(cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // -- Amount Card --
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: cs.primary, width: 4),
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('AMOUNT DEPOSITED',
                      style: AppTypography.labelSm(cs.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Text(_formattedAmount,
                      style: AppTypography.displayMd(cs.onSurface)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // -- Method & Status --
            Row(
              children: [
                Expanded(
                  child: _DetailCard(
                    label: 'Method',
                    icon: Icons.account_balance_outlined,
                    value: method,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatusCard(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // -- Reference --
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ref: $reference',
                      style: AppTypography.bodySm(cs.onSurfaceVariant),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: reference));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reference copied'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Icon(Icons.copy_outlined,
                        color: cs.onSurfaceVariant, size: 18),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // -- Done Button --
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Pop back to wallet root
                  Navigator.of(context).popUntil((r) => r.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Done', style: AppTypography.labelLg(cs.onPrimary)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // TODO: implement receipt view
              },
              child:
                  Text('View Receipt', style: AppTypography.labelMd(cs.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelSm(cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: cs.onSurface, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(value, style: AppTypography.titleSm(cs.onSurface)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status', style: AppTypography.labelSm(cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF27AE60),
                ),
              ),
              const SizedBox(width: 8),
              Text('Confirmed', style: AppTypography.titleSm(cs.onSurface)),
            ],
          ),
        ],
      ),
    );
  }
}
