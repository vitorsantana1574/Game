shader_type canvas_item;
render_mode unshaded;

uniform sampler2D oclusao : filter_linear, repeat_disable;
uniform float segundos = 0.0;
uniform float proporcao_quadro = 1.777778;
uniform bool menu_retrato = false;

vec3 luz_de_palco(vec2 ponto, vec2 origem, vec2 alvo, vec3 cor, float abertura,
		float forca, float piso, float textura_do_piso) {
	vec2 eixo = alvo - origem;
	float progresso = dot(ponto - origem, eixo) / dot(eixo, eixo);
	vec2 perpendicular = vec2(-eixo.y, eixo.x) / length(eixo);
	float distancia = abs(dot(ponto - origem, perpendicular));
	float largura = mix(2.0, abertura, clamp(progresso, 0.0, 1.0));
	float raio = distancia / max(1.0, largura);
	float nevoa = exp(-2.8 * raio * raio)
		* smoothstep(-0.025, 0.03, progresso)
		* (1.0 - smoothstep(0.66, 1.02, progresso))
		* mix(0.25, 0.11, clamp(progresso, 0.0, 1.0));
	float lente = 0.37 * exp(-length((ponto - origem) / vec2(11.0, 6.0)) * 2.0);

	// O brilho parte do mesmo ponto em que o facho encontra o piso.
	float comprimento = max(1.0, 720.0 - alvo.y);
	float t = clamp((ponto.y - alvo.y) / comprimento, 0.0, 1.0);
	float direcao = (alvo.x - 918.0) / max(76.0, alvo.y - 416.0);
	float centro = alvo.x + (ponto.y - alvo.y) * direcao * 0.62;
	float raio_reflexo = (ponto.x - centro) / (abertura * mix(0.26, 0.68, t));
	float reflexo = exp(-2.7 * raio_reflexo * raio_reflexo - 2.2 * t)
		* smoothstep(-20.0, 1.0, ponto.y - alvo.y)
		* (1.0 - t) * piso * textura_do_piso * 0.38;
	return cor * forca * (nevoa + lente + reflexo);
}

void fragment() {
	vec2 escala = vec2(min(1.0, proporcao_quadro / 1.777778),
		min(1.0, 1.777778 / proporcao_quadro));
	vec2 uv_cena = (UV - 0.5) * escala + 0.5;
	vec2 ponto = uv_cena * vec2(1280.0, 720.0);
	vec3 base = texture(TEXTURE, uv_cena).rgb;
	float mascara = texture(oclusao, uv_cena).a;
	float limite_esquerdo = 686.0 - (ponto.y - 452.0) * 0.53;
	float piso = smoothstep(480.0, 524.0, ponto.y)
		* smoothstep(limite_esquerdo, limite_esquerdo + 108.0, ponto.x);
	float textura_do_piso = mix(0.25, 1.0, clamp((base.r + base.g + base.b) / 1.93, 0.0, 1.0))
		* mix(0.32, 1.0, smoothstep(0.02, 0.14, max(base.g, base.b) - base.r));

	float a = segundos * TAU / 16.0 + 0.24;
	float b = segundos * TAU / 21.0 + 1.92;
	float c = segundos * TAU / 25.0 + 3.47;
	vec3 luz = luz_de_palco(ponto, vec2(943.0, 90.0),
		vec2(901.0 + 101.0 * sin(a), 514.0 + 17.0 * cos(a + 0.52)),
		vec3(0.51, 0.88, 1.0), 58.0, 0.89, piso, textura_do_piso);
	luz += luz_de_palco(ponto, vec2(1008.0, 88.0),
		vec2(1054.0 + 101.0 * sin(b), 528.0 + 17.0 * cos(b + 0.52)),
		vec3(0.53, 0.98, 0.8), 63.0, 0.82, piso, textura_do_piso);
	luz += luz_de_palco(ponto, vec2(1169.0, 132.0),
		vec2(1031.0 + 83.0 * sin(c), 505.0 + 17.0 * cos(c + 0.52)),
		vec3(0.82, 0.94, 1.0), 48.0, 0.65, piso, textura_do_piso);
	vec3 fundo = base * 0.94;
	vec3 cena = fundo + (vec3(1.0) - fundo) * clamp(luz * (1.0 - mascara), 0.0, 1.0);
	float mascara_menu = 0.56 * (1.0 - smoothstep(0.0, 0.57, UV.x));
	if (menu_retrato) {
		mascara_menu = smoothstep(0.61, 1.0, UV.y);
	}
	COLOR = vec4(mix(cena, vec3(0.039, 0.09, 0.094), mascara_menu), 1.0);
}
