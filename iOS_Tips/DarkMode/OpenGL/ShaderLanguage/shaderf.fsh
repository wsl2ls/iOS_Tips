varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main()
{
    gl_FragColor = texture2D(colorMap, varyTextCoord);
    
}

// 后缀.vsh(顶点着色器)和.fsh(片元着色器) 是可以自定义的，只是为了区分和管理顶点着色器和片元着色器，也可以用字符串存储
// colorMap 采样器
// varyTextCoord 纹理坐标 由顶点着色器传入，必须和.vsh(顶点着色器)的变量保持一致
