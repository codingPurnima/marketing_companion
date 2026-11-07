import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ArtisanDirectoryPage extends StatefulWidget {
  const ArtisanDirectoryPage({super.key});

  @override
  State<ArtisanDirectoryPage> createState() => _ArtisanDirectoryPageState();
}

class _ArtisanDirectoryPageState extends State<ArtisanDirectoryPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> artisansFuture;

  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    artisansFuture = fetchArtisans();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchArtisans() async {
    final response = await supabase
        .from('artisan_profiles')
        .select(
          'user_id, public_name, bio, craft, district, state, whatsapp_number',
        )
        .order('public_name');

    return List<Map<String, dynamic>>.from(response);
  }

  
void openArtisan(Map<String, dynamic> artisan) {
  final route =
      '/?artisan=${Uri.encodeComponent(artisan['user_id'].toString())}';

  debugPrint('NAVIGATING TO: $route');

  Navigator.pushNamed(context, route);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discover Artisans')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: artisansFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Unable to load artisans.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        artisansFuture = fetchArtisans();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final artisans = snapshot.data ?? [];

          final filteredArtisans = artisans.where((artisan) {
            final query = searchQuery.trim().toLowerCase();

            if (query.isEmpty) return true;

            final searchableText = [
              artisan['public_name'],
              artisan['craft'],
              artisan['district'],
              artisan['state'],
            ].where((value) => value != null).join(' ').toLowerCase();

            return searchableText.contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search artisans by name, craft or location...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: filteredArtisans.isEmpty
                    ? const Center(child: Text('No matching artisans found.'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;

                          final columns = width >= 1000
                              ? 3
                              : width >= 600
                              ? 2
                              : 1;

                          return GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: columns == 1 ? 2.4 : 1.7,
                                ),
                            itemCount: filteredArtisans.length,
                            itemBuilder: (context, index) {
                              final artisan = filteredArtisans[index];

                              final location =
                                  [artisan['district'], artisan['state']]
                                      .where(
                                        (value) =>
                                            value != null &&
                                            value.toString().isNotEmpty,
                                      )
                                      .join(', ');

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () => openArtisan(artisan),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            const CircleAvatar(
                                              radius: 24,
                                              child: Icon(Icons.person_outline),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                artisan['public_name'] ??
                                                    'Artisan',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        if (artisan['craft'] != null)
                                          Text(
                                            artisan['craft'],
                                            style: const TextStyle(
                                              color: Colors.brown,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        if (location.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  location,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Spacer(),
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Text('View profile'),
                                            SizedBox(width: 4),
                                            Icon(Icons.arrow_forward, size: 16),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
