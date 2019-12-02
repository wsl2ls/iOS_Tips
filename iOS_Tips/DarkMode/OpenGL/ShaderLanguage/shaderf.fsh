varying lowp vec2 varyTextCoord;
uniform sampler2D colorMap;

void main()
{
    gl_FragColor = texture2D(colorMap, varyTextCoord);
    
}
