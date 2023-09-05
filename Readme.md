# Flutter WebRTC Video Calling App

The code in this repo consists of the components required to build a fully functional webrtc app in flutter.

## 🚀 TeleDoc

This folder contains the mobile application. It uses the latest version of flutter and socket io for websockets. To install dependencies run:

```sh
flutter pub get
```

To start flutter app run:

```sh
flutter run
```

Or to specify a device to run it on run:

```sh
flutter run -d <device>
```

Where <device> is a device id. You can get it by running:

```sh
flutter devices
```


If you want to reproduce my work to perhaps rebuild your own version, run (to create a new flutter app):

```sh
flutter create <app-name>
```


## Signal

This folder contains the server that powers the mobile application. It uses the latest version of typescript, nodejs and socket io for websockets. To install its dependencies run:

```sh
yarn install
```

To start the server run:

```sh
yarn dev
```

### Alternatively, you can use docker to run the api.

Build the Docker image:

```sh
docker build -t signal .
```

Start the Docker container:

```sh
docker run -p 8080:8080 signal
```


## 📝 Todo

While time to work on projects may be limited, I plan to add a few things to this project in the future:

I plan to build a Signal API with AWS Lambda Websockets which would obviously be a cheaper option than running the current API on AWS EC2 or ECS. I plan to push it to git https://github.com/efenstakes/video-call-signalling-api-aws-lambda.

Add a golang pion server, peerjs, or elixir janus to power group calls.


## Contact
Contact me through.
efenstakes101@gmail.com
