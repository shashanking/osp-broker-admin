class ApiUrls {
  // Staging/prod (live API).
  static const String baseUrl = 'https://totowalla.in/api';
  // LOCAL DEV: backend running on this machine (port 4000).
  // static const String baseUrl = 'http://localhost:4000/api';
  // static const String baseUrl = 'https://api.myprimenetwork.com/api';

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
