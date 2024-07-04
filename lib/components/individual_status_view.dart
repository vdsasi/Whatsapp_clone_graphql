import 'package:flutter/material.dart';
import 'dart:async';
import 'package:whatsapp_clone/models/status_update.dart';

class StatusViewScreen extends StatefulWidget {
  final List<StatusUpdate> statuses;

  const StatusViewScreen({super.key, required this.statuses});

  @override
  _StatusViewScreenState createState() => _StatusViewScreenState();
}

class _StatusViewScreenState extends State<StatusViewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late int _currentIndex;
  final int _duration = 5; // Duration of each status in seconds

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
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
      if (_currentIndex < widget.statuses.length - 1) {
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
                widget.statuses[_currentIndex].imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text('Error loading image',
                        style: TextStyle(color: Colors.white)),
                  );
                },
              ),
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    child: Row(
                      children: List.generate(
                        widget.statuses.length,
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
                                 const AlwaysStoppedAnimation<Color>(Colors.white),
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
                              widget.statuses[_currentIndex].profilePicture),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.statuses[_currentIndex].name,
                            style: const TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
