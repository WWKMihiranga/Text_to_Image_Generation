import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Image Generator',
      themeMode: _themeMode,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: ImageGeneration(toggleTheme: _toggleTheme),
    );
  }
}

class ImageGeneration extends StatefulWidget {
  final VoidCallback toggleTheme;
  const ImageGeneration({super.key, required this.toggleTheme});

  @override
  State<ImageGeneration> createState() => _ImageGenerationState();
}

class _ImageGenerationState extends State<ImageGeneration> {
  TextEditingController textController = TextEditingController();
  Uint8List? imageBytes;
  bool isLoading = false;

  Future<void> saveImage() async {
    if (imageBytes == null) return;

    try {
      // Get the application's documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create a subfolder named "TI Generation"
      final tiGenerationDir = Directory('${directory.path}/TI Generation');
      if (!await tiGenerationDir.exists()) {
        await tiGenerationDir.create(recursive: true);
      }

      // Define file path with .webp extension
      final filePath = '${tiGenerationDir.path}/generated_image.webp';
      final file = File(filePath);

      // Write the image bytes
      await file.writeAsBytes(imageBytes!);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image saved to ${file.path}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error saving image: $e");
    }
  }

  void generateImage() async {
    setState(() {
      isLoading = true;
    });
    try {
      final url = Uri.parse(
          'https://api.stability.ai/v2beta/stable-image/generate/ultra');
      final headers = {
        'authorization':
            'Bearer sk-uYwSo3Z74hUYIMjyTI76hL97MbIkWz43YQVfqJEH1vcPcgAW',
        'accept': 'image/*',
      };

      final request = http.MultipartRequest('POST', url)
        ..headers.addAll(headers)
        ..fields['prompt'] = textController.text
        ..fields['output_format'] = 'webp';

      final response = await request.send();
      if (response.statusCode == 200) {
        final bites = await response.stream.toBytes();
        setState(() {
          imageBytes = bites;
        });
      } else {
        print('Failed to generate image');
      }
    } catch (e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.cyanAccent : Colors.blueAccent;
    final buttonColor = isDarkMode ? Colors.cyanAccent : Colors.blueAccent;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
                isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                color: textColor),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Generate Amazing Images',
              style: GoogleFonts.pacifico(
                fontSize: 28,
                color: textColor,
                shadows: isDarkMode
                    ? [
                        Shadow(
                            blurRadius: 8,
                            color: Colors.cyanAccent.withOpacity(0.8))
                      ]
                    : [],
              ),
            ),
            SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color:
                      isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isDarkMode)
                      BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 2),
                  ],
                ),
                child: imageBytes == null
                    ? Image.asset('assets/placeHolderImage.jpg', width: 250)
                    : Image.memory(imageBytes!, width: 250),
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  if (isDarkMode)
                    BoxShadow(
                        color: Colors.cyanAccent.withOpacity(0.2),
                        blurRadius: 10),
                ],
              ),
              child: TextField(
                controller: textController,
                maxLines: 3,
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Describe your image...",
                  hintStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.black54),
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                backgroundColor: buttonColor,
                foregroundColor: isDarkMode ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), // Soft rounded edges
                ),
                elevation: isDarkMode ? 5 : 3, // Slight shadow for depth
                shadowColor: isDarkMode
                    ? Colors.cyanAccent.withOpacity(0.3)
                    : Colors.blueAccent.withOpacity(0.3),
              ),
              onPressed: isLoading
                  ? null // Disable button while loading
                  : () {
                      if (textController.text.isNotEmpty) {
                        generateImage();
                      }
                    },
              child: isLoading
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: isDarkMode ? Colors.black : Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text("Generating..."),
                      ],
                    )
                  : const Text(
                      'Generate Image',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
            if (imageBytes != null) ...[
              SizedBox(height: 15),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                ),
                onPressed: saveImage,
                icon: const Icon(Icons.download),
                label: const Text('Download Image',
                    style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
