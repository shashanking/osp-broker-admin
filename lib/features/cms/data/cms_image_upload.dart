import 'package:dio/dio.dart'
    show FormData, MultipartFile, DioMediaType;
import 'package:file_picker/file_picker.dart';

import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

/// Uploads a picked image to the shared admin image-upload endpoint and returns
/// its public S3 URL. Reuses `/shop/upload-image` (admin-only, known-public
/// prefix) so CMS images need no extra bucket-policy change. The backend
/// expects a multipart field named `image` and returns `{ data: { url } }`.
Future<String> uploadCmsImage(BaseApiService api, PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw Exception('Selected image has no data');
  }

  final fileName = file.name;
  final ext =
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  const extToMime = {
    'jpg': 'jpeg',
    'jpeg': 'jpeg',
    'png': 'png',
    'gif': 'gif',
    'webp': 'webp',
  };
  final subtype = extToMime[ext] ?? 'png';

  final formData = FormData.fromMap({
    'image': MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType('image', subtype),
    ),
  });

  final response = await api.post(
    '/shop/upload-image',
    data: formData,
    requireAuth: true,
  );
  return (response.data['data']?['url'] ?? '').toString();
}
