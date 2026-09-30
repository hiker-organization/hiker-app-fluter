import 'package:flutter/material.dart';

// Round user photo that shows the default profile image while the network photo
// loads or when it fails. CircleAvatar would show its background color instead.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  // Takes precedence over photoUrl, e.g. a photo just picked from the gallery.
  final ImageProvider? image;

  const UserAvatar({super.key, this.photoUrl, required this.radius, this.image});

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final placeholder = Image.asset('assets/img/profile.png', width: size, height: size, fit: BoxFit.cover);
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    final Widget child;
    if (image != null) {
      child = Image(image: image!, width: size, height: size, fit: BoxFit.cover);
    } else if (hasPhoto) {
      child = Image.network(
        photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
            wasSynchronouslyLoaded || frame != null ? child : placeholder,
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    } else {
      child = placeholder;
    }

    return ClipOval(child: SizedBox(width: size, height: size, child: child));
  }
}
