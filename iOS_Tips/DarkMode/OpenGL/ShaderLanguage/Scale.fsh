precision highp float;

uniform sampler2D Texture;
varying vec2 TextureCoordsVarying;

void main (void) {
    vec4 mask = texture2D(Texture, TextureCoordsVarying);
    gl_FragColor = vec4(mask.rgb, 1.0);
}

