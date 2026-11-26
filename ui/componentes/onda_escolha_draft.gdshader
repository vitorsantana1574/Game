shader_type canvas_item;
render_mode unshaded;

uniform vec4 cor_viva : source_color = vec4(0.1, 0.15, 0.22, 1.0);
uniform vec4 cor_cinza : source_color = vec4(0.10, 0.10, 0.10, 1.0);
uniform sampler2D retrato : source_color, filter_linear, repeat_disable;
uniform vec2 tamanho = vec2(1.0);
uniform float proporcao_retrato = 1.0;
uniform bool tem_retrato = false;
uniform float progresso = 0.0;

float frente(float a, float raio, float t) {
	return raio + min(raio * 0.27, 0.095) * (0.53 * sin(a * 6.0 + t * 11.0)
		+ 0.27 * sin(a * 12.0 - t * 15.0) + 0.20 * sin(a * 23.0 + t * 7.0));
}

void fragment() {
	vec3 viva = cor_viva.rgb;
	vec3 cinza = cor_cinza.rgb;
	if (tem_retrato) {
		float aspecto = tamanho.x / max(tamanho.y, 1.0);
		vec2 recorte = min(vec2(aspecto / proporcao_retrato, proporcao_retrato / aspecto), vec2(1.0));
		vec3 arte = texture(retrato, UV * recorte + (1.0 - recorte) * vec2(0.5, 0.33)).rgb;
		float sombra = smoothstep(0.29, 1.0, UV.y);
		viva = mix(viva, arte, 0.76 - sombra * 0.55);
		float luz = dot(arte, vec3(0.2126, 0.7152, 0.0722));
		cinza = mix(cinza, vec3(luz * 0.74), 0.76 - sombra * 0.55);
	}
	vec3 resultado = viva;
	if (progresso >= 1.0) {
		resultado = cinza;
	} else if (progresso > 0.0) {
		float escala = max(1.0, min(tamanho.x, tamanho.y));
		vec2 ponto = (UV - 0.5) * tamanho / escala;
		float a = atan(ponto.y, ponto.x + 0.00001);
		float t = progresso;
		float raio = 0.01 + (length(tamanho / escala * 0.5) + 0.15) * (1.0 - pow(1.0 - t, 1.45));
		float distancia = length(ponto) - frente(a, raio, t);
		float calor = min(t * 14.0, 1.0) * (1.0 - pow(t, 4.0));
		resultado = mix(cinza, viva, smoothstep(-0.007, 0.007, distancia));

		float labaredas = pow(0.5 + 0.5 * sin(a * 11.0 + t * 13.0 + distancia * 25.0), 6.0);
		float largura = 0.025 + labaredas * 0.085 * step(distancia, 0.0);
		float halo = exp(-abs(distancia) / largura);
		float borda = 1.0 - smoothstep(0.001, 0.022, abs(distancia));
		resultado += calor * (vec3(1.0, 0.31, 0.06) * halo * 0.85 + vec3(1.0, 0.72, 0.29) * borda);

		for (int i = 0; i < 12; i++) {
			float n = float(i);
			float idade = (t - (0.05 + mod(n, 6.0) * 0.065)) / 0.34;
			if (idade >= 0.0 && idade < 1.0) {
				float direcao = n * 2.39996;
				float distancia_brasa = frente(direcao, raio, t) - (0.03 + 0.22 * idade);
				vec2 brasa = vec2(cos(direcao), sin(direcao)) * distancia_brasa;
				brasa.y -= idade * idade * 0.12;
				float luz = 1.0 - smoothstep(0.005, 0.019, length(ponto - brasa));
				resultado += vec3(1.0, 0.57, 0.17) * luz * (1.0 - idade) * calor;
			}
		}
	}
	COLOR = vec4(resultado, 1.0);
}
