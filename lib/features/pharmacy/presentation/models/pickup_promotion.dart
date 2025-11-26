/// Model for pickup-exclusive promotions
class PickupPromotion {
  final String id;
  final String title;
  final String description;
  final double discountPercentage;
  final double? fixedDiscountAmount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? promoCode;
  final int? minimumOrderAmount;

  PickupPromotion({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercentage,
    this.fixedDiscountAmount,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.promoCode,
    this.minimumOrderAmount,
  });

  bool isValidForOrder(double orderAmount) {
    if (!isActive) return false;
    final now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;
    if (minimumOrderAmount != null && orderAmount < minimumOrderAmount!) {
      return false;
    }
    return true;
  }

  double calculateDiscount(double orderAmount) {
    if (!isValidForOrder(orderAmount)) return 0.0;

    if (fixedDiscountAmount != null) {
      return fixedDiscountAmount!;
    }

    return orderAmount * (discountPercentage / 100);
  }
}
