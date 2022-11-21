/*
* Simple fragment shader to set the color of the light.
*/
varying vec4 vColor;
            
void main(void)
{
    gl_FragColor = vColor;
}