import 'package:flutter/material.dart';
import '../notifiers.dart';

class DetailPage extends StatefulWidget {
  final String imageUrl;
  final String imageDescription;
  final String photographerName;

  const DetailPage(
      {super.key,
      required this.imageUrl,
      required this.imageDescription,
      required this.photographerName});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(NetworkImage(widget.imageUrl), context).then((_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'By: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18.0,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              widget.photographerName,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.0,
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        SizedBox(
                          child:  widget.imageDescription.isNotEmpty ?
                                  Column(
                                    children: [
                                      Text(
                                        'Description:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.0,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 4.0),
                                      Text(
                                        widget.imageDescription.isNotEmpty
                                            ? widget.imageDescription
                                            : 'No description available',
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            color: Theme.of(context).colorScheme.onSurface),
                                      ),
                                    ],
                                  ) : 
                                  Text(
                                    'No description available',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      color: Theme.of(context).colorScheme.onSurface),
                                  ),
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
