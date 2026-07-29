#version 320 es

#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform float u_press;
uniform float u_refraction;
uniform float u_blur;
uniform float u_dark_background;

uniform sampler2D u_texture_input;

out vec4 frag_color;

vec4 sample_safe(vec2 uv) {
  return texture(u_texture_input, clamp(uv, vec2(0.002), vec2(0.998)));
}

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;

#ifdef IMPELLER_TARGET_OPENGLES
  uv.y = 1.0 - uv.y;
#endif

  vec2 point = (uv - 0.5) * 2.0;
  float radius = length(point);
  float lens = pow(max(0.0, 1.0 - radius), 1.55);
  float edge = smoothstep(0.54, 0.98, radius);

  float pressure = mix(1.0, 1.34, u_press);
  vec2 refraction = point * lens * u_refraction * pressure;
  vec2 refracted_uv = uv - refraction;

  vec2 texel = 1.0 / u_size;
  vec2 blur_step = texel * u_blur * mix(0.72, 1.24, edge);

  vec4 color = sample_safe(refracted_uv) * 0.28;
  color += sample_safe(refracted_uv + vec2(blur_step.x, 0.0)) * 0.12;
  color += sample_safe(refracted_uv - vec2(blur_step.x, 0.0)) * 0.12;
  color += sample_safe(refracted_uv + vec2(0.0, blur_step.y)) * 0.12;
  color += sample_safe(refracted_uv - vec2(0.0, blur_step.y)) * 0.12;
  color += sample_safe(refracted_uv + blur_step) * 0.06;
  color += sample_safe(refracted_uv - blur_step) * 0.06;
  color += sample_safe(refracted_uv + vec2(blur_step.x, -blur_step.y)) * 0.06;
  color += sample_safe(refracted_uv + vec2(-blur_step.x, blur_step.y)) * 0.06;

  vec2 chroma_offset = normalize(point + vec2(0.0001)) *
      texel * mix(0.35, 1.6, edge) * pressure;
  float red = sample_safe(refracted_uv + chroma_offset).r;
  float blue = sample_safe(refracted_uv - chroma_offset).b;
  color.r = mix(color.r, red, edge * 0.15);
  color.b = mix(color.b, blue, edge * 0.15);

  float gray = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
  color.rgb = mix(vec3(gray), color.rgb, 1.10);

  float upper_light = pow(
      max(0.0, dot(normalize(vec3(point, 0.72)), normalize(vec3(-0.58, -0.74, 0.82)))),
      5.0
  );
  float fresnel = pow(edge, 2.15);
  float light_strength = mix(0.075, 0.13, u_dark_background);
  color.rgb += upper_light * light_strength;
  color.rgb += fresnel * mix(0.018, 0.045, u_dark_background);
  color.rgb *= mix(1.0, 0.975, u_press);

  frag_color = vec4(clamp(color.rgb, 0.0, 1.0), color.a);
}
