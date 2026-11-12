// Peças opacas ou recortadas do VRoid (pele, roupa, cabelo). Veja atleta_vrm.gdshaderinc.
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled;

#define RECORTE
#include "res://shaders/atleta_vrm.gdshaderinc"
