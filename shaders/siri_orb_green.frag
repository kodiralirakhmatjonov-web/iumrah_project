// shaders/siri_orb_green.frag
#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2  uSize;
uniform float uTime;      // seconds
uniform float uPress;     // 0..1 (tap/hold animation)

out vec4 fragColor;

float hash21(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

// lightweight smooth noise
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash21(i);
  float b = hash21(i + vec2(1.0, 0.0));
  float c = hash21(i + vec2(0.0, 1.0));
  float d = hash21(i + vec2(1.0, 1.0));
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 rot(float a) {
  float s = sin(a), c = cos(a);
  return mat2(c, -s, s, c);
}

// One "petal layer": ribbon-like wave field
vec3 layerField(vec2 uv, float t, float ang, float freq, float speed, float width, vec3 col) {
  vec2 p = rot(ang) * uv;

  // add organic distortion
  float n = noise(p * 2.0 + vec2(t * 0.15, -t * 0.12));
  p += 0.10 * vec2(
    sin(p.y * 6.0 + t * 0.9 + n * 2.0),
    cos(p.x * 6.0 - t * 0.8 + n * 2.0)
  );

  // ribbon axis along x, thickness by y
  float ribbon = exp(-abs(p.y) / max(0.0001, width));

  // wave intensity across x
  float w = 0.5 + 0.5 * sin(p.x * freq + t * speed + ang * 3.7 + n * 3.0);

  // soften edges and avoid flat bands
  float s = smoothstep(0.15, 1.0, w) * ribbon;

  return col * s;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = (frag - 0.5 * uSize) / min(uSize.x, uSize.y); // center, aspect-safe

  float t = uTime;

  // Circular mask (orb boundary)
  float r = length(uv);
  float orb = 1.0 - smoothstep(0.78, 0.92, r);

  // Outer vignette inside orb to feel like "glass"
  float innerVignette = smoothstep(0.95, 0.35, r);

  // Press makes it slightly "inflate" and brighten
  float pressGlow = 1.0 + uPress * 0.25;

  // Background alpha outside orb = 0
  if (orb <= 0.001) {
    fragColor = vec4(0.0);
    return;
  }

  // Base "glass" tint
  vec3 col = vec3(0.0);

  // 8 layers, each different direction & dynamics
  // Green palette (premium), but with cyan/yellow mix like Siri (still green-family)
  vec3 c0 = vec3(0.10, 1.00, 0.55);
  vec3 c1 = vec3(0.00, 0.85, 0.55);
  vec3 c2 = vec3(0.30, 1.00, 0.85);
  vec3 c3 = vec3(0.70, 1.00, 0.40);
  vec3 c4 = vec3(0.10, 0.55, 1.00) * 0.55; // faint blue tint to enrich mix (still green)
  vec3 c5 = vec3(1.00, 1.00, 0.55) * 0.45; // warm highlight
  vec3 c6 = vec3(0.15, 1.00, 0.25);
  vec3 c7 = vec3(0.00, 0.65, 0.40);

  col += layerField(uv, t, 0.25, 10.5, 1.25, 0.085, c0);
  col += layerField(uv, t, 1.05,  9.0, 1.05, 0.090, c1);
  col += layerField(uv, t, 1.85, 11.0, 0.95, 0.080, c2);
  col += layerField(uv, t, 2.55,  8.5, 1.35, 0.095, c3);
  col += layerField(uv, t, 3.25, 10.0, 1.10, 0.075, c4);
  col += layerField(uv, t, 3.95, 12.0, 0.90, 0.070, c5);
  col += layerField(uv, t, 4.65,  9.5, 1.45, 0.082, c6);
  col += layerField(uv, t, 5.35, 10.8, 1.15, 0.088, c7);

  // Central bloom (Siri core light)
  float core = exp(-dot(uv, uv) * 6.5);
  vec3 coreCol = vec3(1.2, 1.2, 1.2) * 0.55 + vec3(0.15, 1.0, 0.55) * 0.35;
  col += coreCol * core * 1.45;

  // Soft halo (outside-ish)
  float halo = exp(-dot(uv, uv) * 2.2) - exp(-dot(uv, uv) * 10.0);
  col += vec3(0.10, 0.95, 0.55) * halo * 0.75;

  // Additive feel + “glass” shaping
  col *= innerVignette * pressGlow;

  // Gentle highlight ring near edge
  float rim = smoothstep(0.55, 0.90, r) * (1.0 - smoothstep(0.90, 0.94, r));
  col += vec3(0.15, 1.0, 0.75) * rim * 0.25;

  // Tone mapping-ish (avoid overburn)
  col = col / (vec3(1.0) + col);

  // Final alpha inside orb
  float alpha = orb * 0.98;

  fragColor = vec4(col, alpha);
}
