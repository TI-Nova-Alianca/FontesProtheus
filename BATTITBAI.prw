//  Programa...: BATTITBAI
//  Autor......: Cláudia Lionço
//  Data.......: 21/07/2020
//  Descricao..: Baixa de titulos de mudas de uvas para associados
// 
//  #TipoDePrograma    #Batch
//  #Descricao         #Baixa de titulos de mudas de uvas para associados
//  #PalavasChave      #titulos #baixa #mudas_de_uvas #associados #venda
//  #TabelasPrincipais #SE1 #SF2 #SD2
//  #Modulos 		   #FIN 
//
//  Historico de alteracoes:
//  05/10/2021 - Claudia - Acrescentado o codigo do milho para baixas. GLPI:10994
//  18/10/2021 - Claudia - Será realizada a baixa automatica apenas para associados. GLPI:11100 
//
// ----------------------------------------------------------------------------------------------

#include 'protheus.ch'
#include 'parmtype.ch'

User Function BATTITBAI()
	Local _oAssoc  := NIL
	Local i        := 0 
	Local _aTitulo := {}
	
	// VERIFICA TITULOS DE VENDAS DE MUDAS PARA ASSOCIADOS PARA REALIZAR A BAIXA
	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT"
	_oSQL:_sQuery += " 	   SE1.E1_FILIAL"
	_oSQL:_sQuery += "    ,SE1.E1_PREFIXO"
	_oSQL:_sQuery += "    ,SE1.E1_NUM"
	_oSQL:_sQuery += "    ,SE1.E1_PARCELA"
	_oSQL:_sQuery += "    ,SE1.E1_VALOR"
	_oSQL:_sQuery += "    ,SE1.E1_CLIENTE"
	_oSQL:_sQuery += "    ,SE1.E1_LOJA"
	_oSQL:_sQuery += "    ,SE1.E1_EMISSAO"
	_oSQL:_sQuery += "    ,SE1.E1_TIPO"
	_oSQL:_sQuery += "    ,SE1.E1_BAIXA"
	_oSQL:_sQuery += "    ,SE1.E1_SALDO"
	_oSQL:_sQuery += "    ,SE1.E1_STATUS "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " AS SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SD2") + " AS SD2 "
	_oSQL:_sQuery += " 	ON (SD2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " 			AND D2_COD IN ('7206', '7207','5446','5456')"
	_oSQL:_sQuery += " 			AND D2_FILIAL  = SE1.E1_FILIAL"
	_oSQL:_sQuery += " 			AND D2_DOC     = SE1.E1_NUM"
	_oSQL:_sQuery += " 			AND D2_SERIE   = SE1.E1_PREFIXO"
	_oSQL:_sQuery += " 			AND D2_CLIENTE = SE1.E1_CLIENTE"
	_oSQL:_sQuery += " 			AND D2_LOJA    = SE1.E1_LOJA)"
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND E1_BAIXA = ''"
	_oSQL:_sQuery += " AND E1_STATUS <> 'B'"
	_oSQL:_sQuery += " AND E1_SALDO <> 0"
	_aTitulo := aclone (_oSQL:Qry2Array ())
	
	If len(_aTitulo) > 0
		For i:=1 to len(_aTitulo)	
			_sCliente := _aTitulo[i,6] 
			_sLoja    := _aTitulo[i,7]
			_sCGC     :=  fbuscacpo("SA1",1,xfilial("SA1") + PADR(_sCliente,6,' ') + _sLoja ,"A1_CGC") // busca cpf para localizar o associado na A2
			_sFornec  :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_COD")  // busca por cnpj/cpf
			_sLojFor  :=  fbuscacpo("SA2",3,xfilial("SA2") + _sCGC ,"A2_LOJA") // busca por cnpj/cpf

			_oAssoc := ClsAssoc():New (_sFornec, _sLojFor) 
			If valtype (_oAssoc) == "O" .and. _oAssoc:EhSocio ()
				lMsErroAuto := .F.

				// executar a rotina de baixa automatica do SE1 gerando o SE5
				_aAutoSE1 := {}
				aAdd(_aAutoSE1, {"E1_FILIAL" 	, _aTitulo[i,1]	    				, Nil})
				aAdd(_aAutoSE1, {"E1_PREFIXO" 	, _aTitulo[i,2]	    				, Nil})
				aAdd(_aAutoSE1, {"E1_NUM"     	, _aTitulo[i,3]	    				, Nil})
				aAdd(_aAutoSE1, {"E1_PARCELA" 	, _aTitulo[i,4]	    				, Nil})
				aAdd(_aAutoSE1, {"E1_CLIENTE" 	, _aTitulo[i,6] 					, Nil})
				aAdd(_aAutoSE1, {"E1_LOJA"    	, _aTitulo[i,7] 					, Nil})
				aAdd(_aAutoSE1, {"E1_TIPO"    	, _aTitulo[i,9] 					, Nil})
				AAdd(_aAutoSE1, {"AUTMOTBX"		, 'DACAO'  							, Nil})
				AAdd(_aAutoSE1, {"AUTAGENCIA"  	, '.    ' 		    				, Nil})
				AAdd(_aAutoSE1, {"AUTCONTA"  	, '.         '      				, Nil})
				AAdd(_aAutoSE1, {"AUTDTBAIXA"	, _aTitulo[i,8] 					, Nil})
				AAdd(_aAutoSE1, {"AUTDTCREDITO"	, _aTitulo[i,8] 					, Nil})
				AAdd(_aAutoSE1, {"AUTHIST"   	, 'Vlr.recebido da venda de mudas'	, Nil})
				AAdd(_aAutoSE1, {"AUTDESCONT"	, 0         						, Nil})
				AAdd(_aAutoSE1, {"AUTMULTA"  	, 0         						, Nil})
				AAdd(_aAutoSE1, {"AUTJUROS"  	, 0         						, Nil})
				AAdd(_aAutoSE1, {"AUTVALREC"  	, _aTitulo[i,5] 					, Nil})
				
				_aAutoSE1 := aclone (U_OrdAuto (_aAutoSE1))  // orderna conforme dicionário de dados
				
				cPerg = 'FIN070'
				_aBkpSX1 = U_SalvaSX1 (cPerg)  // Salva parametros da rotina.
				U_GravaSX1 (cPerg, "01", 2)
				U_GravaSX1 (cPerg, "04", 2)
				U_GravaSXK (cPerg, "01", "2", 'G' )
				U_GravaSXK (cPerg, "04", "2", 'G' )
					
				MSExecAuto({|x,y| Fina070(x,y)},_aAutoSE1,3,.F.,5) // rotina automática para baixa de títulos
				
				U_GravaSXK (cPerg, "01", "2", 'D' )
				U_GravaSXK (cPerg, "04", "2", 'D' )
				U_SalvaSX1 (cPerg, _aBkpSX1)  // Restaura parametros da rotina
		    EndIf
		Next
	Endif			
Return
