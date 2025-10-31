
varying vec2 vUv;
uniform sampler2D uLegoTexture;
uniform sampler2D uAvatarTexture;
uniform sampler2D uTrailTexture;
uniform float uSubdivision;
uniform float uLightAngle;

float PI2 = 6.28318530718;

float rand(vec2 co) {
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec3 sdgCircle( in vec2 p, in float r ) 
{
    float d = length(p);
    return vec3( d-r, p/d );
}

vec3 sdgBox( in vec2 p, in vec2 b )
{
    vec2 w = abs(p)-b;
    vec2 s = vec2(p.x<0.0?-1:1,p.y<0.0?-1:1);
    float g = max(w.x,w.y);
    vec2  q = max(w,0.0);
    float l = length(q);
    return vec3(   (g>0.0)?l  :g,
                s*((g>0.0)?q/l:((w.x>w.y)?vec2(1,0):vec2(0,1))));
}

float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
    vec2 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h );
}

float sdArc( in vec2 p, in vec2 sc, in float ra, float rb )
{
    // sc is the sin/cos of the arc's aperture
    p.x = abs(p.x);
    return ((sc.y*p.x>sc.x*p.y) ? length(p-sc*ra) : 
                                  abs(length(p)-ra)) - rb;
}

vec3 smin( in vec3 a, in vec3 b, in float k )
{
    k *= 4.0;
    float h = max(k-abs(a.x-b.x),0.0);
    float m = 0.25*h*h/k;
    float n = 0.50*  h/k;
    return vec3( min(a.x,  b.x) - m, 
                 mix(a.yz, b.yz, (a.x<b.x)?n:1.0-n) );
}

// Funzione per ruotare un vec2 dato un angolo in radianti
vec2 rotate2D(vec2 v, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

vec3 charL(in vec2 p, in vec2 a, in vec2 b, in vec2 c, in float r) {

  float d1 = sdSegment(p, a, b);
  float d2 = sdSegment(p, b, c);

  // return vec3(d1);
  return min(vec3(d1), vec3(d2)) - r;
}

vec3 charE(in vec2 p, in vec2 a, in vec2 b, in vec2 c, in float r) {

  float h = a.y - b.y;
  float x = a.x - b.x;

  float d1 = sdSegment(p, a, b);
  float d2 = sdSegment(p, b, c);
  float d3 = sdSegment(p, b + vec2(x, h), c + vec2(x, h));
  float d4 = sdSegment(p, b + vec2(x * 0.5, h * 0.5), c + vec2(x * 0.5, h * 0.5));

  vec3 char = min(vec3(d1), vec3(d2));
  char = min(char, vec3(d3));
  char = min(char, vec3(d4));

  // return vec3(d1);
  return char - r;
}


vec3 charO( in vec2 p, in vec2 a, in vec2 b, in float r )
{
    float s = abs(sdSegment(p, a, b) - r);
    return vec3(s);
}

vec3 charG(in vec2 p, in vec2 a, in vec2 b, in float r) {
  vec2 x = vec2(-0.069,0.0);
  vec2 y = vec2(0.0,0.01);
  vec2 c = a - x - vec2(a - b) * 0.5;

  float d1 = sdSegment(p, a + x + y, b + x + y);
  float d2 = sdSegment(p, c, b - x -  y  );
  float d3 = sdSegment(p, c, c + x * 0.6);

  float alpha = PI2 * 0.25;
  float a1 = sdArc(rotate2D(p - a, PI2 * 0.03), vec2(sin(alpha), cos(alpha)), 0.0695, 0.00);
  float a2 = sdArc(rotate2D(p - b , PI2 * 0.5 + PI2 * 0.03), vec2(sin(alpha), cos(alpha)), 0.0695, 0.00);
  // float a1 = sdArc(a, b, 0.02, 0.03);

  float char = min(d1,d2);
  char = min(char, d3);
  char = min(char, a1);
  char = min(char, a2);

  return vec3(char) - r;
}

float lego(in vec2 uv, in vec2 l1, in vec2 l2, in vec2 l3, in vec2 e1, in vec2 e2, in vec2 e3, in vec2 g1, in vec2 g2, in vec2 o1, in vec2 o2, in float w, in float r  ) {
  float letterL = charL(uv, l1, l2, l3, w).r;
  float letterE = charE(uv, e1, e2, e3, w).r;
  float letterG = charG(uv, g1, g2, w).r;
  float letterO = charO(uv, o1, o2, r).r;

  float word = min(min(letterL, letterE), min(letterG,letterO - w));

  return word;
}


void main() {
  vec3 map = texture2D(uLegoTexture, vUv).rgb;
  vec3 avatar = texture2D(uAvatarTexture, vUv).rgb;

  float pixelSizeX = fwidth(vUv.x);
  float pixelSizeY = fwidth(vUv.y);

  vec2 uvOffset = vec2(pixelSizeX, pixelSizeY);

  vec2 uvMap = floor(vUv * uSubdivision ) / uSubdivision + 0.1 / uSubdivision;
  vec3 pixelColor = texture2D(uAvatarTexture, uvMap).rgb;
  vec3 trail = texture2D(uTrailTexture, uvMap).rgb;
  vec2 uv = fract(vUv * uSubdivision) * 2.0 - 1.0;
  vec3 color = vec3(1.0, 1.0, 1.0);

  // shadow
  vec2 lightDirection = rotate2D(vec2(1., 0.0), uLightAngle);
  float tLine = sdSegment(uv, vec2(0, 0), lightDirection * 0.2);
  float lt = smoothstep(-0.01, 0.02, tLine - 0.63);
  vec3 shadowColor = mix(vec3(0.3), color, pow(lt,0.5));
  shadowColor += smoothstep(0.0, -0.0,sdgCircle(uv, 0.62).x);

  vec3 light = vec3(0);

  // square
  float tBox = sdgBox(uv, vec2(.93)).x;
  float bt = smoothstep(0.0, -0.05, tBox - 0.07);
  vec3 boxColor = mix(vec3(0.2), color, pow(bt,0.5));

  float rtb = smoothstep(0.0, -0.07, tBox - 0.07);
  rtb *= smoothstep(-0.3, 0., sdgBox(uv - lightDirection * 0.03, vec2(1.1)).x - 0.07);
  light += vec3(1.,1.,1.) * pow(abs(rtb), 3.) * 5.;
  // pixelColor *= clamp(0.0,1.0,1. - (tBox - 0.07));

  

  // circle
  float tCircle = sdgCircle(uv, 0.62).x;
  float ct = smoothstep(0.0, 0.02, tCircle);
  ct += smoothstep(0.0, -0.05, tCircle);
  vec3 circleColor = mix(vec3(0.3), color, pow(ct,0.5));
  color = min(boxColor, circleColor);

  // riflessi circle
  float rtc = smoothstep(0.0, -0.05, tCircle);
  rtc *= smoothstep(-0.3, 0., sdgCircle(uv - lightDirection * 0.08, 0.85).x);
  light += vec3(1.,1.,1.) * pow(rtc, 2.) * 3.;

  color = min(color, shadowColor);

  // letter L
  // float letterL = charL(uv, vec2(-0.357,0.215), vec2(-0.452,-0.205), vec2(-0.31,-0.205), 0.013).r;
  // float letterE = charE(uv, vec2(-0.138,0.215), vec2(-0.232,-0.205), vec2(-0.08,-0.205), 0.013).r;
  // float letterO = charO(uv, vec2(0.39, 0.15), vec2(0.325, -0.135), 0.068).r;
  // float letterG = charG(uv, vec2(0.15,0.15), vec2(0.085,-0.135), 0.013).r;

  float word = lego(uv, vec2(-0.357,0.215), vec2(-0.452,-0.205), vec2(-0.31,-0.205), vec2(-0.138,0.215), vec2(-0.232,-0.205), vec2(-0.08,-0.205),vec2(0.15,0.15), vec2(0.085,-0.135),vec2(0.39, 0.15), vec2(0.325, -0.135), 0.013, 0.068);
  float lw = smoothstep(0.0, 0.01, word);
  lw += smoothstep(0.0, -0.03, word);
  // color = mix(vec3(1.), vec3(0.0), ltL);
  color = mix(vec3(0.6), color, pow(lw,0.5));


  // float rw = lego(uv, vec2(-0.357,0.215), vec2(-0.452,-0.205), vec2(-0.31,-0.205), vec2(-0.138,0.215), vec2(-0.232,-0.205), vec2(-0.08,-0.205),vec2(0.15,0.15), vec2(0.085,-0.135),vec2(0.39, 0.15), vec2(0.325, -0.135), 0.013, 0.068) * 0.2;

  vec2 lOffest = cross(vec3(rotate2D(lightDirection, PI2 * -0.05),0.0),vec3(0.0,0.0,1.0)).xy * 0.015;
  float rw = lego(uv, vec2(-0.357,0.215) + lOffest, vec2(-0.452,-0.205) + lOffest, vec2(-0.31,-0.205) + lOffest, vec2(-0.138,0.215) + lOffest, vec2(-0.232,-0.205) + lOffest, vec2(-0.08,-0.205) + lOffest,vec2(0.15,0.15) + lOffest, vec2(0.085,-0.135) + lOffest,vec2(0.39, 0.15) + lOffest, vec2(0.325, -0.135) + lOffest, 0.01, 0.068) * 0.8;

  float rwt = smoothstep(0.0, -0.01, rw);
  rwt = mix( 0.0, rwt, smoothstep(0.0, -0.05, word));
  rwt += smoothstep(0.0, -0.05, word) * 0.15;
  // rwt += smoothstep(0.0, -0.03, rw);

  light += vec3(1.,1.,1.) * pow(rwt, 0.9) * 2.;


  // color = map * 0.3 + color * .8;
  
  // color = boxColor;
  pixelColor = mix(vec3(0.1), pixelColor, pow(bt,0.01));

  color *= 1.0 + rand(vUv * 100.) * 0.3;
  float luminance = dot(pixelColor, vec3(0.299, 0.587, 0.114));
  vec3 c = vec3(.3,0.5,1.);
  pixelColor = mix(pixelColor, vec3(luminance * c * 3.), trail.r);

  gl_FragColor = vec4(color * pixelColor * 1.0 + light * pixelColor * 8., 1.0);

  // gl_FragColor.rgb = trail;

  #include <tonemapping_fragment>
	#include <colorspace_fragment>
}