/// Il backend ha risposto 2xx senza un `url` utilizzabile (es. errore Cloudinary).
class ImageUploadException implements Exception {
  const ImageUploadException();
}
