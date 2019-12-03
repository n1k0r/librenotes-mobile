import 'package:flutter/material.dart';
import 'package:librenotes/providers/sync.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final serverController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  Sync sync;

  bool authProcess = false;

  @override
  void didChangeDependencies() {
    sync = Provider.of<Sync>(context);

    if (sync.authorized) {
      Navigator.pushReplacementNamed(context, 'notes');
    }

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _getLogo(),
              _getForm(),
            ],
          ),
        ),
      ),
    );
  }

  _getLogo() {
    return Container(
      width: MediaQuery.of(context).size.width / 2,
      padding: EdgeInsets.only(top: 16),
      child: FittedBox(
        fit: BoxFit.contain,
        child: Icon(
          Icons.event_note,
          color: Theme.of(context).accentColor,
        ),
      ),
    );
  }

  _getForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: serverController,
            decoration: InputDecoration(
              labelText: 'Server address',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Server address can not be empty';
              }
              return null;
            },
          ),
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'User name',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'User name can not be empty';
              }
              return null;
            },
          ),
          TextFormField(
            autocorrect: false,
            obscureText: true,
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
            ),
            validator: (value) {
              if (value.isEmpty) {
                return 'Password can not be empty';
              }
              return null;
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: RaisedButton(
                    onPressed: authProcess ? null : _onAuth,
                    child: Text('Log In'),
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.blue[900] : Theme.of(context).buttonColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _onAuth() async {
    setState(() {
      authProcess = true;
    });

    if (!_formKey.currentState.validate()) {
      setState(() {
        authProcess = false;
      });
      return;
    }

    bool result = await sync.auth(
      serverController.text,
      usernameController.text,
      passwordController.text,
    );

    if (result) {
      Navigator.pushReplacementNamed(context, 'notes');
    } else {
      _scaffoldKey.currentState.showSnackBar(_errorSnackBar('Incorrect credentials'));
    }

    setState(() {
      authProcess = false;
    });
  }

  SnackBar _errorSnackBar(String msg) {
    return SnackBar(
      backgroundColor: Colors.red,
      content: Text(
        msg,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
