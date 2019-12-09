precision highp float;
uniform sampler2D Texture;
varying highp vec2 TextureCoordsVarying;

void main() {
    vec2 uv = TextureCoordsVarying.xy;
    if(uv.x <= 1.0 / 3.0){
        uv.x = uv.x + 1.0/3.0;
    }else if(uv.x > 1.0/3.0 && uv.x <= 2.0/3.0){
        uv.x = uv.x;
    }else {
        uv.x = uv.x - 1.0/3.0;
    }
    
    if(uv.y <= 1.0 / 3.0){
        uv.y = uv.y + 1.0/3.0;
    }else if(uv.y > 1.0/3.0 && uv.y <= 2.0/3.0){
        uv.y = uv.y;
    }else {
        uv.y = uv.y - 1.0/3.0;
    }
    gl_FragColor = texture2D(Texture, uv);
}
