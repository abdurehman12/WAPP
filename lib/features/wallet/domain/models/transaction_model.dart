class TransactionModel {
  int? limit;
  int? offset;
  double? totalWalletBalance;
  int? totalWalletTransactio;
  List<WalletTransactioList>? walletTransactioList;

  TransactionModel({this.limit,
        this.offset,
        this.totalWalletBalance,
        this.totalWalletTransactio,
        this.walletTransactioList});



  TransactionModel.fromJson(Map<String, dynamic> json) {
    limit = json['limit'];
    offset = json['offset'];
    if(json['total_wallet_balance'] != null){
      totalWalletBalance = json['total_wallet_balance'].toDouble( );
    }else{
      totalWalletBalance = 0.0;
    }

    totalWalletTransactio = json['total_wallet_transactio'];
    if (json['wallet_transactio_list'] != null) {
      walletTransactioList = <WalletTransactioList>[];
      json['wallet_transactio_list'].forEach((v) {
        walletTransactioList!.add(WalletTransactioList.fromJson(v));
      });
    }
  }

}

class WalletTransactioList {
  int? _id;
  int? _userId;
  String? _transactionId;
  double? _credit;
  double? _debit;
  double? _adminBonus;
  double? _balance;
  String? _transactionType;
  String? _reference;
  String? _createdAt;
  String? _updatedAt;
  String? paymentMethod;

  WalletTransactioList(
      {int? id,
        int? userId,
        String? transactionId,
        double? credit,
        double? debit,
        double? adminBonus,
        double? balance,
        String? transactionType,
        String? reference,
        String? createdAt,
        String? updatedAt,
        String? paymentMethod
      }) {
    if (id != null) {
      _id = id;
    }
    if (userId != null) {
      _userId = userId;
    }
    if (transactionId != null) {
      _transactionId = transactionId;
    }
    if (credit != null) {
      _credit = credit;
    }
    if (debit != null) {
      _debit = debit;
    }
    if (adminBonus != null) {
      _adminBonus = adminBonus;
    }
    if (balance != null) {
      _balance = balance;
    }
    if (transactionType != null) {
      _transactionType = transactionType;
    }
    if (reference != null) {
      _reference = reference;
    }
    if (createdAt != null) {
      _createdAt = createdAt;
    }
    if (updatedAt != null) {
      _updatedAt = updatedAt;
    }
    this.paymentMethod;
  }

  int? get id => _id;
  int? get userId => _userId;
  String? get transactionId => _transactionId;
  double? get credit => _credit;
  double? get debit => _debit;
  double? get adminBonus => _adminBonus;
  double? get balance => _balance;
  String? get transactionType => _transactionType;
  String? get reference => _reference;
  String? get createdAt => _createdAt;
  String? get updatedAt => _updatedAt;

  WalletTransactioList.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
    _userId = json['user_id'];
    _transactionId = json['transaction_id'];
    _credit = json['credit'].toDouble();
    _debit = json['debit'].toDouble();
    _adminBonus = json['admin_bonus'].toDouble();
    _balance = json['balance'].toDouble();
    _transactionType = json['transaction_type'];
    _reference = json['reference'];
    _createdAt = json['created_at'];
    _updatedAt = json['updated_at'];
    paymentMethod = json['payment_method'];
  }

}
