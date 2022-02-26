import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_app/services/auth.dart';
import 'package:contacts_app/services/session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:loadmore/loadmore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:phone_number/phone_number.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:contacts_app/empty.dart';
import 'package:contacts_app/loading.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:share/share.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:faker/faker.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'model/contacts.dart';
import 'model/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamProvider<MyUser?>.value(
      initialData: null,
      value: AuthService().user,
      child: MaterialApp(
        home: MaterialApp(
          title: 'Contacts',
          theme: ThemeData(
            // This is the theme of your application.
            //
            // Try running your application with "flutter run". You'll see the
            // application has a blue toolbar. Then, without quitting the app, try
            // changing the primarySwatch below to Colors.green and then invoke
            // "hot reload" (press "r" in the console where you ran "flutter run",
            // or simply save your changes to "hot reload" in a Flutter IDE).
            // Notice that the counter didn't reset back to zero; the application
            // is not restarted.
            primarySwatch: Colors.blue,
          ),
          home: Contacts(title: 'Contact Lists'),
        ),
      ),
    );
  }
}

class Contacts extends StatefulWidget {
  Contacts({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _ContactsState createState() => _ContactsState();
}

class _ContactsState extends State<Contacts> {
  Faker faker = new Faker();
  bool timeagoOpt = false;
  ScrollController _scrollController = new ScrollController();
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  List<UserContacts> data = [];
  bool isLoading = false;
  final int increment = 15;
  int currentLength = 0;

  PhoneNumberUtil plugin = PhoneNumberUtil();

  Future _onRefresh() async {
    //generate MY mobile phone number
    const _chars = '0123456789';
    Random _rnd = Random();

    String getRandomString(int length) =>
        String.fromCharCodes(Iterable.generate(
            length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    for (int i = 0; i < 5; i++) {
      FirebaseFirestore.instance.collection("contacts").add({
        "user": faker.person.name().toString(),
        "phone":
            "+601" + getRandomString(8).replaceAll(new RegExp(r'[^0-9]'), ''),
        "check-in": DateTime.now()
      });
    }

    _refreshController.refreshCompleted();
  }

  AuthService _auth = new AuthService();

  void _onLoading() async {
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    dynamic result = await _auth.SignInAnon();
    if (result == null) {
      print("error");
    } else {
      print("success");
    }
    if (mounted) setState(() {});
    _refreshController.loadComplete();
  }

  @override
  void initState() {
    _onLoading();

    getTimeFormatData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        print('You have reached end of the list');

        showTopSnackBar(
          context,
          CustomSnackBar.info(
            message: "You have reached end of the list",
          ),
        );
      }
    });
    super.initState();
  }

  Future _loadMore() async {
    setState(() {
      isLoading = true;
    });

    // Add in an artificial delay
    await new Future.delayed(const Duration(seconds: 2));
    for (var i = currentLength; i <= currentLength + increment; i++) {}
    setState(() {
      isLoading = false;
      currentLength = data.length;
    });
  }

  shareContact(BuildContext context, UserContacts contacts) {
    final RenderObject? box = context.findRenderObject();

    Share.share("User : ${contacts.user} - Phone Number : ${contacts.phone}",
        subject: contacts.phone);
    // sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  Future getTimeFormatData() async {
    UserSession.init();
    if (UserSession.getTimeOpt() == null) {
      setState(() {
        timeagoOpt = true;
      });
    } else {
      setState(() {
        timeagoOpt = UserSession.getTimeOpt()!;
      });
    }
  }

  int countlist = 0;

  Future getCountContacts() async {
    QuerySnapshot contactQry =
        await FirebaseFirestore.instance.collection('contacts').get();
    List<DocumentSnapshot> contactsDocCount = contactQry.docs;

    countlist = contactsDocCount.length;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Container(
        child: SmartRefresher(
          controller: _refreshController,
          onRefresh: _onRefresh,
          onLoading: _onLoading,
          enablePullUp: true,
          enablePullDown: true,
          header: WaterDropHeader(),
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus? mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = Text("pull up load");
              } else if (mode == LoadStatus.loading) {
                body = CupertinoActivityIndicator();
              } else if (mode == LoadStatus.failed) {
                body = Text("Load Failed!Click retry!");
              } else if (mode == LoadStatus.canLoading) {
                body = Text("release to load more");
              } else {
                body = Text("No more Data");
              }
              return Container(
                height: 55.0,
                child: Center(child: body),
              );
            },
          ),
          child: LazyLoadScrollView(
            isLoading: isLoading,
            onEndOfPage: () => _loadMore(),
            child: Container(
              margin: const EdgeInsets.only(top: 20.0, bottom: 20.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('contacts')
                    .orderBy('check-in', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Loading();
                  } else {
                    int index = 0;

                    //trans.add(snapshot.data);
                    var listview = ListView(
                      controller: _scrollController,
                      children:
                          snapshot.data!.docs.map((DocumentSnapshot document) {
                        index += 1;
                        return Card(
                          elevation: 10.00,
                          margin: EdgeInsets.all(0.50),
                          child: ListTile(
                            title: Text(document['user'].toString()),
                            subtitle: Text(document['phone'].toString()),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Expanded(
                                    child: IconButton(
                                        iconSize: 18,
                                        onPressed: () {
                                          faker.person.name();
                                          FirebaseFirestore.instance
                                              .collection("contacts")
                                              .doc(document.id)
                                              .delete();
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                        ))),
                                (timeagoOpt == false)
                                    ? Text(DateFormat('dd MMMM yyyy, hh:mm a')
                                        .format(document['check-in'].toDate())
                                        .toString())
                                    : Text(timeago
                                        .format(document['check-in'].toDate())
                                        .toString()),
                              ],
                            ),
                            onLongPress: () {
                              UserContacts users = UserContacts(
                                  user: document['user'].toString(),
                                  phone: document['phone'].toString(),
                                  checkin: document['check-in'].toDate());

                              shareContact(context, users);
                            },
                          ),
                        );
                      }).toList(),
                    );

                    if (index == 0) {
                      return Empty(type: "contacts");
                    } else {
                      return listview;
                    }
                  }
                },
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            timeagoOpt = !timeagoOpt;
            UserSession.setTimeOpt(timeagoOpt);
          });
        },
        child: Icon(Icons.timelapse),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
