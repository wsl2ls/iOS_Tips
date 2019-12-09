varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main()
{
    gl_FragColor = texture2D(colorMap, varyTextCoord);
    
}

// 后缀.vsh和.fsh 是可以自定义的，只是为了区分和管理顶点着色器和片元着色器，也可以用字符串存储
