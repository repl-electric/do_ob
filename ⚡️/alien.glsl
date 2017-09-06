#define PI 3.1415926535

uniform float iBeat;
uniform float iR;
uniform float iG;
uniform float iB;
uniform float iMode;
uniform float iMotion;

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

float random2d(vec2 n) {
    return fract(sin(dot(n, vec2(129.9898, 4.1414))) * 2398.5453);
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
  if(iMode == 1.0){
    gp = floor(coord / size * (4*(sin(iBeat*0.003)*0.5+0.5)));
  }
  else{
    gp = floor(coord / size * 4);
  }
  float cubic = clamp(80.0,1.2, 100.0);
  vec2 rp = floor(fract(coord / size) * cubic); // repeated
  vec2 odd = fract(rp * 0.5) * 1.;
  float rnd = random2d(gp);
  float c = max(odd.x, odd.y) * step(0.5, rnd); // random lines
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

  float cellRand;
  vec2 ij;
  for(int i = 0; i <= maxSubdivisions; i++) {
    ij = getCellIJ(uv, dims);
    cellRand = random2d(ij);
    dims *= 2.0;
    //decide whether to subdivide cells again
    float cellRand2 = random2d(ij + 454.4543);
    if (cellRand2 > 0.3){
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
  float odds = 0.1;
  if (cellRand < odds){
    b = 0.0;
  }

  vec4 c = vec4(b*(iR-gl_Color.x),
                b*(iB-gl_Color.y),
                b*(iG-gl_Color.z),1.0);
  gl_FragColor = lineDistort(c, uv);
  //gl_FragColor = c;
}