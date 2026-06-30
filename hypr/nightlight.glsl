precision mediump float;
varying vec2 v_texcoord;
uniform sampler2D tex;

void main() {
    vec4 color = texture2D(tex, v_texcoord);
    
    // ΕΔΩ ΡΥΘΜΙΖΕΙΣ ΤΗΝ ΑΠΟΧΡΩΣΗ (RGB)
    // Οι τιμές είναι από 0.0 (καθόλου) έως 1.0 (φουλ)
    
    color.r *= 1.00; // Κόκκινο (Άστο στο 1.0 για ζεστό φως)
    color.g *= 0.80; // Πράσινο (Χαμήλωσέ το ελαφρώς για πιο "ροζ/κόκκινο" αποτέλεσμα)
    color.b *= 0.65; // Μπλε (Χαμήλωσέ το πολύ για να κόψεις την ακτινοβολία)
    
    gl_FragColor = color;
}
