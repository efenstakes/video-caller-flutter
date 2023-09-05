import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meetr/models/call_info.dart';
import 'package:meetr/services/signal.dart';

class CallPage extends StatefulWidget {
  late CallInfo callInfo;
  CallPage({super.key, required this.callInfo});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  // socket
  final _socket = SignalService.instance.socket;

  // local peers video
  final _localRTCRenderer = RTCVideoRenderer();

  // remote peers video
  final _remoteRTCRenderer = RTCVideoRenderer();

  // media stream from local peer
  MediaStream? _localStream;


  // webrtc peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // ice candidates that have been collected locally
  final List<RTCIceCandidate> _iceCandidates = [];


  // media states
  bool isAudioOn = true, isVideoOn = true, isFrontCameraActive = true;




  @override
  void initState() {
    // initialize webrtc renderers
    _localRTCRenderer.initialize();
    _remoteRTCRenderer.initialize();

    // watch common socket events like
    //  user leaving, call being denied
    _watchCommonSocketEvents();

    // setup the connection
    _setupConnection();


    // TODO: implement initState
    super.initState();
  }


  @override
  void dispose() {
    _localRTCRenderer.dispose();
    _remoteRTCRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();

    
    // stop watching socket events
    _socket!.off("left-call");
    _socket!.off("call-denied");
    _socket!.off("user-left");
    _socket!.off("call-accepted");
    _socket!.off("offer-answer");
    _socket!.off("offer");
    _socket!.off("ice-candidate");

    super.dispose();
  }


  _watchCommonSocketEvents() {
    
    _socket!.on("left-call", (data) {

      _printSpace();
      print("${widget.callInfo.receiverId} Left the call, quit now");
      _printSpace();

      _goBack();
    });

    
    _socket!.on("call-denied", (data) {
      _printSpace();
      print("call denied, oops");
      _printSpace();

      _goBack();
    });

  }

  _setupConnection() async {
    // create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302'
          ]
        }
      ]
    });


    // listen for media tracks from our remote pal
    _rtcPeerConnection!.onTrack = (track) {
      _printSpace();
      print("got track");
      _printSpace();

      _remoteRTCRenderer.srcObject = track.streams[0];
      
      setState(() {});
    };


    // create our own stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
                ? { 'facingMode': isFrontCameraActive ? 'user' : 'environment', }
                : false,
    });


    // add my local media tracks ti the rtc peer connection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });


    // set the source for my local renderer
    _localRTCRenderer.srcObject = _localStream;

    // update the page so state can be reflected
    setState(() {});


    // if we are the caller
    if( widget.callInfo.isCaller ) {

      // listen for my ice candidates and add them to the ice candidate list
      _rtcPeerConnection!.onIceCandidate = (candidate) {
        setState(()=> _iceCandidates.add(candidate));
      };
      
      // listen for whether the receiver accepts our call
      // if they accept, we create an offer and send it to them
      _socket!.on("call-accepted", (data) async {
        _printSpace();
        print("call answered");
        _printSpace();

        // create sdp offer
        var offer = await _rtcPeerConnection!.createOffer();

        // set it as our local description
        await _rtcPeerConnection!.setLocalDescription(offer);

        // send it to the fella we called
        _socket!.emit("offer", { 'offer': offer.toMap(), 'to': widget.callInfo.receiverId });
      });


      // listen for offer answered event
      _socket!.on("offer-answer", (data) async {
        _printSpace();
        print("offer answered");
        _printSpace();

        // we set the answer as ouR remote sdp
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(data['answer']['sdp'], data['answer']['type'])
        );

        // we then send all collected ice candidates to the receiver
        for ( var iceCandidate in _iceCandidates ) {
          _socket!.emit("ice-candidate", {
            "to": widget.callInfo.receiverId,
            "candidate": {
              "sdpMid": iceCandidate.sdpMid,
              "candidate": iceCandidate.candidate,
              "sdpMLineIndex": iceCandidate.sdpMLineIndex,
            }
          });
        }
      });

      // initiate call to the remote peer
      _socket!.emit("start-call", { "to": widget.callInfo.receiverId });
      
      _printSpace();
      print("start call");
      _printSpace();
    }

    // if we are the receiver
    if( !widget.callInfo.isCaller ) {

      // watch out for offer
      // set it as remote sdp description,
      // generate an answer and set it as local sdp description then send it to our caller
      _socket!.on("offer", (data) async {
        _printSpace();
        print("got offer");
        _printSpace();

        // set it as remote sdp description,
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(data['offer']['sdp'], data['offer']['type'])
        );

        // generate an answer
        RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

        // set answer as local sdp description then
        _rtcPeerConnection!.setLocalDescription(answer);

        // send answer to our caller
        _socket!.emit("offer-answer", {
          "answer": answer.toMap(),
          "to": widget.callInfo.receiverId,
        });

      });


      // watch out for ice candidates and add them as candidates
      _socket!.on("ice-candidate", (data) {
        _printSpace();
        print("got ice candidate");
        print("its data is $data");
        _printSpace();

        String candidate = data["candidate"]["candidate"];
        String sdpMid = data["candidate"]["sdpMid"];
        int sdpMLineIndex = data["candidate"]["sdpMLineIndex"];

        // add it
        _rtcPeerConnection!.addCandidate(
          RTCIceCandidate(candidate, sdpMid, sdpMLineIndex)
        );
      });


      // accept call
      _socket!.emit("accept-call", { "to": widget.callInfo.receiverId });

      _printSpace();
      print("answering call");
      _printSpace();
    }

  }

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;


    return Scaffold(
      body: Container(
        child: Stack(
          children: [


            // the person im chatting with
            Positioned.fill(
              child: RTCVideoView(
                _remoteRTCRenderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                placeholderBuilder: (_) {

                  // return RTCVideoView(
                  //   _localRTCRenderer,
                  //   objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  //   mirror: true,
                  // );
                  return Container(
                    color: Colors.grey[400],
                    child: Center(
                      child: Text("Waiting for ${widget.callInfo.receiverId} to Join"),
                    ),
                  );
                }
              ),
            ),

            // my video
            if( _localRTCRenderer.srcObject != null )
              Positioned(
                right: 16,
                bottom: 72,
                height:  screenSize.height / 4,
                // width: 120,
                child: AspectRatio(
                  aspectRatio: 3/4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: RTCVideoView(
                      _localRTCRenderer,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),

            
            // calling with name
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Container(
                // color: Colors.red,
                alignment: Alignment.center,
                width: double.maxFinite,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(.4),
                  ),
                  child: Text(
                    widget.callInfo.receiverId ?? "Pal",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            
            
            // stream controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16)
                  )
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
              
                    // mute / unmute audio
                    FloatingActionButton(
                      onPressed: _toggleAudio,
                      backgroundColor: isAudioOn ? Colors.pink[300] : Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      mini: true,
                      heroTag: " mute / unmute audio FAB",
                      child: Icon( isAudioOn ? Icons.mic_off_outlined : Icons.mic_none_outlined ),
                    ),
              
                    // show / unshow video
                    FloatingActionButton(
                      onPressed: _toggleVideo,
                      backgroundColor: isVideoOn ? Colors.pink[300] : Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      mini: true,
                      heroTag: "show / unshow video FAB",
                      child: Icon( isVideoOn ? Icons.videocam_off_outlined : Icons.videocam_rounded )
                    ),
              
                    // leave call
                    FloatingActionButton(
                      onPressed: _leaveCall,
                      backgroundColor: Colors.red[500],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      mini: true,
                      heroTag: "leave call FAB",
                      child: const Icon(Icons.call_end_outlined),
                    ),
              
                  ],
                ),
              )
            ),
            

          ],
        ),
      ),
    );
  }


  _toggleAudio() {
    isAudioOn = !isAudioOn;

    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }


  _toggleVideo() {
    isVideoOn = !isVideoOn;

    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  _unshowVideo() {
    
  }
  
  _leaveCall() {
    _socket!.emit("leave-call", { "to": widget.callInfo.receiverId });
    Navigator.pop(context);
  }

  
  
  _goBack() {
    Navigator.of(context).pop(); 
  }

  _printSpace() {
    print("<==================================>");
    print("<==================================>");
    print("\t <==================================>");
    print("<==================================>");
    print("<==================================>");
  }


}