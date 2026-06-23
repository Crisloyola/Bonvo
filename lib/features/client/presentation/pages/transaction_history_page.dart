import 'package:flutter/material.dart';
import 'package:bonvo/config/themes/app_theme.dart';
import 'package:bonvo/core/widgets/transaction_tile.dart';
import 'package:bonvo/features/points/domain/entities/transaction.dart';
import 'package:bonvo/features/points/domain/repositories/points_repository.dart';
import 'package:bonvo/injection/injection.dart';
import 'package:intl/intl.dart';

class TransactionHistoryPage extends StatefulWidget {
  final String userId;
  const TransactionHistoryPage({super.key, required this.userId});

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  late final Future<List<Transaction>> _txFuture;

  @override
  void initState() {
    super.initState();
    _txFuture = getIt<PointsRepository>()
        .getUserTransactions(widget.userId)
        .then((either) => either.fold((_) => [], (list) => list));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<List<Transaction>>(
        future: _txFuture,
        builder: (context, snap) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.primaryDeep,
                title: const Text('Historial de puntos'),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration:
                        const BoxDecoration(gradient: AppColors.gradient),
                  ),
                ),
              ),
              if (snap.connectionState == ConnectionState.waiting)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!snap.hasData || snap.data!.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.greenTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              size: 40, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Sin transacciones aún',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aquí verás tu historial de\npuntos acumulados y canjeados',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final tx = snap.data![i];
                        final isEarn = tx.type == TransactionType.earn;
                        return TransactionTile(
                          title: tx.businessName,
                          subtitle: DateFormat('dd/MM/yyyy HH:mm')
                              .format(tx.timestamp),
                          points: tx.points,
                          isEarned: isEarn,
                          amountLabel: isEarn
                              ? 'S/ ${tx.amount.toStringAsFixed(2)}'
                              : null,
                        );
                      },
                      childCount: snap.data!.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
