import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../core/app_palette.dart';

final _rng = Random();

/// Builds a one-shot explosion (particle burst + expanding shock ring) at
/// [position]. Components auto-remove when their animation finishes.
List<Component> buildExplosion(Vector2 position, double scale) {
  final particle = Particle.generate(
    count: 26,
    lifespan: 0.7,
    generator: (i) {
      final angle = _rng.nextDouble() * pi * 2;
      final speed = (60 + _rng.nextDouble() * 180) * scale;
      final color =
          AppPalette.explosion[_rng.nextInt(AppPalette.explosion.length)];
      return AcceleratedParticle(
        acceleration: Vector2(0, 140),
        speed: Vector2(cos(angle) * speed, sin(angle) * speed),
        child: CircleParticle(
          radius: (2 + _rng.nextDouble() * 4) * scale,
          paint: Paint()..color = color,
        ),
      );
    },
  );

  final ring = CircleComponent(
    radius: 6 * scale,
    anchor: Anchor.center,
    position: position.clone(),
    paint: Paint()
      ..color = AppPalette.accentSecondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale,
  )
    ..add(
      ScaleEffect.to(
        Vector2.all(6),
        EffectController(duration: 0.45, curve: Curves.easeOut),
      ),
    )
    ..add(
      OpacityEffect.fadeOut(
        EffectController(duration: 0.45, curve: Curves.easeOut),
        onComplete: () {},
      ),
    )
    ..add(RemoveEffect(delay: 0.5));

  return [
    ParticleSystemComponent(particle: particle, position: position.clone()),
    ring,
  ];
}
