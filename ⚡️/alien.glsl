#define PI 3.1415926535
#define rand(p) fract(sin(dot(p ,vec2(12.9898,78.233))) * 43758.5453)

uniform float iBeat;
uniform float iR;
uniform float iG;
uniform float iB;
uniform float iMode;
uniform float iMotion;
uniform float iZoom;
uniform float iAlien;
uniform float iHarp;
uniform float iBright;

float random2d(vec2 n) {
    return fract(sin(dot(n, vec2(129.9898, 4.1414))) * 2398.5453);
}

vec4 dots(void){
  float num = 50.;
  vec2 t = gl_FragCoord.xy;
  t /= iResolution.x;
  if(t.x > 0.5){
    t.y += iGlobalTime * 0.006;
  }
  else if(t.x < 0.4){
    t.y -= iGlobalTime * 0.005;
  }
  else{
    t.y -= iGlobalTime * 0.004;
  }
  t *= num;
  float r = rand(floor(t*num)/num);

  return vec4( smoothstep(.5,.6, 1. -length(fract(t) - .5)) * rand(floor(t)/num));
}

vec4 lineDistort(vec4 cTextureScreen, vec2 uv1){
  float sCount = 900.;
  float nIntensity=0.8;
  float sIntensity=0.8;
  float noiseEntry = 0.0001;
  float accelerator= 1000.0;

  // sample the source
  float x = uv1.x * uv1.y * iGlobalTime * accelerator;
  x = mod( x, 13.0 ) * mod( x, 123.0 );
  float dx = mod( x, 0.05 );
  vec3 cResult = cTextureScreen.rgb + cTextureScreen.rgb * clamp( 0.1 + dx * 100.0, 0.0, 1.0 );
  // get us a sine and cosine
  vec2 sc = vec2( sin( uv1.y * sCount ), cos( uv1.y * sCount ) );
  // add scanlines
  cResult += cTextureScreen.rgb * vec3( sc.x, sc.y, sc.x ) * sIntensity;

  // interpolate between source and result by intensity
  cResult = cTextureScreen.rgb + clamp(nIntensity, noiseEntry,1.0 ) * (cResult - cTextureScreen.rgb);

  return vec4(cResult, cTextureScreen.a);
}


#ifdef GL_ES
precision mediump float;
#endif

const float side = 0.3;
const float angle = PI*1.0/3.0;
const float sinA = 0.86602540378;
const float cosA = 0.5;
const vec3 zero = vec3(0.0);
const vec3 one = vec3(1.0);

// generates the colors for the rays in the background
vec4 rayColor(vec2 fragToCenterPos, vec2 fragCoord) {
  float d = length(fragToCenterPos);
  fragToCenterPos = normalize(fragToCenterPos);

  float multiplier = 0.0;
  const float loop = 10.0;
  const float dotTreshold = 0.50;
  const float timeScale = 0.1;
  const float fstep = 1.0;
  float c = 0.5/(d*d);
  float freq = 2.25;
  for (float i = 1.0; i < loop; i++) {
    float attn = c;
    attn *= 1.85*(sin(i*1.0*iHarp)*0.5+0.5);
    float t = iHarp*timeScale - fstep*i;
    vec2 dir = vec2(cos(freq*t), sin(freq*t));
    float m = dot(dir, fragToCenterPos);
    m = pow(abs(m), 32.0);
    m *= float((m) > dotTreshold);
    multiplier += iBright*attn*m/(i);
  }

  float f = abs(cos(iGlobalTime/2.0));

  const vec4 rayColor = vec4(0.2, 0.1, 0.1, 1.0);

  float pat = abs(sin(10.0*mod(fragCoord.y*fragCoord.x, 1.5)));
  f += pat;
  vec4 color = f*multiplier*rayColor;
  return color;
}

vec4 sun(float b) {
  vec4 r = vec4(0.0);
  //if (b > 0.0){
    float aspect = iResolution.x / iResolution.y;
    vec3 pos = vec3(gl_FragCoord.xy / iResolution.xy, 1.0);
    pos.x *= aspect;

    vec2 fragToCenterPos = vec2(pos.x - 0.8*aspect, pos.y - 0.6);
    vec4 rayCol = rayColor(fragToCenterPos,gl_FragCoord.xy);

    float u, v, w;
    float c = 0.0;

    vec4 triforceColor = vec4(0.0);
    r = mix(rayCol, triforceColor, c);
    //}
  return r;
}


vec2 getCellIJ(vec2 uv, float gridDims){
    return floor(uv * gridDims)/ gridDims;
}

vec2 rotate2D(vec2 position, float theta){
    mat2 m = mat2( cos(theta), -sin(theta), sin(theta), cos(theta) );
    return m * position;
}

//Based on https://github.com/keijiro/ShaderSketches/blob/master/Text.glsl by the amazing @keijiro
float letter(vec2 coord, float size){
  vec2 gp;
  if(iMode == 0.0){
    gp = floor(coord / size * (7.0*(sin(iBeat*0.003)*0.5+0.5)));
  }
  else{
    gp = floor(coord / size * 7.0);
  }
  float cubic;

  if(iMode == 0.0){
    cubic = clamp(iZoom,1.2, 20.0); //20
  }else{
    cubic = 7.0;
  }

  vec2 rp;

  if (iMode == 0.0 && rand(vec2(coord.x, coord.y)) > 0.1){
    rp = floor(fract(coord / size) * cubic) +
      clamp(rand(coord.xy+(iGlobalTime)*0.5+0.5), 0.0001, 0.001)*iBeat;
  }
  else{
    rp = floor(fract(coord / size) * cubic); // repeated
  }
  //vec2 rp = floor(fract(coord / size) * cubic)/0.00001*iBeat; // repeated


  float f = clamp(0.5, 0.11,1.0);
  vec2 odd = fract(rp * f) * 1.;
  float rnd = random2d(gp);
  float alienRatio = 0.5;
  if(iMode == 3.0 || iMode == 4.0){
    alienRatio = clamp(iAlien, 0.0,1.0);
  }
  if(iMode == 1.0){
    alienRatio = 1.0;
  }
  if(iMode == 2.0){
    alienRatio = 0.0;
  }

  float c = max(odd.x, odd.y) * step(alienRatio, rnd); // random lines
  c += min(odd.x, odd.y);      // fill corner and center points
  c *= rp.x * (10000. - rp.x); // cropping
  c *= rp.y * (60000. - rp.y);
  return clamp(c, 0., 1.);
}

void main(void){
  vec2 uv = (gl_FragCoord.xy / iResolution.xy) * 1;
  uv.x *= iResolution.x/iResolution.y;
  float t = iGlobalTime;
  float scrollSpeed = clamp(iMotion,0.0,0.05);
  float dims = 2.0;
  int maxSubdivisions = 3;

  uv = rotate2D(uv,PI/60.0); //angle
  uv.y -= iGlobalTime * scrollSpeed;

  float dimsRate = 2.0;
  float cellRandRate = 0.5;

  if(iMode == 4.0){
    cellRandRate = 0.9;
    dimsRate = 2.0;
  }

  float cellRand;
  vec2 ij;
  for(int i = 0; i <= maxSubdivisions; i++) {
    ij = getCellIJ(uv, dims);
    cellRand = random2d(ij);
    dims *= dimsRate;
    float cellRand2 = random2d(ij + 454.4543);
    float subdivide = 0.3;
    if (iMode == 0.0){
      subdivide = iHarp;
    }
    if (cellRand2 > subdivide){
      break;
    }
  }

  //draw letters
  float scale = 1.0;//1.0;
  float b = letter(uv, scale / (dims));

  //fade in
  float scrollPos = iGlobalTime*scrollSpeed + 0.5;
  float showPos = -ij.y + cellRand;
  float fade = smoothstep(showPos ,showPos + 0.05, scrollPos );
  b *= fade;
  float odds = 0.0;//+0.*sin(iGlobalTime)*0.5+0.5;
  if (cellRand < odds){
    b = 0.0;
  }

  if(iHarp > 0.0 && iMode == 0.0){
    //   if(b>0.0){
      float r = sun(b).x;
      b /= r*(iHarp);
      b += r;
      //}
  }

  vec4 blendC = vec4(b*(iR-gl_Color.x), b*(iB-gl_Color.y), b*(iG-gl_Color.z),1.0);
  //vec4 rawC = vec4(vec3(b),1.0);
  //vec4 dr = dots();
  //gl_FragColor = vec4(b-dr.x);
  gl_FragColor = lineDistort(blendC, uv);

  //gl_FragColor = rawC;

  if(b == 1.0 ){
    //gl_FragColor -= dots();
    //    gl_FragColor.x *= sin(iGlobalTime)*10.5+0.5;
    //    gl_FragColor.y *= sin(iGlobalTime)*10.5+0.5;
    //    gl_FragColor.z *= sin(iGlobalTime)*10.5+0.5;
  }
}
