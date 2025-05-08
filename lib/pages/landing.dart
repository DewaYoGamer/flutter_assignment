import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import './detailpage.dart';
import '../notifiers.dart';

class Landing extends StatefulWidget {
  const Landing({super.key});

  @override
  State<Landing> createState() => Gallery();
}

class Gallery extends State<Landing> {
  final SearchController _searchController = SearchController();
  final String apiKey =
      '59U4EPCPSBeRcfwAeX9pWLugRxxf52I78bbL5xmkKV1P8RHMrlmvUjaC';
  List<dynamic> photos = [];
  final Dio dio = Dio();
  bool isLoading = false;
  bool hasSearched = false;
  int page = 1;

  Future<void> fetchPhotos(String query, {int? pageNumber}) async {
    setState(() {
      isLoading = true;
      hasSearched = true;
      if (pageNumber != null) {
        page = pageNumber;
      }
    });

    final url =
        'https://api.pexels.com/v1/search?query=$query&per_page=21&page=$page';

    try {
      final response = await dio.get(
        url,
        options: Options(
          headers: {
            'Authorization': apiKey,
          },
        ),
      );
      if (response.statusCode == 200) {
        setState(() {
          photos = response.data['photos'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load photos');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to fetch photos');
    }
  }

  void nextPage() {
    if (photos.isNotEmpty) {
      fetchPhotos(_searchController.text, pageNumber: page + 1);
    }
  }

  void previousPage() {
    if (page > 1) {
      fetchPhotos(_searchController.text, pageNumber: page - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pexels Gallery',
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              selectedThemeNotifier.value = !selectedThemeNotifier.value;
            },
            tooltip: 'Ganti Tema',
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            SearchBar(
              controller: _searchController,
              hintText: 'Search for images...',
              hintStyle: WidgetStatePropertyAll(const TextStyle(
                color: Colors.grey,
              )),
              onSubmitted: (query) {
                if (query.isNotEmpty) {
                  fetchPhotos(query);
                }
              },
              leading: const Icon(Icons.search),
              trailing: [
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : photos.isEmpty
                      ? Center(
                          child: Text(hasSearched
                              ? 'No images found for your search term.'
                              : 'Please enter a search term to find images.', style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                              ),))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: photos.length,
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailPage(
                                        imageUrl: photo['src']['original'], 
                                        imageDescription: photo['alt'],
                                        photographerName: photo['photographer']),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  photo['src']['medium'],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (hasSearched && photos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: page > 1 ? previousPage : null,
                      child: const Icon(Icons.arrow_back),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$page',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: photos.isNotEmpty ? nextPage : null,
                      child: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
