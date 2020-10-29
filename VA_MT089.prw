// Programa...: VA_MT089
// Autor......: Cláudia Lionço
// Data.......: 08/10/2019
// Descricao..: Tela de manutencao do TES Inteligente

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Manutencao do arquivo de TES inteligente (SFM) em formato de grid
// #PalavasChave      #TES_inteligente #manutencao_em_grid
// #TabelasPrincipais #SFM
// #Modulos           #FIS

// Historico de alteracoes:
// 17/10/2019 - Cláudia - Incluida rotina AxCadastro para inclusão de um unico registro
// 14/01/2020 - Cláudia - Alteração de leitura e gravação da SX5 devido as validações da R25
// 15/05/2020 - Claudia - Incluida validações de mensagens, conforme GPLI: 7920
// 29/10/2020 - Robert  - Invertido teste de grupo de produtos na carastrado para evitar msg REGNOIS
//                      - Inseridas tags para catalogo de programas.
//

//-------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'
#include "rwmake.ch"

// ------------------------------------------------------------------------------------------
User Function VA_MT089 ()
	private aRotina   := {}
	private cString   := "SFM"
	private cCadastro := "Manutenção de TES Inteligente - Aliança"
	
	_cPerg   := "VA_MT089"
	_ValidPerg()
    Pergunte(_cPerg,.T.)
    
    If empty(mv_par01) 
    	u_help("É obrigatório o uso do filtro de <Tipo de Operação> nesta rotina!")
    Else
    	_sPreFiltr:=""
    	_sPreFiltr += IIf(!empty(mv_par01),"FM_TIPO = '" + alltrim(mv_par01) + "'","")
    	If !empty(_sPreFiltr) .and.!empty(mv_par02)
    		_sPreFiltr +=" AND "
    	EndIf
    	_sPreFiltr += IIf(!empty(mv_par02),"FM_EST = '" + upper(alltrim(mv_par02)) + "'","")
    	
		aadd (aRotina, {"&Pesquisar"	, "AxPesqui"	, 	0, 1})
		aadd (aRotina, {"&Visualizar"	, "U_MT89A (2)"	,   0, 2})
		aadd (aRotina, {"&Incluir"		, "U_MT89I"		,   0, 3})
		aadd (aRotina, {"&Alterar"		, "U_MT89A (4, 	'allwaystrue ()', 'allwaystrue ()', .T., _sPreFiltr)",   0, 4})
		aadd (aRotina, {"&Relatório"	, "U_MT89R (6)"	,   0, 6})
		
		dbselectarea ("SFM")
		dbSetOrder (1)
		
		aCabTela  := {} 
		aadd (aCabTela,{ "Grupo de tributação"	,"FM_GRTRIB"	})
		aadd (aCabTela,{ "Grupo de produto"		,"FM_GRPROD"	})
		aadd (aCabTela,{ "Estado"				,"FM_EST"		})
		aadd (aCabTela,{ "Tipo de cliente"		,"FM_TIPOCLI"	})
		aadd (aCabTela,{ "Tipo de operação"		,"FM_TIPO"		})
		aadd (aCabTela,{ "TES de entrada"		,"FM_TE"		})
		aadd (aCabTela,{ "TES de saída"			,"FM_TS"		})
		aadd (aCabTela,{ "Tipo de pedido"		,"FM_TIPOMOV"	})
		aadd (aCabTela,{ "NCM"					,"FM_POSIPI"	})
		aadd (aCabTela,{ "Produto"			    ,"FM_PRODUTO"	})
		aadd (aCabTela,{ "Enq. IPI"				,"FM_GRPCST"	})
		
		mBrowse(,,,,"SFM",aCabTela,,,,,,,,,,,,,_sPreFiltr)
	EndIf
return
// --------------------------------------------------------------------------
// Incluir AxCadastro
User Function MT89I()
	nOpcA  := AxInclui("SFM",,,,,,"U_MT89TudOk()")
	If nOpcA = 1
		_sId := U_MT89SX5()
		_Mt89GrAx(_sId)			
	EndIf
Return
// --------------------------------------------------------------------------
// Visualizacao, Alteracao, Exclusao
User Function MT89A (_nOpcao, _sLinhaOK, _sTudoOK, _lFiltro, _sPreFiltr)
	local _lContinua  := .T.
	local _aCampos    := {}
	local _sFiltro    := ""
	local _n		  := 0
	private _sModo    := ""
	private aHeader   := {}
	private aCols     := {}
	private inclui    := (_nOpcao == 3)
	private altera    := (_nOpcao == 4)
	private nOpc      := _nOpcao
	
	SFM -> (dbsetorder (1))
	
	If _lContinua
		CursorWait ()
		_sTipoOp  := alltrim(mv_par01)
		_sSeek    := xfilial ("SFM") + _sTipoOp
		_sWhile   := "FM_TIPO == '" +_sTipoOp +"'"
		_aCampos  := U_MT89Cpos ()
		// filtro
    	_sFiltro += IIf(!empty(mv_par01),"FM_TIPO = '" + alltrim(mv_par01) + "'","")
    	If !empty(_sFiltro) .and.!empty(mv_par02)
    		_sFiltro +=" .AND. "
    	EndIf
    	_sFiltro += IIf(!empty(mv_par02),"FM_EST = '" + upper(alltrim(mv_par02)) + "'","")    	
				
		aHeader := U_GeraHead (""		,; // Arquivo
		                       .F.		,; // Para MSNewGetDados, informar .T.
		                       {}		,; // Campos a nao incluir
		                       _aCampos	,; // Campos a incluir
		                       .T.		 ) // Apenas os campos informados.
		
		aCols := U_GeraCols ("SFM"		,;  // Alias
		                      1			,;  // Indice
		                      _sSeek	,;  // Seek inicial
		                      _sWhile	,;  // While
		                      aHeader	,;  // aHeader
		                      .F.		,;  // Nao executa gatilhos
		                      altera	,;  // Gera linha vazia, se nao encontrar dados.
		                      .T.		,;  // Trava registros
		                      _sFiltro )  // Expressao para filtro adicional
		
		CursorArrow ()

		// Variaveis para o Modelo2
		sTitulo := "Manutenção de TES Inteligente"
		aC   := {}
		aR   := {}
		aCGD := {80,   5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		aCJN := {100, 50, oMainWnd:nClientHeight - 50     , oMainWnd:nClientWidth - 50}
		
		_lContinua = Modelo2 (sTitulo	,;  // Titulo
		                 aC				,;  // Cabecalho
		                 aR				,;  // Rodape
		                 aCGD			,;  // Coordenadas da getdados
		                 nOpc			,;  // nOPC
		                 "U_MT89LOK ()"	,;  // Linha OK
		                 _sTudoOK		,;  // Tudo OK
										,;  // Gets editaveis
										,;  // bloco codigo para tecla F4
										,;  // Campos inicializados
						 999			,;  // Numero maximo de linhas
		                 aCJN			,;  // Coordenadas da janela
		                 .T.			)   // Linhas podem ser deletadas.
		If _lContinua
			If nOpc == 5 
				// caso necessite de 
			Else	
				// Grava dados do aCols.
				SFM -> (dbsetorder (1))
				_aCposFora := {}
				
				For _n = 1 to len (aCols)
					N = _n
					_sGrTrib := GDFieldGet ("FM_GRTRIB")
					_sEst	 := GDFieldGet ("FM_EST")
					_sGrProd := GDFieldGet ("FM_GRPROD")
					_sTipCli := GDFieldGet ("FM_TIPOCLI")
					_sTipOp  := GDFieldGet ("FM_TIPO")
					_sTe	 := GDFieldGet ("FM_TE")
					_sTs	 := GDFieldGet ("FM_TS")
					_sTipPed := GDFieldGet ("FM_TIPOMOV")
					_sNCM    := GDFieldGet ("FM_POSIPI")
					_sProd   := GDFieldGet ("FM_PRODUTO")
					_sEnqIPI := GDFieldGet ("FM_GRPCST")				
					_recno   := GDFieldGet ("ZZZ_RECNO")
					
					// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
					If GDFieldGet ("ZZZ_RECNO") > 0
						SFM -> (dbgoto (GDFieldGet ("ZZZ_RECNO")))
		
						// Se esta deletado em aCols, preciso excluir do arquivo tambem.
						If GDDeleted ()
							reclock ("SFM", .F.)
							SFM -> (dbdelete ())
							msunlock ("SFM")
							
							_GrvDesc := "Exclusão de Tes inteligente (Grid)"
							_Mt89GrvEv (_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _GrvDesc)
						Else
							// verifica se alterado ou apenas repasse do grid
							_AltDes := ""
							_lAlt := _VerAltReg(_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _recno,_AltDes)
							
							If _lAlt == .F.
								_GrvDesc := "Alteração de Tes inteligente (Grid) " + alltrim(_AltDes)
								_Mt89GrvEv (_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _GrvDesc)
							EndIf
							
							reclock ("SFM", .F.)
							U_GrvACols ("SFM", N, _aCposFora)
							msunlock ("SFM")
						EndIf
		
					Else  // A linha ainda nao existe no arquivo
						If GDDeleted ()
							loop
						Else
							_sId := U_MT89SX5()
							
							reclock ("SFM", .T.)
							U_GrvACols ("SFM", N, _aCposFora)
							sfm -> fm_id = _sId
							msunlock ("SFM")
							
							_GrvDesc := "Inclusão de Tes inteligente (Grid)"
							_Mt89GrvEv (_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _GrvDesc)
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	Endif

	SFM -> (dbgotop ())
Return
// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function MT89LOK ()
	local _lRet := .T.
//	u_log2 ('debug', 'iniciando ' + procname ())

	If _lRet .and. ! GDDeleted ()
//		u_log2 ('debug', 'vou chamar GDCheckKey')
//		_lRet = GDCheckKey ({"FM_FILIAL","FM_TIPOCLI","FM_GRTRIB","FM_GRPROD","FM_EST","FM_TIPO"}, 4, {}, "Registro duplicado", .t.)
		_lRet = GDCheckKey ({"FM_GRTRIB","FM_GRPROD","FM_EST","FM_TIPOCLI","FM_TIPO"}, 4)
//		u_log2 ('debug', 'voltou do GDCheckKey com ' + cvaltochar (_lRet))
	Endif
	
	If _lRet .and. ! GDDeleted ()
//		If empty(GDFieldGet("FM_GRTRIB"))
//			u_help("Campo Grupo de tributação é obrigatório!")
//			_lRet := .F.
//		EndIf
//		
//		If empty(GDFieldGet("FM_GRPROD"))
//			u_help("Campo Grupo tributário do produto é obrigatório")
//			_lRet := .F.
//		EndIf
//		
//		If empty(GDFieldGet("FM_EST"))
//			u_help("Campo Estado é obrigatório")
//			_lRet := .F.
//		EndIf
//		
//		If empty(GDFieldGet("FM_TIPOCLI"))
//			u_help("Campo Tipo de cliente é obrigatório")
//			_lRet := .F.
//		EndIf
		
//		u_log2 ('debug', 'testando campos 1')
		If empty(GDFieldGet("FM_TIPO"))
			u_help("Campo Tipo de operação é obrigatório",, .t.)
			_lRet := .F.
		Else
			If GDFieldGet("FM_TIPO") <> mv_par01
				u_help("Tipo de operação diferente do parâmetro selecionado! Não será possível incluir o registro.",, .t.)
				_lRet := .F.
			EndIf
		EndIf
		
		//u_log2 ('debug', 'testando campos 2')
		If empty(GDFieldGet("FM_TE")) .and. empty(GDFieldGet("FM_TS"))
			u_help("Campos Tes de entrada e Tes de saída vazios! Obrigatório o preenchimento de um dos campos.",, .t.)
			_lRet := .F.
		EndIf
	EndIf
	
	If _lRet .and. ! GDDeleted ()
		//u_log2 ('debug', 'testando campos 3')
//		If (ExistCpo ("SX5", "ZF" + (GDFieldGet("FM_GRTRIB"))) == .F.) .and. !empty(GDFieldGet("FM_GRTRIB"))
		If !empty(GDFieldGet("FM_GRTRIB")) .and. ! ExistCpo ("SX5", "ZF" + GDFieldGet("FM_GRTRIB"))
			u_help("Valor digitado no campo <Grupo de tributação> não existe no cadastro!",, .t.)
			_lRet := .F.
		EndIf

		//u_log2 ('debug', 'testando campos 4')
		If alltrim(GDFieldGet("FM_GRPROD")) <> ''
//			If (ExistCpo ("SX5", "21" + (GDFieldGet("FM_GRPROD"))) == .F.) .and. (!empty(GDFieldGet("FM_GRPROD")))
			If !empty(GDFieldGet("FM_GRPROD")) .and. ! ExistCpo ("SX5", "21" + GDFieldGet("FM_GRPROD"))
				u_help("Valor digitado no campo <Grupo de tributação do produto> não existe no cadastro!",, .t.)
				_lRet := .F.
			EndIf
		EndIf

		If alltrim(GDFieldGet("FM_EST")) <> ''
//			If (ExistCpo ("SX5", "12" + (GDFieldGet("FM_EST"))) == .F.) .and. (!empty(GDFieldGet("FM_EST")))
			If !empty(GDFieldGet("FM_EST")) .and. ! ExistCpo ("SX5", "12" + GDFieldGet("FM_EST"))
				u_help("Valor digitado no campo <Estado> não existe no cadastro!",, .t.)
				_lRet := .F.
			EndIf
		EndIf
		  
		If alltrim(GDFieldGet("FM_TIPO")) <> ''
			If (ExistCpo ("SX5","DJ" + (GDFieldGet("FM_TIPO"))) == .F.) .and. (!empty(GDFieldGet("FM_TIPO")))
				u_help("Valor digitado no campo <Tipo de Operação> não existe no cadastro!",, .t.)
				_lRet := .F.
			EndIf
		EndIf
		   
		If !empty(GDFieldGet("FM_TE")) .and. ExistCpo ("SF4",(GDFieldGet("FM_TE"))) == .F.
			u_help("Valor digitado no campo <Tes de entrada> não existe no cadastro!",, .t.)
			_lRet := .F.
		EndIf	
		
		If !empty(GDFieldGet("FM_TS")) .and. ExistCpo ("SF4",(GDFieldGet("FM_TS")))  == .F.
			u_help("Valor digitado no campo <Tes de saída> não existe no cadastro!",, .t.)
			_lRet := .F.
		EndIf
	EndIf
	//u_log2 ('debug', 'finalizando ' + procname ())
Return _lRet
// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function MT89TudOk()
	Local _lRet := .T.
	
	If _lRet 
//		If empty(M -> FM_GRTRIB)
//			u_help("Campo Grupo de tributação é obrigatório!")
//			_lRet := .F.
//		EndIf
//		
//		If empty(M -> FM_GRPROD)
//			u_help("Campo Grupo tributário do produto é obrigatório")
//			_lRet := .F.
//		EndIf
//		
//		If empty(M -> FM_EST)
//			u_help("Campo Estado é obrigatório")
//			_lRet := .F.
//		EndIf
//		
//		If empty(M -> FM_TIPOCLI)
//			u_help("Campo Tipo de cliente é obrigatório")
//			_lRet := .F.
//		EndIf
		
		If empty(M -> FM_TIPO)
			u_help("Campo Tipo de operação é obrigatório")
			_lRet := .F.
		Else
			If M -> FM_TIPO <> mv_par01
				u_help("Tipo de operação diferente do parâmetro selecionado! Não será possível incluir o registro.")
				_lRet := .F.
			EndIf
		EndIf
		
		If empty(M -> FM_TE) .and. empty(M -> FM_TS)
			u_help("Campos Tes de entrada e Tes de saída vazios! Obrigatório o preenchimento de um dos campos.")
			_lRet := .F.
		EndIf
	EndIf
	
	If _lRet 
		If ExistCpo ("SX5", "ZF" + M -> FM_GRTRIB) == .F.
			u_help("Valor digitado no campo <Grupo de tributação> não existe no cadastro!")	
			_lRet := .F.
		EndIf
		
		If alltrim(M -> FM_GRPROD) <> ''
			If ExistCpo ("SX5", "21" + M -> FM_GRPROD) == .F.
				u_help("Valor digitado no campo <Grupo de tributação do produto> não existe no cadastro!")	
				_lRet := .F.
			EndIf
		EndIf
		
		If alltrim(M -> FM_EST) <> ''
			If ExistCpo ("SX5", "12" + M -> FM_EST) == .F. 
				u_help("Valor digitado no campo <Estado> não existe no cadastro!")	
				_lRet := .F.
			EndIf
		EndIf
		 
		If ExistCpo ("SX5","DJ" + M -> FM_TIPO) == .F.
			u_help("Valor digitado no campo <Tipo de Operação> não existe no cadastro!")	
			_lRet := .F.
		EndIf
		   
		If !empty(M -> FM_TE) .and. ExistCpo("SF4",M -> FM_TE) == .F.    
			u_help("Valor digitado no campo <Tes de entrada> não existe no cadastro!")	
			_lRet := .F.
		EndIf	
		
		If !empty(M -> FM_TS) .and. ExistCpo("SF4",M -> FM_TS)  == .F.    
			u_help("Valor digitado no campo <Tes de saída> não existe no cadastro!")	
			_lRet := .F.
		EndIf
	EndIf
Return _lRet
// --------------------------------------------------------------------------
// Adiciona campos no grid
User Function MT89Cpos()
	local _aCampos := {}
	
	aadd (_aCampos, "FM_GRTRIB")
	aadd (_aCampos, "FM_GRPROD")
	aadd (_aCampos, "FM_EST")
	aadd (_aCampos, "FM_TIPOCLI")
	aadd (_aCampos, "FM_TIPO")
	aadd (_aCampos, "FM_TE")
	aadd (_aCampos, "FM_TS")
	aadd (_aCampos, "FM_TIPOMOV")
	aadd (_aCampos, "FM_POSIPI")
	aadd (_aCampos, "FM_PRODUTO")
	aadd (_aCampos, "FM_GRPCST")
	aadd (_aCampos, "ZZZ_RECNO") 	// Adiciona sempre o campo RECNO para posterior uso em gravacoes.

Return _aCampos   
//-------------------------------------------------------------------
//Atualiza SX5
User Function MT89SX5()
	Local _cRet	    := ''
	Local _X5Descri := ""
	Local _aDados   := {}
	Local _i		:= 0
	
	_aDados := FWGetSX5("RV","SFM")
	
	For _i=1 to len(_aDados)
		_X5Descri := _aDados[_i,4]
		//U_HELP(_X5Descri)
		_cRet	  := Soma1(Substr(_X5Descri,1,6),6)
		//u_help(_cRet)
		FwPutSX5(/*cFlavour*/,"RV","SFM",_cRet)
	Next
	//Atualizar SX5 com o último ID utilizado
	
//	If  SX5->( dbSeek(xFilial('SX5')+"RV"+'SFM'))
//		_cRet	:= Soma1(Substr(X5Descri(),1,6),6)
//	EndIf
//
//	//Atualizar SX5 com o último ID utilizado
//	SX5->( dbSeek(xFilial('SX5')+"RV"+'SFM'))
//	If SX5->(dbSeek(xFilial("SX5")+"RV"+'SFM'))
//		RecLock('SX5',.F.)
//		SX5->X5_DESCRI		:= _cRet
//		SX5->X5_DESCSPA 	:= _cRet
//		SX5->X5_DESCENG 	:= _cRet
//		MsUnlock()
//	EndIF
Return _cRet
//-------------------------------------------------------------------
//Grava Eventos
Static Function _Mt89GrvEv (_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _GrvDesc)
	_oEvento := ClsEvent():New ()
	_oEvento:Alias     = 'SFM'
	_oEvento:Texto     = AllTrim(_GrvDesc) + chr (13) + chr (10) + ;
						 "Grp.Trib.:" + alltrim(_sGrTrib) + " Est:" + alltrim(_sEst) + " Grp.Prod.:" + alltrim(_sGrProd) + chr (13) + chr (10) + ;
						 "Tipo Cli.:" + alltrim(_sTipCli) + " Tipo Op.:" + alltrim(_sTipOp) + " TE:" + alltrim(_sTe) + " TS:" + alltrim(_sTs) + chr (13) + chr (10) + ;
						 "Tip.Ped.:" + alltrim(_sTipPed) + " NCM:"+alltrim(_sNCM) + " Prod.:" + alltrim(_sProd) + " Enq.IPI:" + alltrim(_sEnqIPI) + "."
	_oEvento:CodEven   = "SFM001"
	_oEvento:Grava()
Return
//-------------------------------------------------------------------
//Evento de alteração
Static Function _VerAltReg(_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _recno, _AltDes)
	Local _lAlt     := .T.
	Local _cQueryA  := ""
	Local aRetAlt	:= {}
	Local x			:= 0
	
	_cQueryA += " SELECT"
	_cQueryA += "	FM_GRTRIB"
	_cQueryA += "   ,FM_EST"
	_cQueryA += "   ,FM_GRPROD"
	_cQueryA += "   ,FM_TIPOCLI"
	_cQueryA += "   ,FM_TIPO"
	_cQueryA += "   ,FM_TE"
	_cQueryA += "   ,FM_TS"
	_cQueryA += "   ,FM_TIPOMOV"
	_cQueryA += "   ,FM_POSIPI"
	_cQueryA += "   ,FM_PRODUTO"
	_cQueryA += "   ,FM_GRPCST"		
	_cQueryA += " FROM " + RetSQLName ("SFM")
	_cQueryA += " WHERE D_E_L_E_T_ = ''"
	_cQueryA += " AND R_E_C_N_O_ = '" + ALLTRIM(str(_recno)) + "'"
	aRetAlt := U_Qry2Array(_cQueryA)
	
	If len(aRetAlt) > 0
		For x:=1 to len(aRetAlt)
			If  alltrim (aRetAlt[x,1])  <>  alltrim(_sGrTrib) 	.or.;
				alltrim (aRetAlt[x,2])  <>  alltrim(_sEst) 		.or.;
				alltrim (aRetAlt[x,3])  <>  alltrim(_sGrProd) 	.or.;
				alltrim (aRetAlt[x,4])  <>  alltrim(_sTipCli) 	.or.;
				alltrim (aRetAlt[x,5])  <>  alltrim(_sTipOp) 	.or.;
				alltrim (aRetAlt[x,6])  <>  alltrim(_sTe) 		.or.;
				alltrim (aRetAlt[x,7])  <>  alltrim(_sTs) 		.or.;
				alltrim (aRetAlt[x,8])  <>  alltrim(_sTipPed) 	.or.;
				alltrim (aRetAlt[x,9])  <>  alltrim(_sNCM) 		.or.;
				alltrim (aRetAlt[x,10]) <>  alltrim(_sProd) 	.or.;
				alltrim (aRetAlt[x,11]) <>  alltrim(_sEnqIPI) 
					_lAlt     := .F.
			EndIf
		Next
	EndIf

Return _lAlt
//-------------------------------------------------------------------
//Evento de inclusão pelo AxCadastro
Static Function _Mt89GrAx(_sId)
	Local _cQueryA  := ""
	Local aRetAlt	:= {}
	Local x			:= 0
	
	_cQueryA += " SELECT"
	_cQueryA += "	FM_GRTRIB"
	_cQueryA += "   ,FM_EST"
	_cQueryA += "   ,FM_GRPROD"
	_cQueryA += "   ,FM_TIPOCLI"
	_cQueryA += "   ,FM_TIPO"
	_cQueryA += "   ,FM_TE"
	_cQueryA += "   ,FM_TS"
	_cQueryA += "   ,FM_TIPOMOV"
	_cQueryA += "   ,FM_POSIPI"
	_cQueryA += "   ,FM_PRODUTO"
	_cQueryA += "   ,FM_GRPCST"		
	_cQueryA += " FROM " + RetSQLName ("SFM")
	_cQueryA += " WHERE D_E_L_E_T_ = ''"
	_cQueryA += " AND FM_ID = '" + ALLTRIM(_sId) + "'"
	aRetAlt := U_Qry2Array(_cQueryA)
	
	If len(aRetAlt) > 0
		For x:=1 to len(aRetAlt)
			_sGrTrib := alltrim (aRetAlt[x,1])
			_sEst	 := alltrim (aRetAlt[x,2])
			_sGrProd := alltrim (aRetAlt[x,3])
			_sTipCli := alltrim (aRetAlt[x,4])
			_sTipOp  := alltrim (aRetAlt[x,5])
			_sTe	 := alltrim (aRetAlt[x,6])
			_sTs     := alltrim (aRetAlt[x,7])
			_sTipPed := alltrim (aRetAlt[x,8])
			_sNCM	 := alltrim (aRetAlt[x,9])
			_sProd	 := alltrim (aRetAlt[x,10])
			_sEnqIPI := alltrim (aRetAlt[x,11])
			
			_GrvDesc := "Inclusão de Tes inteligente (Grid)"
			
			_Mt89GrvEv (_sGrTrib, _sEst, _sGrProd, _sTipCli, _sTipOp, _sTe, _sTs, _sTipPed, _sNCM, _sProd, _sEnqIPI, _GrvDesc)		
		Next
	EndIf
Return 
//-------------------------------------------------------------------
//Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
//    Local _aEst      := {}
    //                     PERGUNT            TIPO TAM DEC VALID F3       Opcoes                      					Help
    aadd (_aRegsPerg, {01, "Tipo de operação", "C", 2, 0,  "",  "DJ", {},                         					""})
    aadd (_aRegsPerg, {02, "Estado          ", "C", 2, 0,  "",  "12", {},                         					""})
     U_ValPerg (_cPerg, _aRegsPerg)
Return
//
//
//-------------------------------------------------------------------
// Relatório
User Function MT89R()
	Private oReport
	Private cPerg   := "MT89R"
	
	//_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//-------------------------------------------------------------------
// ReportDef
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
//	Local oFunction
	
	oReport := TReport():New("MT89R","TES Inteligente",cPerg,{|oReport| PrintReport(oReport)},"TES Inteligente")
	
	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)
	
	//SESSÃO 1 CUPONS
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	oSection1:SetTotalInLine(.F.)

	TRCell():New(oSection1,"COLUNA1", 	"" ,"Grupo Trib."	 		,,15,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Estado"	 			,,10,/*lPixel*/,{||	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Grupo Trib.Produto"   	,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Tipo de Cliente"		,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"01 Venda Producao"	    ,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"04 Bonificação"		,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"51 Devolucao de Venda"	,,20,/*lPixel*/,{|| },"LEFT",,,,,,,,.F.)
Return(oReport)
//-------------------------------------------------------------------
// PrintReport
Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""		
    
	cQuery := ""
	cQuery += " SELECT"
	cQuery += " 	SFM.FM_GRTRIB"
	cQuery += "    ,SFM.FM_EST"
	cQuery += "    ,SFM.FM_GRPROD"
	cQuery += "    ,CASE"
	cQuery += " 		WHEN SFM.FM_TIPOCLI = 'F' THEN 'Consumidor final'"
	cQuery += " 		WHEN SFM.FM_TIPOCLI = 'L' THEN 'Produtor Rural'"
	cQuery += " 		WHEN SFM.FM_TIPOCLI = 'R' THEN 'Revendedor'"
	cQuery += " 		WHEN SFM.FM_TIPOCLI = 'S' THEN 'Solidário'"
	cQuery += " 		WHEN SFM.FM_TIPOCLI = 'X' THEN 'Exportação'"
	cQuery += " 	END AS FM_TIPOCLI"
	cQuery += "    ,(SELECT"
	cQuery += " 			FM_TS"
	cQuery += " 		FROM " + RetSQLName ("SFM") + " SFM1"
	cQuery += " 		WHERE SFM1.D_E_L_E_T_ = ''"
	cQuery += " 		AND SFM1.FM_TIPO = '01'"
	cQuery += " 		AND SFM.FM_GRTRIB = SFM1.FM_GRTRIB"
	cQuery += " 		AND SFM.FM_EST = SFM1.FM_EST"
	cQuery += " 		AND SFM.FM_GRPROD = SFM1.FM_GRPROD"
	cQuery += " 		AND SFM.FM_EST = SFM1.FM_EST"
	cQuery += " 		AND SFM.FM_TIPOCLI = SFM1.FM_TIPOCLI)"
	cQuery += " 	AS 'FM_01'"
	cQuery += "    ,(SELECT"
	cQuery += " 			FM_TS"
	cQuery += " 		FROM " + RetSQLName ("SFM") + " SFM2"
	cQuery += " 		WHERE SFM2.D_E_L_E_T_ = ''" 
	cQuery += " 		AND SFM2.FM_TIPO = '04'"
	cQuery += " 		AND SFM.FM_GRTRIB = SFM2.FM_GRTRIB"
	cQuery += " 		AND SFM.FM_EST = SFM2.FM_EST"
	cQuery += " 		AND SFM.FM_GRPROD = SFM2.FM_GRPROD"
	cQuery += " 		AND SFM.FM_EST = SFM2.FM_EST"
	cQuery += " 		AND SFM.FM_TIPOCLI = SFM2.FM_TIPOCLI)"
	cQuery += " 	AS 'FM_04'"
	cQuery += "    ,(SELECT"
	cQuery += " 			FM_TE"
	cQuery += " 		FROM " + RetSQLName ("SFM") + " SFM3"
	cQuery += " 		WHERE SFM3.D_E_L_E_T_ = ''" 
	cQuery += " 		AND SFM3.FM_TIPO = '51'"	
	cQuery += " 		AND SFM.FM_GRTRIB = SFM3.FM_GRTRIB"
	cQuery += " 		AND SFM.FM_EST = SFM3.FM_EST"
	cQuery += " 		AND SFM.FM_GRPROD = SFM3.FM_GRPROD"
	cQuery += " 		AND SFM.FM_EST = SFM3.FM_EST"
	cQuery += " 		AND SFM.FM_TIPOCLI = SFM3.FM_TIPOCLI)"
	cQuery += " 	AS 'FM_51'"
	cQuery += " FROM " + RetSQLName ("SFM") + " SFM"
	cQuery += " WHERE SFM.D_E_L_E_T_ = ''"
	If !empty(mv_par02)
		cQuery += " AND SFM.FM_EST='"+mv_par02+"'"
	EndIf
	cQuery += " GROUP BY FM_GRTRIB"
	cQuery += " 		,FM_EST"
	cQuery += " 		,FM_GRPROD"
	cQuery += " 		,FM_TIPOCLI"
	cQuery += " ORDER BY FM_GRTRIB,FM_EST,FM_GRPROD,FM_TIPOCLI "
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
		
	oSection1:Init()
	oSection1:SetHeaderSection(.T.)
	
	TRA->(DbGotop())
	
	While TRA->(!Eof())	
		oSection1:Cell("COLUNA1")	:SetBlock   ({|| TRA->FM_GRTRIB		})
		oSection1:Cell("COLUNA2")	:SetBlock   ({|| TRA->FM_EST   		})
		oSection1:Cell("COLUNA3")	:SetBlock   ({|| TRA->FM_GRPROD		})
		oSection1:Cell("COLUNA4")	:SetBlock   ({|| TRA->FM_TIPOCLI 	})
		oSection1:Cell("COLUNA5")	:SetBlock   ({|| TRA->FM_01 		})
		oSection1:Cell("COLUNA6")	:SetBlock   ({|| TRA->FM_04			})
		oSection1:Cell("COLUNA7")	:SetBlock   ({|| TRA->FM_51  		})
		oSection1:PrintLine()
		
		DBSelectArea("TRA")
		dbskip()
	enddo
			
	oSection1:Finish()
	TRA->(DbCloseArea())
Return
