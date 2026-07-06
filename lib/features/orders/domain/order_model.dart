/// One row from GET /payment/admin/orders — a payment receipt enriched with the
/// buyer and the purchased item.
class OrderModel {
  final String id;
  final String type; // MEMBERSHIP | KUDO_COIN | PIN | BADGE | SHOP_ITEM | UNKNOWN
  final String itemLabel;
  final String? buyerId;
  final String? buyerName;
  final String? buyerEmail;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final DateTime? createdAt;

  const OrderModel({
    required this.id,
    required this.type,
    required this.itemLabel,
    this.buyerId,
    this.buyerName,
    this.buyerEmail,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: (j['id'] ?? '').toString(),
        type: (j['type'] ?? 'UNKNOWN').toString(),
        itemLabel: (j['itemLabel'] ?? '').toString(),
        buyerId: j['buyerId']?.toString(),
        buyerName: j['buyerName']?.toString(),
        buyerEmail: j['buyerEmail']?.toString(),
        amount: j['amount'] == null ? 0 : (j['amount'] as num).toDouble(),
        currency: (j['currency'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        paymentMethod: (j['paymentMethod'] ?? '').toString(),
        transactionId: (j['transactionId'] ?? '').toString(),
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'].toString())
            : null,
      );

  String get typeLabel {
    switch (type) {
      case 'MEMBERSHIP':
        return 'Membership';
      case 'KUDO_COIN':
        return 'Kudo Coins';
      case 'PIN':
        return 'Pin';
      case 'BADGE':
        return 'Badge';
      case 'SHOP_ITEM':
        return 'Shop Item';
      default:
        return 'Other';
    }
  }
}
