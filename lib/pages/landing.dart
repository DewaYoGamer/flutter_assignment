import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import '../services/auth_service.dart';
import '../notifiers.dart';
import 'login_page.dart';
import 'create_anggota_page.dart';
import 'member_detail_page.dart';

List<Member> _members = [];

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();
  List<Member> _filteredMembers = [];
  bool _isLoading = false;
  bool _isSilentlyRefreshing = false;
  String _errorMessage = '';
  String _searchQuery = '';
  Timer? _refreshTimer;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMembers();

    // Set up a timer to refresh data every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _silentRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Silently refresh data without showing loading state
  Future<void> _silentRefresh() async {
    if (_isSilentlyRefreshing) return;

    _isSilentlyRefreshing = true;
    try {
      final members = await _memberService.getMembers();
      if (mounted) {
        setState(() {
          _members = members;
          _filterMembers();
          _isSilentlyRefreshing = false;
        });
      }
    } catch (e) {
      _isSilentlyRefreshing = false;
      // Don't show errors for background refreshes
    }
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final members = await _memberService.getMembers();
      setState(() {
        _members = members;
        _filterMembers();
        _isLoading = false;
      });
    } catch (e) {
      print(
        "error $e",
      ); // Log the error for debugging without adding a period which creates a new statement
      setState(() {
        if (e is DioException && e.response?.statusCode == 406) {
          // Token expired error (406) - user-friendly message without exposing error code
          _errorMessage = 'Sesi anda telah berakhir. Silakan login kembali.';
        } else {
          // Generic error message that doesn't expose technical details
          _errorMessage = 'Gagal memuat data. Silakan coba lagi.';
        }
        _isLoading = false;
      });
    }
  }

  // Method to handle login redirection
  void _navigateToLogin() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _filterMembers() {
    if (_searchQuery.isEmpty) {
      _filteredMembers = List.from(_members);
      return;
    }

    final query = _searchQuery.toLowerCase();
    _filteredMembers =
        _members.where((member) {
          return member.nama.toLowerCase().contains(query) ||
              member.alamat.toLowerCase().contains(query) ||
              member.telepon.toLowerCase().contains(query) ||
              member.nomorInduk.toString().contains(query);
        }).toList();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterMembers();
    });
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Confirm Logout',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _logout() async {
    _showLogoutConfirmation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Anggota'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: Icon(
              Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              selectedThemeNotifier.value = !selectedThemeNotifier.value;
            },
            tooltip: 'Ganti Tema',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
            color: Theme.of(context).colorScheme.error,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .3),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final existingNomorInduks =
              _members.map((m) => m.nomorInduk).toList();

          final created = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => CreateAnggotaPage(
                    existingNomorInduks: existingNomorInduks,
                  ),
            ),
          );
          if (created == true) {
            _loadMembers();
          }
        },
        tooltip: 'Tambah Anggota',
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      // Check if it's a token expiration error
      final bool isTokenExpired = _errorMessage.contains(
        'Sesi anda telah berakhir',
      );

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (isTokenExpired) ...[
              ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Login'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _loadMembers,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(child: Text('Tidak ada anggota ditemukan'));
    }

    if (_filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil untuk "$_searchQuery"',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _filteredMembers.length,
        itemBuilder: (context, index) {
          final member = _filteredMembers[index];
          return MemberListItem(member: member, onRefresh: _loadMembers);
        },
      ),
    );
  }
}

class MemberListItem extends StatelessWidget {
  final Member member;
  final Function onRefresh;

  const MemberListItem({
    super.key,
    required this.member,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.statusAktif == 1 ? Colors.blue : Colors.grey,
          foregroundColor: Colors.white,
          child: Text(member.nama[0]),
        ),
        title: Text(
          member.nama,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color:
                member.statusAktif == 0
                    ? Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6)
                    : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No. Induk: ${member.nomorInduk}'),
            Text(
              member.statusAktif == 1 ? 'Aktif' : 'Tidak Aktif',
              style: TextStyle(
                color: member.statusAktif == 1 ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          // Get all members for nomor induk validation
          final existingNomorInduks =
              _members.map((m) => m.nomorInduk).toList();

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MemberDetailPage(
                    member: member,
                    existingNomorInduks: existingNomorInduks,
                  ),
            ),
          );

          // If data was changed (edited or deleted), refresh the list
          if (result == true) {
            onRefresh();
          }
        },
      ),
    );
  }
}
