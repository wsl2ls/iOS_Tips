precision mediump float;

varying vec2 TextureCoordsVarying;
uniform sampler2D Texture;
const vec2 TexSize = vec2(400.0, 400.0);
const vec2 mosaicSize = vec2(16.0, 16.0);

void main()
{
    vec2 intXY = vec2(TextureCoordsVarying.x*TexSize.x, TextureCoordsVarying.y*TexSize.y);
    
    vec2 XYMosaic = vec2(floor(intXY.x/mosaicSize.x)*mosaicSize.x, floor(intXY.y/mosaicSize.y)*mosaicSize.y);
    
    vec2 UVMosaic = vec2(XYMosaic.x/TexSize.x, XYMosaic.y/TexSize.y);
    vec4 color = texture2D(Texture, UVMosaic);
    gl_FragColor = color;
}
