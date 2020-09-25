// Programa...: MA270TOK
// Autor......: Cláudia Lionço
// Data.......: 05/09/2019
// Descricao..: Gera registros de inventário na tabela SB7
//
// Historico de alteracoes:
// 20/07/2020 - Robert  - Verificacao de acesso passa a validar acesso 106 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
//

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #Ponto de entrada auxiliar para validar se o usuario tem permissao para digitacao de inventario.
// #PalavasChave      #inventario
// #TabelasPrincipais #SB7
// #Modulos           #EST

#include 'protheus.ch'
#include 'parmtype.ch'

// ------------------------------------------------------------------------------------
User function MA270TOK()
	local lRet      := .T.
	local _aAreaAnt := U_ML_SRArea ()

	If Altera
		If ! U_ZZUVL ('106', __cUserId, .F.) 
			u_help ("Usuário sem permissão para inclusão/alteração de registro de inventário.")
			VoltarValores()
			_lRet = .F.
		Else
			_lRet := .T.
		Endif
	EndIf
	
	U_ML_SRArea (_aAreaAnt)		
Return lRet

Static function VoltarValores()

	DbSelectArea("SB7")
	SB7 -> (DBSetorder(3))
	SB7 -> (dbseek (xFilial("SB7") + m-> b7_doc + m-> b7_cod + m-> b7_local, .F.))
	
	m->b7_tipo    := sb7-> b7_tipo
	m->b7_doc     := sb7-> b7_doc
	m->b7_quant   := sb7-> b7_quant
	m->b7_qtsegum := sb7-> b7_qtsegum
	m->b7_data    := sb7-> b7_data
	m->b7_numlote := sb7-> b7_numlote 
	m->b7_lotectl := sb7-> b7_lotectl
	m->b7_localiz := sb7-> b7_localiz
	m->b7_tpestr  := sb7-> b7_tpestr
	m->b7_contage := sb7-> b7_contage
	m->b7_coduni  := sb7-> b7_coduni
	m->b7_idunit  := sb7-> b7_idunit

Return
