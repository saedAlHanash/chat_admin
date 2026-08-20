class CompressConfig {
  final int quality;
  final int percentage; // 0-100
  final String format; // e.g., 'jpg', 'mp4', 'mp3'

  const CompressConfig({
    this.quality = 80,
    this.percentage = 70,
    this.format = '',
  });
}

class ImageCompressConfig extends CompressConfig {
  final int maxWidth;
  final int maxHeight;

  const ImageCompressConfig({
    int quality = 80,
    String format = 'jpg',
    this.maxWidth = 1024,
    this.maxHeight = 1024,
  }) : super(quality: quality, format: format);
}

class VideoCompressConfig extends CompressConfig {
  final bool includeAudio;
  final String frameRate;

  const VideoCompressConfig({
    int quality = 80,
    this.includeAudio = true,
    this.frameRate = '30',
  }) : super(quality: quality);
}
