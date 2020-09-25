// Programa:  MA242BUT
// Autor:     Robert Koch
// Data:      04/08/2020
// Descricao: P.E. para manipular botoes da enchoiceber na tela de desmontagem de produtos.
//            Criado inicialmente para chamar consulta de itens usados em OP (GLPI 8259).
//
// Historico de alteracoes:
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #PalavasChave      #botoes #desmontagem
// #TabelasPrincipais #SD3
// #Modulos           #PCP #EST

// --------------------------------------------------------------------------
user function MA242BUT ()
	local _aAreaAnt := U_ML_SRArea ()
	local _aBotoes := aclone (paramixb [2])

	aadd (_aBotoes, {'PRODUTO',{|| U_MA242COP ()}, 'Consultar consumo OP', 'Consultar material consumido numa OP'})

	U_ML_SRArea (_aAreaAnt)
return _aBotoes
