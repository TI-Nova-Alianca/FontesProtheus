// Programa: MT120PCol
// Autor...: Robert Koch
// Data....: 24/08/2012
// Funcao..: PE 'Linha OK' na manutencao de pedidos de compra / autorizacoes de entrega.
//           Criado inicialmente para validacoes ref. obra Flores da Cunha.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         # PE 'Linha OK' na manutencao de pedidos de compra
// #PalavasChave      #compras #pedido_de_compras #ponto_de_entrada 
// #TabelasPrincipais #SA5
// #Modulos   		  #COM 
//
// Historico de alteracoes:
// 06/09/2012 - Robert  - Considerava duas vezes o item atual na verificacao de saldos PIF.
// 03/12/2015 - Robert  - Validacoes de CC com campo B1_VARATEI.
// 06/02/2018 - Robert  - Desabilitadas validacoes ref. obra da planta de Lagoa Bela.
// 14/08/2018 - Catia   - Validações SA5 tabela de produto x fornecedor para TODO item com B1_TIPO DIFERENTE de GG
// 06/11/2019 - Cláudia - Alterada a validação para que caso não existir o código fornecedor inserido na tabela,
//                        não permita a gravação.
// 02/02/2022 - Claudia - Ajustada validação produto x fornecedor. GLPI: 11556
// 18/09/2023 - Claudia - Incluida exceção de produtos tipo 'SG'. GLPI: 14231
//
// -----------------------------------------------------------------------------------------------------------------
User Function MT120PCol ()
	Local _lRet     := .T.
	Local _aAreaAnt := U_ML_SRArea ()
	Local nOper     := PARAMIXB[1]
     
    If nOper == 1 //-- 1 = Chamada via A120LINOK, 2 = Chamada via A120TUDOK
		If _lRet
			_lRet := _VProdForn ()
		EndIf
    EndIf

	U_ML_SRArea (_aAreaAnt)
return _lRet
//
// ---------------------------------------------------------------------------------------
// Validacoes tabela Produto x Fornecedor
Static Function _VProdForn ()
	Local _oSQL   := ClsSQL():New ()
	Local _lRet   := .T.
	Local _aDados := {}

	If ! GDDeleted ()
		_wtipo = fbuscacpo ("SB1", 1, xfilial ("SB1") + GDFieldGet ("C7_PRODUTO"),  "B1_TIPO")

		If _wtipo != 'GG' .and. _wtipo != 'AI' .and. _wtipo != 'SG' // verifica se existe amarracao na SA5			
			_oSQL:_sQuery := ""
    		_oSQL:_sQuery += " SELECT "
			_oSQL:_sQuery += " 		A5_CODPRF "
  			_oSQL:_sQuery += " FROM " + RetSQLName ("SA5") 
 			_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
   			_oSQL:_sQuery += " AND A5_PRODUTO = '" + GDFieldGet ("C7_PRODUTO") + "'" 
   	 		_oSQL:_sQuery += " AND A5_FORNECE = '" + cA120Forn + "'"
   			_oSQL:_sQuery += " AND A5_LOJA    = '" + cA120Loj + "'"
			_aDados := aclone (_oSQL:Qry2Array (.F., .F.))

			If Len(_aDados) < 1
				u_help ("Produto sem amarração produto x fornecedor. Verifique!")
	   			_lRet = .F.	   
			EndIf   			 
		EndIf			
	EndIf
Return _lRet
