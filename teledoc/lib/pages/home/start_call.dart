import 'package:flutter/material.dart';
import 'package:meetr/models/call_info.dart';


class StartCallWidget extends StatefulWidget {
  Function? setInfo;
  CallInfo? callInfo;
  StartCallWidget({super.key, this.setInfo, this.callInfo});

  @override
  State<StartCallWidget> createState() => _StartCallWidgetState();
}

class _StartCallWidgetState extends State<StartCallWidget> {
  CallInfo _callInfo = CallInfo(isCaller: false);

  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();

    setState(() {
      _callInfo.callerId = widget.callInfo?.callerId;
      _callInfo.receiverId = widget.callInfo?.receiverId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      child: Form(
        key: _formKey,
        child: Row(
          children: [
      
      
            Flexible(
              flex: 1,
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: "Who to call",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  prefixIcon: const Icon(Icons.person_4_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please who to call';
                  }
                  return null;
                },
                onSaved: (data)=> setState(()=> _callInfo.receiverId = data!),
              ),
            ),
            const SizedBox(width: 8),
      
            FloatingActionButton(
              onPressed: ()=> _submitForm!(),
              heroTag: const Key('FABStartCall'),
              elevation: 0,
              child: const Icon(Icons.call_outlined),
              // shape: RoundedRectangleBorder(
              //   borderRadius: BorderRadius.circular(6),
              // ),
            ),
      
      
          ],
        ),
      ),
    );
  }

  
  _submitForm() {
    // Validate returns true if the form is valid, or false otherwise.
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print("Your data is valid");
      print("name ${_callInfo.callerId}");
      print("receiver ${_callInfo.receiverId}");
      // If the form is valid, display a snackbar. In the real world,
      // you'd often call a server or save the information in a database.
      widget.setInfo!(_callInfo);
    } else {
      print("Your data is not valid");
    }
  }
}