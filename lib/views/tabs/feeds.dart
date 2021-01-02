import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:techstagram/models/posts.dart';
import 'package:techstagram/models/user.dart';
import 'package:techstagram/resources/auth.dart';
import 'package:techstagram/resources/uploadimage.dart';
import 'package:techstagram/services/database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:techstagram/ui/HomePage.dart';
import 'package:techstagram/ui/Otheruser/other_user.dart';
import 'package:techstagram/utils/utils.dart';
import 'package:techstagram/views/tabs/comments_screen.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'dart:math' as math;
import 'package:image_cropper/image_cropper.dart';
import 'package:uuid/uuid.dart';


class FeedsPage extends StatefulWidget {

  final String displayNamecurrentUser;

  @override

  FeedsPage({
    this.displayNamecurrentUser,
  });

  @override
  _FeedsPageState createState() => _FeedsPageState(displayNamecurrentUser: displayNamecurrentUser);

}

class _FeedsPageState extends State<FeedsPage> {


  final String displayNamecurrentUser;
  List<Posts> posts;
  List<DocumentSnapshot> list;
  Map<String, dynamic> _profile;
  bool _loading = false;
  DocumentSnapshot docSnap;
  FirebaseUser currUser;
  ScrollController scrollController = new ScrollController();
  Posts currentpost;
  List<bool> _likes = List.filled(10000,false);

  double _scale = 1.0;
  double _previousScale;
  var yOffset = 400.0;
  var xOffset = 50.0;
  var rotation = 0.0;
  var lastRotation = 0.0;
  var time = "s";
  User currentUser;
  String NotificationId = Uuid().v4();

  File _image;
  bool upload;
  int likescount;
  bool loading = false;
  int Plength;



  Stream<QuerySnapshot> postsStream;
  final timelineReference = Firestore.instance.collection('posts');
  String postIdX;
  //bool _liked = false;
  //var like = new List();
  //int likeint;


  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  TextEditingController emailController,urlController,descriptionController,
      displayNameController,photoUrlController,
      timestampController,likesController,uidController;

  _FeedsPageState({this.displayNamecurrentUser,this.postIdX});


  @override
  void initState() {

    emailController = TextEditingController();
    likesController = TextEditingController();
    uidController = TextEditingController();
    displayNameController = TextEditingController();
    photoUrlController = TextEditingController();

    super.initState();
    // Subscriptions are created here
    authService.profile.listen((state) => setState(() => _profile = state));

    authService.loading.listen((state) => setState(() => _loading = state));
    fetchPosts();
    fetchProfileData();
    fetchLikes();
    //getPostCount();
  }

  File crop;

  // getPostCount() async {
  //   await DatabaseService().getPosts().then((val){
  //     setState(() {
  //       Plength = val;
  //     });
  //   });
  //   print("yaha ai bhai length");
  //   print(Plength);
  // }

  Future pickImage() async {
    if(_image == null){
      // ignore: deprecated_member_use
      await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
        setState(() async {
          if(image != null){
            crop = await ImageCropper.cropImage(
                sourcePath: image.path,
                aspectRatio: CropAspectRatio(
                    ratioX: 1, ratioY: 1),
                compressQuality: 100,
                maxWidth: 700,
                maxHeight: 700,
                compressFormat: ImageCompressFormat.jpg,
                androidUiSettings: AndroidUiSettings(
                  toolbarColor: Colors.white,
                  toolbarTitle: "AIO Cropper",
                  activeControlsWidgetColor: Colors.purple,
                  toolbarWidgetColor: Colors.deepPurple,
                  statusBarColor: Colors.purple,
                  backgroundColor: Colors.white,
                  showCropGrid: false,
                  dimmedLayerColor: Colors.black54,
                )
            );
            upload = true;
            _image = crop;
            if(_image != null){
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UploadImage(file: _image),));
            }else{
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1),));
            }

          }else{
            Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1),));
          }

        });
      });
      if (_image != null){
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UploadImage(file: _image),));
      }else{
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1),));
      }
    }else if(crop == null){
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage(initialindexg: 1),));
    }



//    Navigator.push(
//      context,
//      MaterialPageRoute(builder: (context) => UploadImage(file: _image,)),
//    );
    print("Done..");
  }

  fetchPosts() async {

    await DatabaseService().getPosts().then((val){
      setState(() {
        postsStream = val;
      });
    });
  }

  getlikes( String displayNamecurrent, String postId, int index) async {

    await Firestore.instance.collection('posts')
        .document(postIdX)
        .collection('likes')
        .document(displayNamecurrent)
        .get()
        .then((value) {
      if (value.exists) {
        setState(() {
          //likeint = int.parse(postId);
          //_liked = true;
          _likes[index] = true;
          //like[likeint] = "true";
        });
      }
    });
  }

  fetchLikes() async {
    currUser = await FirebaseAuth.instance.currentUser();
    try {
      docSnap = await Firestore.instance
          .collection("likes")
          .document(currUser.uid)
          .get();
    } on PlatformException catch (e) {
      print("PlatformException in fetching user profile. E  = " + e.message);
    }
  }

  fetchProfileData() async {
    currUser = await FirebaseAuth.instance.currentUser();
    try {
      docSnap = await Firestore.instance
          .collection("users")
          .document(currUser.uid)
          .get();
      emailController.text = docSnap.data["email"];
      likesController.text = docSnap.data["likes"];
      uidController.text =  docSnap.data["uid"];
      displayNameController.text = docSnap.data["displayName"];
      photoUrlController.text = docSnap.data["photoURL"];
    } on PlatformException catch (e) {
      print("PlatformException in fetching user profile. E  = " + e.message);
    }
  }

  String readTimestamp(int timestamp) {
    var now = DateTime.now();
//    var format = DateFormat('HH:mm a');
    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    var diff = now.difference(date);
    var time = '';

    if (diff.inSeconds <= 0 || diff.inSeconds > 0 && diff.inMinutes == 0 || diff.inMinutes > 0 && diff.inHours == 0 || diff.inHours > 0 && diff.inDays == 0) {
      if (diff.inHours > 0) {
        time = "${diff.inHours} ${diff.inHours == 1 ? "hour" : "hours"} ago";
      }

      else if (diff.inSeconds <= 0) {
        time = "just now";
      }


      else if (diff.inMinutes > 0) {
        time = "${diff.inMinutes} ${diff.inMinutes == 1 ? "minute" : "minutes"} ago";
      }
    } else if (diff.inDays > 0 && diff.inDays < 7) {
      if (diff.inDays == 1) {
        time = diff.inDays.toString() + ' DAY AGO';
      } else {
        time = diff.inDays.toString() + ' DAYS AGO';
      }
    }



    else {
      if (diff.inDays == 7) {
        time = (diff.inDays / 7).floor().toString() + ' WEEK AGO';
      } else {
        time = (diff.inDays / 7).floor().toString() + ' WEEKS AGO';
      }
    }

    return time;
  }




  @override
  Widget build(BuildContext context) {

    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    final image = Image.asset(
      AvailableImages.emptyState['assetPath'],
    );

    final notificationHeader = Container(
      padding: EdgeInsets.only(top: 30.0, bottom: 10.0),
      child: Text(
        "No Posts",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0),
      ),
    );

    return GestureDetector(
      child: Scaffold(
        key: _scaffoldKey,
        body: StreamBuilder(
          stream: postsStream,
          builder: (context, snapshot) {
            return snapshot.hasData
                ? Column(
              children: [

                new Expanded(
                  child: ListView.builder(
                      controller: scrollController,
                      itemCount: snapshot.data.documents.length,

                      itemBuilder: (context, index) {

                        int len = snapshot.data.documents.length;

                        postIdX = snapshot.data.documents[index]['postId'];

                        String email = snapshot.data.documents[index]['email'];

                        String description = snapshot.data.documents[index]['description'];

                        String displayName = snapshot.data.documents[index]['displayName'];

                        String photoUrl = snapshot.data.documents[index]['photoURL'];

                        String OwnerDisplayName = snapshot.data.documents[index]['OwnerDisplayName'];

                        String OwnerPhotourl = snapshot.data.documents[index]['OwnerPhotourl'];

                        bool shared = snapshot.data.documents[index]['shared'];

                        String uid = snapshot.data.documents[index]["uid"];

                        int shares = snapshot.data.documents[index]["shares"];

                        Timestamp timestamp = snapshot.data.documents[index]['timestamp'];

                        String url = snapshot.data.documents[index]['url'];

                        int cam = snapshot.data.documents[index]['cam'];

                        String postId = snapshot.data.documents[index]['postId'];

                        int likes = snapshot.data.documents[index]['likes'];

                        int comments = snapshot.data.documents[index]['comments'];

                        readTimestamp(timestamp.seconds);

                        getlikes(displayNamecurrentUser, postIdX, index);

                        Notification() async {
                          //print(currUid);

                          setState(() {
                            // file = null;
                            NotificationId = Uuid().v4();
                          });

                          return await Firestore.instance.collection("users")
                              .document(uid).collection("notification")
                              .document(NotificationId)
                              .setData({"likes" : likes+1,
                            "notificationId" : NotificationId,
                            "username": displayNamecurrentUser,
                            //"comment": commentTextEditingController.text,

                            "timestamp": DateTime.now(),
                            "url": photoUrl,
                            "uid": uid,
                            "status" : "like",
                            "postId" : postId,
                          });

                        }

                        return (shared==true)?Container(
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[
                              Container(height: 0.0,width: 0.0,),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OtherUserProfile(uid: uid,displayNamecurrentUser: displayNameController.text,displayName: displayName,uidX: uidController.text,)),
                                ),
                                child: Container(
                                  padding: EdgeInsets.only(
                                    top: 10,
                                    left: 10,
                                    right: 10.0,
                                  ),

                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: <Widget>[

                                          Row(
                                            children: <Widget>[

                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(40),
                                                child: Image(
                                                  image: NetworkImage(photoUrl),
                                                  width: 40,
                                                  height: 40,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Text(displayName,style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18.0,
                                              ),),
                                            ],
                                          ),

                                          IconButton(
                                            icon: Icon(SimpleLineIcons.options),
                                            onPressed: () {},
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(bottom: 1.0),
                                child: Container(
                                  height: 50.0,
                                  color: Colors.grey.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 15.0,right: 15.0,),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(40),
                                              child: Image(
                                                image: NetworkImage(OwnerPhotourl),
                                                width: 30,
                                                height: 30,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            SizedBox(
                                              width: 10,
                                            ),
                                            Text(OwnerDisplayName,style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.0,
                                            ),),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),


                              GestureDetector(
                                onDoubleTap: () {

                                  if (_likes[index] == false) {
                                    setState(() {
                                      _likes[index] = true;
                                    });

                                    DatabaseService().likepost(
                                        likes, postId,
                                        displayNameController.text);
                                  }
                                },
                                onTap: null,

                                child: Container(
                                  height: 350.0,
                                  child: GestureDetector(
                                    child : (cam == 1)? Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(math.pi),
                                      child: FadeInImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                        //image: NetworkImage("posts[i].postImage"),
                                        placeholder: AssetImage("assets/images/loading.gif"),
                                        width: MediaQuery.of(context).size.width,
                                      ),
                                    ):FadeInImage(
                                      image: NetworkImage(url),
                                      fit: BoxFit.cover,
                                      //image: NetworkImage("posts[i].postImage"),
                                      placeholder: AssetImage("assets/images/loading.gif"),
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[

                                  Row(
                                    children: <Widget>[

                                      IconButton(
                                        padding: EdgeInsets.only(left: 10),
                                        onPressed: (_likes[index] == true)
                                            ? () {


                                          setState(() {
                                            _likes[index] = false;
                                            //like[likeint] = "false";
                                            loading = true;
                                          });

                                          DatabaseService().unlikepost(
                                              likes, postId,displayNameController.text);

                                          setState(() {
                                            loading = false;
                                          });
                                        }
                                            : () {
                                          setState(() {
                                            _likes[index] = true;
                                            //like[likeint] = "true";
                                            loading = true;
                                          });

                                          DatabaseService().likepost(
                                              likes, postId,displayNameController.text);
                                          Notification();

                                          setState(() {
                                            loading = false;
                                          });
                                        },
                                        icon: Icon(Icons.thumb_up),
                                        iconSize: 25,
                                        color: (_likes[index] == true) ? Colors.deepPurple : Colors.grey,
                                      ),

                                      Text(
                                        likes.toString(),style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(top: 3.0),
                                        child: IconButton(

                                          onPressed: () {

                                            Navigator.push(context, MaterialPageRoute(builder: (context){
                                              return CommentsPage(comments: comments,postId: postId, uid: uid, postImageUrl: url,timestamp: timestamp,displayName: displayName,photoUrl: photoUrlController.text,displayNamecurrentUser: displayNameController.text);
                                            }));

                                          },


                                          icon: Icon(Icons.insert_comment,color: Colors.deepPurpleAccent),
                                        ),
                                      ),

                                      Text(comments.toString()),

                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => UploadImage(ownerPostId: postIdX,file: File(url),sharedurl: url,ownerdiscription: description,ownerphotourl: photoUrl,ownerdisplayname: displayName,shared: true,cam: cam,)),
                                          );
                                        },
                                        icon: Icon(FontAwesomeIcons.share,color: Colors.deepPurpleAccent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Row(
                                    children: [

                                      Container(
                                        child: RichText(
                                          textAlign: TextAlign.start,
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          text: TextSpan(
                                            children: [

                                              TextSpan(
                                                text: displayName + "  ",
                                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,
                                                    fontSize: 18.0),
                                              ),
                                              TextSpan(
                                                text: description,
                                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.normal,
                                                    fontSize: 15.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                              ),

                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  readTimestamp(timestamp.seconds),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ),

                            ],
                          ),

                        ):Container(
                          color: Colors.white,
                          child: Column(
                            children: <Widget>[

                              Container(
                                height: 0.0,width: 0.0,
                                ),

                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OtherUserProfile(uid: uid,displayNamecurrentUser: displayNameController.text,displayName: displayName,uidX: uidController.text,)),
                                ),

                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: <Widget>[

                                      Row(
                                        children: <Widget>[

                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(40),
                                            child: Image(
                                              image: NetworkImage(photoUrl),
                                              width: 40,
                                              height: 40,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(displayName,style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.0,
                                          ),),
                                        ],
                                      ),
                                      IconButton(
                                        icon: Icon(SimpleLineIcons.options),
                                        onPressed: () {},
                                      ),
                                    ],
                                  ),
                                ),
                              ),


                              GestureDetector(
                                onDoubleTap: () async {

                                  if (_likes[index] == false) {
                                    setState(() {
                                      _likes[index] = true;
                                      //print(_liked);
                                    });

                                    await DatabaseService().likepost(
                                        likes, postId,
                                        displayNameController.text);
                                    }
                                },
                                onTap: null,

                                child: Container(
                                  height: 350.0,
                                  child: GestureDetector(

                                    child :(cam == 1)?Transform(
                                      alignment: Alignment.center,
                                      transform: Matrix4.rotationY(math.pi),
                                      child: FadeInImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                        //image: NetworkImage("posts[i].postImage"),
                                        placeholder: AssetImage("assets/images/loading.gif"),
                                        width: MediaQuery.of(context).size.width,
                                      ),

                                    ):FadeInImage(
                                      image: NetworkImage(url,),
                                      fit: BoxFit.cover,
                                      placeholder: AssetImage("assets/images/loading.gif"),
                                      width: MediaQuery.of(context).size.width,
                                    ),
                                  ),
                                ),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: <Widget>[

                                  Row(
                                    children: <Widget>[

                                      IconButton(
                                        padding: EdgeInsets.only(left: 10),
                                        onPressed: (_likes[index] == true)
                                            ? () {
                                          setState(() {
                                            _likes[index] = false;
                                            //like[likeint] = "false";
                                            loading = true;
//                                              likes--;
                                            DatabaseService().unlikepost(
                                                likes, postId,displayNameController.text);
                                            loading = false;
                                          });
                                        }
                                            : () {
                                          setState(() {
                                            _likes[index] = true;
                                            //like[likeint] = "true";
                                            loading = true;
                                            DatabaseService().likepost(
                                                likes, postId,displayNameController.text);
                                            Notification();
                                            loading = false;
                                          });
                                        },
                                        icon: Icon(Icons.thumb_up),
                                        iconSize: 25,
                                        color: (_likes[index] == true) ? Colors.deepPurple : Colors.grey,
                                      ),

                                      Text(
                                        likes.toString(),style: TextStyle(
                                        color: Colors.black,
                                      ),
                                      ),

                                      Padding(
                                        padding: const EdgeInsets.only(top: 3.0),
                                        child: IconButton(

                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context){
                                              return CommentsPage(comments: comments,postId: postId, uid: uid, postImageUrl: url,timestamp: timestamp,displayName: displayName,photoUrl: photoUrlController.text,displayNamecurrentUser: displayNameController.text);
                                            }));
                                          },
                                          icon: Icon(Icons.insert_comment,color: Colors.deepPurpleAccent),
                                        ),
                                      ),

                                      Text(comments.toString()),

                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (context) => UploadImage(ownerPostId: postId,shares: shares,file: File(url),sharedurl: url,ownerdiscription: description,ownerphotourl: photoUrl,ownerdisplayname: displayName,shared: true,cam: cam,)),
                                          );
                                        },
                                        icon: Icon(FontAwesomeIcons.share,color: Colors.deepPurpleAccent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Row(
                                    children: [

                                      Container(
                                        child: RichText(
                                          textAlign: TextAlign.start,
                                          softWrap: true,
                                          overflow: TextOverflow.visible,
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: displayName + "  ",
                                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold,
                                                    fontSize: 18.0),
                                              ),
                                              TextSpan(
                                                text: description,
                                                style: TextStyle(color: Colors.black,fontWeight: FontWeight.normal,
                                                    fontSize: 15.0),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                              ),

                              Container(
                                width: MediaQuery.of(context).size.width,
                                margin: EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                              ),

                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                alignment: Alignment.topLeft,
                                child: Text(
                                  readTimestamp(timestamp.seconds),
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                  ),
                ),
              ],
            )
                : Container(
              padding: EdgeInsets.only(
                top: 40.0,
                left: 30.0,
                right: 30.0,
                bottom: 30.0,
              ),
              height: deviceHeight,
              width: deviceWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  //pageTitle,
                  SizedBox(
                    height: deviceHeight * 0.1,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      image,
                      notificationHeader,
                      //notificationText,
                    ],
                  ),
                ],
              ),
            );
            },
        ),

        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.white,
          child: Icon(FontAwesomeIcons.plusSquare,color: Colors.purple,),
          onPressed: (){
            pickImage();
          },
        ),
      ),
    );


  }
}