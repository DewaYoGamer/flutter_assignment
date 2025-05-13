import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/member_service.dart';
import '../models/member.dart';
import 'package:dio/dio.dart';

class EditAnggotaPage extends StatefulWidget {
  final Member member;
  final List<int>? existingNomorInduks;

  const EditAnggotaPage({
    super.key,
    required this.member,
    this.existingNomorInduks,
  });

  @override
  State<EditAnggotaPage> createState() => _EditAnggotaPageState();
}

class _EditAnggotaPageState extends State<EditAnggotaPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomorIndukController;
  late final TextEditingController _namaController;
  late final TextEditingController _alamatController;
  late final TextEditingController _tglLahirController;
  late final TextEditingController _teleponController;
  bool _isLoading = false;
  String _errorMessage = '';
  final _memberService = MemberService();
  // Track active status
  bool _statusAktif = true;
  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing member data
    _nomorIndukController = TextEditingController(
      text: widget.member.nomorInduk.toString(),
    );
    _namaController = TextEditingController(text: widget.member.nama);
    _alamatController = TextEditingController(text: widget.member.alamat);
    _tglLahirController = TextEditingController(text: widget.member.tglLahir);
    _teleponController = TextEditingController(text: widget.member.telepon);
    // Initialize status_aktif
    _statusAktif = widget.member.statusAktif == 1;
  }

  @override
  void dispose() {
    _nomorIndukController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    _tglLahirController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // Client-side validation is already done in the validator
      final int newNomorInduk = int.parse(_nomorIndukController.text);

      Map<String, dynamic> data = {
        // Only include fields that have changed
        if (_nomorIndukController.text != widget.member.nomorInduk.toString())
          'nomor_induk': newNomorInduk,
        if (_namaController.text != widget.member.nama)
          'nama': _namaController.text,
        if (_alamatController.text != widget.member.alamat)
          'alamat': _alamatController.text,
        if (_tglLahirController.text != widget.member.tglLahir)
          'tgl_lahir': _tglLahirController.text,
        if (_teleponController.text != widget.member.telepon)
          'telepon': _teleponController.text,
        // Include status_aktif if changed
        if (_statusAktif != (widget.member.statusAktif == 1))
          'status_aktif': _statusAktif ? 1 : 0,
      };

      // Only update if there are changes
      if (data.isNotEmpty) {
        await _memberService.updateMember(widget.member.id, data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data anggota berhasil diperbarui'), backgroundColor: Colors.green,),
        );
        // Return true to indicate data was updated
        Navigator.of(context).pop(true);
      } else {
        // No changes made
        if (!mounted) return;
        Navigator.of(context).pop(false); // false indicates no changes
      }
    } catch (e) {
      setState(() {
        if (e is DioException) {
          final message = e.response?.data['message'] ?? e.message;

          // Check if error is related to duplicate nomor induk
          if (message.toString().contains('Duplicate entry') &&
              e.response?.statusCode == 405) {
            _errorMessage =
                'Nomor Induk ${_nomorIndukController.text} sudah digunakan oleh anggota lain.';
          } else {
            _errorMessage = 'Error: $message';
          }
        } else {
          _errorMessage = 'Error: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(widget.member.tglLahir) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _tglLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Anggota'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                TextFormField(
                  controller: _nomorIndukController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nomor Induk',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor Induk wajib diisi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Nomor Induk harus berupa angka';
                    }

                    // Check for duplicates if existingNomorInduks was provided and value has changed
                    final newNomorInduk = int.parse(value);
                    if (widget.existingNomorInduks != null &&
                        newNomorInduk != widget.member.nomorInduk &&
                        widget.existingNomorInduks!.contains(newNomorInduk)) {
                      return 'Nomor Induk $newNomorInduk sudah digunakan';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _namaController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alamatController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    border: OutlineInputBorder(),
                  ),
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Alamat wajib diisi'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tglLahirController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: _selectDate,
                  validator:
                      (value) =>
                          value == null || value.isEmpty
                              ? 'Tanggal lahir wajib diisi'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _teleponController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telepon',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telepon wajib diisi';
                    }
                    if (value.length < 10 || value.length > 13) {
                      return 'Telepon harus 10-13 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Status Aktif switch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Status Aktif',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                      ),
                      Switch(
                        value: _statusAktif,
                        onChanged: (value) {
                          setState(() {
                            _statusAktif = value;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Simpan Perubahan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
