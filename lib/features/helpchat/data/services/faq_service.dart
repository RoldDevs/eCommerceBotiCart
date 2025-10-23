class FAQItem {
  final String question;
  final String answer;
  final List<String> keywords;
  final String category;

  FAQItem({
    required this.question,
    required this.answer,
    required this.keywords,
    required this.category,
  });
}

class FAQService {
  static final List<FAQItem> _faqs = [
    // App General
    FAQItem(
      question: "What is BotiCart?",
      answer: "BotiCart is your trusted online pharmacy platform that connects you with verified pharmacies. You can browse medicines, place orders, chat with pharmacists, and get your medications delivered to your doorstep.",
      keywords: ["what", "boticart", "app", "about", "platform"],
      category: "General",
    ),
    
    // Ordering
    FAQItem(
      question: "How do I place an order?",
      answer: "To place an order:\n1. Browse or search for medicines\n2. Select the medicine and quantity\n3. Add to cart or buy now\n4. Provide delivery details\n5. Complete payment\n6. Track your order status",
      keywords: ["order", "place", "buy", "purchase", "how"],
      category: "Ordering",
    ),
    
    FAQItem(
      question: "Can I order prescription medicines?",
      answer: "Yes! You can order prescription medicines by uploading a valid prescription from your doctor. Go to your account settings to upload prescription documents. Our pharmacists will verify before processing your order.",
      keywords: ["prescription", "medicine", "upload", "doctor", "verify"],
      category: "Ordering",
    ),
    
    FAQItem(
      question: "What payment methods do you accept?",
      answer: "We accept various payment methods including credit/debit cards, digital wallets, and cash on delivery (where available). Payment options will be shown during checkout.",
      keywords: ["payment", "pay", "method", "card", "cash", "wallet"],
      category: "Payment",
    ),
    
    // Delivery
    FAQItem(
      question: "How long does delivery take?",
      answer: "Delivery time depends on your location and the pharmacy. Typically:\n• Same-day delivery: 2-4 hours\n• Standard delivery: 1-2 days\n• Express delivery: 30-60 minutes (in select areas)",
      keywords: ["delivery", "time", "how long", "fast", "quick"],
      category: "Delivery",
    ),
    
    FAQItem(
      question: "What are the delivery charges?",
      answer: "Delivery charges vary based on distance and delivery speed. The exact fee will be calculated and shown during checkout before you confirm your order.",
      keywords: ["delivery", "charge", "fee", "cost", "price"],
      category: "Delivery",
    ),
    
    FAQItem(
      question: "Can I track my order?",
      answer: "Yes! You can track your order in real-time. Go to 'Orders' section in the app to see your order status, estimated delivery time, and delivery person details.",
      keywords: ["track", "order", "status", "where", "delivery"],
      category: "Tracking",
    ),
    
    // Account
    FAQItem(
      question: "How do I create an account?",
      answer: "You can create an account by:\n1. Downloading the BotiCart app\n2. Tap 'Sign Up'\n3. Enter your details (name, email, phone)\n4. Verify your phone number\n5. Start shopping!",
      keywords: ["account", "create", "sign up", "register", "new"],
      category: "Account",
    ),
    
    FAQItem(
      question: "I forgot my password",
      answer: "To reset your password:\n1. Go to login screen\n2. Tap 'Forgot Password'\n3. Enter your registered email\n4. Check your email for reset link\n5. Create a new password",
      keywords: ["password", "forgot", "reset", "login", "access"],
      category: "Account",
    ),
    
    // Pharmacy
    FAQItem(
      question: "How do I chat with a pharmacy?",
      answer: "To chat with a pharmacy:\n1. Go to 'Messages' tab\n2. Select a pharmacy or start a new conversation\n3. Type your message and send\n4. The pharmacy will respond to your queries",
      keywords: ["chat", "pharmacy", "message", "talk", "contact"],
      category: "Communication",
    ),
    
    FAQItem(
      question: "Are the pharmacies verified?",
      answer: "Yes! All pharmacies on BotiCart are verified and licensed. We ensure they meet quality standards and have proper certifications to sell medicines safely.",
      keywords: ["pharmacy", "verified", "licensed", "safe", "trusted"],
      category: "Safety",
    ),
    
    // Cart & Wishlist
    FAQItem(
      question: "How do I add items to cart?",
      answer: "To add items to cart:\n1. Find the medicine you want\n2. Tap on it to view details\n3. Select quantity\n4. Tap 'Add to Cart'\n5. Continue shopping or proceed to checkout",
      keywords: ["cart", "add", "item", "medicine", "shopping"],
      category: "Shopping",
    ),
    
    FAQItem(
      question: "Can I save items for later?",
      answer: "Yes! You can save medicines to your favorites by tapping the heart icon on any medicine. Access your saved items from your account section.",
      keywords: ["save", "favorite", "wishlist", "later", "heart"],
      category: "Shopping",
    ),
    
    // Technical Issues
    FAQItem(
      question: "The app is not working properly",
      answer: "If you're experiencing technical issues:\n1. Close and restart the app\n2. Check your internet connection\n3. Update to the latest app version\n4. Clear app cache\n5. Contact support if problem persists",
      keywords: ["app", "not working", "problem", "issue", "bug", "crash"],
      category: "Technical",
    ),
    
    FAQItem(
      question: "How do I update the app?",
      answer: "To update BotiCart:\n• Android: Go to Google Play Store, search 'BotiCart', tap 'Update'\n• iOS: Go to App Store, search 'BotiCart', tap 'Update'\nEnable auto-updates for the latest features!",
      keywords: ["update", "version", "new", "latest", "upgrade"],
      category: "Technical",
    ),
    
    // Support
    FAQItem(
      question: "How can I contact customer support?",
      answer: "You can reach our customer support:\n• Through this help chat\n• Email: support@boticart.com\n• Phone: Available in app settings\n• We're here 24/7 to help you!",
      keywords: ["support", "contact", "help", "customer service", "phone"],
      category: "Support",
    ),
    
    FAQItem(
      question: "Can I cancel my order?",
      answer: "You can cancel your order if it hasn't been prepared yet. Go to 'Orders' section, find your order, and tap 'Cancel Order'. If already prepared, contact the pharmacy directly.",
      keywords: ["cancel", "order", "stop", "refund", "return"],
      category: "Orders",
    ),
    
    // Medicine Information
    FAQItem(
      question: "How do I search for medicines?",
      answer: "To search for medicines:\n1. Use the search bar on home screen\n2. Type medicine name or condition\n3. Use filters to narrow results\n4. Browse by categories (Generic, Branded, OTC, etc.)",
      keywords: ["search", "find", "medicine", "drug", "medication"],
      category: "Search",
    ),
    
    FAQItem(
      question: "What's the difference between generic and branded medicines?",
      answer: "Generic medicines contain the same active ingredients as branded ones but are usually more affordable. Branded medicines are original formulations by pharmaceutical companies. Both are equally effective when prescribed properly.",
      keywords: ["generic", "branded", "difference", "medicine", "same"],
      category: "Medicine Info",
    ),
  ];

  static String? findAnswer(String userMessage) {
    final message = userMessage.toLowerCase().trim();
    
    // Direct keyword matching with scoring
    Map<FAQItem, int> scores = {};
    
    for (final faq in _faqs) {
      int score = 0;
      
      // Check for keyword matches
      for (final keyword in faq.keywords) {
        if (message.contains(keyword.toLowerCase())) {
          score += 2;
        }
      }
      
      // Check for partial matches in question
      final questionWords = faq.question.toLowerCase().split(' ');
      for (final word in questionWords) {
        if (word.length > 3 && message.contains(word)) {
          score += 1;
        }
      }
      
      if (score > 0) {
        scores[faq] = score;
      }
    }
    
    if (scores.isNotEmpty) {
      // Return the FAQ with highest score
      final bestMatch = scores.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (bestMatch.value >= 2) { // Minimum threshold
        return bestMatch.key.answer;
      }
    }
    
    // Fallback responses for common greetings
    if (_isGreeting(message)) {
      return "Hello! 👋 Welcome to BotiCart support. I'm here to help you with any questions about our pharmacy app. You can ask me about:\n\n• Placing orders\n• Delivery information\n• Account issues\n• Medicine searches\n• Payment methods\n• And much more!\n\nWhat would you like to know?";
    }
    
    if (_isThankYou(message)) {
      return "You're welcome! 😊 Is there anything else I can help you with regarding BotiCart?";
    }
    
    // Default response when no match found
    return "I'd be happy to help you! Here are some common topics I can assist with:\n\n🛒 **Ordering**: How to place orders, prescription medicines\n🚚 **Delivery**: Delivery times, charges, tracking\n💳 **Payment**: Payment methods and issues\n👤 **Account**: Creating account, password reset\n💬 **Chat**: How to contact pharmacies\n🔍 **Search**: Finding medicines and information\n\nPlease ask me about any of these topics, or describe your specific question and I'll do my best to help!";
  }
  
  static bool _isGreeting(String message) {
    final greetings = ['hello', 'hi', 'hey', 'good morning', 'good afternoon', 'good evening', 'help'];
    return greetings.any((greeting) => message.contains(greeting));
  }
  
  static bool _isThankYou(String message) {
    final thanks = ['thank', 'thanks', 'thank you', 'ty'];
    return thanks.any((thank) => message.contains(thank));
  }
  
  static List<FAQItem> getAllFAQs() => _faqs;
  
  static List<FAQItem> getFAQsByCategory(String category) {
    return _faqs.where((faq) => faq.category == category).toList();
  }
  
  static List<String> getCategories() {
    return _faqs.map((faq) => faq.category).toSet().toList();
  }
}