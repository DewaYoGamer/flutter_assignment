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
  final TextEditingController _searchController = TextEditingController();
  final MemberService _memberService = MemberService();
  final AuthService _authService = AuthService();
  List<Member> _filteredMembers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    await _authService.debugStoredData();
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
      // Check if it's a token expiration error (status code 406)
      if (e is DioException && e.response?.statusCode == 406) {
        // Try auto-refreshing the token if Remember Me is enabled
        final isRemembered = await _authService.isRememberMeEnabled();
        if (isRemembered) {
          // Attempt to refresh token using stored credentials
          final refreshSuccess = await _authService.refreshToken();
          if (refreshSuccess && mounted) {
            // Token refreshed successfully, try loading members again
            try {
              final members = await _memberService.getMembers();

              if (!mounted) return;

              setState(() {
                _members = members;
                _filterMembers();
                _isLoading = false;
              });
              return;
            } catch (_) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Gagal memuat data. Silakan coba lagi.';
                  _isLoading = false;
                });
              }
            }
          }
        }

        if (mounted) {
          await _authService.clearCredentials();
          await _authService.logout();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat data. Silakan coba lagi.';
            _isLoading = false;
          });
        }
      }
    }
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
        title: const Text('Daftar Anggota'),
        actions: [
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: const Text('Retry'),
            ),
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
        leading: member.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(member.imageUrl!),
              )
            : CircleAvatar(
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
