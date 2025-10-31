vec2 curlNoise(vec2 p) {
    float eps = 0.0001;

    float n1 = cnoise(vec2(p.x, p.y + eps));
    float n2 = cnoise(vec2(p.x, p.y - eps));
    float a = (n1 - n2) / (2.0 * eps);

    float n3 = cnoise(vec2(p.x + eps, p.y));
    float n4 = cnoise(vec2(p.x - eps, p.y));
    float b = (n3 - n4) / (2.0 * eps);

    return normalize(vec2(a, -b));
}

vec3 curlNoise(vec3 p) {
  float e = 0.1;

  float dx1 = cnoise(vec3(p.x, p.y + e, p.z)) - cnoise(vec3(p.x, p.y - e, p.z));
  float dx2 = cnoise(vec3(p.x, p.y, p.z + e)) - cnoise(vec3(p.x, p.y, p.z - e));
  float dy1 = cnoise(vec3(p.x, p.y, p.z + e)) - cnoise(vec3(p.x, p.y, p.z - e));
  float dy2 = cnoise(vec3(p.x + e, p.y, p.z)) - cnoise(vec3(p.x - e, p.y, p.z));
  float dz1 = cnoise(vec3(p.x + e, p.y, p.z)) - cnoise(vec3(p.x - e, p.y, p.z));
  float dz2 = cnoise(vec3(p.x, p.y + e, p.z)) - cnoise(vec3(p.x, p.y - e, p.z));

  float curlX = dy1 - dz2;
  float curlY = dz1 - dx2;
  float curlZ = dx1 - dy2;

  return normalize(vec3(curlX, curlY, curlZ));
}