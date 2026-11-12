// Pele do rosto do VRoid: igual a atleta_vrm_recorte, mas sem receber sombra
// projetada (cabelo e nariz faziam manchas no rosto), como o rosto do atleta gerado.
shader_type spatial;
render_mode ambient_light_disabled, cull_disabled, shadows_disabled;

#define RECORTE
#include "res://shaders/atleta_vrm.gdshaderinc"
