attribute vec4 position;       //顶点坐标
attribute vec2 textCoordinate;   //纹理坐标
varying lowp vec2 varyTextCoord; //纹理坐标  传递给片元着色器

void main()
{
    varyTextCoord = textCoordinate;
    gl_Position = position;
}

// 后缀.vsh和.fsh 是可以自定义的，只是为了区分和管理顶点着色器和片元着色器，也可以用字符串存储
