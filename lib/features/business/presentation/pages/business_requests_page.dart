import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/utils/responsive.dart';
import 'package:bonvo/features/business/domain/entities/business.dart';
import 'package:bonvo/features/business/domain/repositories/business_repository.dart';
import 'package:bonvo/features/business/presentation/widgets/business_web_shell.dart';
import 'package:bonvo/features/business/presentation/widgets/pending_requests.dart';
import 'package:bonvo/injection/injection.dart';

/// Todas las solicitudes pendientes del negocio (compras y canjes).
class BusinessRequestsPage extends StatefulWidget {
  final String businessId;
  final String businessName;

  const BusinessRequestsPage({
    super.key,
    required this.businessId,
    this.businessName = '',
  });

  @override
  State<BusinessRequestsPage> createState() => _BusinessRequestsPageState();
}

class _BusinessRequestsPageState extends State<BusinessRequestsPage> {
  Business? _business;

  @override
  void initState() {
    super.initState();
    getIt<BusinessRepository>().getBusiness(widget.businessId).then((r) {
      if (mounted) r.fold((_) {}, (b) => setState(() => _business = b));
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final content = _business == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                wide ? 32 : 16, wide ? 28 : 16, wide ? 32 : 16, 32),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide) ...[
                      const Text('Solicitudes',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.5)),
                      const SizedBox(height: 4),
                    ],
                    const Text(
                      'Aprueba las compras que tus clientes registraron y '
                      'confirma la entrega de los regalos que pidieron.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    PendingRequestsList(
                      businessId: widget.businessId,
                      programs: _business!.programs,
                    ),
                  ],
                ),
              ),
            ),
          );

    if (wide) {
      return BusinessWebShell(
        current: BusinessSection.requests,
        businessId: widget.businessId,
        businessName: _business?.name ?? widget.businessName,
        logoBase64: _business?.logoBase64,
        child: content,
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Solicitudes')),
      body: content,
    );
  }
}
