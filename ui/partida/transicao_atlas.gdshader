shader_type canvas_item;

uniform sampler2D atlas_atual : filter_linear, repeat_disable;
uniform sampler2D atlas_seguinte : filter_linear, repeat_disable;
uniform vec4 regiao_atual;
uniform vec4 regiao_seguinte;
uniform float mistura : hint_range(0.0, 1.0);
// Animações opacas (Cérbero e Hydra) guardam só a cor; o recorte da arena vem desta máscara.
uniform sampler2D mascara : filter_linear, repeat_disable;
uniform bool usa_mascara = false;

void fragment() {
	vec4 a = texture(atlas_atual, regiao_atual.xy + UV * regiao_atual.zw);
	vec4 b = texture(atlas_seguinte, regiao_seguinte.xy + UV * regiao_seguinte.zw);
	// Mistura pré-multiplicada para preservar a borda do vapor e das brasas.
	float opacidade = mix(a.a, b.a, mistura);
	vec3 cor = mix(a.rgb * a.a, b.rgb * b.a, mistura);
	if (usa_mascara) {
		opacidade *= texture(mascara, UV).r;
	}
	COLOR = vec4(cor / max(mix(a.a, b.a, mistura), 0.0001), opacidade);
}
