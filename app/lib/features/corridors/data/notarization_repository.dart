//one receipt from the server notary, and the reader that gets the latest one

class Notarization {
  const Notarization({
    required this.date,
    required this.hash,
    required this.txHash,
    required this.network,
  });

  final String date;
  final String hash;
  final String txHash;
  final String network;

  //the public page of the transaction, like preview.cardanoscan.io
  String get explorerUrl {
    return 'https://$network.cardanoscan.io/transaction/$txHash';
  }
}

abstract class NotarizationRepository {
  //the newest receipt, or null if nothing was sent yet
  Future<Notarization?> latest();
}
