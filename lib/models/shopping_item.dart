class ShoppingItem {
  final String name;
  final String category;
  final String amount;
  final bool owned;
  final bool purchased;

  const ShoppingItem({
    required this.name,
    this.category = 'Pantry',
    this.amount = '',
    this.owned = false,
    this.purchased = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'amount': amount,
        'owned': owned,
        'purchased': purchased,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Pantry',
      amount: json['amount'] as String? ?? '',
      owned: json['owned'] as bool? ?? false,
      purchased: json['purchased'] as bool? ?? false,
    );
  }

  ShoppingItem copyWith({bool? purchased}) {
    return ShoppingItem(
      name: name,
      category: category,
      amount: amount,
      owned: owned,
      purchased: purchased ?? this.purchased,
    );
  }
}
