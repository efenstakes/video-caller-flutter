import 'package:flutter/material.dart';
import 'package:meetr/models/call_info.dart';
import 'package:meetr/pages/call/page.dart';
import 'package:meetr/pages/home/incoming_call.dart';
import 'package:meetr/pages/home/start_call.dart';
import 'package:meetr/services/signal.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:math';



class HomePage extends StatefulWidget {
  final String callerId;
  const HomePage({super.key, required this.callerId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // socket
  final _socket = SignalService.instance.socket;

  bool _hasIncomingCall = false;

  CallInfo _callInfo = CallInfo( isCaller: false );

  List<String> onlineFriends = [];


  @override
  void initState() {
    super.initState();

    setState(() => _callInfo.callerId = widget.callerId);


    // when we get a call
    _socket!.on("incoming-call", (data) {
      print("data ${data}");
      print("data from ${data['from']}");
      setState(() {
        _hasIncomingCall = true;
        _callInfo.receiverId = data['from'];
        _callInfo.isCaller = false;
      });
    });

    // when new user joins
    _socket!.on("new-user", (data) {

      print("new user joined ${data['user']}");

      if( !onlineFriends.contains(data['user']) ) {

        setState(()=> onlineFriends.add(data['user']));
      }
    });
    
    // when new users join
    _socket!.on("new-users", (data) {

      _printSpace();
      print("new users joined ${data['users']}");
      _printSpace();

      for (var index = 0; index < (data['users'] as List<dynamic>).length; index ++ ) {
        var user = data['users'][index];

        _printSpace();
        print("new user ${user}");
        _printSpace();

        if( !onlineFriends.contains((user as String)) ) {

          setState(()=> onlineFriends.add(user));
        }
      }
    });

    // when new user joins
    _socket!.on("user-left", (data) {

      print("user left ${data['user']}");

      setState(()=> onlineFriends.remove(data['user']));
    });
  }

  @override
  void dispose() {
    // stop watching socket events
    _socket!.off("incoming-call");
    _socket!.off("new-users");
    _socket!.off("user-left");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if( _hasIncomingCall ) {

      return Scaffold(
      appBar: AppBar(
        title: const Text("TeleDoc"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
          child: IncomingCallWidget(
                  caller: _callInfo.receiverId,
                  denyCall: _denyCall,
                  acceptCall: _acceptCall,
                ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("TeleDoc"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
          child: Container(
            height: double.maxFinite,
            child: Stack(
              children: [
          
                Container(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
          
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text("Hello,",
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              _callInfo.callerId!,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),

                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      ...onlineFriends.map((friend) {
                        Random random = Random();
          
                        return ListTile(
                            onTap: () {
                              _setInfo(CallInfo(isCaller: true, receiverId: friend,));
                            },
                            leading: CircleAvatar(
                              backgroundColor: Color.fromRGBO(
                                  random.nextInt(255),
                                  random.nextInt(255),
                                  random.nextInt(255),
                                  .6,
                              ),
                              child: Text(
                                friend.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(friend),
                            subtitle: const Text(
                              "Tap to call..",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            trailing: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                      }).toList(),
                      
                    ],
                  ),
                ),
          
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  // child: Text("data"),
                  child: StartCallWidget(
                          setInfo: _setInfo,
                          callInfo: _callInfo,
                        ),
                ),
                // Positioned(
                //   bottom: 0,
                //   left: 0,
                //   right: 0,
                //   // child: Text("data"),
                //   child: !_hasIncomingCall
                //           ?
                //             StartCallWidget(
                //               setInfo: _setInfo,
                //               callInfo: _callInfo,
                //             )
                //           : 
                //             IncomingCallWidget(
                //               caller: "Caller",
                //               denyCall: _denyCall,
                //               acceptCall: _acceptCall,
                //             ),
                // ),

              ],
            ),
          ),
      ),
    );
  }// build

  
  _acceptCall() {
    _printSpace();
    print("  <====================> Accepting call");
    _printSpace();
    _socket!.emit("accept-call", <String, dynamic> {
      "to": _callInfo.receiverId,
    });

    _printSpace();
    print("  <====================> Going to call page with data ${_callInfo.toJson()}");
    _printSpace();
    // return;

    setState(()=> _hasIncomingCall = false);

    // go to the rooms page
    // Navigator.of(context).pushNamed(
    //   '/call',
    //   arguments: {
    //     'info': _callInfo.toJson(),
    //   }
    // );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context)=> CallPage(callInfo: _callInfo))
    );
  }

  _denyCall() {
    _printSpace();
    print("  <====================> Denying call");
    _printSpace();

    setState(()=> _hasIncomingCall = false);

    _socket!.emit("deny-call", <String, dynamic> {
      "to": _callInfo.receiverId,
    });
  }


  _setInfo(CallInfo info) {
    _printSpace();
    print("  <====================> _setInfo ");
    _printSpace();

    setState(() {
      _callInfo.receiverId = info.receiverId;
      _callInfo.isCaller = true;
    });

    
    // go to the rooms page
    // Navigator.of(context).pushNamed(
    //   '/call',
    //   arguments: {
    //     'info': _callInfo.toJson(),
    //     // 'room': _callInfo.,
    //     // 'isCaller': !_hasIncomingCall,
    //     // 'callee': _callee,
    //   }
    // );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context)=> CallPage(callInfo: _callInfo))
    );
  }

  _printSpace() {
    print("");
    print("");
    print("\t <==================================>");
    print("");
    print("");
  }


}