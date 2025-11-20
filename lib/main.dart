import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(const MyApp());
}

// =====================
// 🔹 Widget Tile Gambar
// =====================
class ImageTile extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final VoidCallback onTap;

  const ImageTile({
    super.key,
    this.imagePath,
    this.imageBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageBytes != null) {
      imageWidget = Image.memory(imageBytes!, fit: BoxFit.cover);
    } else if (imagePath != null && imagePath!.isNotEmpty) {
      if (imagePath!.startsWith('assets/')) {
        imageWidget = Image.asset(imagePath!, fit: BoxFit.cover);
      } else {
        imageWidget = Image.file(File(imagePath!), fit: BoxFit.cover);
      }
    } else {
      imageWidget = const Icon(Icons.image_not_supported);
    }

    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: imagePath ?? imageBytes.hashCode.toString(),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(2, 3),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageWidget,
          ),
        ),
      ),
    );
  }
}

// ====================
// 🔹 Halaman Utama
// ====================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Map<String, List<Map<String, dynamic>>> categories = {
    'Pemandangan': [
      {'path': 'assets/images/pic1.jpg'},
      {'path': 'assets/images/pic2.jpg'},
    ],
    'Burung': [
      {'path': 'assets/images/burung1.jpg'},
      {'path': 'assets/images/burung2.jpg'},
    ],
    'Arsitektur': [
      {'path': 'assets/images/arsitektur1.jpg'},
      {'path': 'assets/images/arsitektur2.jpg'},
    ],
  };

  String selectedCategory = 'Pemandangan';

  // ✅ Upload gambar baru (langsung tampil)
  Future<void> _addImageToCategory() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // WAJIB untuk Web
    );

    if (result == null) return;

    final file = result.files.first;

    setState(() {
      if (kIsWeb && file.bytes != null) {
        // Untuk Flutter Web
        categories[selectedCategory]?.add({'bytes': file.bytes});
      } else if (file.path != null && file.path!.isNotEmpty) {
        // Untuk Android / iOS
        categories[selectedCategory]?.add({'path': file.path});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = categories[selectedCategory] ?? [];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gallery App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My Gallery'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_a_photo),
              onPressed: _addImageToCategory,
            ),
          ],
        ),
        body: Column(
          children: [
            // 🔸 Pilihan kategori
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: categories.keys.map((category) {
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: Colors.deepPurple,
                      backgroundColor: Colors.grey[300],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // 🔸 Grid Gambar
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final item = images[index];
                  return ImageTile(
                    imagePath: item['path'],
                    imageBytes: item['bytes'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ImageViewerPage(
                            images: images,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================
// 🔹 Viewer + Swipe
// ====================
class ImageViewerPage extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final int initialIndex;

  const ImageViewerPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  void _nextImage() {
    if (currentIndex < widget.images.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevImage() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Image ${currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemBuilder: (context, index) {
              final item = widget.images[index];
              final tag = item['path'] ?? item['bytes'].hashCode.toString();

              Widget imageWidget;
              if (item['bytes'] != null) {
                imageWidget = Image.memory(item['bytes'], fit: BoxFit.contain);
              } else if (item['path'] != null &&
                  item['path'].toString().startsWith('assets/')) {
                imageWidget = Image.asset(item['path'], fit: BoxFit.contain);
              } else {
                imageWidget = Image.file(File(item['path']), fit: BoxFit.contain);
              }

              return Center(child: Hero(tag: tag, child: imageWidget));
            },
          ),

          // Panah kiri
          if (currentIndex > 0)
            Positioned(
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 40),
                onPressed: _prevImage,
              ),
            ),

          // Panah kanan
          if (currentIndex < widget.images.length - 1)
            Positioned(
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 40),
                onPressed: _nextImage,
              ),
            ),
        ],
      ),
    );
  }
}
