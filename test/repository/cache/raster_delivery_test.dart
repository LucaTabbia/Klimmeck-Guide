import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/cache/raster_delivery.dart';

void main() {
  test('asks Cloudinary for a WebP 1024 px wide instead of the heavy SVG', () {
    expect(
      rasterDeliveryUrl(
        'https://res.cloudinary.com/x/image/upload/v1757660480/main/heal.svg',
      ),
      'https://res.cloudinary.com/x/image/upload/f_webp,w_1024/v1757660480/main/heal.svg',
    );
  });

  test('leaves alone what is not a Cloudinary SVG', () {
    const png = 'https://res.cloudinary.com/x/image/upload/v1/main/map.png';
    const elsewhere = 'https://example.com/icons/arrow.svg';

    expect(rasterDeliveryUrl(png), png);
    expect(rasterDeliveryUrl(elsewhere), elsewhere);
  });
}
