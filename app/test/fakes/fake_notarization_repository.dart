import 'package:fairfare/features/corridors/data/notarization_repository.dart';

//sample receipt for tests and the fake data switch
class FakeNotarizationRepository implements NotarizationRepository {
  @override
  Future<Notarization?> latest() async {
    return const Notarization(
      date: '2026-11-21',
      hash: 'bf2c448ee241836c8569db29c0fabcd2048e028d289cfe9383204e0bee8edfa7',
      txHash:
          'be02b94f01a13c4441f2651d76e7d4a9d9536224786e00a8277108a0ce7c364b',
      network: 'preview',
    );
  }
}
