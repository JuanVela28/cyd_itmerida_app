import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

class InstitutionalLogos extends StatelessWidget {
  /// Altura de los logotipos.
  final double height;

  final bool withBackground;

  const InstitutionalLogos({
    super.key,
    this.height = 48,
    this.withBackground = false,
  });

  /// Convierte los colores oscuros en transparencia y conserva los detalles claros en color blanco.
  static const ColorFilter _whiteLogoFilter = ColorFilter.matrix(<double>[
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0.2126,
    0.7152,
    0.0722,
    0,
    0,
  ]);

  Widget _buildLogo(String assetPath, String description) {
    return ColorFiltered(
      colorFilter: _whiteLogoFilter,
      child: SvgPicture.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        semanticsLabel: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logos = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logotipo TecNM.
          _buildLogo(
            'assets/images/logo_tecnm.svg',
            'Tecnológico Nacional de México',
          ),

          // Escudo ITM.
          _buildLogo(
            'assets/images/logo_itm_white.svg',
            'Instituto Tecnológico de Mérida',
          ),
        ],
      ),
    );

    // En fondos guinda no se necesita decoración adicional.
    if (!withBackground) {
      return logos;
    }

    // Permite utilizar logotipos blancos en pantallas claras.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryGuinda,
        borderRadius: BorderRadius.circular(12),
      ),
      child: logos,
    );
  }
}
