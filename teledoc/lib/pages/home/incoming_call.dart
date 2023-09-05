import 'package:flutter/material.dart';

class IncomingCallWidget extends StatelessWidget {
  Function? acceptCall;
  Function? denyCall;
  String? caller;

  IncomingCallWidget({super.key, this.acceptCall, this.denyCall, this.caller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [        

        CircleAvatar(
          backgroundColor: Colors.orange[200],
          radius: 80,
        ),
        const SizedBox(height: 20),

        const Text("Incoming Call"),
        const SizedBox(height: 20),

        Text(
          caller!,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 80),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            FloatingActionButton(
              onPressed: ()=> acceptCall!(),
              // label: const Text("Accept Call"),
              heroTag: const Key('FABAcceptCall'),
              elevation: 0,
              child: const Icon(Icons.call_outlined),
            ),

            FloatingActionButton(
              onPressed: ()=> denyCall!(),
              // label: const Text("Deny Call"),
              heroTag: const Key('FABDenyCall'),
              elevation: 0,
              backgroundColor: Colors.red[300],
              child: const Icon(Icons.call_end_outlined),
            ),

          ],
        ),

      ],
    );
  }
}