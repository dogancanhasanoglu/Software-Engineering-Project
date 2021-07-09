import 'package:flutter/material.dart';


class QuantityKeys {
  final GlobalKey quantityKey;
  QuantityKeys({
    @required this.quantityKey,


  }) ;

}



class textControllers {
  final TextEditingController controller;

  textControllers({
    @required this.controller,


  });
}


class DeliveryListModel {
  final String  deliveryStatus, address, date, customerName;
  final double total_cost;
  final int deliveryID, customerID;
  final List <DeliveryProductModel> products;


  DeliveryListModel({
    // @required this.text,
    @required this.address,
    @required this.deliveryStatus,
    @required this.total_cost,
    @required this.customerID,
    @required this.deliveryID,
    @required this.products,
    @required this.date,
    @required this.customerName,

  }) ;
}

class DeliveryProductModel {
  final String productName, image, status;
  final int productID, quantity;
  final double price;



  DeliveryProductModel({
    @required this.productName,
    @required this.status,
    @required this.image,
    @required this.productID,
    @required this.quantity,
    @required this.price,
  }) ;
}


class RefundListModel {
  final String  orderDate, status;
  final double cost;
  final int basketID, customerID,quantity,invoiceID;
  final List <ProductModel> products;


  RefundListModel({
    @required this.orderDate,
    @required this.status,
    @required this.cost,
    @required this.customerID,
    @required this.basketID,
    @required this.quantity,
    @required this.products,
    @required this.invoiceID,

  }) ;
}


class ProductModel {
  final String productName, image;
  final int productID;
  final double price;



  ProductModel({
    @required this.productName,
    @required this.image,
    @required this.productID,
    @required this.price,
  }) ;
}


class SalesMonth {
  final String month;
  final double sales;

  SalesMonth({this.month, this.sales});
}