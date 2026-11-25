"""Testa a proposta de kits nº 1 (docs/balanceamento/proposta_kits_1.md) sem mexer nos dados do jogo.

Uso: python3 tools/prototipos/testar_proposta_kits_1.py [rodadas]
Aplica as mudanças em memória, recalibra só os 4 campeões e mostra a taxa de vitória antes e depois.
"""
import os,sys,copy,json,statistics
AQUI=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0,AQUI); sys.path.insert(0,os.path.join(os.path.dirname(AQUI),'conversao'))
import laboratorio_campeoes as L, converter_campeoes as C

def aplicar_proposta(cs):
    d={c['id']:c for c in cs}
    v=d['vedrassa']
    v['habilidades'][1]['mecanica']['redireciona']={'pct':0.2,'duracao':2.5}
    v['passiva']['mecanica']['pct_vida_bonus_propria']=0.05
    n=d['nalcora']; b=n['build_ids']
    n['build_ids']=[b[0],'lamina_do_eclipse','manto_da_noite_eterna','presa_da_serpente','escudo_do_guardiao']
    for h in n['habilidades']: h['mecanica']['ignora_escudo_magico']=True; h['mecanica']['divisao_adaptativa']=True
    n['passiva']['mecanica']['reinicia_ao_abater']=True
    n['habilidades'][2]['mecanica']['bonus_se_lento']=0.3
    k=d['clavento']; b=k['build_ids']; k['build_ids']=[b[0],b[1],b[3],b[4],'armadura_viva_de_cristal']
    k['habilidades'][1]['mecanica']['exposto_apos_uso']={'pct':0.2,'duracao':2}
    k['habilidades'][2]['mecanica']['atordoamento']=0.45
    k['habilidades'][2]['mecanica']['atordoamento_extra_se_lento']=0.3
    p=d['prismora']; q=p['habilidades'][0]
    q['dano']['base']=[q['dano']['base'][0],q['dano']['base'][1]*0.5]; q['mecanica']['bonus_por_item']=0.12
    q['mecanica']['imobiliza_ao_lancar']=0.35; p['habilidades'][2]['mecanica']['imobiliza_ao_lancar']=0.35
    q['mecanica']['dano_por_distancia']={'distancia':600,'perto':0.7}
    return cs

ALVOS=['vedrassa','nalcora','clavento','prismora']
def com_botoes(base,botoes):
    cs=copy.deepcopy(base)
    for c in cs:
        if c['id'] in botoes and botoes[c['id']]!=(1.0,1.0):
            C.aplicar_fator(c,botoes[c['id']][0],botoes[c['id']][1],'proposta')
    return cs

def mostrar(tab,cs,rot):
    for cid in ALVOS:
        c=next(x for x in cs if x['id']==cid); al=L.ALVO_CURVA[c['curva_de_forca']]
        t={m:L.taxa(tab,cid,m) for m in L.MOMENTOS}
        print("  %s %-9s %-9s"%(rot,cid,c['curva_de_forca'])," ".join("%s %4.1f%% (alvo %2.0f)"%(m,t[m]*100,al[m]*100) for m in L.MOMENTOS), " geral %4.1f%%"%((0.3*t['inicio']+0.4*t['meio']+0.3*t['fim'])*100))

if __name__=='__main__':
    atual=L.carregar_campeoes()
    rodadas=int(sys.argv[1]) if len(sys.argv)>1 else 5
    tab=L.medir(atual,1500,101); mostrar(tab,atual,"atual   ")
    base=aplicar_proposta(copy.deepcopy(atual))
    botoes={c:(1.0,1.0) for c in ALVOS}
    for r in range(rodadas):
        cs=com_botoes(base,botoes)
        tab=L.medir(cs,1500,201+r); mostrar(tab,cs,"r%d      "%r)
        for cid in ALVOS:
            c=next(x for x in cs if x['id']==cid); al=L.ALVO_CURVA[c['curva_de_forca']]
            e={m:al[m]-L.taxa(tab,cid,m) for m in L.MOMENTOS}
            i,f=botoes[cid]
            i*=1+max(-0.15,min(0.15,(e['inicio']+0.3*e['meio'])/0.3*0.4))
            f*=1+max(-0.15,min(0.15,(e['fim']+0.3*e['meio'])/0.3*0.4))
            botoes[cid]=(round(max(0.6,min(1.6,i)),3),round(max(0.6,min(1.6,f)),3))
        print("  botões",botoes)
    cs=com_botoes(base,botoes); tab=L.medir(cs,2000,999); mostrar(tab,cs,"final   ")
    for classe in ("tanque","assassino","lutador","mago","suporte","atirador"):
        g=[c for c in cs if c['classe']==classe]
        print("  %-9s"%classe,"  ".join("%s %5.1f%%"%(m,statistics.mean(L.taxa(tab,c['id'],m) for c in g)*100) for m in L.MOMENTOS))
    print('  botões finais',botoes)
