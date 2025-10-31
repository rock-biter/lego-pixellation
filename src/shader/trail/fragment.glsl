#include ../perlin.glsl;

float PI = 3.14159;

uniform vec2 uResolution;
uniform sampler2D uMap;
uniform vec2 uUVPointer;
uniform vec2 uPointerSpeed;
uniform float uDt;
uniform float uTime;
uniform float uSize;

varying vec2 vUv;

void main() {
  vec2 uv = gl_FragCoord.xy / uResolution;
  vec2 texel = vec2(1.0) / uResolution;

  // trail color
  float texelScale = uDt * 30.;
  texel *= texelScale;

  vec3 mapColor = texture(uMap,uv).rgb;
  vec3 mapColor1 = texture(uMap,uv + texel).rgb;
  vec3 mapColor2 = texture(uMap,uv - texel).rgb;
  vec3 mapColor3 = texture(uMap,uv + texel * vec2(-1,1)).rgb;
  vec3 mapColor4 = texture(uMap,uv + texel * vec2(1,-1)).rgb;
  vec3 mapMix = (mapColor1 + mapColor2 + mapColor3 + mapColor4) / 4.0;
  vec3 mapMin = min(min(mapColor1,mapColor2), min(mapColor3, mapColor4));

  vec2 height = mapColor.gb;

  // if(mapMix.r < mapColor.r) {
  //   mapColor = (mapMix + mapMin) / 2.;
  // } else {
    mapColor = mapMin;
  // }
  mapColor *= 1.0 - uDt * 0.1;

  // uv -= 0.5;
  // uv *= 2.0;
  // uv.x *= uResolution.x / uResolution.y;

  float d = distance(uv, uUVPointer);
  // float d2 = d;
  d += cnoise(vec3(uv * 1., uTime)) * 0.5 * uSize;
  d += cnoise(vec3(uv * 5. + 100., uTime)) * 0.5 * uSize;

  float maxSpeed = 0.5;

  vec2 speed = clamp(uPointerSpeed * 2.,vec2(-maxSpeed),vec2(maxSpeed));

  float t = pow(smoothstep(uSize,0.00,d ),1.2);
  vec3 color = mix(mapColor, vec3(1.0), t );

  // ripple effect
  // float height = mapColor.b;

  texelScale = uDt * 200.;

  vec3 north = texture(uMap,uv + vec2(0.0,texel.y * texelScale)).rgb;
  vec3 south = texture(uMap,uv + vec2(0.0,-texel.y * texelScale)).rgb;
  vec3 east = texture(uMap,uv + vec2(texel.x * texelScale,0.0)).rgb;
  vec3 west = texture(uMap,uv + vec2(-texel.x * texelScale,0.0)).rgb;

  float newHeight = (( north.g + south.g + east.g + west.g ) * 0.5 - height.y) * (1. - uDt * 0.1);

  

  float cursorSize = 0.005 + length(speed) * 0.01;

  float s = 1.0 - smoothstep(0.0,cursorSize,d);

  float mousePhase = clamp( length( ( uv - vec2( 0.5 ) ) * 1. - vec2( uUVPointer.x, uUVPointer.y ) * 0.5 ) * PI / 2., 0.0, PI );
	newHeight += ( cos( mousePhase ) + 1.0 ) * max(0.001,length(speed)) * s;

  newHeight = clamp(newHeight, 0., 3.);

  gl_FragColor = vec4(color.r,newHeight,height.x, 1.0);

}