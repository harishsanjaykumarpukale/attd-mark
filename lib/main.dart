import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:barcode_scan/barcode_scan.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:giffy_dialog/giffy_dialog.dart';
import 'package:http/http.dart';

void main() {
  runApp(MaterialApp(
    title: 'scanner',
    home: Scanner(),
  ));
}

class Scanner extends StatefulWidget {
  @override
  _ScannerState createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  String result1 = '';
  String result = '';
  ScanResult qrResult;

  Future _qrScan() async {
    try {
      qrResult = await BarcodeScanner.scan();
      result1 = '';
      result = '';
      // scanned(context);
      _add();
    } on PlatformException catch (e) {
      if (e.code == BarcodeScanner.cameraAccessDenied) {
        result = 'Camera permission Denied';
      } else {
        setState(() {
          result = 'Unknown Error $e';
        });
      }
    } on FormatException {
      setState(() {
        error(context);
        result = 'Required QR Code with JSON Data, but found wrong format';
      });
    } catch (e) {
      result = 'Unknown Error $e';
    }
  }

  Future _add() async {
    Map<Object, dynamic> data;
    try {
      data = jsonDecode(qrResult.rawContent);
    } catch (FormatException) {
      error(context);
    }
    print(data);
    String url =
        "https://us-central1-folk-test-8a3ae.cloudfunctions.net/createAttendanceDoc";

    Map<String, String> headers = {"Content-type": "application/json"};

    Response response = await post(
      url,
      headers: headers,
      body: jsonEncode(data),
    );

    print("Response code" + response.statusCode.toString() + response.body);
    if (response.statusCode == 200)
      uploaded(context);
    else
      networkError(context);
    // Firestore.instance
    //     .collection("QRData")
    //     .add(data)
    //     .whenComplete(() => uploaded(context));
  }

  error(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return NetworkGiffyDialog(
            image: Image(
                image: AssetImage('images/error.webp'), fit: BoxFit.cover),
            title: Text(
              'Wrong Format Detected',
              style: TextStyle(
                  color: Colors.red, fontSize: 30, fontFamily: 'MetalMania'),
            ),
            description: Text(
                'Found untraceble format of data. Need JSON Data to get scanned and stored'),
            buttonOkText:
                Text('Scan Again', style: TextStyle(color: Colors.white)),
            onOkButtonPressed: () {
              Navigator.pop(context, _qrScan());
            },
          );
        });
  }

  networkError(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return NetworkGiffyDialog(
            image: Image(
                image: AssetImage('images/error.webp'), fit: BoxFit.cover),
            title: Text(
              'Network Error',
              style: TextStyle(
                  color: Colors.red, fontSize: 30, fontFamily: 'MetalMania'),
            ),
            description: Text('Please check your network connection'),
            buttonOkText:
                Text('Scan Again', style: TextStyle(color: Colors.white)),
            onOkButtonPressed: () {
              Navigator.pop(context, _qrScan());
            },
          );
        });
  }

  scanned(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return NetworkGiffyDialog(
            image: Image(
                image: AssetImage('images/scanned.gif'), fit: BoxFit.cover),
            title: Text(
              'Scanned Successfully',
              style: TextStyle(
                  color: Colors.green, fontSize: 30, fontFamily: 'MetalMania'),
            ),
            description: Text(
                'QR Code Scanned Successfully. To add it to cloud press upload button below.'),
            buttonOkText: Text(
              'Upload',
              style: TextStyle(color: Colors.white),
            ),
            onOkButtonPressed: () {
              Navigator.pop(context, _add());
            },
          );
        });
  }

  uploaded(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return NetworkGiffyDialog(
            image: Image(
                image: AssetImage('images/uploaded.gif'), fit: BoxFit.cover),
            title: Text(
              'Uploaded Successfully',
              style: TextStyle(
                  color: Colors.green, fontSize: 30, fontFamily: 'MetalMania'),
            ),
            description:
                Text('JSON Data has been added successfully to the Cloud.'),
            onlyOkButton: true,
            buttonOkText: Text(
              'Ok',
              style: TextStyle(color: Colors.white),
            ),
            onOkButtonPressed: () {
              Navigator.pop(context);
              _qrScan();
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink.shade900,
        centerTitle: true,
        title: Text('QR Code Scanner'),
      ),
      body: Center(
        /*child: Container(
          constraints: BoxConstraints.expand(),
          decoration: BoxDecoration(
              image: DecorationImage(
                  image: AssetImage('images/back.jpg'), fit: BoxFit.cover)),*/
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text(
                  ' Scan QR Code and\n Store JSON Data.',
                  style: TextStyle(
                    fontSize: 40,
                    color: Colors.blue.shade900,
                    fontFamily: 'MetalMania',
                  ),
                ),
                Icon(
                  Icons.thumb_up,
                  color: Colors.pink.shade900,
                  size: 70,
                )
              ],
            ),
            Image(
              image: AssetImage('images/home.gif'),
            ),
          ],
        ),
        //),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _qrScan();
        },
        backgroundColor: Colors.pink.shade900,
        icon: Icon(Icons.camera_alt),
        label: Text('Scan'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
