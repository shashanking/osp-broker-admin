class ApiUrls {
  static const String baseUrl = 'https://totowalla.in/api';
  // Prod url
  // static const String baseUrl = 'https://api.myprimenetwork.com/api';
  // local development
  // static const String baseUrl = 'http://localhost:3001/api';

  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refreshToken';
  static const String userProfile = '/auth/me';
  static const String auctionCategories = '/auction/category';
  static const String auctions = '/auction';

  // Shop
  static const String shopItems = '/shop/items';
  static const String shopCategories = '/shop/category';
}
