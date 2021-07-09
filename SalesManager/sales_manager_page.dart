import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:shop_app/screens/ProductManager/InvoiceModels.dart';
import 'package:shop_app/screens/ProductManager/pdf_save.dart';
import 'package:shop_app/size_config.dart';
import 'dart:convert';

import 'model.dart';

class SalesManager extends StatefulWidget {
  static String routeName = "/salesmanager";

  @override
  _SalesManagerState createState() => _SalesManagerState();
}

class _SalesManagerState extends State<SalesManager>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin<SalesManager> {
  TabController _controller;
  TextEditingController txtController;
  int _selectedIndex = 0;
  List<DataRow> rows;

  List<DataRow> productRows;
  List<QuantityKeys> keys;

  List<textControllers> controllers;

  List<QuantityKeys> keys2;
  List<textControllers> controllers2;
  List<DeliveryListModel> demoDelivery;
  List<DeliveryProductModel> deliveryProducts;
  List<RefundListModel> demoRefund;
  List<ProductModel> refundProducts;
  var mapping;
  dynamic total_revenue=0;
  dynamic total_profit=0;
  dynamic total_invoices=0;

  bool delivery = false;
  bool chart = false;

  final List<SalesMonth> data = [];
  final List<SalesMonth> dataprofit = [];
  final List<SalesMonth> datapiechart = [];
  final List<SalesMonth> datavgrating = [];

  Future<void> showInvoices(String start, String end) async {
    print("show called");
    final url = Uri.parse('http://192.168.1.35:8000/e_commerce/viewrevenue');

    var body = {
      'start': start,
      'end': end,
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Map<String, dynamic> jsonMap = json.decode(response.body);
      int looplength = jsonMap['revenue'].length;
      print(looplength);
      print(jsonMap['revenue']);
      for (int i = 0; i < looplength; i++) {
        String monthString = "";
        if (jsonMap['months'][i] == 1) monthString = "January";
        if (jsonMap['months'][i] == 2) monthString = "February";
        if (jsonMap['months'][i] == 3) monthString = "March";
        if (jsonMap['months'][i] == 4) monthString = "April";
        if (jsonMap['months'][i] == 5) monthString = "May";
        if (jsonMap['months'][i] == 6) monthString = "June";
        if (jsonMap['months'][i] == 7) monthString = "July";
        if (jsonMap['months'][i] == 8) monthString = "August";
        if (jsonMap['months'][i] == 9) monthString = "September";
        if (jsonMap['months'][i] == 10) monthString = "October";
        if (jsonMap['months'][i] == 11) monthString = "November";
        if (jsonMap['months'][i] == 12) monthString = "December";
        print(monthString);
        print(jsonMap['profit'][i]);
        data.add(SalesMonth(month: monthString, sales: jsonMap['revenue'][i]));
        total_revenue+= jsonMap['revenue'][i];
        total_profit+= jsonMap['profit'][i];
        total_invoices += jsonMap['invoicecount'][i];
        dataprofit
            .add(SalesMonth(month: monthString, sales: jsonMap['profit'][i]));
        datapiechart.add(
            SalesMonth(month: monthString, sales: jsonMap['invoicecount'][i]));

      }
    }
    print(datapiechart);
    total_profit = num.parse(total_profit.toStringAsFixed(2));
    total_revenue = num.parse(total_revenue.toStringAsFixed(2));
    total_invoices = num.parse(total_invoices.toStringAsFixed(2));
    setState(() {});
  }

  Future<void> avgRating() async {
    final url =
    Uri.parse('http://192.168.1.35:8000/e_commerce/getproductchart');

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: {},
      encoding: Encoding.getByName("utf-8"),
    );
    List<Map<String, dynamic>> response_list = [];
    if (response.statusCode >= 200 && response.statusCode < 300) {
      print("burada");
      List<dynamic> jsonMap = json.decode(response.body);
      print("bi de burada");
      print(jsonMap);
      print(jsonMap.length);
      //response_list.add(jsonMap);
      //int looplength = jsonMap['productName'].length;
      //print(looplength);
      //response_list.add(jsonMap);
      for (int i = 0; i < jsonMap.length; i++) {
        //print(response_list[i]['productName']);
        print(jsonMap[i]["avgRating"]);
        double rating = double.parse(jsonMap[i]["avgRating"]);
        //print(rating);
        if (rating != 0) {
          datavgrating
              .add(SalesMonth(month: jsonMap[i]["productName"], sales: rating));
        }
      }
    }

    setState(() {});
  }

  Future<void> setPrice(String price, int productID) async {
    final url = Uri.parse('http://192.168.1.35:8000/e_commerce/setprice');

    var body = {"price": price.toString(), "productID": productID.toString()};

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      //Successful transmission
      print("successful");
    }
    setState(() {
      showProducts();
    });
  }

  Future<void> setDiscount(String discount, int productID) async {
    final url = Uri.parse('http://192.168.1.35:8000/e_commerce/setdiscount');

    var body = {
      "discount": discount.toString(),
      "productID": productID.toString()
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      //Successful transmission
      print("successful");
    }
    setState(() {
      showProducts();
    });
  }

  Future<void> approveRefund(
      int invoiceID, int productID, bool isApproved) async {
    final url = Uri.parse('http://192.168.1.35:8000/e_commerce/refundreview');

    var body = {
      "invoiceID": invoiceID.toString(),
      "productID": productID.toString(),
      "isApproved": isApproved.toString()
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );
    if (response.statusCode == 200) {
      //Successful transmission
      print("successful");
    }
    setState(() {
      showRefunds();
    });
  }

  Future<void> showProducts() async {
    productRows = [];
    keys = [];
    controllers = [];
    keys2 = [];
    controllers2 = [];
    mapping = {};
    final url =
    Uri.parse('http://192.168.1.35:8000/e_commerce/showallproducts');
    SharedPreferences AppState = await SharedPreferences.getInstance();
    if (!AppState.containsKey('managerID')) {
      AppState.setInt('managerID', 1);
    }
    print(AppState.getInt('managerID'));
    var body = {
      "managerID": '${AppState.getInt('managerID')}',
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );

    if (response.statusCode == 200) {
      //Successful transmission
      print("successful");
      int i = 0;
      for (var entry in json.decode(response.body)) {
        print(entry);

        controllers.add(textControllers(
            controller: TextEditingController(text: "${entry['price']}")));
        controllers2.add(textControllers(
            controller:
            TextEditingController(text: "${entry['discountPrice']}")));

        keys.add(QuantityKeys(quantityKey: GlobalKey()));
        keys2.add(QuantityKeys(quantityKey: GlobalKey()));
        mapping[entry["productName"]] = i;
        productRows.add(
          DataRow(
            cells: <DataCell>[
              DataCell(
                ListTile(
                  leading: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                      maxWidth: 64,
                      maxHeight: 64,
                    ),
                    child: Image.network(entry['image'], fit: BoxFit.cover),
                  ),
                  title: Text(
                    entry['productName'],
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'ID: ${entry["productID"]}\nSerial Number: ${entry["serialNo"]}',
                    style: TextStyle(color: Colors.white),
                  ),
                  //trailing: Icon(Icons.more_vert),
                  isThreeLine: true,
                ),
              ),
              DataCell(Text(entry['categoryName'],
                  style: TextStyle(color: Colors.white))),
              DataCell(
                Form(
                  key: keys[i].quantityKey,
                  child: Row(
                    children: [
                      Container(
                        width: 125,
                        height: 60,
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              BorderSide(color: Colors.blueGrey[800]),
                              gapPadding: 1,
                            ),
                          ),
                          controller: controllers[i].controller,
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        width: 100,
                        height: 50,
                        child: RawMaterialButton(
                            fillColor: Colors.green,
                            child: Text(
                              "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              int a = mapping[entry['productName']];
                              String val = controllers[a].controller.text;
                              setPrice(val, entry["productID"]);
                            }),
                      ),
                    ],
                  ),
                ),
              ),
              DataCell(
                Form(
                  key: keys2[i].quantityKey,
                  child: Row(
                    children: [
                      Container(
                        width: 125,
                        height: 60,
                        child: TextFormField(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                              BorderSide(color: Colors.blueGrey[800]),
                              gapPadding: 1,
                            ),
                          ),
                          controller: controllers2[i].controller,
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      SizedBox(width: 15),
                      Container(
                        width: 100,
                        height: 50,
                        child: RawMaterialButton(
                            fillColor: Colors.green,
                            child: Text(
                              "Apply",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              int a = mapping[entry['productName']];
                              String val = controllers2[a].controller.text;
                              setDiscount(val, entry["productID"]);
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
        i++;
      }
      setState(() {});
    } else
      print("something went wrong");
    setState(() {});
  }

  Future<void> showDeliveries(String start, String end) async {
    demoDelivery = [];
    deliveryProducts = [];
    final url =
    Uri.parse('http://192.168.1.35:8000/e_commerce/showdeliveriesrange');
    SharedPreferences AppState = await SharedPreferences.getInstance();
    if (!AppState.containsKey('managerID')) {
      AppState.setInt('managerID', 1);
    }
    print(AppState.getInt('managerID'));
    var body = {
      "managerID": '${AppState.getInt('managerID')}',
      "start": start,
      "end": end,
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );

    /* if(response.statusCode == 200) {
      //Successful transmission

      for (var entry in json.decode(response.body))
        print(entry);

    }
*/
    if (response.statusCode == 200) {
      //Successful transmission
      print("successful at getting deliveries");
      int i = 0;
      for (var entry in json.decode(response.body)) {
        //print(entry["product"]);
        deliveryProducts = [];
        for (var ent in entry["product"]) {
          double cost= num.parse(ent["cost"]) ;
          deliveryProducts.add(DeliveryProductModel(
            image: ent["image"] != ""
                ? ent["image"]
                : "https://static.zara.net/photos///2021/V/0/1/p/0962/152/615/2/w/1280/0962152615_2_2_1.jpg?ts=1619177784421",
            productID: ent["productID_id"],
            quantity: ent["quantity"],
            productName: ent["productName"],
            status: ent["status"],
            price: cost,
          ));
        }
        demoDelivery.add(
          DeliveryListModel(
              address: entry["address"],
              deliveryStatus: entry["deliveryStatus"],
              total_cost: num.parse(entry["total_cost"].toStringAsFixed(2)),
              customerID: entry["customerID"],
              deliveryID: entry["deliveryID"],
              date: DateFormat.yMd().format(DateTime.parse(entry["orderDate"])),
              customerName: entry["customerName"],
              products: deliveryProducts),
        );
      }
      print(demoDelivery.length);
    }

    setState(() {});
  }

  Future<void> showRefunds() async {
    demoRefund = [];
    refundProducts = [];
    final url = Uri.parse('http://192.168.1.35:8000/e_commerce/showallrefunds');
    SharedPreferences AppState = await SharedPreferences.getInstance();
    if (!AppState.containsKey('managerID')) {
      AppState.setInt('managerID', 1);
    }
    print(AppState.getInt('managerID'));
    var body = {
      "managerID": '${AppState.getInt('managerID')}',
    };

    final response = await http.post(
      Uri.http(url.authority, url.path),
      headers: <String, String>{
        "Accept": "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      },
      body: body,
      encoding: Encoding.getByName("utf-8"),
    );

    /* if(response.statusCode == 200) {
      //Successful transmission

      for (var entry in json.decode(response.body))
        print(entry);

    }
*/
    if (response.statusCode == 200) {
      //Successful transmission
      print("successful at getting deliveries");
      int i = 0;
      for (var entry in json.decode(response.body)) {
        //print(entry["product"]);
        refundProducts = [];
        for (var ent in entry["product"]) {
          refundProducts.add(ProductModel(
            image: ent["image"] != ""
                ? ent["image"]
                : "https://static.zara.net/photos///2021/V/0/1/p/0962/152/615/2/w/1280/0962152615_2_2_1.jpg?ts=1619177784421",
            productID: ent["productID"],
            price: ent["price"],
            productName: ent["productName"],
          ));
        }
        demoRefund.add(
          RefundListModel(
              invoiceID: entry["invoiceID"],
              orderDate: entry["orderDate"],
              status: entry["status"],
              cost: num.parse(entry["cost"].toStringAsFixed(2)),
              customerID: entry["customerID"],
              basketID: entry["basketID_id"],
              quantity: entry["quantity"],
              products: refundProducts),
        );
      }
      print(demoRefund.length);
    }

    setState(() {});
  }

  @override
  void initState() {
    print("init called");
    showProducts();
    // showDeliveries();
    showRefunds();
    // showInvoices(start,end);
    avgRating();
    // showRefunds();
    _controller = TabController(length: 4, vsync: this);

    _controller.addListener(() {
      setState(() {
        _selectedIndex = _controller.index;
      });
      print("Selected Index: " + _controller.index.toString());
    });

    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget ProductTable() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(100, 20, 100, 10),
      //center
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.blueGrey,
        ),
        child: productRows.length != 0
            ? DataTable(
          horizontalMargin: 10,
          // dataRowHeight : (MediaQuery.of(context).size.height - 56) / 2 ,
          dataRowHeight: 130,
          dataRowColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                if (states.contains(MaterialState.selected))
                  return Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.08);
                return null; // Use the default value.
              }),
          columns: const <DataColumn>[
            DataColumn(
              label: Text(
                'Product',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DataColumn(
              label: Text(
                'Category',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DataColumn(
              label: Text(
                'Price',
                style: TextStyle(color: Colors.white),
              ),
            ),
            DataColumn(
              label: Text(
                'Discount Price',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
          rows: productRows,
        )
            : Center(
          child: Container(
            height: 500,
            width: 500,

            child: CircularProgressIndicator(

              valueColor: AlwaysStoppedAnimation(Colors.blueAccent),
              strokeWidth: 8.0,
            ),
            alignment: Alignment.center,
            padding: EdgeInsets.only(top: 40.0),

          ),
        ),
      ),
    );
  }

  final _formKey = GlobalKey<FormState>();
  String start, end;

  Widget RangeTable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Please enter a date range:',
                style: TextStyle(fontSize: 40.0, color: Colors.white),
              ),
              SizedBox(height: 60),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 400,
                    height: 110,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a start date (yyyy-mm-dd)',
                        hintStyle:
                        TextStyle(fontSize: 20.0, color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSaved: (String value) {
                        start = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a start date";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 400,
                    height: 110,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a end date (yyyy-mm-dd)',
                        hintStyle:
                        TextStyle(fontSize: 20.0, color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSaved: (String value) {
                        end = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a end date";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              RawMaterialButton(
                  fillColor: Colors.teal,
                  constraints: BoxConstraints.tight(Size(300, 60)),
                  child: Text(
                    "Enter",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      _formKey.currentState.save();
                      showDeliveries(start, end);
                      delivery = true;
                      setState(() {});
                    }
                  }),
            ],
          ),
        ),
      ],
    );
  }

  final _formKey2 = GlobalKey<FormState>();
  String start2, end2;

  Widget ChartTable() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Form(
          key: _formKey2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Please enter a date range:',
                style: TextStyle(fontSize: 40.0, color: Colors.white),
              ),
              SizedBox(height: 60),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 400,
                    height: 110,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a start date (yyyy-mm-dd)',
                        hintStyle:
                        TextStyle(fontSize: 20.0, color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSaved: (String value) {
                        start2 = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a start date";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 400,
                    height: 110,
                    child: TextFormField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter a end date (yyyy-mm-dd)',
                        hintStyle:
                        TextStyle(fontSize: 20.0, color: Colors.white),
                      ),
                      style: TextStyle(color: Colors.white),
                      onSaved: (String value) {
                        end2 = value;
                      },
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Please enter a end date";
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              RawMaterialButton(
                  fillColor: Colors.teal,
                  constraints: BoxConstraints.tight(Size(300, 60)),
                  child: Text(
                    "Enter",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    if (_formKey2.currentState.validate()) {
                      _formKey2.currentState.save();
                      showInvoices(start2, end2);
                      chart = true;
                      setState(() {});
                    }
                  }),
            ],
          ),
        ),
      ],
    );
  }

  Widget DeliveryTable() {
    return Padding(
      padding: EdgeInsets.fromLTRB(60, 30, 60, 5),
      child: ListView.builder(
        // outer ListView
        itemCount: demoDelivery.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              index != 0
                  ? Divider(
                color: Colors.white, //Colors.grey[50],
                thickness: 0.8,
                height: 20,
              )
                  : Container(
                //color: Colors.grey[850],
                color: Colors.grey[700], //Color(0xFF343333),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      'Products',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      height: 50,
                      width: 190,
                    ),
                    Text(
                      'Total Price',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 1,
                    ),
                    Text(
                      'Customer ID',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Delivery ID',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 25,
                    ),
                    Text(
                      'Status',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 32,
                    ),
                    Text(
                      'Delivery Address',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 50,
                    ),
                    Text(
                      'Invoice PDF',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: index == 0 ? 10 : 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 13,
                    child: ListView.builder(
                      // inner ListView
                      shrinkWrap: true, // 1st add
                      physics: ClampingScrollPhysics(), // 2nd add
                      itemCount: demoDelivery[index].products.length,
                      itemBuilder: (context, i) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.grey[800],
                              child: ListTile(
                                leading: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: 64,
                                    minHeight: 64,
                                    maxWidth: 84,
                                    maxHeight: 84,
                                  ),
                                  child: Image.network(
                                      demoDelivery[index].products[i].image,
                                      fit: BoxFit.cover),
                                ),
                                title: Text(
                                  demoDelivery[index].products[i].productName,
                                  style: TextStyle(color: Colors.white),
                                ),
                                subtitle: demoDelivery[index]
                                    .products[i]
                                    .status !=
                                    "Refunded"
                                    ? Text(
                                    'ID: ${demoDelivery[index].products[i].productID}\nQuantity: ${demoDelivery[index].products[i].quantity}',
                                    style: TextStyle(color: Colors.white))
                                    : Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text:
                                        'ID: ${demoDelivery[index].products[i].productID}   ',
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                      TextSpan(
                                        text: ' Refunded',
                                        style: TextStyle(
                                          color: Colors.white,
                                          backgroundColor:
                                          Colors.red[900],
                                          //fontSize: 20,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '.',
                                        style: TextStyle(
                                          color: Colors.red[900],
                                          backgroundColor:
                                          Colors.red[900],
                                          //fontSize: 20,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                        '\nQuantity: ${demoDelivery[index].products[i].quantity}',
                                        style: TextStyle(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),

                                //trailing: Icon(Icons.more_vert),
                                isThreeLine: true,
                              ),
                            ),
                          ),
                        ],
                      ), //ListTile(title: Text('Item $index')),
                    ),
                  ),
                  SizedBox(
                    width: 29,
                  ), //Text("hi there"),
                  Expanded(
                      flex: 6,
                      child: Text("${demoDelivery[index].total_cost} TL",
                          style: TextStyle(color: Colors.white))),
                  Expanded(
                    flex: 6,
                    child: Text("${demoDelivery[index].customerID}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoDelivery[index].deliveryID}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          demoDelivery[index].deliveryStatus == "Processing" ?  TextSpan(children: [
                            TextSpan(
                              text: ' Processing',
                              style: TextStyle(
                                color: Colors.white,
                                backgroundColor:
                                Color(0xFF613525),
                                //fontSize: 20,
                              ), ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: Color(0xFF613525),
                                backgroundColor:
                                Color(0xFF613525),
                                //fontSize: 20,
                              ), ) ]
                          ): demoDelivery[index].deliveryStatus == "In-transit" ?  TextSpan(children: [
                            TextSpan(
                              text: ' In-transit',
                              style: TextStyle(
                                color: Colors.white,
                                backgroundColor:
                                Colors.teal,
                                //fontSize: 20,
                              ), ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: Colors.teal,
                                backgroundColor:
                                Colors.teal,
                                //fontSize: 20,
                              ), ) ]
                          ): demoDelivery[index].deliveryStatus == "Delivered" ?  TextSpan(children: [
                            TextSpan(
                              text: ' Delivered',
                              style: TextStyle(
                                color: Colors.white,
                                backgroundColor:
                                Colors.green[800],
                                //fontSize: 20,
                              ), ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color:  Colors.green[800],
                                backgroundColor:
                                Colors.green[800],
                                //fontSize: 20,
                              ), ) ]
                          ): demoDelivery[index].deliveryStatus == "Cancelled" ?  TextSpan(children: [
                            TextSpan(
                              text: ' Cancelled',
                              style: TextStyle(
                                color: Colors.white,
                                backgroundColor:
                                Color(0xff580606),
                                //fontSize: 20,
                              ), ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: Color(0xff580606),
                                backgroundColor:
                                Color(0xff580606),
                                //fontSize: 20,
                              ), ) ]
                          ): Container(),



                        ],
                      ),
                    ),
                  ),

                  Expanded(
                    flex: 6,
                    child: Container(
                      width: 90,
                      child: Text("${demoDelivery[index].address}",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                  ),
                  // Expanded(
                  //   flex: 1,
                  //  child: SizedBox(
                  //    width: 50,
                  Column(
                    children: [
                      Container(
                        width: 95,
                        child: RawMaterialButton(
                            fillColor: Colors.amber.shade900,
                            child: Text(
                              "View Invoice",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              final date = demoDelivery[index].date;
                              // final dueDate = DateTime.now().add(Duration(days: 7));

                              List<InvoiceItem> demoItems = [];
                              for(int i=0; i<demoDelivery[index].products.length; i++)
                              {
                                demoItems.add(InvoiceItem(
                                  description: demoDelivery[index].products[i].productName ,
                                  quantity: demoDelivery[index].products[i].quantity,
                                  vat: 0.19,
                                  unitPrice: demoDelivery[index].products[i].price,
                                ),

                                );
                              }

                              final invoice = Invoice(
                                customer: Customer(
                                  name: demoDelivery[index].customerName,
                                  address: demoDelivery[index].address,
                                ),
                                info: InvoiceInfo(
                                  date: date,
                                  description: 'Details of your order dated ' + demoDelivery[index].date + ":",
                                  number: '${demoDelivery[index].deliveryID}',
                                ),

                                items: demoItems,
                              );

                              final pdfFile =  PdfApi.openFile(invoice); //PdfInvoiceApi.generate(invoice);
                            }),
                      ),
                      Container(
                          width: 95,
                          child: RawMaterialButton(
                            fillColor: Colors.blueAccent,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Download",
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width:1),
                                Icon(Icons.download_rounded, size: 17,),
                              ],
                            ),
                            onPressed: () {
                              final date = demoDelivery[index].date;
                              // final dueDate = DateTime.now().add(Duration(days: 7));

                              List<InvoiceItem> demoItems = [];
                              for(int i=0; i<demoDelivery[index].products.length; i++)
                              {
                                demoItems.add(InvoiceItem(
                                  description: demoDelivery[index].products[i].productName ,
                                  quantity: demoDelivery[index].products[i].quantity,
                                  vat: 0.19,
                                  unitPrice: demoDelivery[index].products[i].price,
                                ),

                                );
                              }

                              final invoice = Invoice(
                                customer: Customer(
                                  name: demoDelivery[index].customerName,
                                  address: demoDelivery[index].address,
                                ),
                                info: InvoiceInfo(
                                  date: date,
                                  description: 'Details of your order dated ' + demoDelivery[index].date + ":",
                                  number: '${demoDelivery[index].deliveryID}',
                                ),

                                items: demoItems,

                              );
                              PdfApi.saveDocument(invoice);
                            },
                          )
                      ),
                    ],
                  ),
                  //   ),
                  //   ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget RefundTable() {
    return Padding(
      padding: EdgeInsets.fromLTRB(60, 30, 60, 5),
      child: ListView.builder(
        // outer ListView
        itemCount: demoRefund.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              index != 0
                  ? Divider(
                color: Colors.white, //Colors.grey[50],
                thickness: 0.8,
                height: 20,
              )
                  : Container(
                //color: Colors.grey[850],
                color: Colors.grey[700], //Color(0xFF343333),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: <Widget>[
                    Text(
                      'Products',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      height: 50,
                      width: 190,
                    ),
                    Text(
                      'Total Price',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 1,
                    ),
                    Text(
                      'Customer ID',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Basket ID',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Quantity',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Status',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      'Order Date',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 50,
                    ),
                    Text(
                      'Action',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: index == 0 ? 10 : 0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    flex: 13,
                    child: ListView.builder(
                      // inner ListView
                      shrinkWrap: true, // 1st add
                      physics: ClampingScrollPhysics(), // 2nd add
                      itemCount: demoRefund[index].products.length,
                      itemBuilder: (context, i) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Card(
                              color: Colors.grey[800],
                              child: ListTile(
                                  leading: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: 64,
                                      minHeight: 64,
                                      maxWidth: 84,
                                      maxHeight: 84,
                                    ),
                                    child: Image.network(
                                        demoRefund[index].products[i].image,
                                        fit: BoxFit.cover),
                                  ),
                                  title: Text(
                                    demoRefund[index].products[i].productName,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                      'ID: ${demoRefund[index].products[i].productID}',
                                      style: TextStyle(color: Colors.white))),

                              //trailing: Icon(Icons.more_vert),
                            ),
                          ),
                        ],
                      ), //ListTile(title: Text('Item $index')),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                  ), //Text("hi there"),
                  Expanded(
                      flex: 6,
                      child: Text("${demoRefund[index].cost} TL",
                          style: TextStyle(color: Colors.white))),
                  SizedBox(
                    width: 100,
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoRefund[index].customerID}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoRefund[index].basketID}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    width: 50,
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoRefund[index].quantity}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    width: 40,
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoRefund[index].status}",
                        style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(
                    width: 40,
                  ),
                  Expanded(
                    flex: 6,
                    child: Text("${demoRefund[index].orderDate}",
                        style: TextStyle(color: Colors.white)),
                  ),

                  SizedBox(
                    width: 70,
                  ),
                  // Expanded(
                  //   flex: 1,
                  //  child: SizedBox(
                  //    width: 50,
                  Container(
                    width: 95,
                    child: Column(
                      children: [
                        RawMaterialButton(
                            fillColor: Colors.green,
                            elevation: 6.0,
                            child: Text(
                              "Accept",
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () {
                              approveRefund(
                                  demoRefund[index].invoiceID,
                                  demoRefund[index].products[0].productID,
                                  true);
                            }),
                        RawMaterialButton(
                            fillColor: Colors.red,
                            elevation: 6.0,
                            child: Text("Decline",
                                style: TextStyle(color: Colors.white)),
                            onPressed: () {
                              approveRefund(
                                  demoRefund[index].invoiceID,
                                  demoRefund[index].products[0].productID,
                                  false);
                            }),
                      ],
                    ),
                  ),
                  //   ),
                  //   ),
                ],
              )
            ],
          );
        },
      ),
    );
  }

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade900,
        appBar: AppBar(
          backgroundColor: Colors.grey.shade900,
          bottom: TabBar(
            controller: _controller,
            labelPadding: EdgeInsets.symmetric(horizontal: 100.0),
            isScrollable: true,
            tabs: [
              Tab(text: "Set Price & Discount"),
              Tab(text: "View Refunds"),
              Tab(text: "Invoice Query"),
              Tab(text: "View Chart")
            ],
          ),
          title: Text('Sales Manager', style: TextStyle(color: Colors.white)),
          centerTitle: true,
        ),
        body: TabBarView(
          controller: _controller,
          children: [
            ProductTable(),
            RefundTable(),
            delivery ? DeliveryTable() : RangeTable(),
            chart
                ? Container(
                height: 750,
                width: 1536,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Column(

                      children: [

                        SizedBox(height:43,
                        ),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children :[

                              Text (
                                "Total Revenue: $total_revenue",
                                style:
                                TextStyle(
                                  color : Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                              SizedBox(width:20.0),
                              Text (
                                "Total Profit: $total_profit",
                                style:
                                TextStyle(
                                  color : Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                            ]

                        ),

                        SalesChart(
                          data: data,
                          dataprofit: dataprofit,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Column(

                      children: [

                        SizedBox(height:43,
                        ),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children :[

                              Text (
                                "Total Invoice Count: $total_invoices",
                                style:
                                TextStyle(
                                  color : Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),


                            ]

                        ),

                        PieChartInvoices(datapiechart: datapiechart),
                      ],
                    ),

                    SizedBox(
                      height: 5,
                    ),
                    Column(

                      children: [

                        SizedBox(height:43,
                        ),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children :[

                              Text (
                                "Rating Range: ",
                                style:
                                TextStyle(
                                  color : Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),
                              Icon(Icons.star_border_purple500_outlined,
                                color: Colors.white,),

                              Text (
                                " 0 - 5",
                                style:
                                TextStyle(
                                  color : Colors.white,
                                  fontSize: 20.0,
                                ),
                              ),


                            ]

                        ),

                        LineChartRating(datavgrating: datavgrating),
                      ],
                    ),
                  ],
                ))
                : ChartTable(),
          ],
        ),
      ),
    );
  }
}

class SalesChart extends StatelessWidget {
  final List<SalesMonth> data;
  final List<SalesMonth> dataprofit;

  SalesChart({this.data, this.dataprofit});

  @override
  Widget build(BuildContext context) {
    print(SizeConfig.screenWidth);
    print(SizeConfig.screenHeight);
    List<charts.Series<SalesMonth, String>> series = [
      charts.Series(
          id: "Revenue",
          data: data,
          domainFn: (SalesMonth sales, _) => sales.month,
          measureFn: (SalesMonth sales, _) => sales.sales,
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault),
      charts.Series(
          id: "Profit",
          data: dataprofit,
          domainFn: (SalesMonth sales, _) => sales.month,
          measureFn: (SalesMonth sales, _) => sales.sales,
          colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault),
    ];
    return Container(
        padding: EdgeInsets.all(15.0),
        margin: EdgeInsets.all(10.0),
        color: Colors.white,
        height: 500,
        width: 450,
        child: Column(children: [
          Text("Revenue-Profit per Month"),
          Expanded(
              child: charts.OrdinalComboChart(
                series,
                behaviors: [new charts.SeriesLegend()],
                animate: true,
                //defaultRenderer: new charts.BarRendererConfig(
                //groupingType: charts.BarGroupingType.grouped),
                //customSeriesRenderers: [ new charts.LineRendererConfig(customRendererId: 'customLine'),]
              )),
        ]));
  }
}

class SalesMonth {
  final String month;
  final double sales;

  SalesMonth({this.month, this.sales});
}

class PieChartInvoices extends StatelessWidget {
  final List<SalesMonth> datapiechart;

  PieChartInvoices({this.datapiechart});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<SalesMonth, String>> series = [
      charts.Series(
        id: "Revenue",
        data: datapiechart,
        domainFn: (SalesMonth sales, _) => sales.month,
        measureFn: (SalesMonth sales, _) => sales.sales,
      )

      //colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault)
    ];
    return Container(
        padding: EdgeInsets.all(15.0),
        margin: EdgeInsets.all(10.0),
        color: Colors.white,
        height: 500,
        width: 450,
        child: Column(children: [
          Text("Number of Invoices per Month"),
          Expanded(
              child: charts.PieChart(
                series,
                behaviors: [new charts.DatumLegend()],
                defaultRenderer: new charts.ArcRendererConfig(
                    arcWidth: 250,
                    arcRendererDecorators: [
                      // <-- add this to the code
                      charts.ArcLabelDecorator() // <-- and this of course
                    ]),
                //defaultRenderer: new charts.ArcRendererConfig(arcRendererDecorators: [
                //new charts.ArcLabelDecorator(
                //labelPosition: charts.ArcLabelPosition.outside)]),
                animate: true,
                //defaultRenderer: new charts.BarRendererConfig(
                //groupingType: charts.BarGroupingType.grouped),
                //customSeriesRenderers: [ new charts.LineRendererConfig(customRendererId: 'customLine'),]
              )),
        ]));
  }
}

class LineChartRating extends StatelessWidget {
  final List<SalesMonth> datavgrating;

  LineChartRating({this.datavgrating});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<SalesMonth, String>> series = [
      charts.Series(
        id: "Rating",
        data: datavgrating,
        domainFn: (SalesMonth sales, _) => sales.month,
        measureFn: (SalesMonth sales, _) => sales.sales,
      ),
    ];
    return Container(
        padding: EdgeInsets.all(15.0),
        margin: EdgeInsets.all(10.0),
        color: Colors.white,
        height: 500,
        width: 450,
        child: Column(children: [
          Text("Average Ratings per Product"),
          Expanded(
              child: charts.BarChart(
                series,

                domainAxis: new charts.OrdinalAxisSpec(
                    renderSpec: new charts.SmallTickRendererSpec(
                        minimumPaddingBetweenLabelsPx: 0,
                        // Tick and Label styling here.
                        labelRotation: 50,
                        labelStyle: new charts.TextStyleSpec(
                            fontSize: 8, // size in Pts.
                            color: charts.MaterialPalette.black),

                        // Change the line colors to match text color.
                        lineStyle: new charts.LineStyleSpec(
                            color: charts.MaterialPalette.black))),

                //behaviors: [new charts.DatumLegend()],
                //defaultRenderer: new charts.ArcRendererConfig(arcRendererDecorators: [
                //new charts.ArcLabelDecorator(
                //labelPosition: charts.ArcLabelPosition.outside)]),
                animate: true,
                //defaultRenderer: new charts.BarRendererConfig(
                //groupingType: charts.BarGroupingType.grouped),
                //customSeriesRenderers: [ new charts.LineRendererConfig(customRendererId: 'customLine'),]
              )),
        ]));
  }
}
