precision highp float;
uniform sampler2D Texture;
varying highp vec2 TextureCoordsVarying;

void main() {
    vec2 uv = TextureCoordsVarying.xy;
    if(uv.x <= 1.0 / 4.0){
        uv.x = uv.x + 3.0/8.0;
    }else if(uv.x > 1.0/4.0 && uv.x <= 2.0/4.0){
        uv.x = uv.x + 1.0/8.0;
    }else if(uv.x > 2.0/4.0 && uv.x <= 3.0/4.0){
        uv.x = uv.x - 1.0/8.0;
    }else {
        uv.x = uv.x - 3.0/8.;
    }
    
    if(uv.y <= 1.0 / 4.0){
        uv.y = uv.y + 3.0/8.0 ;
    }else if(uv.y > 1.0/4.0 && uv.y <= 2.0/4.0){
        uv.y = uv.y + 1.0/8.0;
    }else if(uv.y > 2.0/4.0 && uv.y <= 3.0/4.0){
        uv.y = uv.y - 1.0/8.0;
    }else {
        uv.y = uv.y - 3.0/8.0;
    }
    gl_FragColor = texture2D(Texture, uv);
}
