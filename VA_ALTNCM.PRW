//  Programa...: VA_POSIPI
//  Autor......: Catia Cardoso
//  Data.......: 25/04/2017
//  Descricao..: Altera NCM dos produtos 
//
// #TipoDePrograma    #Processo
// #Descricao         #Altera NCM dos produtos 
// #PalavasChave      #posicao_IPI
// #TabelasPrincipais #SB1
// #Modulos           #
//
// Historico de alterações
// 04/02/2020 - Andre   - Adicionado filtro por Produto. B1_COD.
// 02/03/2023 - Claudia - Alterado processo para realizar para varios produtos. GLPI: 13243
//
// ------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "VA_INCLU.prw"

User function VA_POSIPI()
	Local i	      := 0
	Local _aDados := {}

	cPerg   := "VA_POSIPI"
	if ! u_zzuvl ('019', __cUserId, .T.)
		return
	endif
	
	_ValidPerg()
	
	if Pergunte(cPerg,.T.) 
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT  "
		_oSQL:_sQuery += " 		B1_COD "
		_oSQL:_sQuery += " FROM " + RetSQLName ("SB1") 
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND B1_COD BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
		_oSQL:_sQuery += " AND B1_POSIPI    = '" + mv_par03 + "' "
		_oSQL:Log ()
		_aDados = aclone (_oSQL:Qry2Array())

    	if len(_aDados) > 0 
    		for i := 1 to len(_aDados)
    			_sProduto = _aDados[i, 1]

		    	// grava log de alteração
				_oEvento:= ClsEvent():new ()
				_oEvento:CodEven   = "ALT001"
				_oEvento:Texto	   = "Alterado NCM, rotina VA_ALTNCM" 
				_oEvento:Texto     += " De " + mv_par03 + " para " + mv_par04
				_oEvento:Produto   = _sProduto
				_oEvento:Alias     = "SB1"
				_oEvento:Hist	   = "1"
				_oEvento:Status	   = "4"
				_oEvento:Sub	   = ""
				_oEvento:Prazo	   = 0
				_oEvento:Flag	   = .T.
				_oEvento:Grava ()

				// atualiza cadastro do produtos
				DbSelectArea("SB1")
				DbSetOrder(1)
				if DbSeek(xFilial("SB1")+ _sProduto,.F.)
					reclock("SB1", .F.)
						SB1->B1_POSIPI := mv_par04 
						SB1->B1_IPI    := mv_par05
			    	MsUnLock()
				endif	    	
			next
			Alert("Alteração de NCM's concluída.")
		else
			Alert("Não foi encontrado nenhum produto com essa NCM.")													
		endif
	endif
return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT               TIPO TAM DEC VALID F3    Opcoes       Help
    aadd (_aRegsPerg, {01, "Produto de        ", "C", 15, 0,  "",   "SB1", {},  		""})
	aadd (_aRegsPerg, {02, "Produto até       ", "C", 15, 0,  "",   "SB1", {},  		""})
    aadd (_aRegsPerg, {03, "NCM Atual         ", "C", 10, 0,  "",   "SYD", {},  		""})
    aadd (_aRegsPerg, {04, "Nova NCM          ", "C", 10, 0,  "",   "SYD", {},  		""})
	aadd (_aRegsPerg, {05, "Aliq.IPI          ", "N",  5, 2,  "",   "   ", {},  		""})
	
    U_ValPerg (cPerg, _aRegsPerg)
Return
