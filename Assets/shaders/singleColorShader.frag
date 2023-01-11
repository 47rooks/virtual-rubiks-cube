/*
 * This shader outputs a simple single color for all fragments.
 * It is used in the stencil based outlining example.
 */
void main(void) {
    gl_FragColor = vec4(0.04, 0.28, 0.26, 1.0);
}