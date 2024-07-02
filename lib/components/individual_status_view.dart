import 'package:flutter/material.dart';
import 'dart:async';
import 'package:whatsapp_clone/models/status_update.dart';

class StatusViewScreen extends StatefulWidget {
  final StatusUpdate status;
  final List<StatusUpdate> allStatuses;
  final int initialIndex;

  StatusViewScreen({
    required this.status,
    required this.allStatuses,
    required this.initialIndex,
  });

  @override
  _StatusViewScreenState createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _currentIndex;
  final int _duration = 5; // Duration of each status in seconds
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _duration),
    );

    _animationController.addListener(() {
      setState(() {});
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _moveToNextStatus();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimation();
    });
  }

  void _startAnimation() {
    _animationController.forward(from: 0.0);
  }

  void _moveToNextStatus() {
    setState(() {
      if (_currentIndex < widget.allStatuses.length - 1) {
        _currentIndex++;
        _animationController.forward(from: 0.0);
      } else {
        // All statuses viewed, close the screen
        Navigator.of(context).pop();
      }
    });
  }

  void _moveToPreviousStatus() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
        _animationController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _animationController.stop(),
        onTapUp: (_) => _moveToNextStatus(),
        onLongPressStart: (_) => _animationController.stop(),
        onLongPressEnd: (_) => _animationController.forward(),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _moveToPreviousStatus();
          } else if (details.primaryVelocity! < 0) {
            _moveToNextStatus();
          }
        },
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                widget.allStatuses[_currentIndex].imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                      child: Text('Error loading image',
                          style: TextStyle(color: Colors.white)));
                },
              ),
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: List.generate(
                        widget.allStatuses.length,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: LinearProgressIndicator(
                              value: index < _currentIndex
                                  ? 1
                                  : (index == _currentIndex
                                      ? _animationController.value
                                      : 0),
                              backgroundColor: Colors.grey[700],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                              widget.allStatuses[_currentIndex].profilePicture),
                          radius: 20,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.allStatuses[_currentIndex].name,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  _buildMessageInput(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.emoji_emotions, color: Colors.white),
            onPressed: () {
              // TODO: Implement emoji picker
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Reply to status...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () {
              // TODO: Implement send message functionality
              print('Sending message: ${_messageController.text}');
              _messageController.clear();
            },
          ),
        ],
      ),
    );
  }
}
