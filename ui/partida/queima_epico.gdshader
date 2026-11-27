shader_type canvas_item;
render_mode unshaded;

uniform float progresso : hint_range(0.0, 1.0) = 0.0;
uniform vec2 centro = vec2(0.5);
uniform float proporcao = 1.0;
uniform bool tem_terceira_cabeca = false;
uniform sampler2D terceira_cabeca : source_color, filter_linear, repeat_disable;

float ruido(vec2 p) {
	vec2 celula = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 v = fract(sin(vec4(dot(celula, vec2(127.1, 311.7))) +
		vec4(0.0, 127.1, 311.7, 438.8)) * 43758.5453);
	return mix(mix(v.x, v.y, f.x), mix(v.z, v.w, f.x), f.y);
}

void fragment() {
	vec4 criatura = texture(TEXTURE, UV);
	if (tem_terceira_cabeca) {
		vec4 cabeca = texture(terceira_cabeca, UV);
		float atras = cabeca.a * (1.0 - criatura.a) * smoothstep(0.0, 0.12, progresso);
		vec3 cor = criatura.rgb * criatura.a + cabeca.rgb * atras;
		criatura.a += atras;
		criatura.rgb = cor / max(criatura.a, 0.0001);
	}
	vec2 escala = vec2(proporcao, 1.0);
	vec2 p = (UV - centro) * escala;
	float raio = length(max(centro, 1.0 - centro) * escala);
	float grao = ruido(UV * 58.0);
	float relevo = ruido(UV * 20.0);
	float ordem = length(p) / raio + 0.10 * (relevo - 0.5) + 0.04 * (grao - 0.5);
	// A faixa incandescente acompanha a superfície. O que fica atrás dela vira cinza e dissolve.
	float t = smoothstep(0.10, 1.0, progresso);
	float distancia = ordem - mix(-0.22, 1.35, t);
	float carvao = 1.0 - smoothstep(-0.035, 0.075, distancia);
	float intacto = smoothstep(-0.20, -0.075, distancia);
	float borda = 1.0 - smoothstep(0.006, 0.047, abs(distancia + 0.02));
	float fissuras = smoothstep(0.44, 0.76, grao) * borda;
	vec3 escuro = criatura.rgb * vec3(0.24, 0.20, 0.19);
	vec3 cor = mix(criatura.rgb, escuro, carvao);
	cor += vec3(0.43, 0.092, 0.021) * borda * (0.30 + 0.70 * relevo);
	cor += vec3(0.73, 0.30, 0.072) * fissuras;
	COLOR = vec4(cor, criatura.a * intacto);
}
