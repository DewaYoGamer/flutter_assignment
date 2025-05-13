import 'package:dio/dio.dart';
import '../models/member.dart';
import 'api_service.dart';

class MemberService {
  final ApiService _apiService = ApiService();

  MemberService();
  Future<List<Member>> getMembers() async {
    try {
      final response = await _apiService.get('anggota');

      if (response.statusCode == 200) {
        final List<dynamic> members = response.data['data']['anggotas'];
        return members.map((json) => Member.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load members: ${response.statusCode}');
      }
    } on DioException {
      rethrow;
    }
  }

  Future<Member> getMemberById(int id) async {
    try {
      final response = await _apiService.get('anggota/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = response.data['data']['anggota'];

        return Member.fromJson(dataMap);
      } else {
        throw Exception('Failed to load member: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error fetching member: ${e.message}');
    }
  }

  Future<void> createMember(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('anggota', data);
      if (response.statusCode != 200) {
        throw Exception('Failed to create member: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error creating member: ${e.message}');
    }
  }

  // Update member information
  Future<void> updateMember(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.patch('anggota/$id', data);
      if (response.statusCode != 200) {
        throw Exception('Failed to update member: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error updating member: ${e.message}');
    }
  }

  // Delete a member
  Future<void> deleteMember(int id) async {
    try {
      final response = await _apiService.delete('anggota/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete member: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Error deleting member: ${e.message}');
    }
  }

  // Check if a member has been updated since last fetch
  Future<bool> hasMemberUpdated(Member cachedMember) async {
    try {
      final Member latestMember = await getMemberById(cachedMember.id);

      // Compare relevant fields to determine if there was an update
      return cachedMember.nama != latestMember.nama ||
          cachedMember.alamat != latestMember.alamat ||
          cachedMember.telepon != latestMember.telepon ||
          cachedMember.tglLahir != latestMember.tglLahir ||
          cachedMember.nomorInduk != latestMember.nomorInduk ||
          cachedMember.statusAktif != latestMember.statusAktif;
    } catch (_) {
      // If we can't fetch the member, assume it has been updated or deleted
      return true;
    }
  }
}
