class Member {
  final int id;
  final int nomorInduk;
  final String nama;
  final String alamat;
  final String tglLahir;
  final String telepon;
  final String? imageUrl;
  final int statusAktif;

  Member({
    required this.id,
    required this.nomorInduk,
    required this.nama,
    required this.alamat,
    required this.tglLahir,
    required this.telepon,
    this.imageUrl,
    required this.statusAktif,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      nomorInduk: json['nomor_induk'],
      nama: json['nama'],
      alamat: json['alamat'],
      tglLahir: json['tgl_lahir'],
      telepon: json['telepon'],
      imageUrl: json['image_url'],
      statusAktif: json['status_aktif'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomor_induk': nomorInduk,
      'nama': nama,
      'alamat': alamat,
      'tgl_lahir': tglLahir,
      'telepon': telepon,
      'image_url': imageUrl,
      'status_aktif': statusAktif,
    };
  }
}
