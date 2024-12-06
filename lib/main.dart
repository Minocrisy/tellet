import 'package:flutter/material.dart';
import 'services/speech_service.dart';
import 'services/video_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TelleT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  final VideoService _videoService = VideoService();
  
  bool _isListening = false;
  String _transcription = '';
  bool _isGenerating = false;
  String? _videoUrl;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speechService.initialize();
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      
      await _speechService.startListening(
        onResult: (text) {
          setState(() => _transcription = text);
        },
        onDone: () {
          setState(() => _isListening = false);
          if (_transcription.isNotEmpty) {
            _generateVideo();
          }
        },
      );
    } else {
      setState(() => _isListening = false);
      await _speechService.stopListening();
    }
  }

  Future<void> _generateVideo() async {
    if (_transcription.isEmpty) return;
    
    setState(() {
      _isGenerating = true;
      _videoUrl = null;
    });

    try {
      final videoUrl = await _videoService.generateVideo(_transcription);
      
      if (videoUrl != null) {
        setState(() {
          _videoUrl = videoUrl;
          _isGenerating = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to generate video. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isGenerating = false);
      }
    } catch (e) {
      print('Error generating video: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TelleT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Description:',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _transcription.isEmpty 
                        ? 'Tap the microphone and describe what video you want to create...' 
                        : _transcription,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_videoUrl != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Generated Video:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Video URL: $_videoUrl',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Generating your video...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isGenerating ? null : _toggleListening,
        backgroundColor: _isListening 
            ? Colors.red 
            : Theme.of(context).colorScheme.primary,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
