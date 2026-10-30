import 'package:flutter_test/flutter_test.dart';
import 'package:bonvo/features/loyalty/domain/loyalty.dart';

void main() {
  group('Puntos por monto', () {
    test('ejemplo del cliente: S/ 100 da 2 pts', () {
      const p = LoyaltyPrograms(pointsPerSol: 2, pointsEverySoles: 100);
      expect(p.pointsFor(10000), 2);
      expect(p.pointsRule, '2 pts por cada S/ 100');
    });

    test('solo cuentan tramos completos', () {
      const p = LoyaltyPrograms(pointsPerSol: 2, pointsEverySoles: 100);
      expect(p.pointsFor(9999), 0); // S/ 99.99
      expect(p.pointsFor(25000), 4); // S/ 250
    });

    test('negocios antiguos (sin everySoles) siguen igual: 1 pt por S/ 1', () {
      final p = LoyaltyPrograms.fromMap(const {
        'points': {'enabled': true, 'perSol': 5},
      });
      expect(p.pointsEverySoles, 1);
      expect(p.pointsFor(20000), 1000); // S/ 200 × 5
    });

    test('se guarda y se vuelve a leer igual', () {
      const p = LoyaltyPrograms(pointsPerSol: 3, pointsEverySoles: 10);
      expect(LoyaltyPrograms.fromMap(p.toMap()), p);
    });

    test('programa de puntos apagado no da puntos', () {
      const p = LoyaltyPrograms(pointsEnabled: false);
      expect(p.pointsFor(10000), 0);
    });
  });

  group('El cliente elige qué sumar', () {
    const all = LoyaltyPrograms(
      stampsEnabled: true,
      cashbackEnabled: true,
      cashbackPercent: 3,
      pointsEnabled: true,
      pointsPerSol: 2,
      pointsEverySoles: 10,
    );

    test('solo puntos', () {
      final e = all.earnFor(5000, only: LoyaltyProgram.points);
      expect([e.points, e.cashbackCents, e.stamps], [10, 0, 0]);
      expect(e.describe(), '+10 pts');
    });

    test('solo cashback', () {
      final e = all.earnFor(5000, only: LoyaltyProgram.cashback);
      expect([e.points, e.cashbackCents, e.stamps], [0, 150, 0]);
    });

    test('solo sello, aunque no ponga monto', () {
      final e = all.earnFor(0, only: LoyaltyProgram.stamps);
      expect([e.points, e.cashbackCents, e.stamps], [0, 0, 1]);
    });

    test('solicitudes antiguas (sin elección) suman todo', () {
      final e = all.earnFor(5000);
      expect([e.points, e.cashbackCents, e.stamps], [10, 150, 1]);
    });

    test('las opciones son solo los programas activos', () {
      const p = LoyaltyPrograms(stampsEnabled: true, pointsEnabled: false);
      expect(p.enabledPrograms, [LoyaltyProgram.stamps]);
      expect(all.enabledPrograms.length, 3);
    });
  });

  test('cashback: 2% de S/ 100 = S/ 2.00', () {
    const p = LoyaltyPrograms(cashbackEnabled: true, cashbackPercent: 2);
    expect(p.cashbackFor(10000), 200);
    expect(formatSoles(p.cashbackFor(10000)), 'S/ 2.00');
  });
}
