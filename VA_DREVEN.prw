// Programa..: VA_DREVEN.PRX
// Autor.....: Cláudia Lionço
// Data......: 14/04/2020
// Descrição.: Relatório de rentabilidade
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function VA_DREVEN()
	Private oReport
	
	If ! U_Zzuvl ('039', __cUserId, .T.)
		Return
	Endif
	
	_lContinua := .T.
	
//	// Controle de semaforo.
//	_nLock := U_Semaforo (procname () + cEmpAnt + xfilial ("SA1"))
//	If _nLock == 0
//		msgalert ("Nao foi possivel obter acesso exclusivo a esta rotina nesta empresa/filial.")
//		_lContinua = .F.
//	Endif
	
	cPerg := "VA_DREVEN"
	
	_ValidPerg()
    Pergunte(cPerg,.t.)
    
	oReport := ReportDef()
	oReport:PrintDialog()

Return
// --------------------------------------------------------------------------------------------
// Cria cabeçalho
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("VA_DREVEN","Relatório de Rentabilidade",cPerg,{|oReport| PrintReport(oReport)},"Relatório de Rentabilidade")
	TReport():ShowParamPage()
	
	oReport:ShowParamPage() // imprime parametros
	oReport:SetLineHeight(45)
	oReport:nFontBody := 10
	//oReport:SetPortrait()
	//oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.F.,.F.,.F.) 
	
Return(oReport)
// --------------------------------------------------------------------------------------------
// Imprime os dados de rentabilidade
Static Function PrintReport(oReport)
	Local oSection1   := oReport:Section(1)
	Local _aDados     := {}
	Local _aAnoAnt    := {}
	Local _nBaseDados := mv_par16
	Local _nTipo      := mv_par01
	Local _i          := 0
	//Local _x		  := 1
	//Local _y          := 1
	
	_aDados := U_GeraRent(mv_par01,mv_par02,mv_par03,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,mv_par12,mv_par13,mv_par14,mv_par15, mv_par17)	
	
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
	For _i:= 2 to len(_aDados)
		_sTitulo := ""
		_sDesc   := ""
		Do Case
			Case _nTipo == 1 // supervisor
				_sDesc   := Posicione("ZAE",1,xFilial("ZAE") + _aDados[_i,29], "ZAE_NOME")
				_sTitulo := " SUPERVISOR: " + alltrim(_aDados[_i,29]) + " - " + alltrim(_sDesc)
			Case _nTipo == 2 // cliente
				_sDesc   := Posicione("SA1",1,xFilial("SA1") + _aDados[_i,29] + _aDados[_i,30], "A1_NOME")
				_sTitulo := " CLIENTE: " + alltrim(_aDados[_i,29]) + "/"  +  alltrim(_aDados[_i,30]) + " - " + alltrim(_sDesc)
			Case _nTipo == 3 // rede
				_sDesc   := Posicione("SA1",1,xFilial("SA1") + _aDados[_i,29] + _aDados[_i,30], "A1_NOME")
				_sTitulo := " REDE: " + alltrim(_aDados[_i,29]) + "/"  +  alltrim(_aDados[_i,30]) + " - " + alltrim(_sDesc)
			Case _nTipo == 4 // vendedor
				_sDesc   := Posicione("SA3",1,xFilial("SA3") + _aDados[_i,29] , "A3_NOME")
				_sTitulo := " VENDEDOR: " + alltrim(_aDados[_i,29]) + " - " + alltrim(_sDesc)
			Case _nTipo == 5 // estado
				_sTitulo := " ESTADO: " + alltrim(_aDados[_i,29]) 
		EndCase
		
		Do Case
			Case _nBaseDados == 1 // Previsto  
			 
				oReport:PrintText(_sTitulo,,100)
				oReport:PrintText("",,100)
				oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 4], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 4]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 8], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 8]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,10], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,10]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,12], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,12]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,15], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,15]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,19], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,19]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,21], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,21]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,23], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,23]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				If _aDados[_i, 3] >= 1
					_VlrMargem := _aDados[_i, 3]
				Else
					_VlrMargem := _aDados[_i, 1]
				EndIf
				oReport:PrintText("*** MARGEM PREVISTA            " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,27], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,27]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																	  
				oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
				oReport:PrintText("",,100)
			
			
			Case _nBaseDados == 2 // Realizado
			
				oReport:PrintText(_sTitulo,,100)
				oReport:PrintText("",,100)
				oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 5], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 5]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão realizada          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 9], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 9]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,11], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,11]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,13], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,13]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,16], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,16]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão realizada          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,20], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,20]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,22], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,22]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,24], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,24]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				If _aDados[_i, 3] >= 1
					_VlrMargem := _aDados[_i, 3]
				Else
					_VlrMargem := _aDados[_i, 1]
				EndIf
				oReport:PrintText("*** MARGEM REALIZADA           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,28], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,28]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
				oReport:PrintText("",,100)
				
				
				
			Case _nBaseDados == 3 // Previsto x realizado
			
				oReport:PrintText(_sTitulo,,100)
				oReport:PrintText("",,100)
				oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("                               " + PADL(ALLTRIM("PREVISTO"),35,' ') + PADL(ALLTRIM("REALIZADO"),35,' '),,300)
				oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' '),,300)
				oReport:PrintText("(-)Custo produtos              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 4], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 4]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
				 													  PADL(ALLTRIM(TRANSFORM(_aDados[_i, 5], "@E 999,999,999.99")),25,' ') +;
				 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 5]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300) 
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 8], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 8]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +; 
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i, 9], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 9]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete                       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,10], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,10]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i,11], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,11]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel                       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,12], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,12]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																      PADL(ALLTRIM(TRANSFORM(_aDados[_i,13], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,13]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Custo produtos              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,15], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,15]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i,16], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,16]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Comissão                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,19], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,19]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i,20], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,20]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Frete                       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,21], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,21]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i,22], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,22]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Rapel                       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,23], "@E 999,999,999.99")),25,' ') +;
																      PADL(ALLTRIM(TRANSFORM((_aDados[_i,23]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																      PADL(ALLTRIM(TRANSFORM(_aDados[_i,24], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,24]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("",,100)
				If _aDados[_i, 3] >= 1
					_VlrMargem := _aDados[_i, 3]
				Else
					_VlrMargem := _aDados[_i, 1]
				EndIf
				oReport:PrintText("*** MARGEM                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,27], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,27]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" +;
																	  PADL(ALLTRIM(TRANSFORM(_aDados[_i,28], "@E 999,999,999.99")),25,' ') +;
																	  PADL(ALLTRIM(TRANSFORM((_aDados[_i,28]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
				oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
				oReport:PrintText("",,100)
				
				
			Case _nBaseDados == 4 // Anual Previsto
	
				_dDtAntI := YearSub(mv_par02,1)
				_dDtAntF := YearSub(mv_par03,1)
				
				_sAnoAtual := str(year(mv_par02))
				_sAnoAnt   := str(year(_dDtAntI))
				
				Do Case
					Case _nTipo == 1 // supervisor
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,_aDados[_i,29],_aDados[_i,29],mv_par08,mv_par09,mv_par10,mv_par11,mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 2 // cliente
						_nMax := 30
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,_aDados[_i,29],_aDados[_i,29],_aDados[_i,30],_aDados[_i,30],mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 3 // rede
						_nMax := 30
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,_aDados[_i,29],_aDados[_i,29],_aDados[_i,30],_aDados[_i,30],mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 4 // vendedor
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,_aDados[_i,29],_aDados[_i,29],mv_par14,mv_par15, 2)
					Case _nTipo == 5 // estado
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,mv_par12,mv_par13,_aDados[_i,29],_aDados[_i,29], 2)
				EndCase
			
				If Len(_aAnoAnt) <= 1
					_nValor:=0
					oReport:PrintText(_sTitulo,,100)
					oReport:PrintText("",,100)
					oReport:PrintText("                               " + PADL(ALLTRIM(_sAnoAtual),36,' ') + PADL(ALLTRIM(_sAnoAnt),36,' '),,300)
					oReport:PrintText("                               " + PADL(ALLTRIM("_______"),36,'_') + PADL(ALLTRIM("______"),36,'_'),,300)
					oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') + ;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') ,,300)
					oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					
					oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') +;
																          PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') + PADL(' ',11,' '),,300)
					
					oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 4], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 4]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300) 
					
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 8], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 8]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +; 
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,10], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,10]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Rapel previto               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,12], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,12]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,15], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,15]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,19], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,19]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,21], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,21]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Rapel previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,23], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,23]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					
					oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					If _aDados[_i, 3] >= 1
						_VlrMargem := _aDados[_i, 3]
					Else
						_VlrMargem := _aDados[_i, 1]
					EndIf
					oReport:PrintText("*** MARGEM PREVISTA            " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,27], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,27]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
					oReport:PrintText("",,100)
				Else
					oReport:PrintText(_sTitulo,,100)
					oReport:PrintText("",,100)
					oReport:PrintText("                               " + PADL(ALLTRIM(_sAnoAtual),36,' ') + PADL(ALLTRIM(_sAnoAnt),36,' '),,300)
					oReport:PrintText("                               " + PADL(ALLTRIM("_______"),36,'_') + PADL(ALLTRIM("______"),36,'_'),,300)
					oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' ') + PADL('',11,' ') + ;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 1], "@E 999,999,999.99")),25,' ') + PADL('',11,' ') ,,300)
					oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 2]/_aAnoAnt[2,1]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					
					oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') +;
																          PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' '),,300)
					
					oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 4], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 4]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 4], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 4]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300) 
					
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 6]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 7]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 8], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 8]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +; 
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 8], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 8]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,10], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,10]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,10], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,10]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Rapel previto               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,12], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,12]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,12], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,12]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,14]/_aAnoAnt[2,1]) * 100, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Custo produtos previsto     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,15], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,15]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,15], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,15]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,17]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,18]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Comissão prevista           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,19], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,19]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,19], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,19]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Frete previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,21], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,21]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,21], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,21]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Rapel previsto              " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,23], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,23]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,23], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,23]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,25]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					
					oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,26]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					If _aDados[_i, 3] >= 1
						_VlrMargem := _aDados[_i, 3]
					Else
						_VlrMargem := _aDados[_i, 1]
					EndIf
					//
					If _aAnoAnt[2, 3] >= 1
						_VlrMarAnt := _aAnoAnt[2, 3]
					Else
						_VlrMarAnt := _aAnoAnt[2, 1]
					EndIf

					oReport:PrintText("*** MARGEM PREVISTA             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,27], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,27]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,27], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,27]/_VlrMarAnt) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
					oReport:PrintText("",,100)
				EndIf
				
			Case _nBaseDados == 5 // Anual Realizado
	
				_dDtAntI := YearSub(mv_par02,1)
				_dDtAntF := YearSub(mv_par03,1)
				
				_sAnoAtual := str(year(mv_par02))
				_sAnoAnt   := str(year(_dDtAntI))
				
				Do Case
					Case _nTipo == 1 // supervisor
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,_aDados[_i,29],_aDados[_i,29],mv_par08,mv_par09,mv_par10,mv_par11,mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 2 // cliente
						_nMax := 30
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,_aDados[_i,29],_aDados[_i,29],_aDados[_i,30],_aDados[_i,30],mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 3 // rede
						_nMax := 30
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,_aDados[_i,29],_aDados[_i,29],_aDados[_i,30],_aDados[_i,30],mv_par12,mv_par13,mv_par14,mv_par15, 2)
					Case _nTipo == 4 // vendedor
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,_aDados[_i,29],_aDados[_i,29],mv_par14,mv_par15, 2)
					Case _nTipo == 5 // estado
						_nMax := 29
						_aAnoAnt := U_GeraRent(mv_par01,_dDtAntI,_dDtAntF,mv_par04,mv_par05,mv_par06,mv_par07,mv_par08,mv_par09,mv_par10,mv_par11,mv_par12,mv_par13,_aDados[_i,29],_aDados[_i,29], 2)
				EndCase

				If Len(_aAnoAnt) <= 1
					_nValor:=0
					oReport:PrintText(_sTitulo,,100)
					oReport:PrintText("",,100)
					oReport:PrintText("                               " + PADL(ALLTRIM(_sAnoAtual),36,' ') + PADL(ALLTRIM(_sAnoAnt),36,' '),,300)
					oReport:PrintText("                               " + PADL(ALLTRIM("_______"),36,'_') + PADL(ALLTRIM("______"),36,'_'),,300)
					oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') + ;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') ,,300)
					oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					
					oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') +;
																          PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') + PADL(' ',11,' '),,300)
					
					oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 5], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 5]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300) 
					
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Comissão realizada          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 9], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 9]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +; 
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,11], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,11]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,13], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,13]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,16], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,16]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor * 100, "@E9 999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Comissão realizado          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,20], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,20]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,22], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,22]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,24], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,24]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					
					oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					If _aDados[_i, 3] >= 1
						_VlrMargem := _aDados[_i, 3]
					Else
						_VlrMargem := _aDados[_i, 1]
					EndIf
					oReport:PrintText("*** MARGEM REALIZADA           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,28], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,28]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM(_nValor, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
					oReport:PrintText("",,100)
				Else
					oReport:PrintText(_sTitulo,,100)
					oReport:PrintText("",,100)
					oReport:PrintText("                               " + PADL(ALLTRIM(_sAnoAtual),36,' ') + PADL(ALLTRIM(_sAnoAnt),36,' '),,300)
					oReport:PrintText("                               " + PADL(ALLTRIM("_______"),36,'_') + PADL(ALLTRIM("______"),36,'_'),,300)
					oReport:PrintText("FATURAMENTO                    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 1], "@E 999,999,999.99")),25,' ') + PADL('',11,' ') + ;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 1], "@E 999,999,999.99")),25,' ') + PADL('',11,' ') ,,300)
					oReport:PrintText("DEVOLUÇÕES                     " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 2]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 2], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 2]/_aAnoAnt[2,1]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					
					oReport:PrintText("FATURAMENTO - DEVOLUÇÕES       " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') +;
																          PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 3], "@E 999,999,999.99")),25,' ') + PADL(' ',11,' ') ,,300)
					
					oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 5], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 5]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
					 													  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 5], "@E 999,999,999.99")),25,' ') +;
					 													  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 5]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300) 
					
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 6]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 6], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 6]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 7]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 7], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 7]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Comissão realizada          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 9], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i, 9]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +; 
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 9], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2, 9]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,11], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,11]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,11], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,11]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					
					oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,13], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,13]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,13], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,13]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("BONIFICAÇÕES                   " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,14]/_aDados[_i,1]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,14], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,14]/_aAnoAnt[2,1]) * 100, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Custo produtos realizado    " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,16], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,16]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,16], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,16]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Impostos destacados NF      " + PADL(ALLTRIM(TRANSFORM(_aDados[_i, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,17]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2, 17], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,17]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
																		  
					oReport:PrintText("(-)Impostos sobre faturamento  " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,18]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,18], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,18]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Comissão realizado          " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,20], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,20]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,20], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,20]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Frete realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,22], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,22]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,22], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,22]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
																		  
					oReport:PrintText("(-)Rapel realizado             " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,24], "@E 999,999,999.99")),25,' ') +;
																	      PADL(ALLTRIM(TRANSFORM((_aDados[_i,24]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																	      PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,24], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,24]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("",,100)
					oReport:PrintText("Verbas liberadas               " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,25]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,25], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,25]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					
					oReport:PrintText("(-)Verbas utilizadas           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,26]/_aDados[_i,3]) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,26], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,26]/_aAnoAnt[2,3]) * 100, "@E 9999.99")),10,' ') + "%",,300)
					oReport:PrintText("",,100)
					If _aDados[_i, 3] >= 1
						_VlrMargem := _aDados[_i, 3]
					Else
						_VlrMargem := _aDados[_i, 1]
					EndIf
					If _aAnoAnt[_i, 3] >= 1
						_VlrMarAnt := _aAnoAnt[2, 3]
					Else
						_VlrMarAnt := _aAnoAnt[2, 1]
					EndIf
					oReport:PrintText("*** MARGEM REALIZADA           " + PADL(ALLTRIM(TRANSFORM(_aDados[_i,28], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aDados[_i,28]/_VlrMargem) * 100, "@E 9999.99")),10,' ') + "%" +;
																		  PADL(ALLTRIM(TRANSFORM(_aAnoAnt[2,28], "@E 999,999,999.99")),25,' ') +;
																		  PADL(ALLTRIM(TRANSFORM((_aAnoAnt[2,28]/_VlrMarAnt) * 100, "@E 9999.99")),10,' ') + "%" ,,300)
					oReport:PrintText("___________________________________________________________________________________________________________________________",,100)
					oReport:PrintText("",,100)
				EndIf
		EndCase 
	Next
	oSection1:Finish()
Return
// --------------------------------------------------------------------------------------------
// Gera dados de rentabilidade
// Tipos:
// 1=COMP/VEND;
// 2=Devolucao;
// 3=Bonificacao;
// 4=Comodato;
// 5=Ret.comodato;
// 6=Frete;
// 7=Servicos;
// 8=Uso e Consumo;
// 9=Outros   
//
// _nTipo: 1 - Supervisor, 2 - Cliente, 3 - Rede, 4 - Vendedor, 5 - Estado
//
User Function GeraRent(_nTipo,_dDtaIni,_dDtaFin,_sFilIni,_sFilFin,_sSuperIni,_sSuperFin,_sCliIni,_sCliFin,_sLojaIni,_sLojaFin,_sVendIni,_sVendFin,_sUFIni,_sUFFin, _nImpCsv)
	local _oSQL   := NIL
	Local _aDados := {}
	
	If _nTipo == 3
		_sCliIni  := Posicione("SA1",1,xFilial("SA1") + _sCliIni + _sLojaIni, "A1_VACBASE")
		_sLojaIni := Posicione("SA1",1,xFilial("SA1") + _sCliIni + _sLojaIni, "A1_VALBASE")
		_sCliFin  := _sCliIni
		_sLojaFin := _sLojaIni
	EndIf

	_oSQL:= ClsSQL ():New ()
	_oSQL:_sQuery := " WITH RENTABILIDADE "
	_oSQL:_sQuery += " AS"
	_oSQL:_sQuery += " ("
		// TIPO 1
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		EMISSAO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,SUPER"
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,VENDEDOR"
	_oSQL:_sQuery += " 	   ,ESTADO"
	_oSQL:_sQuery += " 	   ,C_BASE AS REDE"
	_oSQL:_sQuery += " 	   ,L_BASE AS REDE_LOJA"
	_oSQL:_sQuery += " 	   ,SUM(NF_VLR_BRT) AS FATURAMENTO"
	_oSQL:_sQuery += " 	   ,0 AS DEVOLUCAO"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_PREV) AS CUSTO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_REAL) AS CUSTO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,SUM(NF_VALIPI + NF_ICMSRET) AS IMP_DEST_NF_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_DEV"
	_oSQL:_sQuery += " 	   ,SUM(NF_ICMS + NF_COFINS + NF_PIS) AS IMP_SOBFAT_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_DEV"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_PREV) AS COMISSAO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_REAL) AS COMISSAO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_PREVISTO) AS FRETE_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_DEV"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_REALIZADO) AS FRETE_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_DEV"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_PREVISTO) AS RAPEL_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_DEV"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_REALIZADO) AS RAPEL_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS BONIFICACAO"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPDEST"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPSOBFAT"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_REAL"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += " 	FROM LKSRV_BI_ALIANCA.BI_ALIANCA.dbo.VA_RENTABILIDADE"
	_oSQL:_sQuery += " 	WHERE TIPO = '1'"
	_oSQL:_sQuery += " 	AND EMISSAO BETWEEN  '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	_oSQL:_sQuery += " 	AND FILIAL BETWEEN   '" + _sFilIni   + "' AND '" + _sFilFin   + "'"
	If _nTipo == 1 // supervisor
		_oSQL:_sQuery += " 	AND SUPER BETWEEN    '" + _sSuperIni + "' AND '" + _sSuperFin + "'"
	EndIf
	If _nTipo == 2 // cliente
		_oSQL:_sQuery += " 	AND CLIENTE BETWEEN  '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND LOJA BETWEEN     '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf
	If _nTipo == 3 // rede
		_oSQL:_sQuery += " 	AND C_BASE BETWEEN   '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND L_BASE BETWEEN   '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf 
	If _nTipo == 4 // vendedor
		_oSQL:_sQuery += " 	AND VENDEDOR BETWEEN '" + _sVendIni  + "' AND '" + _sVendFin  + "'"
	EndIf
	If _nTipo == 5 // estado
		_oSQL:_sQuery += " 	AND ESTADO BETWEEN   '" + _sUFIni    + "' AND '" + _sUFFin    + "'"
	EndIf
	_oSQL:_sQuery += " 	GROUP BY EMISSAO"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,SUPER"
	_oSQL:_sQuery += " 			,CLIENTE"
	_oSQL:_sQuery += " 			,LOJA"
	_oSQL:_sQuery += " 			,VENDEDOR"
	_oSQL:_sQuery += " 			,ESTADO"
	_oSQL:_sQuery += " 			,C_BASE"
	_oSQL:_sQuery += " 			,L_BASE"
		// TIPO 2
	_oSQL:_sQuery += " 	UNION ALL"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		EMISSAO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,SUPER"
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,VENDEDOR"
	_oSQL:_sQuery += " 	   ,ESTADO"
	_oSQL:_sQuery += " 	   ,C_BASE AS REDE"
	_oSQL:_sQuery += " 	   ,L_BASE AS REDE_LOJA"
	_oSQL:_sQuery += " 	   ,0 AS FATURAMENTO"
	_oSQL:_sQuery += " 	   ,SUM(NF_VLR_BRT * -1) AS DEVOLUCAO"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_PREV * -1) AS CUSTO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_REAL * -1) AS CUSTO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_FAT"
	_oSQL:_sQuery += " 	   ,SUM((NF_VALIPI + NF_ICMSRET) * -1) AS IMP_DEST_NF_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_FAT"
	_oSQL:_sQuery += " 	   ,SUM((NF_ICMS + NF_COFINS + NF_PIS) * -1) AS IMP_SOBFAT_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_PREV * -1) AS COMISSAO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_REAL * -1) AS COMISSAO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_FAT"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_PREVISTO * -1) AS FRETE_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_FAT"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_REALIZADO * -1) AS FRETE_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_FAT"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_PREVISTO * -1) AS RAPEL_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_FAT"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_REALIZADO * -1) AS RAPEL_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS BONIFICACAO"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPDEST"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPSOBFAT"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_REAL"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += " 	FROM LKSRV_BI_ALIANCA.BI_ALIANCA.dbo.VA_RENTABILIDADE"
	_oSQL:_sQuery += " 	WHERE TIPO = '2'"
	_oSQL:_sQuery += " 	AND EMISSAO BETWEEN  '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	_oSQL:_sQuery += " 	AND FILIAL BETWEEN   '" + _sFilIni   + "' AND '" + _sFilFin   + "'"
	If _nTipo == 1 // supervisor
		_oSQL:_sQuery += " 	AND SUPER BETWEEN    '" + _sSuperIni + "' AND '" + _sSuperFin + "'"
	EndIf
	If _nTipo == 2 // cliente
		_oSQL:_sQuery += " 	AND CLIENTE BETWEEN  '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND LOJA BETWEEN     '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf
	If _nTipo == 3 // rede
		_oSQL:_sQuery += " 	AND C_BASE BETWEEN   '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND L_BASE BETWEEN   '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf 
	If _nTipo == 4 // vendedor
		_oSQL:_sQuery += " 	AND VENDEDOR BETWEEN '" + _sVendIni  + "' AND '" + _sVendFin  + "'"
	EndIf
	If _nTipo == 5 // estado
		_oSQL:_sQuery += " 	AND ESTADO BETWEEN   '" + _sUFIni    + "' AND '" + _sUFFin    + "'"
	EndIf
	_oSQL:_sQuery += " 	GROUP BY EMISSAO"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,SUPER"
	_oSQL:_sQuery += " 			,CLIENTE"
	_oSQL:_sQuery += " 			,LOJA"
	_oSQL:_sQuery += " 			,VENDEDOR"
	_oSQL:_sQuery += " 			,ESTADO"
	_oSQL:_sQuery += " 			,C_BASE"
	_oSQL:_sQuery += " 			,L_BASE"
		// TIPO 3
	_oSQL:_sQuery += " 	UNION ALL"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		EMISSAO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,SUPER"
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,VENDEDOR"
	_oSQL:_sQuery += " 	   ,ESTADO"
	_oSQL:_sQuery += " 	   ,C_BASE AS REDE"
	_oSQL:_sQuery += " 	   ,L_BASE AS REDE_LOJA"
	_oSQL:_sQuery += " 	   ,0 AS FATURAMENTO"
	_oSQL:_sQuery += " 	   ,0 AS DEVOLUCAO"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_DEV"
	_oSQL:_sQuery += " 	   ,SUM(NF_VLR_BRT) AS BONIFICACAO"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_PREV) AS BON_CUSTO_PREV"
	_oSQL:_sQuery += " 	   ,SUM(CUSTO_REAL) AS BON_CUSTO_REAL"
	_oSQL:_sQuery += " 	   ,SUM(NF_VALIPI + NF_ICMSRET) AS BON_IMPDEST"
	_oSQL:_sQuery += " 	   ,SUM(NF_ICMS + NF_COFINS + NF_PIS) AS BON_IMPSOBFAT"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_PREV) AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += " 	   ,SUM(VLR_COMIS_REAL) AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_PREVISTO) AS BON_FRETE_PREV"
	_oSQL:_sQuery += " 	   ,SUM(FRETE_REALIZADO) AS BON_FRETE_REAL"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_PREVISTO) AS BON_RAPEL_PREV"
	_oSQL:_sQuery += " 	   ,SUM(RAPEL_REALIZADO) AS BON_RAPEL_REAL"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += " 	FROM LKSRV_BI_ALIANCA.BI_ALIANCA.dbo.VA_RENTABILIDADE"
	_oSQL:_sQuery += " 	WHERE TIPO = '3'"
	_oSQL:_sQuery += " 	AND EMISSAO BETWEEN  '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	_oSQL:_sQuery += " 	AND FILIAL BETWEEN   '" + _sFilIni   + "' AND '" + _sFilFin   + "'"
	If _nTipo == 1 // supervisor
		_oSQL:_sQuery += " 	AND SUPER BETWEEN    '" + _sSuperIni + "' AND '" + _sSuperFin + "'"
	EndIf
	If _nTipo == 2 // cliente
		_oSQL:_sQuery += " 	AND CLIENTE BETWEEN  '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND LOJA BETWEEN     '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf
	If _nTipo == 3 // rede
		_oSQL:_sQuery += " 	AND C_BASE BETWEEN   '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND L_BASE BETWEEN   '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf 
	If _nTipo == 4 // vendedor
		_oSQL:_sQuery += " 	AND VENDEDOR BETWEEN '" + _sVendIni  + "' AND '" + _sVendFin  + "'"
	EndIf
	If _nTipo == 5 // estado
		_oSQL:_sQuery += " 	AND ESTADO BETWEEN   '" + _sUFIni    + "' AND '" + _sUFFin    + "'"
	EndIf
	_oSQL:_sQuery += " 	GROUP BY EMISSAO"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,SUPER"
	_oSQL:_sQuery += " 			,CLIENTE"
	_oSQL:_sQuery += " 			,LOJA"
	_oSQL:_sQuery += " 			,VENDEDOR"
	_oSQL:_sQuery += " 			,ESTADO"
	_oSQL:_sQuery += " 			,C_BASE"
	_oSQL:_sQuery += " 			,L_BASE"
		// TIPO A
	_oSQL:_sQuery += " 	UNION ALL"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		EMISSAO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,SUPER"
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,VENDEDOR"
	_oSQL:_sQuery += " 	   ,ESTADO"
	_oSQL:_sQuery += " 	   ,C_BASE AS REDE"
	_oSQL:_sQuery += " 	   ,L_BASE AS REDE_LOJA"
	_oSQL:_sQuery += " 	   ,0 AS FATURAMENTO"
	_oSQL:_sQuery += " 	   ,0 AS DEVOLUCAO"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS BONIFICACAO"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPDEST"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPSOBFAT"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_REAL"
	_oSQL:_sQuery += " 	   ,SUM(VERBAS_LIB) AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += " 	FROM LKSRV_BI_ALIANCA.BI_ALIANCA.dbo.VA_RENTABILIDADE"
	_oSQL:_sQuery += " 	WHERE TIPO = 'A'"
	_oSQL:_sQuery += " 	AND EMISSAO BETWEEN  '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	_oSQL:_sQuery += " 	AND FILIAL BETWEEN   '" + _sFilIni   + "' AND '" + _sFilFin   + "'"
	If _nTipo == 1 // supervisor
		_oSQL:_sQuery += " 	AND SUPER BETWEEN    '" + _sSuperIni + "' AND '" + _sSuperFin + "'"
	EndIf
	If _nTipo == 2 // cliente
		_oSQL:_sQuery += " 	AND CLIENTE BETWEEN  '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND LOJA BETWEEN     '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf
	If _nTipo == 3 // rede
		_oSQL:_sQuery += " 	AND C_BASE BETWEEN   '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND L_BASE BETWEEN   '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf 
	If _nTipo == 4 // vendedor
		_oSQL:_sQuery += " 	AND VENDEDOR BETWEEN '" + _sVendIni  + "' AND '" + _sVendFin  + "'"
	EndIf
	If _nTipo == 5 // estado
		_oSQL:_sQuery += " 	AND ESTADO BETWEEN   '" + _sUFIni    + "' AND '" + _sUFFin    + "'"
	EndIf
	_oSQL:_sQuery += " 	GROUP BY EMISSAO"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,SUPER"
	_oSQL:_sQuery += " 			,CLIENTE"
	_oSQL:_sQuery += " 			,LOJA"
	_oSQL:_sQuery += " 			,VENDEDOR"
	_oSQL:_sQuery += " 			,ESTADO"
	_oSQL:_sQuery += " 			,C_BASE"
	_oSQL:_sQuery += " 			,L_BASE"
	_oSQL:_sQuery += " 
		// TIPO 6
	_oSQL:_sQuery += " 	UNION ALL"
	_oSQL:_sQuery += " 	SELECT"
	_oSQL:_sQuery += " 		EMISSAO"
	_oSQL:_sQuery += " 	   ,FILIAL"
	_oSQL:_sQuery += " 	   ,SUPER"
	_oSQL:_sQuery += " 	   ,CLIENTE"
	_oSQL:_sQuery += " 	   ,LOJA"
	_oSQL:_sQuery += " 	   ,VENDEDOR"
	_oSQL:_sQuery += " 	   ,ESTADO"
	_oSQL:_sQuery += " 	   ,C_BASE AS REDE"
	_oSQL:_sQuery += " 	   ,L_BASE AS REDE_LOJA"
	_oSQL:_sQuery += " 	   ,0 AS FATURAMENTO"
	_oSQL:_sQuery += " 	   ,0 AS DEVOLUCAO"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS CUSTO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_DEST_NF_DEV"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_FAT"
	_oSQL:_sQuery += " 	   ,0 AS IMP_SOBFAT_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS COMISSAO_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS FRETE_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_PREV_DEV"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_FAT"
	_oSQL:_sQuery += " 	   ,0 AS RAPEL_REAL_DEV"
	_oSQL:_sQuery += " 	   ,0 AS BONIFICACAO"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_CUSTO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPDEST"
	_oSQL:_sQuery += " 	   ,0 AS BON_IMPSOBFAT"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_FRETE_REAL"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_PREV"
	_oSQL:_sQuery += " 	   ,0 AS BON_RAPEL_REAL"
	_oSQL:_sQuery += " 	   ,0 AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += " 	   ,SUM(VERBAS_UTIL) AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += " 	FROM LKSRV_BI_ALIANCA.BI_ALIANCA.dbo.VA_RENTABILIDADE"
	_oSQL:_sQuery += " 	WHERE TIPO = '6'"
	_oSQL:_sQuery += " 	AND EMISSAO BETWEEN  '" + DTOS(_dDtaIni) + "' AND '" + DTOS(_dDtaFin) + "'"
	_oSQL:_sQuery += " 	AND FILIAL BETWEEN   '" + _sFilIni   + "' AND '" + _sFilFin   + "'"
	If _nTipo == 1 // supervisor
		_oSQL:_sQuery += " 	AND SUPER BETWEEN    '" + _sSuperIni + "' AND '" + _sSuperFin + "'"
	EndIf
	If _nTipo == 2 // cliente
		_oSQL:_sQuery += " 	AND CLIENTE BETWEEN  '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND LOJA BETWEEN     '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf
	If _nTipo == 3 // rede
		_oSQL:_sQuery += " 	AND C_BASE BETWEEN   '" + _sCliIni   + "' AND '" + _sCliFin   + "'"
		_oSQL:_sQuery += " 	AND L_BASE BETWEEN   '" + _sLojaIni  + "' AND '" + _sLojaFin  + "'"
	EndIf 
	If _nTipo == 4 // vendedor
		_oSQL:_sQuery += " 	AND VENDEDOR BETWEEN '" + _sVendIni  + "' AND '" + _sVendFin  + "'"
	EndIf
	If _nTipo == 5 // estado
		_oSQL:_sQuery += " 	AND ESTADO BETWEEN   '" + _sUFIni    + "' AND '" + _sUFFin    + "'"
	EndIf
	_oSQL:_sQuery += " 	GROUP BY EMISSAO"
	_oSQL:_sQuery += " 			,FILIAL"
	_oSQL:_sQuery += " 			,SUPER"
	_oSQL:_sQuery += " 			,CLIENTE"
	_oSQL:_sQuery += " 			,LOJA"
	_oSQL:_sQuery += " 			,VENDEDOR"
	_oSQL:_sQuery += " 			,ESTADO"
	_oSQL:_sQuery += " 			,C_BASE"
	_oSQL:_sQuery += " 			,L_BASE)"
	_oSQL:_sQuery += " SELECT"
	_oSQL:_sQuery += "     SUM(FATURAMENTO) AS FATURAMENTO"
	_oSQL:_sQuery += "    ,SUM(DEVOLUCAO) AS DEVOLUCAO"
	_oSQL:_sQuery += "    ,SUM(FATURAMENTO - DEVOLUCAO) AS DIF_FAT_DEV"
	_oSQL:_sQuery += "    ,SUM(CUSTO_PREV_FAT - CUSTO_PREV_DEV) AS CUSTO_PREV"
	_oSQL:_sQuery += "    ,SUM(CUSTO_REAL_FAT - CUSTO_REAL_DEV) AS CUSTO_REAL"
	_oSQL:_sQuery += "    ,SUM(IMP_DEST_NF_FAT - IMP_DEST_NF_DEV) AS IMP_DEST_NF"
	_oSQL:_sQuery += "    ,SUM(IMP_SOBFAT_FAT - IMP_SOBFAT_DEV) AS IMP_SOBFAT"
	_oSQL:_sQuery += "    ,SUM(COMISSAO_PREV_FAT - COMISSAO_PREV_DEV) AS COMISSAO_PREV"
	_oSQL:_sQuery += "    ,SUM(COMISSAO_REAL_FAT - COMISSAO_REAL_DEV) AS COMISSAO_REAL"
	_oSQL:_sQuery += "    ,SUM(FRETE_PREV_FAT - FRETE_PREV_DEV) AS FRETE_PREV"
	_oSQL:_sQuery += "    ,SUM(FRETE_REAL_FAT - FRETE_REAL_DEV) AS FRETE_REAL"
	_oSQL:_sQuery += "    ,SUM(RAPEL_PREV_FAT - RAPEL_PREV_DEV) AS RAPEL_PREV"
	_oSQL:_sQuery += "    ,SUM(RAPEL_REAL_FAT - RAPEL_REAL_DEV) AS RAPEL_REAL"
	_oSQL:_sQuery += "    ,SUM(BONIFICACAO) AS BONIFICACAO"
	_oSQL:_sQuery += "    ,SUM(BON_CUSTO_PREV) AS BON_CUSTO_PREV"
	_oSQL:_sQuery += "    ,SUM(BON_CUSTO_REAL) AS BON_CUSTO_REAL"
	_oSQL:_sQuery += "    ,SUM(BON_IMPDEST) AS BON_IMPDEST"
	_oSQL:_sQuery += "    ,SUM(BON_IMPSOBFAT) AS BON_IMPSOBFAT"
	_oSQL:_sQuery += "    ,SUM(BON_COMISSAO_PREV) AS BON_COMISSAO_PREV"
	_oSQL:_sQuery += "    ,SUM(BON_COMISSAO_REAL) AS BON_COMISSAO_REAL"
	_oSQL:_sQuery += "    ,SUM(BON_FRETE_PREV) AS BON_FRETE_PREV"
	_oSQL:_sQuery += "    ,SUM(BON_FRETE_REAL) AS BON_FRETE_REAL"
	_oSQL:_sQuery += "    ,SUM(BON_RAPEL_PREV) AS BON_RAPEL_PREV"
	_oSQL:_sQuery += "    ,SUM(BON_RAPEL_REAL) AS BON_RAPEL_REAL"
	_oSQL:_sQuery += "    ,SUM(VERBAS_LIBERADAS) AS VERBAS_LIBERADAS"
	_oSQL:_sQuery += "    ,SUM(VERBAS_UTILIZADAS) AS VERBAS_UTILIZADAS"
	_oSQL:_sQuery += "    ,SUM(FATURAMENTO - DEVOLUCAO) - SUM(CUSTO_PREV_FAT - CUSTO_PREV_DEV) - SUM(IMP_DEST_NF_FAT - IMP_DEST_NF_DEV) - SUM(IMP_SOBFAT_FAT - IMP_SOBFAT_DEV) - SUM(COMISSAO_PREV_FAT - COMISSAO_PREV_DEV) - SUM(FRETE_PREV_FAT - FRETE_PREV_DEV) - SUM(RAPEL_PREV_FAT - RAPEL_PREV_DEV) - SUM(BON_CUSTO_PREV) - SUM(BON_IMPDEST) - SUM(BON_IMPSOBFAT) - SUM(BON_COMISSAO_PREV) - SUM(BON_FRETE_PREV) - SUM(BON_RAPEL_PREV) - SUM(VERBAS_UTILIZADAS) AS MARGEM_PREVISTA"
	_oSQL:_sQuery += "    ,SUM(FATURAMENTO - DEVOLUCAO) - SUM(CUSTO_REAL_FAT - CUSTO_REAL_DEV) - SUM(IMP_DEST_NF_FAT - IMP_DEST_NF_DEV) - SUM(IMP_SOBFAT_FAT - IMP_SOBFAT_DEV) - SUM(COMISSAO_REAL_FAT - COMISSAO_REAL_DEV) - SUM(FRETE_REAL_FAT - FRETE_REAL_DEV) - SUM(RAPEL_REAL_FAT - RAPEL_REAL_DEV) - SUM(BON_CUSTO_REAL) - SUM(BON_IMPDEST) - SUM(BON_IMPSOBFAT) - SUM(BON_COMISSAO_REAL) - SUM(BON_FRETE_REAL) - SUM(BON_RAPEL_REAL) - SUM(VERBAS_UTILIZADAS) AS MARGEM_REALIZADA"
	Do Case 
		Case _nTipo == 1
			_oSQL:_sQuery += " 	,SUPER"
		Case _nTipo == 2
			_oSQL:_sQuery += " 	,CLIENTE, LOJA"
		Case _nTipo == 3
			_oSQL:_sQuery += " 	,REDE, REDE_LOJA"
		Case _nTipo == 4
			_oSQL:_sQuery += " 	,VENDEDOR"
		Case _nTipo == 5
			_oSQL:_sQuery += " 	,ESTADO"
	EndCase
	_oSQL:_sQuery += " FROM RENTABILIDADE"
	Do Case 
		Case _nTipo == 1
			_oSQL:_sQuery += " 	GROUP BY SUPER"
			_oSQL:_sQuery += " 	ORDER BY SUPER"
		Case _nTipo == 2
			_oSQL:_sQuery += " 	GROUP BY CLIENTE, LOJA"
			_oSQL:_sQuery += " 	ORDER BY CLIENTE, LOJA"
		Case _nTipo == 3
			_oSQL:_sQuery += " 	GROUP BY REDE, REDE_LOJA"
			_oSQL:_sQuery += " 	ORDER BY REDE, REDE_LOJA"
		Case _nTipo == 4
			_oSQL:_sQuery += " 	GROUP BY VENDEDOR"
			_oSQL:_sQuery += " 	ORDER BY VENDEDOR"
		Case _nTipo == 5
			_oSQL:_sQuery += " 	GROUP BY ESTADO"
			_oSQL:_sQuery += " 	ORDER BY ESTADO"
	EndCase
	_oSQL:Log()
	
	If _nImpCsv == 1
		_oSQL:Qry2XLS()
	EndIf
	
	_aDados := aclone (_oSQL:Qry2Array (.t.,.t.))
	
	/* RETORNO
		_aDados[_i,1]  = Faturamento
		_aDados[_i,2]  = Devoluções
		_aDados[_i,3]  = Faturamento - Devoluções
		_aDados[_i,4]  = Custo produtos previsto
		_aDados[_i,5]  = Custo produtos realizada
		_aDados[_i,6]  = Impostos destacados NF
		_aDados[_i,7]  = Impostos sobre faturamento
		_aDados[_i,8]  = Comissão prevista
		_aDados[_i,9]  = Comissão realizada
		_aDados[_i,10] = Frete previsto
		_aDados[_i,11] = Frete realizado
		_aDados[_i,12] = Rapel previsto
		_aDados[_i,13] = Rapel realizado
		_aDados[_i,14] = Bonificações
		_aDados[_i,15] = Custo produtos previsto
		_aDados[_i,16] = Custo produto realizado
		_aDados[_i,17] = Impostos destacados NF
		_aDados[_i,18] = Impostos sobre faturamento
		_aDados[_i,19] = Comissão prevista
		_aDados[_i,20] = Comissão realizada
		_aDados[_i,21] = Frete previsto
		_aDados[_i,22] = Frete realizado
		_aDados[_i,23] = Rapel previsto
		_aDados[_i,24] = Rapel realizado
		_aDados[_i,25] = Verbas liberadas
		_aDados[_i,26] = Verbas utilizadas
		_aDados[_i,27] = Margem prevista
		_aDados[_i,28] = Margem realizada 
		_aDados[_i,29] = Supervisor/Cliente/Rede/Vendedor/Estado
		_aDados[_i,30] = Loja cliente/ Loja rede
	*/
Return _aDados
// --------------------------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT               TIPO TAM DEC VALID F3     Opcoes                     							Help
	aadd (_aRegsPerg, {01, "Tipo DRE          ", "N", 1,  0,  "",   "   ", {"Supervisor","Cliente","Rede","Vendedor","Estado"},				""						})
	aadd (_aRegsPerg, {02, "Periodo de        ", "D", 8,  0,  "",   "   ", {},                        						 				""						})
	aadd (_aRegsPerg, {03, "Periodo ate       ", "D", 8,  0,  "",   "   ", {},                        										""						})
	aadd (_aRegsPerg, {04, "Filial de         ", "C", 2,  0,  "",   "SM0", {},                        										""						})
    aadd (_aRegsPerg, {05, "Filial até        ", "C", 2,  0,  "",   "SM0", {},                        										""						})
	aadd (_aRegsPerg, {06, "Supervisor de     ", "C", 6,  0,  "",   "ZAE", {},                        										"Supervisor Inicial"	})
	aadd (_aRegsPerg, {07, "Supervisor até    ", "C", 6,  0,  "",   "ZAE", {},                        										"Supervidor Final"		})
	aadd (_aRegsPerg, {08, "Cliente de        ", "C", 6,  0,  "",   "SA1", {},                        										"Cliente Inicial"		})
	aadd (_aRegsPerg, {09, "Cliente ate       ", "C", 6,  0,  "",   "SA1", {},                        										"Cliente Final"			})
	aadd (_aRegsPerg, {10, "Loja de           ", "C", 2,  0,  "",   "   ", {},                        										"Loja Inicial"			})
	aadd (_aRegsPerg, {11, "Loja ate          ", "C", 2,  0,  "",   "   ", {},                        										"Loja Final"			})
	aadd (_aRegsPerg, {12, "Vendedor de  	  ", "C", 3,  0,  "",   "SA3", {},                        										"Vendedor Inicial"		})
	aadd (_aRegsPerg, {13, "Vendedor até      ", "C", 3,  0,  "",   "SA3", {},                        										"Vendedor Final"		})
	aadd (_aRegsPerg, {14, "UF de             ", "C", 2,  0,  "",   "12 ", {},                        										"UF inicial do cliente" })
	aadd (_aRegsPerg, {15, "UF ate            ", "C", 2,  0,  "",   "12 ", {},                        										"UF final do cliente"	})
	aadd (_aRegsPerg, {16, "Base Informações  ", "N", 1,  0,  "",   "   ", {"Previsto","Realizado","Previsto X Realizado","Anual Previsto", "Anual Realizado"},	""  })
	aadd (_aRegsPerg, {17, "Imprime planilha  ", "N", 1,  0,  "",   "   ", {"Sim","Não"},													"Planilha .CSV estilo Banco de Dados"})

   	U_ValPerg (cPerg, _aRegsPerg)   	  
   	
Return
