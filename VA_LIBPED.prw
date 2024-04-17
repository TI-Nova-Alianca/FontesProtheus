// Programa...: VA_LIBPED
// Autor......: Catia Cardoso
// Data.......: 14/04/2016
// Descricao..: Analise e Libera Pedidos com Bloqueio Financeiro
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Tela #Atualizacao
// #Descricao         #Analise e Libera Pedidos com Bloqueio Financeiro
// #PalavasChave      #liberacao_de_pedidos #bloqueio_financeiro
// #TabelasPrincipais #SC5 #SC6 
// #Modulos   		  #FIN 
//
// Historico de alteracoes:
// 14/04/2016 - criado novo indice por banco
// 03/05/2016 - ao liberar o pedido nao estava "sumindo" da tela de seleção
// 03/05/2016 - a função de totais por banco nao esta apurando corretamente os valores
// 06/06/2016 - estava dando mensagem de que o pedido nao estava bloqueado - quando clicava no liberar
// 10/06/2016 - estava tendo problemas para liberar alguns pedidos dava mensagem de que o pedido nao estava bloqueado
// 15/06/2016 - não estava excluindo o pedido do browse apos a liberacao
// 04/04/2018 - recuperado o programa que estava corrompido 
// 15/10/2019 - Sandra/Claudia - criado novo indice por Nome
// 19/12/2019 - Cláudia - Criação de tela de dados do cliente e gravação do campo OBS
// 13/01/2020 - Claudia - Inclusão da função <ArqTrb> (exigencia release 12.1.25 do Protheus)
// 07/12/2020 - Claudia - Inclusão de botao para visualização de observações de clientes. GLPI: 8971
// 03/05/2023 - Claudia - Alterado o grupo de 055 para 149. GLPI: 13519
// 17/04/2023 - Sandra  - Inclusão do tipo A -  F4_MARGEM GLPI: 15282
//
// ----------------------------------------------------------------------------------------------
#include 'totvs.ch'

User Function VA_LIBPED()
	
	local _aCores   := {}
	Local aStruct   := {}
	Local aHead     := {}
	Local _aArqTrb  := {}
	Local j		    := 0
	Local i		    := 0
	Private bFiltraBrw := {|| Nil}
	
	cPerg   := "VA_LIBPED"
	
	if ! u_zzuvl ('036', __cUserId, .F.)
		if ! u_zzuvl ('149', __cUserId, .T.)
			msgalert ("Usuario sem permissao para usar estar rotina.")
			return
		endif			
	endif
	
	_ValidPerg()
	
    if Pergunte(cPerg,.T.) 

		//Campos que aparecerÃ£o na MBrowse
		AAdd( aHead, { "Cliente"         ,{|| TRB->CODIGO}   ,"C", 06 , 0, "" } )
		AAdd( aHead, { "Loja"            ,{|| TRB->LOJA}     ,"C", 02 , 0, "" } )
		AAdd( aHead, { "Nome_Cli"        ,{|| TRB->NOME}     ,"C", 45 , 0, "" } )
		AAdd( aHead, { "Cidade"          ,{|| TRB->CIDADE}   ,"C", 20 , 0, "" } )
		AAdd( aHead, { "Estado"          ,{|| TRB->UF}       ,"C", 05 , 0, "" } )
		AAdd( aHead, { "Banco"           ,{|| TRB->BANCO}    ,"C", 05 , 0, "" } )
		AAdd( aHead, { "Usuario"         ,{|| TRB->USUARIO}  ,"C", 15 , 0, "" } )
		AAdd( aHead, { "Pedido"          ,{|| TRB->PEDIDO}   ,"C", 10 , 0, "" } )
		AAdd( aHead, { "Vlr Produtos"    ,{|| TRB->VLR_PROD} ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Vlr Impostos"    ,{|| TRB->VLR_IMP}  ,"N", 12 , 2, "@E 9,999,999.99" } )
		AAdd( aHead, { "Total Pedido"    ,{|| TRB->VLR_TOT}  ,"N", 12 , 2, "@E 9,999,999.99" } )
		
		// define estrutura do arquivo de trabalho	
		AAdd( aStruct, { "CODIGO"  , "C", 06, 0 } )
		AAdd( aStruct, { "LOJA"    , "C", 02, 0 } )
		AAdd( aStruct, { "NOME"    , "C", 30, 0 } )
		AAdd( aStruct, { "CIDADE"  , "C", 20, 0 } )
		AAdd( aStruct, { "UF"      , "C", 02, 0 } )
		AAdd( aStruct, { "BANCO"   , "C", 03, 0 } )
		AAdd( aStruct, { "USUARIO" , "C", 25, 0 } )
		AAdd( aStruct, { "PEDIDO"  , "C", 06, 0 } )
		AAdd( aStruct, { "VLR_PROD", "N", 12, 2 } )
		AAdd( aStruct, { "VLR_IMP" , "N", 12, 2 } )
		AAdd( aStruct, { "VLR_TOT" , "N", 12, 2 } )
		AAdd( aStruct, { "PED_REG" , "N", 08, 0 } )
		
		U_ArqTrb ("Cria", "TRB", aStruct, {"PEDIDO","CODIGO+LOJA","BANCO+PEDIDO","NOME"}, @_aArqTrb)		

		// gera arquivo dados dos pedidos
		_sSQL := ""
		_sSQL += " SELECT DISTINCT SC6.C6_NUM"
		_sSQL += "      , SC5.C5_CLIENTE, SC5.C5_LOJACLI, SC5.C5_TIPO, SC5.C5_TIPOCLI, SC5.C5_BANCO"
	 	_sSQL += "      , SC5.C5_VAEST, SC5.C5_VAMUN, SC5.C5_VAUSER"
	 	_sSQL += "      , SC5.R_E_C_N_O_"
  		_sSQL += "   FROM SC6010 AS SC6"
		_sSQL += " 		INNER JOIN SC5010 AS SC5"
		_sSQL += " 			ON (SC5.D_E_L_E_T_ = ''"
		_sSQL += " 				AND SC5.C5_FILIAL = SC6.C6_FILIAL"
		_sSQL += " 				AND SC5.C5_NUM    = SC6.C6_NUM)"
		if mv_par01 == 1 //OPCAO DE ANALISAR SO OS BLOQUEADOS POR CREDITO
			_sSQL += " 		INNER JOIN SC9010 AS SC9"
			_sSQL += " 			ON (SC9.D_E_L_E_T_ = ''"
			_sSQL += " 				AND SC9.C9_FILIAL = SC6.C6_FILIAL"
			_sSQL += " 				AND SC9.C9_PEDIDO = SC6.C6_NUM"
			_sSQL += " 				AND SC9.C9_ITEM   = SC6.C6_ITEM"
			_sSQL += " 				AND SC9.C9_BLCRED > 0"
			_sSQL += " 				AND SC9.C9_NFISCAL = ''"
			_sSQL += " 				AND SC9.C9_SERIENF = '')"
		endif
		_sSQL += " 		INNER JOIN SF4010 AS SF4"
		_sSQL += " 			ON (SF4.D_E_L_E_T_ = ''"
		_sSQL += " 				AND SF4.F4_CODIGO = SC6.C6_TES"
		_sSQL += " 				AND SF4.F4_MARGEM IN  ('1','A') "
		_sSQL += " 				AND SF4.F4_DUPLIC = 'S')"
		_sSQL += "  WHERE SC6.D_E_L_E_T_ = ''"
   		_sSQL += "    AND SC6.C6_FILIAL  = '" + xFilial("SC6") + "'"
   		_sSQL += "    AND SC6.C6_NOTA    = ''"
   		_sSQL += "    AND SC6.C6_BLQ NOT IN ('R','S')"
   		_sSQL += "    AND (SC6.C6_QTDVEN - SC6.C6_QTDENT) > 0"
   		//u_showmemo (_sSQL)
		aPedidos := U_Qry2Array(_sSQL)

		if len (aPedidos) > 0
			
			for i=1 to len(aPedidos)
				_wimpostos = 0
				_wprodutos = 0
				
				// inicializa MAFISINI para poder bucar o valor da ST
				MaFisIni(aPedidos [i,2],;						// 1-Codigo Cliente/Fornecedor
						 aPedidos [i,3],;						// 2-Loja do Cliente/Fornecedor
						 IIf(aPedidos [i,4]$'DB',"F","C"),;		// 3-C:Cliente , F:Fornecedor
						 aPedidos [i,4],;						// 4-Tipo da NF
						 aPedidos [i,5],;						// 5-Tipo do Cliente/Fornecedor
						 MaFisRelImp("MTR700",{"SC5","SC6"}),;	// 6-Relacao de Impostos que suportados no arquivo
						 ,;						   				// 7-Tipo de complemento
						 ,;										// 8-Permite Incluir Impostos no Rodape .T./.F.
						 "SB1",;								// 9-Alias do Cadastro de Produtos - ("SBI" P/ Front Loja)
						 "MTR700")								// 10-Nome da rotina que esta utilizando a funcao
						 
				// buscar todos os itens do pedido
				_sSQL := ""
				_sSQL += " SELECT SC6.C6_NUM, SC6.C6_ITEM, SC6.C6_PRODUTO, SC6.C6_TES, SC6.C6_QTDVEN, SC6.C6_PRCVEN"
				_sSQL += "      , SC6.C6_VALOR - ((SC6.C6_PRCVEN * SC6.C6_QTDVEN) - (SC6.C6_PRUNIT * SC6.C6_QTDVEN)) AS VLR_ITEM"
				_sSQL += "      , SC6.C6_VALOR"
	 			_sSQL += "   FROM SC6010 AS SC6"
				_sSQL += " 		INNER JOIN SC5010 AS SC5"
				_sSQL += " 			ON (SC5.D_E_L_E_T_ = ''"
				_sSQL += " 				AND SC5.C5_FILIAL = SC6.C6_FILIAL"
				_sSQL += " 				AND SC5.C5_NUM    = SC6.C6_NUM)"
				_sSQL += " 		INNER JOIN SF4010 AS SF4"
				_sSQL += " 			ON (SF4.D_E_L_E_T_ = ''"
				_sSQL += " 				AND SF4.F4_CODIGO = SC6.C6_TES"
				_sSQL += " 				AND SF4.F4_MARGEM IN  ('1','A')"
				_sSQL += " 				AND SF4.F4_DUPLIC = 'S')"
				_sSQL += "  WHERE SC6.D_E_L_E_T_ = ''"
		   		_sSQL += "    AND SC6.C6_FILIAL  = '" + xFilial("SC6") + "'"

		   		// Robert, 01/02/2019
		   		_sSQL += "    AND SC6.C6_BLQ NOT IN ('R', 'S')"  // Eliminado residuo / bloqueio manual

		   		_sSQL += "    AND SC6.C6_NUM     = '" + aPedidos [i,1] + "'"
				_sSQL += " ORDER BY SC6.C6_NUM, SC6.C6_ITEM"							 
				aItens := U_Qry2Array(_sSQL)
				
				if len (aItens) > 0
					_wimpostos = 0
					_wprodutos = 0
					for j=1 to len(aItens)
						// busca IPI do item
						MaFisAdd( aItens [j,3],; // produto
						 		  aItens [j,4],; // TES
								  aItens [j,5],; // quantidade
								  aItens [j,6],; // valor item				
										 	 0,;
											"",;
											"",;
											"",;
											 0,;
											 0,;
											 0,;
											 0,;
				 				  aItens [j,8],; // valor total do item
											 0,;
											 0,;
											  0)
						_nValSol := MaFisRet( j, "IT_VALSOL")
						_nValIpi := MaFisRet( j, "IT_VALIPI")
						_wimpostos := _wimpostos + (_nValSol + _nValIpi)
						_wprodutos := _wprodutos + aItens [j,8] // valor do item  
					next
				endif
				MaFisEnd ()
				
				// grava arquivo de trabalho					
				DbSelectArea("TRB")
		        RecLock("TRB",.T.)
		        	TRB->CODIGO  = aPedidos[I,2]
		        	TRB->LOJA    = aPedidos[I,3]
		        	TRB->NOME    = fBuscaCpo ('SA1', 1, xfilial('SA1') + aPedidos[I,2] + aPedidos[I,3], "A1_NOME")
		        	TRB->CIDADE  = aPedidos[I,8]
		        	TRB->UF      = aPedidos[I,7]
		        	TRB->BANCO   = aPedidos[I,6]
		        	TRB->USUARIO = aPedidos[I,9]
		        	TRB->PEDIDO  = aPedidos[I,1]
		        	TRB->VLR_PROD= _wprodutos
		        	TRB->VLR_IMP = _wimpostos 
		        	TRB->VLR_TOT = _wprodutos + _wimpostos
		        	TRB->PED_REG = aPedidos[I,10]
		        	//TRB->LIBERADO = ''
		        MsUnLock()
			next
		endif

		Private aRotina   := {}
		private cCadastro := "Liberação de Pedidos - Financeiro"
		private _sArqLog  := iif (type ("_sArqLog") == "C", _sArqLog, U_Nomelog ())
			
		aadd (aRotina, {"&Libera"             			, "U_L_LIBPED"              , 0 ,5})
		aadd (aRotina, {"&Altera Banco"       			, "U_A_LIBPED(TRB->PEDIDO)" , 0 ,5})
		aadd (aRotina, {"&Totais por Banco"   			, "U_T_LIBPED"              , 0 ,5})
		aadd (aRotina, {"&Dados adicionais clientes"    , "U_D_LIBPED(TRB->CODIGO,TRB->LOJA)" , 0 ,5})
		aadd (aRotina, {"&Observações"    				, "U_VA_OBSFIN('2',TRB->CODIGO,TRB->LOJA)" , 0 ,5})
		
		Private cDelFunc := ".T."
		_sArqLog := U_NomeLog ()
		u_logId ()
		
		dbSelectArea("TRB")
		dbSetOrder(1)
		
		_wfiltro := "LIBERADO != '*'"		    
		mBrowse(,,,,"TRB",aHead,,,,,_aCores,,,,,,,,)
		
		TRB->(dbCloseArea())
		
		//u_arqtrb ("FechaTodos",,,, @_aArqTrb)    
	endif		
Return
// --------------------------------------------------------------------------
// altera banco do pedido pedido
User Function A_LIBPED(_wpedido)

	U_VA_ALTBCO(_wpedido)
	// atualiza arquivo de trabalho
	dbSelectArea("TRB")
	dbSetOrder(1)
	
	RecLock("TRB",.F.)
	    TRB->BANCO   = fBuscaCpo ('SC5', 1, xfilial('SC5') + _wpedido, "C5_BANCO")
	MsUnLock()
Return		
// --------------------------------------------------------------------------
// libera pedido
User Function L_LIBPED()
	_wlibera = .F.
	
	_sSQL := ""
	_sSQL += " SELECT TOP 1 SC9.C9_FILIAL, SC9.C9_PEDIDO, SC9.C9_ITEM, SC9.C9_SEQUEN, SC9.C9_PRODUTO"
	_sSQL += "   FROM SC9010 AS SC9"
	_sSQL += "  WHERE SC9.D_E_L_E_T_ = ''"
	_sSQL += "    AND SC9.C9_FILIAL  = '" + xFilial("SC6") + "'"
	_sSQL += "    AND SC9.C9_PEDIDO  = '" + TRB->PEDIDO + "'"
	_sSQL += "    AND SC9.C9_BLCRED > 0"
	aSC9 := U_Qry2Array(_sSQL)
	
	DbSelectArea("SC9")
	DbSetOrder(1)
	DbSeek( aSC9[1,1] + aSC9[1,2] + aSC9[1,3] + aSC9[1,4] + aSC9[1,5], .F.)
	A450LibMan("SC9", sc9 -> (recno ()),4)
	// verifica se o pedido foi liberado para excluir do browse
	aSC9Apos := U_Qry2Array(_sSQL)
	if len(aSC9Apos) = 0
		// se liberou deleta do arquivo de trabalho
		dbSelectArea("TRB")
		dbSetOrder(1)
		if dbseek (TRB->PEDIDO, .F.)
			reclock ("TRB", .F.)
				TRB -> (dbdelete ())
			msunlock ()
		endif
	endif
Return
// --------------------------------------------------------------------------
// totais por banco
User Function T_LIBPED()
	local _aBancos  := {}
	local _nBancos  := 0
	
	DbSelectArea("TRB")
	DbSetOrder(1)
	Dbgotop()
	Do While ! Eof ()
		_nBancos = ascan (_aBancos, {|_aVal| _aVal [1] == BANCO})
		
		if _nBancos == 0
			aadd (_aBancos, {BANCO, 0 ,0})
			_nBancos = len (_aBancos)
		endif
		
		_aBancos [_nBancos, 2] += 1 
		_aBancos [_nBancos, 3] += VLR_TOT 
			
	   dbskip()
	enddo
	
	if len(_aBancos) > 0 
		_aCols = {}
		aadd (_aCols, {1,  "BANCO"   , 30,  "@!"})
	   	aadd (_aCols, {2,  "PEDIDOS" , 30,  "@E 9999"})
	   	aadd (_aCols, {3,  "VALOR"   , 45,  "@E 999,999.99"})
	    
		U_F3Array (_aBancos, "TOTAIS POR BANCO", _aCols, oMainWnd:nClientWidth - 650, oMainWnd:nClientHeight - 450 , "", "", .T., 'C' )
	endif
Return
//// --------------------------------------------------------------------------
//// Dados adicionais do cliente
//User Function D_LIBPED(sCliente,sLoja)                    
//	Local Folder
//	Local oSay1
//	Local oSay2
//	Local oSay3
//	Local oSay4
//	Local oSay5
//	Local oSay6
//	Local oSay7
//	Local oGet1
//	Local oButton1 
//	Local cObs     := ""
//	Local cQuery   := ""
//	Local aButtons := {}
//	Static oDlg
//	
//	cQuery := " SELECT"
//	cQuery += " 	A1_COD"
//	cQuery += "    ,A1_LOJA"
//	cQuery += "    ,A1_NOME"
//	cQuery += "    ,A1_NATUREZ"
//	cQuery += "    ,ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), A1_VAMUDOU)),'') AS A1_VAMUDOU  "
//	cQuery += " FROM " + RetSqlName("SA1")
//	cQuery += " WHERE D_E_L_E_T_ = ''"
//	cQuery += " AND A1_COD = '"+sCliente+"'"
//	cQuery += " AND A1_LOJA = '"+sLoja+"'"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	TRA->(DbGotop())
//
//	While TRA->(!Eof())	
//		cObs := TRA->A1_VAMUDOU
//
//		DEFINE MSDIALOG oDlg TITLE "Dados Adicionais do Cliente" FROM 000, 000  TO 500, 600 COLORS 0, 16777215 PIXEL
//		
//		@ 038, 004 FOLDER Folder SIZE 291, 206 OF oDlg ITEMS "Cadastrais","Financeiro","Atualizar" COLORS 0, 16777215 MESSAGE "Cadastro" PIXEL
//		@ 007, 007 SAY oSay7 PROMPT "OBS Financeiro" SIZE 040, 007 OF Folder:aDialogs[3] COLORS 0, 16777215 PIXEL
//		@ 020, 007 GET oMultiGe1 VAR cObs OF Folder:aDialogs[3] MULTILINE SIZE 269, 051 COLORS 0, 16777215 HSCROLL PIXEL
//		@ 007, 007 SAY oSay5 PROMPT "Natureza" SIZE 025, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
//		@ 007, 050 SAY oSay6 PROMPT TRA->A1_NATUREZ SIZE 025, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
//		@ 007, 007 SAY oSay1 PROMPT "Cliente" SIZE 020, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
//		@ 007, 050 SAY oSay2 PROMPT TRA->A1_COD SIZE 025, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
//		@ 007, 077 SAY oSay3 PROMPT TRA->A1_LOJA SIZE 010, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
//		@ 007, 095 SAY oSay4 PROMPT TRA->A1_NOME SIZE 130, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
//		EnchoiceBar(oDlg, {|| _GravaCliente(oDlg,sCliente, sLoja, cObs)}, {|| oDlg:End ()},,aButtons)
//		
//		ACTIVATE MSDIALOG oDlg CENTERED
//	 
//		DBSelectArea("TRA")
//		dbskip()
//	EndDo
//	
//	TRA->(DbCloseArea())
//Return
// --------------------------------------------------------------------------
// Dados adicionais do cliente
User Function D_LIBPED(sCliente,sLoja) 
	Local aButtons := {}
	Local Folder
	Local oSay1
	Local oSay10
	Local oSay11
	Local oSay12
	Local oSay13
	Local oSay14
	Local oSay15
	Local oSay16
	Local oSay17
	Local oSay18
	Local oSay19
	Local oSay2
	Local oSay20
	Local oSay21
	Local oSay22
	Local oSay23
	Local oSay24
	Local oSay25
	Local oSay26
	Local oSay27
	Local oSay28
	Local oSay29
	Local oSay3
	Local oSay30
	Local oSay31
	Local oSay32
	Local oSay33
	Local oSay34
	Local oSay35
	Local oSay36
	Local oSay37
	Local oSay38
	Local oSay39
	Local oSay4
	Local oSay40
	Local oSay41
	Local oSay5
	Local oSay6
	Local oSay7
	Local oSay8
	Local oSay9
	//Local oButton1 
	Local cObs     := ""
	Local cQuery   := ""
	//Local aButtons := {}
	Static oDlg
	
	cQuery := " SELECT "
	cQuery += " 	A1_COD"
	cQuery += "    ,A1_LOJA"
	cQuery += "    ,A1_NOME"
	cQuery += "    ,A1_NREDUZ"
	cQuery += "    ,CASE"
	cQuery += " 		WHEN A1_MSBLQL = 1 THEN '1-INATIVO'"
	cQuery += " 		WHEN A1_MSBLQL = 2 THEN '2-ATIVO'"
	cQuery += " 	END AS A1_MSBLQL"
	cQuery += "    ,A1_END"
	cQuery += "    ,A1_BAIRRO"
	cQuery += "    ,A1_EST"
	cQuery += "    ,A1_CEP"
	cQuery += "    ,A1_MUN"
	cQuery += "    ,A1_CONTATO"
	cQuery += "    ,A1_EMAIL"
	cQuery += "    ,A1_NATUREZ"
	cQuery += "    ,A1_BCO1"
	cQuery += "    ,CASE"
	cQuery += " 		WHEN A1_FORMA = 1 THEN '1-BOLETO'"
	cQuery += " 		WHEN A1_FORMA = 2 THEN '2-DEPOSITO'"
	cQuery += " 		WHEN A1_FORMA = 3 THEN '3-DINHEIRO'"
	cQuery += " 	END AS A1_FORMA"
	cQuery += "    ,A1_MCOMPRA"
	cQuery += "    ,A1_MSALDO"
	cQuery += "    ,A1_METR"
	cQuery += "    ,A1_NROCOM"
	cQuery += "    ,A1_ATR"
	cQuery += "    ,A1_TITPROT"
	cQuery += "    ,ISNULL(CONVERT(VARCHAR(2047), CONVERT(VARBINARY(2047), A1_VAMUDOU)), '') AS A1_VAMUDOU"
	cQuery += " FROM " + RetSqlName("SA1")
	cQuery += " WHERE D_E_L_E_T_ = ''"
	cQuery += " AND A1_COD = '"+sCliente+"'"
	cQuery += " AND A1_LOJA = '"+sLoja+"'"
	//dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
	aCliente := U_Qry2Array(cQuery)  
	
	TRA->(DbGotop())
	
	If Len(aCliente) = 1
		sCod 	 := aCliente[1,1]
		sLoja	 := aCliente[1,2]
		sNome	 := aCliente[1,3]
		sNReduz  := aCliente[1,4]
		sBlq	 := aCliente[1,5]
		sEnd	 := aCliente[1,6]
		sBairro	 := aCliente[1,7]
		sUf		 := aCliente[1,8]
		sCep	 := aCliente[1,9]
		sMun	 := aCliente[1,10]
		sContato := aCliente[1,11]
		sEmail	 := aCliente[1,12]
		sNaturez := aCliente[1,13]
		sBco     := aCliente[1,14]
		sFPgto   := aCliente[1,15]
		nMCompra := aCliente[1,16]
		nMSaldo  := aCliente[1,17]
		nMetr    := aCliente[1,18]
		nNroCom  := aCliente[1,19]
		nAtr     := aCliente[1,20]
		nTitProt := aCliente[1,21]
		cObs	 := aCliente[1,22]
		
		DEFINE MSDIALOG oDlg TITLE "Dados Adicionais do Cliente" FROM 000, 000  TO 340, 600 COLORS 0, 16777215 PIXEL
	
		@ 038, 004 FOLDER Folder SIZE 291, 128 OF oDlg ITEMS "Cadastrais","Financeiro","Atualizar" COLORS 0, 16777215 MESSAGE "Cadastro" PIXEL
		// ABA FINANCEIRO
		@ 010, 007 SAY oSay5 PROMPT "Natureza" SIZE 040, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 010, 050 SAY oSay6 PROMPT sNaturez SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 010, 145 SAY oSay26 PROMPT "Banco" SIZE 040, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 010, 190 SAY oSay27 PROMPT sBco SIZE 025, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 022, 007 SAY oSay28 PROMPT "Forma Pgt." SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 022, 050 SAY oSay29 PROMPT sFPgto SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 035, 007 SAY oSay30 PROMPT "Maior compra" SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 035, 050 SAY oSay31 PROMPT nMCompra SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 047, 007 SAY oSay32 PROMPT "Maior saldo" SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 047, 050 SAY oSay33 PROMPT nMSaldo SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 060, 007 SAY oSay34 PROMPT "Média atraso" SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 060, 050 SAY oSay35 PROMPT nMetr SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 072, 007 SAY oSay36 PROMPT "Nº compras" SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 072, 050 SAY oSay37 PROMPT nNroCom SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 085, 007 SAY oSay38 PROMPT "Valor atrasos" SIZE 035, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 085, 050 SAY oSay39 PROMPT nAtr SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 097, 007 SAY oSay40 PROMPT "Tit. protestados" SIZE 040, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		@ 097, 050 SAY oSay41 PROMPT nTitProt SIZE 090, 007 OF Folder:aDialogs[2] COLORS 0, 16777215 PIXEL
		// ABA ATUALIZAR
		@ 007, 007 SAY oSay7 PROMPT "OBS Financeiro" SIZE 040, 007 OF Folder:aDialogs[3] COLORS 0, 16777215 PIXEL
		@ 020, 007 GET oMultiGe1 VAR cObs OF Folder:aDialogs[3] MULTILINE SIZE 269, 051 COLORS 0, 16777215 HSCROLL PIXEL
		// ABA CADASTRIAIS
		@ 010, 007 SAY oSay1 PROMPT "Cliente" SIZE 020, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 010, 050 SAY oSay2 PROMPT sCod SIZE 025, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 010, 077 SAY oSay3 PROMPT sLoja SIZE 010, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 010, 095 SAY oSay4 PROMPT sNome SIZE 130, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 022, 007 SAY oSay8 PROMPT "Nome fantasia" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 022, 050 SAY oSay9 PROMPT sNReduz SIZE 200, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 035, 007 SAY oSay10 PROMPT "Bloqueado" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 035, 050 SAY oSay11 PROMPT sBlq SIZE 100, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 047, 007 SAY oSay12 PROMPT "Endereço" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 047, 050 SAY oSay13 PROMPT sEnd SIZE 200, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 060, 007 SAY oSay15 PROMPT "Bairro" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 060, 050 SAY oSay14 PROMPT sBairro SIZE 150, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 060, 205 SAY oSay16 PROMPT "UF" SIZE 010, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 060, 222 SAY oSay17 PROMPT sUf SIZE 025, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 007 SAY oSay18 PROMPT "Município" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 050 SAY oSay19 PROMPT sMun SIZE 150, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 205 SAY oSay20 PROMPT "CEP" SIZE 015, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 072, 222 SAY oSay21 PROMPT sCep SIZE 060, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 085, 007 SAY oSay22 PROMPT "Contato" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 085, 050 SAY oSay23 PROMPT sContato SIZE 150, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 097, 007 SAY oSay24 PROMPT "E-mail" SIZE 035, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		@ 097, 050 SAY oSay25 PROMPT sEmail SIZE 200, 007 OF Folder:aDialogs[1] COLORS 0, 16777215 PIXEL
		
		ACTIVATE MSDIALOG oDlg ON INIT (EnchoiceBar(oDlg, {||_GravaCliente(oDlg,sCliente, sLoja, cObs),{||oDlg:End()}}, {|| oDlg:End ()},,aButtons))
    Else
    	If Len(aCliente) = 0
    		u_help("Cliente não encontrado!")
    	EndIf
    	If Len(aCliente) > 1
    		u_help("Encontrado mais que um cliente com a chave indicada!")
    	EndIf
	EndIf	  	
Return
// --------------------------------------------------------------------------
//
Static Function _GravaCliente(oDlg,sCliente, sLoja, cObs)
	DbSelectArea("SA1")                
	DbSetOrder(1)
	If SA1 -> (dbseek (xFilial("SA1") + sCliente + sLoja ))
		cOldObs := SA1->A1_VAMUDOU
		RecLock("SA1",.F.)	
			SA1->A1_VAMUDOU := cObs
		MsUnLock()
	EndIf
	oDlg:End()
	
	_oEvento := ClsEvent():New ()
	_oEvento:Alias        = 'SA1'
	_oEvento:Texto        = "Alteração no campo <A1_VAMUDOU> na VA_LIBPED"
	_oEvento:CodEven      = "SA1004"
	_oEvento:Cliente      = alltrim(sCliente)
	_oEvento:LojaCli      = alltrim(sLoja)
	_oEvento:Grava()
	
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    aadd (_aRegsPerg, {01, "Analisa Apenas Bloqueados   ?", "N", 1, 0,  "",   "   ", {"Sim", "Nao"}, ""})
    U_ValPerg (cPerg, _aRegsPerg)
Return
