varying vec2 vUv;
uniform sampler2D uLegoTexture;
uniform float uSubdivision;

float PI2 = 6.28318530718;

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


void main() {
  vec3 map = texture2D(uLegoTexture, vUv).rgb;


  vec2 uvMap = floor(vUv * uSubdivision ) / uSubdivision + 0.5 / uSubdivision;
  vec3 pixelColor = texture2D(uLegoTexture, uvMap).rgb;
  vec2 uv = fract(vUv * uSubdivision) * 2.0 - 1.0;
  vec3 color = vec3(1.0, 1.0, 1.0);

  // shadow
  float tLine = sdSegment(uv, vec2(0, 0), vec2(-0.15, 0.15));
  float lt = smoothstep(-0.01, 0.02, tLine - 0.63);
  vec3 shadowColor = mix(vec3(0.3), color, pow(lt,0.5));
  shadowColor += smoothstep(0.0, -0.0,sdgCircle(uv, 0.62).x);

  // square
  float tBox = sdgBox(uv, vec2(.93)).x;
  float bt = smoothstep(0.0, -0.05, tBox - 0.07);
  vec3 boxColor = mix(vec3(0.3), color, pow(bt,0.5));

  // circle
  float tCircle = sdgCircle(uv, 0.62).x;
  float ct = smoothstep(0.0, 0.02, tCircle);
  ct += smoothstep(0.0, -0.05, tCircle);
  vec3 circleColor = mix(vec3(0.3), color, pow(ct,0.5));

  color = min(boxColor, circleColor);

  color = min(color, shadowColor);

  // letter L
  float letterL = charL(uv, vec2(-0.357,0.215), vec2(-0.452,-0.205), vec2(-0.31,-0.205), 0.013).r;
  float letterE = charE(uv, vec2(-0.138,0.215), vec2(-0.232,-0.205), vec2(-0.08,-0.205), 0.013).r;
  float letterO = charO(uv, vec2(0.39, 0.15), vec2(0.325, -0.135), 0.068).r;
  float letterG = charG(uv, vec2(0.15,0.15), vec2(0.085,-0.135), 0.013).r;

  float word = min(min(letterL, letterE), min(letterG,letterO - 0.013));
  float lw = smoothstep(0.0, 0.01, word);
  lw += smoothstep(0.0, -0.03, word);
  // color = mix(vec3(1.), vec3(0.0), ltL);
  color = mix(vec3(0.6), color, pow(lw,0.3));

  // color = map * 0.3 + color * .8;
  
  

  gl_FragColor = vec4(color * pixelColor, 1.0);

  #include <tonemapping_fragment>
	#include <colorspace_fragment>
}