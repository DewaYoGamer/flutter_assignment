import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/member_service.dart';
import 'package:dio/dio.dart';
import 'edit_anggota_page.dart';

class MemberDetailPage extends StatefulWidget {
  final Member member;
  final List<int>? existingNomorInduks;

  const MemberDetailPage({
    super.key,
    required this.member,
    this.existingNomorInduks,
  });

  @override
  State<MemberDetailPage> createState() => _MemberDetailPageState();
}

class _MemberDetailPageState extends State<MemberDetailPage> {
  final MemberService _memberService = MemberService();
  bool _isLoading = false;
  bool result = false;
  late Member _member;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Konfirmasi Hapus',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Apakah anda yakin ingin menghapus anggota ${_member.nama}?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Batal',
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
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _deleteAnggota();
    }
  }

  Future<void> _refreshMemberData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedMember = await _memberService.getMemberById(_member.id);
      setState(() {
        _member = updatedMember;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show detailed error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is DioException
                  ? 'Gagal memuat data: ${e.response?.data['message'] ?? e.message}'
                  : 'Gagal memuat data: ${e.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _deleteAnggota() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _memberService.deleteMember(_member.id);
      if (!mounted) return;

      // Show success message and pop back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anggota berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // true indicates data changed
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is DioException
                ? 'Error: ${e.response?.data['message'] ?? e.message}'
                : 'Error: ${e.toString()}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Handle edit button press with proper context management
  Future<void> _handleEditPress() async {
    // Get existingNomorInduks
    List<int> existingNomorInduks = [];

    try {
      if (widget.existingNomorInduks != null) {
        // Use the list passed from landing page
        existingNomorInduks = widget.existingNomorInduks!;
      } else {
        // Fallback to fetching members if not provided
        final members = await _memberService.getMembers();
        existingNomorInduks =
            members
                .where((m) => m.id != _member.id) // exclude current member
                .map((m) => m.nomorInduk)
                .toList();
      }
    } catch (e) {
      if (!mounted) return;

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is DioException
                ? 'Gagal memuat data: ${e.response?.data['message'] ?? e.message}'
                : 'Gagal memuat data: ${e.toString()}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (!mounted) return;

    await _navigateToEditPage(existingNomorInduks);
  }

  // Separate navigation function to avoid context across async gaps
  Future<void> _navigateToEditPage(List<int> existingNomorInduks) async {
    // Perform the navigation
    final navigationResult = await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => EditAnggotaPage(
              member: _member,
              existingNomorInduks: existingNomorInduks,
            ),
      ),
    );

    // Handle the result - set result to true if navigationResult is true
    // otherwise, keep it as false (default value)
    if (navigationResult == true && mounted) {
      result = true;
      // Refresh member data
      await _refreshMemberData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, result);
          },
        ),
        title: const Text('Detail Anggota'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                _isLoading
                    ? null
                    : () async {
                      await _handleEditPress();
                    },
            tooltip: 'Edit Anggota',
          ),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked:(didPop) async {
          if (didPop) {
            return;
          }
          Navigator.pop(context, result);
        },
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                  onRefresh: _refreshMemberData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child:
                              _member.imageUrl != null
                                  ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: NetworkImage(
                                      _member.imageUrl!,
                                    ),
                                  )
                                  : CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      _member.nama[0],
                                      style: const TextStyle(
                                        fontSize: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 24),
                        DetailItem(
                          label: 'Nomor Induk',
                          value: _member.nomorInduk.toString(),
                        ),
                        DetailItem(label: 'Nama', value: _member.nama),
                        DetailItem(label: 'Alamat', value: _member.alamat),
                        DetailItem(
                          label: 'Tanggal Lahir',
                          value: _member.tglLahir,
                        ),
                        DetailItem(label: 'Telepon', value: _member.telepon),
                        Row(
                          children: [
                            Text(
                              'Status Aktif:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Padding(padding: EdgeInsets.only(left: 16.0)),
                            Text(
                              _member.statusAktif == 1
                                  ? 'Aktif'
                                  : 'Tidak Aktif',
                              style: TextStyle(
                                fontSize: 18,
                                color:
                                    _member.statusAktif == 1
                                        ? Colors.green
                                        : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading ? null : _showDeleteConfirmation,
                            icon: const Icon(Icons.delete),
                            label: const Text('Hapus Anggota'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

class DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const DetailItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
