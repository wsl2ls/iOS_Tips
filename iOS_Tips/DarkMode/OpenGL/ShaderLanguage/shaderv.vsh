attribute vec4 position;
attribute vec2 textCoordinate;
varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = textCoordinate;
    gl_Position = position;
}

// 后缀.vsh和.fsh 是可以自定义的，只是为了区分和管理顶点着色器和片元着色器
