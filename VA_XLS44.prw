// Programa...: VA_XLS44
// Autor......: Robert Koch
// Data.......: 14/06/2019
// Descricao..: Consulta prazos medios de recebimentos e pagamentos

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Consulta
// #Descricao         #Consulta prazos medios de recebimentos e pagamentos
// #PalavasChave      #prazo_medio_pagamentos #prazo_medio_recebimentos
// #TabelasPrincipais #SE1 #SE2
// #Modulos           #FIN

// Historico de alteracoes:
// 09/12/2019 - Robert  - Passa a permitir selecionar criterio de agrupamento por cliente ou representante (apenas carteira a receber).
// 05/03/2020 - Claudia - Ajuste de fonte conforme solicita��o de vers�o 12.1.25
// 05/01/2021 - Robert  - Nao estava abrindo a tela de parametros.
//

// --------------------------------------------------------------------------
User Function VA_XLS44 ()	
	Private cPerg   := "VAXLS44"
	
	_ValidPerg()
	if Pergunte(cPerg, .T.)
		Processa( { |lEnd| _Gera() } )
	endif

return
//
// --------------------------------------------------------------------------
Static Function _Gera()
	local _oSQL := NIL

	procregua (4)
	incproc ()
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	if mv_par03 == 1
		_oSQL:_sQuery += "SELECT * FROM VA_FPRAZOS_MEDIOS_PAGAR ('', 'Z', '" + dtos (mv_par01) + "', '" + dtos (mv_par02) + "')"
		_oSQL:_sQuery += " ORDER BY TOT_VALOR DESC"
	else
		_oSQL:_sQuery += "SELECT * FROM VA_FPRAZOS_MEDIOS_RECEBER ('', 'Z', '" + dtos (mv_par01) + "', '" + dtos (mv_par02) + "', '" + iif (mv_par04 == 1, 'C', 'R') + "')"
		_oSQL:_sQuery += " ORDER BY TOT_VALOR DESC"
	endif
	_oSQL:Log ()
	u_ShowArray (_oSQL:Qry2Array (.F., .T.))
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                           TIPO TAM DEC VALID F3     Opcoes                        Help
	aadd (_aRegsPerg, {01, "Data emissao inicial          ", "D", 8,  0,  "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {02, "Data emissao final            ", "D", 8,  0,  "",   "   ", {},                           ""})
	aadd (_aRegsPerg, {03, "Carteira                      ", "N", 1,  0,  "",   "   ", {'Pagar', 'Receber'},         ""})
	aadd (_aRegsPerg, {04, "Agrupar(carteira receber) por ", "N", 1,  0,  "",   "   ", {'Cliente', 'Representante'}, ""})
	U_ValPerg (cPerg, _aRegsPerg)
Return
