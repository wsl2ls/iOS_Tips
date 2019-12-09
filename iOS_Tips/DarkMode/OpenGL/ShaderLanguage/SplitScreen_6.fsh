precision highp float;
uniform sampler2D Texture;
varying highp vec2 TextureCoordsVarying;

void main() {
    vec2 uv = TextureCoordsVarying.xy;
   
    if(uv.x <= 1.0 / 3.0){
        uv.x = uv.x + 1.0/3.0;
    }else if(uv.x >= 2.0/3.0){
        uv.x = uv.x - 1.0/3.0;
    }
    
    if(uv.y <= 0.5){
        uv.y = uv.y + 0.25;
    }else {
        uv.y = uv.y - 0.25;
    }
    
    
    gl_FragColor = texture2D(Texture, uv);
}
