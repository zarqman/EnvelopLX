/* fBM thanks to:
 *
 * thebookofshaders.com, by Patricio Gonzalez Vivo
 * https://thebookofshaders.com/13/
 *
 * Domain Warping and fBM, by Inigo Quilez
 * https://www.iquilezles.org/www/articles/warp/warp.htm
 * https://www.iquilezles.org/www/articles/fbm/fbm.htm
 *
 * Code made, adapted, modified and merged by Giovanni Muzio - Kesson
 * https://kesson.io
 */

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 iResolution;        // The screen resolution
uniform float iTime;             // time
uniform float size;             // The amount of fBM
uniform float brightness;       // The base brightness of the fBM
uniform float warping_speed_1;  // Warping speed of the horizontal parameter of the second layer of warping
uniform float warping_speed_2;  // Warping speed of the vertical parameter of the second layer of warping
uniform vec3 colorA;         // The second color to mix in the warping
uniform vec3 colorB;        // The last color to mix the warping

#define PI 3.14159265359
#define NUM_OCTAVES 4

//	<https://www.shadertoy.com/view/4dS3Wd>
//	By Morgan McGuire @morgan3d, http://graphicscodex.com
//
float hash(float n) { return fract(sin(n) * 1e4); }
float hash(in vec2 _st) { return fract(sin(dot(_st.xy, vec2(12.9898,78.233)))* 43758.5453123); }

float noise(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash(i), hash(i + 1.0), u);
}

float noise(vec2 x) {
	vec2 i = floor(x);
	vec2 f = fract(x);

	// Four corners in 2D of a tile
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));

	// Simple 2D lerp using smoothstep envelope between the values.
	// return vec3(mix(mix(a, b, smoothstep(0.0, 1.0, f.x)),
	//			mix(c, d, smoothstep(0.0, 1.0, f.x)),
	//			smoothstep(0.0, 1.0, f.y)));

	// Same code, with the clamps in smoothstep and common subexpressions
	// optimized away.
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

float fbm( in vec2 x) {    
    // float G = exp2(-H);
    float f = 1.0;
    float a = brightness;
    float t = 0.0;
    for( int i=0; i < NUM_OCTAVES; i++ ) {
        t += a*noise(vec2(f*x));
        f *= 2.0;
        a *= 0.25;
    }
    return t;
}

void main(void) {
    vec2 st = (gl_FragCoord.xy/iResolution.xy)*size;

    vec3 color = vec3(0.0);

    // First layer of warping
    vec2 q = vec2(fbm( st + vec2(0.01)*iTime ),
             fbm( st + vec2(5.2,1.3) ) );

    // Second layer of warping
    vec2 r = vec2(fbm( st + 16.0 * q + vec2(1.7, 9.2) + warping_speed_1 * iTime ),
             fbm( st + 16.0 * q + vec2(8.3, 2.8) + warping_speed_2 * iTime ) );

    float f = fbm(st + r);

    color = vec3(0.0);
    color = mix(color, colorA,clamp(length(q)*1.0,0.0,1.0));
    color = mix(color, colorB, clamp(length(r.x),0.0,1.0));

    gl_FragColor = vec4((f*f*f+0.5*f*f+0.5*f)*color,1.0);
}