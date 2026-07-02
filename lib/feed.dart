import 'dart:convert';

import 'package:anjanitek/utils/api_urls.dart';
import 'package:anjanitek/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:anjanitek/utils/show_toast.dart';
import 'package:anjanitek/utils/constants.dart' as Constants;
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

// Model for Feed Item
class FeedItem {
  final int id;
  final String sender;
  final String name;
  final String role;
  final String sentAt;
  final String message;
  final String media;
  final String category;
  int reactions;

  FeedItem({
    required this.id,
    required this.sender,
    required this.name,
    required this.role,
    required this.sentAt,
    required this.message,
    required this.media,
    required this.category,
    this.reactions = 0,
  });
  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      id: json['id'],
      sender: json['sender'] ?? '0',
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'user',
      sentAt: json['sentAt'] ?? '0 min',
      message: json['message'] ?? '',
      media: json['media'] ?? '',
      category: json['category'] ?? 'general',
      reactions: json['reactions'] ?? 0,
    );
  }
}

// Model for Feed Reaction
class FeedReaction {
  final int id;
  final int feedId;
  final String sender;
  final String sentAt;
  final String message;
  final int type;

  FeedReaction({
    required this.id,
    required this.feedId,
    required this.sender,
    required this.sentAt,
    required this.message,
    required this.type,
  });

  factory FeedReaction.fromJson(Map<String, dynamic> json) {
    return FeedReaction(
      id: json['id'],
      feedId: json['feedId'],
      sender: json['sender'],
      sentAt: json['sentAt'],
      message: json['message'],
      type: json['type'],
    );
  }
}

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedItem> _feedItems = [];
  List<FeedReaction> _feedReactions = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  bool _hasMore = true;
  final int _limit = 20;
  late SharedPreferences prefs;
  String id = '';
  String name = '';
  String sender = '';
  String role = '';
  int isActive = 0;

  @override
  void initState() {
    super.initState();
    getUsers();
    _scrollController.addListener(_onScroll);
  }

  // get user details
    void getUsers() async {
      
        prefs = await SharedPreferences.getInstance();

        if(prefs.containsKey(Constants.name)){
          setState(() {
            
            name = prefs.get(Constants.name) as String;
            id = prefs.get(Constants.id) as String;
            sender = prefs.get(Constants.id) as String;
            role = prefs.get(Constants.role) as String;
            isActive = prefs.get(Constants.isActive) as int;
            
          });
        } 
        _fetchInitialData();
    }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Trigger load when user is 200px from the bottom
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchMoreData();
      }
    }
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMore = true;
    });

    var result = await get(
        Uri.parse(APIUrls.getUrl("${APIUrls.feed}${APIUrls.pass}/1/$_currentPage", {})),
        headers: {"Accept": "application/json"},
      );
      var jsonString = jsonDecode(result.body); 
      var jsonObject = jsonString as Map; 
      
      if(jsonObject['status'] == 200){
          var showData = jsonObject['data'] as List;
          var reactionsData = jsonObject['reactions'] as List;

          setState(() {
            _feedItems = showData.map<FeedItem>((json) => FeedItem.fromJson(json)).toList();
            _feedReactions = reactionsData.map<FeedReaction>((json) => FeedReaction.fromJson(json)).toList();
            _hasMore = showData.length >= _limit;
            _isLoading = false;
          });
      }
      else {
        setState(() {
          _isLoading = false;
        });
      }
  }

  Future<void> _fetchMoreData() async {
    if (!_hasMore || _isLoading) return;

    setState(() => _isLoading = true);
    _currentPage += _limit;

    var result = await get(
        Uri.parse(APIUrls.getUrl("${APIUrls.feed}${APIUrls.pass}/1/$_currentPage", {})),
        headers: {"Accept": "application/json"},
      );
      var jsonString = jsonDecode(result.body); 
      var jsonObject = jsonString as Map; 
      
      if(jsonObject['status'] == 200){
          var showData = jsonObject['data'] as List;
          var reactionsData = jsonObject['reactions'] as List;
          setState(() {
            _feedItems.addAll(showData.map<FeedItem>((json) => FeedItem.fromJson(json)).toList());
            _feedReactions.addAll(reactionsData.map<FeedReaction>((json) => FeedReaction.fromJson(json)).toList());
            _hasMore = showData.length >= _limit;
            _isLoading = false;
          });
      }
      else {
        setState(() {
          _isLoading = false;
        });
      }
  }


  void _showPostBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostBottomSheet(name: name, sender: sender, role: role, onPostSuccess: (newItem) {
        setState(() {
          _feedItems.insert(0, newItem);
        });
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text('Feed', style: GoogleFonts.montserrat(textStyle: Theme.of(context).textTheme.headlineSmall, fontWeight: FontWeight.bold), ),
        actions: [
          // IconButton(
          //   icon: const HugeIcon(icon: HugeIcons.strokeRoundedAdd01, color: Colors.black, size: 28),
          //   onPressed: _showPostBottomSheet,
          // ),
          
          (role.toLowerCase() == Constants.superAdmin.toLowerCase() || role.toLowerCase() == Constants.globalAdmin.toLowerCase() ) 
          ? 
          ElevatedButton(
            style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF048563), // Dark background color
            foregroundColor: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Smaller padding
            // minimumSize: Size(0, 24), // Minimum height
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            ),
            elevation: 2, // Shadow depth
            ),
            onPressed: _showPostBottomSheet,
            child: Text('New Post', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold )), // Smaller font size
          )
          : sizedBox(0),

          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: 
        () => _fetchInitialData(),
        child: 
      // if. feed is empty show a text "No feed items yet"
      _feedItems.isEmpty && !_isLoading
      ? Center(
        child:
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 16,
          children: [
            HugeIcon( 
              icon: HugeIcons.strokeRoundedInbox,
              color: Colors.grey.shade300,
              size: 40,
            ),
            Text(
              "No feed items yet",
              style: GoogleFonts.montserrat(
                textStyle: Theme.of(context).textTheme.bodyLarge,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            )
            ],
          )
          
        )
      : 
      ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 180),
        itemCount: _feedItems.length + (_isLoading ? 1 : 0),
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          if (index < _feedItems.length) {
            return FeedCard(item: _feedItems[index], currentUserId: id, reactions: _feedReactions,);
          } else {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
            );
          }
        },
      ),
      ),
    );
  }
}

class FeedCard extends StatefulWidget {
  final FeedItem item;
  final String currentUserId;
  final List<FeedReaction> reactions;
  const FeedCard({super.key, required this.item, required this.currentUserId, required this.reactions});

  @override
  State<FeedCard> createState() => _FeedCardState();
}

class _FeedCardState extends State<FeedCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isReacting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // CircleAvatar(radius: 22, backgroundImage: NetworkImage(item.userAvatar)),
              // const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        Text(widget.item.name, style: GoogleFonts.inter(textStyle: Theme.of(context).textTheme.bodyLarge, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis, maxLines: 1),
                        // const SizedBox(width: 4),
                        widget.item.role.toLowerCase() != 'dealer' ? const Icon(Icons.verified, size: 16, color: Color(0xFF42A5F5)) : const SizedBox.shrink(),
                      ],
                    ),
                    // Calculate the time ago using the sendtAt value which is DateTime string and show in "5 min ago" format
                    Text(
                      (() {
                        try {
                          final DateTime postDate = DateTime.parse(widget.item.sentAt);
                          final Duration difference = DateTime.now().difference(postDate);
                          // if (difference.inDays > 0) return '${difference.inDays} days ago';
                          if (difference.inDays > 0) return DateFormat('d-MMM-yy', 'en_US').format(postDate);
                          if (difference.inHours > 0) return '${difference.inHours} hours ago';
                          if (difference.inMinutes > 0) return '${difference.inMinutes} min ago';
                          return 'just now';
                        } catch (e) {
                          return widget.item.sentAt;
                        }
                      })(),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.item.message,
            style: const TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text('#${widget.item.category}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500)),
          if (widget.item.media!='-') ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.item.media.split(',').length > 1 
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 4, mainAxisSpacing: 4,
                    ),
                    itemCount: widget.item.media.split(',').length.clamp(0, 4),
                    itemBuilder: (context, index) => Image.network('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.item.media.split(',')[index]}.webp?alt=media', fit: BoxFit.cover),
                  )
                : Image.network('https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/${widget.item.media}.webp?alt=media', fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              // on click of the reaction button, show a toast "Reacted to post"
              GestureDetector(
                onTap: 
                // check if current user has already reacted to the current post using the feedId
                // if not then proceed to react
                widget.reactions.any((reaction) => reaction.feedId == widget.item.id && reaction.sender == widget.currentUserId) ? null :
                _isReacting ? null : () async {
                  
                  // add haptic feedback of tap
                  HapticFeedback.selectionClick();

                  setState(() => _isReacting = true);
                  _controller.forward().then((_) => _controller.reverse());
                  
                  try {
                    
                    var result = await get(Uri.parse(APIUrls.getUrl("${APIUrls.feed}${APIUrls.pass}/1.5/${widget.item.id}/${widget.currentUserId}/NULL/1", {})),
                      headers: {"Accept": "application/json"},
                    );
                    var jsonString = jsonDecode(result.body); 
                    var jsonObject = jsonString as Map; 
                    
                    if(jsonObject['status'] == 200){
                      setState(() {
                        widget.item.reactions += 1;

                        // add the reaction details to the reactions list
                        widget.reactions.add(FeedReaction(
                          id: jsonObject['reactionId'] ?? 0,
                          feedId: widget.item.id,
                          sender: widget.currentUserId,
                          sentAt: DateTime.now().toIso8601String(),
                          message: 'NULL',
                          type: 1,
                        ));
                      });
                      showToast(context, "Reaction sent!", Constants.success);
                    } else {
                      showToast(context, "Failed to react", Constants.warning);
                    }
                  } catch (e) {
                    showToast(context, "Error reacting to post", Constants.warning);
                  } finally {
                    setState(() => _isReacting = false);
                  }
                },
                child: Builder(
                  builder: (context) {
                    final hasReacted = widget.reactions.any((reaction) => reaction.feedId == widget.item.id && reaction.sender == widget.currentUserId);
                    final iconColor = hasReacted ? const Color(0xFF048563) : Colors.grey;
                    return _ActionBtn(
                      icon: _isReacting
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: iconColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.grey),
                            ),
                          )
                        : ScaleTransition(
                            scale: _scaleAnimation,
                            child: HugeIcon(icon: HugeIcons.strokeRoundedStar, strokeWidth: hasReacted ? 2 : 1, color: iconColor, size: 22),
                          ),
                      count: widget.item.reactions,
                      isLoading: _isReacting,
                      iconColor: iconColor,
                    );
                  },
                ),
              ),
              // const HugeIcon(icon: HugeIcons.strokeRoundedShare01, color: Colors.grey, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final Widget icon; // Changed from HugeIcon to Widget to support ScaleTransition
  final int count;
  final bool isLoading;
  final Color iconColor;
  const _ActionBtn({required this.icon, required this.count, this.isLoading = false, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 6),
        Text(count.toString(), style: TextStyle(color: iconColor, fontSize: 14)),
      ],
    );
  }
}

class PostBottomSheet extends StatefulWidget {
  final String sender;
  final String name;
  final String role;
  final Function(FeedItem)? onPostSuccess;
  const PostBottomSheet({super.key, required this.sender, required this.name, required this.role, this.onPostSuccess});

  @override
  State<PostBottomSheet> createState() => _PostBottomSheetState();
}

class _PostBottomSheetState extends State<PostBottomSheet> {
  String _selectedCat = 'update';
  final List<String> _cats = ['update', 'circular', 'general'];
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  String? imageUrl = '-';
  bool _isUploading = false;
  bool _isPosting = false;

  // Future<void> _pickImage() async {
  //   final ImagePicker picker = ImagePicker();
  //   final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     setState(() => _selectedImage = File(image.path));
  //   }
  // }

  // Future<String?> _uploadImage(File image) async {
  //   try {
  //     String fileName = 'feed/${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     Reference ref = FirebaseStorage.instance.ref().child(fileName);
  //     await ref.putFile(image);
  //     return await ref.getDownloadURL();
  //   } catch (e) {
  //     return null;
  //   }
  // }


  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    File imageSelected = File(image.path);
                    Navigator.of(context).pop();
                    setState(() {
                        _isUploading = true;
                      });
                    if (imageSelected.lengthSync() > 50000) {
                        // Compress the image
                        final result = await FlutterImageCompress.compressAndGetFile(
                          imageSelected.absolute.path,
                          '${imageSelected.absolute.path}_compressed.webp',
                          minWidth: 512,
                          format: CompressFormat.webp,
                          quality: 30,
                        );
                        if (result != null) {
                          imageSelected = File(result.path);
                        }
                      }
                    setState(() {
                        _selectedImage = File(imageSelected.path);
                    });
                    
                  }
                  
                  await _uploadImage(_selectedImage!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    File imageSelected = File(image.path);
                    Navigator.of(context).pop();
                    setState(() {
                        _isUploading = true;
                      });

                    if (imageSelected.lengthSync() > 50000) {
                        // Compress the image
                        final result = await FlutterImageCompress.compressAndGetFile(
                          imageSelected.absolute.path,
                          '${imageSelected.absolute.path}_compressed.webp',
                          minWidth: 512,
                          format: CompressFormat.webp,
                          quality: 30,
                        );
                        if (result != null) {
                          imageSelected = File(result.path);
                        }
                      }
                    setState(() {
                      _selectedImage = File(imageSelected.path);
                    });
                  }
                  
                  await _uploadImage(_selectedImage!);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(File image) async {
    setState(() {
      _isUploading = true;
    });
    try {
      final storageRef = FirebaseStorage.instanceFor(bucket: "gs://anjanitek-communications.firebasestorage.app").ref();
      // need to create a unique id for the image
      final String id = DateTime.now().millisecondsSinceEpoch.toString();
      final imageRef = storageRef.child('$id.webp');
      await imageRef.putFile(image);
      var _imageUrl = await imageRef.getDownloadURL();
      
      setState(() {
        imageUrl = id;
        // 'https://firebasestorage.googleapis.com/v0/b/anjanitek-communications.firebasestorage.app/o/$id.webp?alt=media';
        // imgName = "${id}-${DateFormat('dd-MM-yyyy').format(_selectedDate)}.webp";
      });
      print('Image uploaded: $imageUrl');
    } catch (e) {
      print('Failed to upload image: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _handlePost({required String sender, required String role}) async {
    if (_messageController.text.trim().isEmpty) {
      showToast(context, "Please enter a message", Constants.warning);
      return;
    }

    setState(() => _isPosting = true);

    try {
      // print("${APIUrls.feed}${APIUrls.pass}/0/$sender/${DateFormat('yyyy-MM-dd hh:mm:ss').format(DateTime.now())}/${_messageController.text}/$imageUrl/$_selectedCat");
      
      var result = await get(
          Uri.parse(APIUrls.getUrl("${APIUrls.feed}${APIUrls.pass}/0/$sender/${_messageController.text}/$imageUrl/$_selectedCat",{})),
          headers: {
            'Content-Type': 'application/json', // Specify the content type
          },
          // body: jsonEncode(paymentItem), // Convert the object to JSON string
        );

        // print(result.body);
        // Decode the JSON string into a Map using the jsonDecode function
        var jsonString = jsonDecode(result.body); 
        
        // convert jsonString to Map
        var jsonObject = jsonString as Map; 
        
      // check if the api returned success
      if (jsonObject['status'] == 200) {
        
        // add the feed item to the top of the feed list
        final newItem = FeedItem(
          id: jsonObject['id'],
          sender: widget.sender,
          name: widget.name,
          role: widget.role,
          sentAt: DateTime.now().toIso8601String(),
          message: _messageController.text,
          media: imageUrl ?? '-',
          category: _selectedCat,
          reactions: 0,
        );
        widget.onPostSuccess!(newItem);
        
        showToast(context, "Posted successfully", Constants.success);

        Navigator.pop(context);
      } else {
        showToast(context, "Failed to post", Constants.warning);
      }
    } catch (e) {
      showToast(context, "An error occurred", Constants.warning);
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('New post', style: GoogleFonts.inter(textStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 20))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: _isPosting ? null : () => _handlePost(sender: widget.sender, role: widget.role),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF048563), shape: const StadiumBorder()),
                  child: _isPosting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            TextField(
              controller: _messageController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(hintText: "What's on your mind?", border: InputBorder.none),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 14,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: () => setState(() => _selectedImage = null),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _cats.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    backgroundColor: Colors.white,
                    label: Text('#$c'),
                    selected: _selectedCat == c,
                    onSelected: (s) => setState(() => _selectedCat = c),
                    selectedColor: const Color(0x33048563),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _isUploading ? 
                // show a circular progress indicator
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                :
                 IconButton(onPressed: _pickImage, icon: const HugeIcon(icon: HugeIcons.strokeRoundedImage01, color: Colors.black)),
                // IconButton(onPressed: () {}, icon: const HugeIcon(icon: HugeIcons.strokeRoundedLocation01, color: Colors.black)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}