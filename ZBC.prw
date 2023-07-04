// Programa...: ZBC
// Autor......: Cláudia Lionço
// Data.......: 15/10/2019
// Descricao..: Tela de manutenção de eventos produtivos
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Tela de manutenção de eventos produtivos
// #PalavasChave      #manutencao_eventos_produtivos #eventos_produtivos 
// #TabelasPrincipais #ZBC
// #Modulos   		  #PCP 
//
// Historico de alteracoes:
// 05/11/2019 - Claudia - Desenvolvido relatório de eventos produtivos
//						  Incluida validação de acesso de usuário e controle de semáforo
// 12/12/2019 - Claudia - Ajustes conforme GLPI 7187
// 30/12/2019 - Claudia - Incluido relatório de materiais diário no menu. GLPI: 7260
// 13/01/2020 - Claudia - Inclusão da função <ArqTrb> (exigencia release 12.1.25 do Protheus)
// 09/09/2021 - Claudia - Incluidas as rotinas de exportação e importação de dados de eventos. GLPI: 10807
// 11/10/2021 - Claudia - Incluida rotina para geração de materiais no menu do outras ações. GLPI: 11035
// 22/03/2022 - Claudia - Ajuste da data invertida (AAAAMMDD) na exportação para planilha. GLPI: 11754
// 22/03/2022 - Claudia - Ordenado por data a exportacao da planilha. GLPI: 11755
// 22/03/2022 - Claudia - Validação de produto em linha. GLPI: 11767/11786
// 04/07/2023 - Claudia - Ajustada a exportação/importação. GLPI 13763
//
// -------------------------------------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function ZBC()
	Local aRotAdic   := {}
	Local aButtons   := {}
	Local _lRet      := .T.
	Local _lContinua := .T.
	
	// Controle de semaforo.
	_nLock := U_Semaforo (procname () + cEmpAnt)
	if _nLock == 0
		msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
		_lContinua = .F.
	endif
	
	If _lContinua
		_lRet = _LibRotina ()
		
		If _lRet == .T.
			Aadd(aRotAdic,{ "Planejamento"		,"U_VA_PLJPRD(ZBC->ZBC_FILIAL,ZBC->ZBC_COD,ZBC->ZBC_ANO)", 0, 6 })
			Aadd(aRotAdic,{ "Rel.Planejamento"	,"U_VA_RPLJPRD()", 0, 6 })
			Aadd(aRotAdic,{ "Rel.Materiais"		,"U_VA_ZBCMAT()" , 0, 6 }) 
			Aadd(aRotAdic,{ "Rel.Mat.Diário"	,"U_VA_ZBCMDI()" , 0, 6 })
			Aadd(aRotAdic,{ "Rel.Custos"	    ,"U_VA_ZBCCUS()" , 0, 6 })
			Aadd(aRotAdic,{ "Gera Materiais"	,"U_VA_ZBCBI()" , 0, 6 })
		
			//( [ cAlias ] [ cTitle ] [ cDel ] [ cOk ] [ aRotAdic ] [ bPre ] [ bOK ] [ bTTS ] [ bNoTTS ] [ aAuto ] [ nOpcAuto ] [ aButtons ] [ aACS ] [ cTela ] )
			AxCadastro("ZBC", "Manutenção de eventos produtivos", "U_ZBCEXC(ZBC->ZBC_FILIAL,ZBC->ZBC_COD,ZBC->ZBC_ANO)", "U_ValidaZBC()",aRotAdic , , , , , , , aButtons, , )  
		EndIf
	EndIf
Return
//
// --------------------------------------------------------------------------
// Liberação de rotina
static function _LibRotina ()
	local _lRet      := .T.
	
	if ! U_ZZUVL ('093', __cUserId, .F.) 
		u_help ("Usuário sem permissão para utilização da rotina 093!")
		_lRet = .F.
	endif
return _lRet
//
// --------------------------------------------------------------------------
// Planejamento de produção
User Function VA_PLJPRD(_sZBCFilial, _sZBCCod, _sZBCAno)
	Private cCadastro 	:= "Plano mestre de produção"
	Private aRotina 	:= {}
	
	_sPreFiltr := "HC_FILIAL ='" + alltrim(_sZBCFilial) + "' AND HC_VAEVENT='" + alltrim(_sZBCCod) + "' AND HC_ANO='" + alltrim(_sZBCAno) + "'"
	
	AADD( aRotina, {"Pesquisar"  		,"AxPesqui" 	,0,1})
	AADD( aRotina, {"Visualizar" 		,"U_PLJA(2)"  	,0,2})
	AADD( aRotina, {"Incluir"    		,"U_PLJI()"  	,0,3})
	AADD( aRotina, {"Alterar"    		,"U_PLJA(4, 	'allwaystrue ()', 'allwaystrue ()', .T., _sPreFiltr, '" + _sZBCCod +"')"  	,0,4})
	AADD( aRotina, {"Exportar .CSV"    	,"U_PLJEXP('"+ _sZBCFilial + "','"+  _sZBCCod + "','" + _sZBCAno + "')" ,0,6})
	AADD( aRotina, {"Importar .CSV"    	,"U_PLJIMP('"+ _sZBCFilial + "','"+  _sZBCCod + "','" + _sZBCAno + "')" ,0,6})

	dbSelectArea("SHC")
	dbSetOrder(5)
	dbGoTop()
	
	aCabTela  := {} 
	aadd (aCabTela,{ "Filial"		,"HC_FILIAL" })
	aadd (aCabTela,{ "Item"			,"HC_ITEM"	 })
	aadd (aCabTela,{ "Produto"		,"HC_PRODUTO"})
	aadd (aCabTela,{ "Descrição"	,"HC_VADESCR"})
	aadd (aCabTela,{ "Documento"	,"HC_DOC"	 })
	aadd (aCabTela,{ "Quantidade"	,"HC_QUANT"	 })
	aadd (aCabTela,{ "Data"			,"HC_DATA"	 })
	aadd (aCabTela,{ "Evento"		,"HC_VAEVENT"})
	aadd (aCabTela,{ "Evento"		,"HC_ANO"	 })
	aadd (aCabTela,{ "Revisão"		,"HC_REVISAO"})
	aadd (aCabTela,{ "Grupo Opc."	,"HC_GRPOPC" })
	aadd (aCabTela,{ "Opcional"		,"HC_OPCITEM"})
	aadd (aCabTela,{ "Paradas"		,"HC_TPOPRD" })
	aadd (aCabTela,{ "Linha Envase"	,"HC_VALINEN"})
	aadd (aCabTela,{ "Descrição"	,"HC_DESCLIN"})
			
	mBrowse(,,,,"SHC",aCabTela,,,,,,,,,,,,,_sPreFiltr)
Return
//
// --------------------------------------------------------------------------
// Incluir AxCadastro
User Function PLJI()
	AxInclui("SHC",,,,,,"U_PLJITOk()")
Return
//
// --------------------------------------------------------------------------
// Rotina Tudo OK tabela SHC
User Function PLJITOk()
	Local _lRet   := .T.
	Local _oSQL   := ClsSQL ():New ()
	local _nLinha := 0
	Local _x      := 0

	If !inclui
		For _nLinha := 1 to len(aCols)
			If ! GDDeleted (_nLinha)
				If empty(GDFieldGet ("HC_FILIAL" , _nLinha))
					u_help("Campo <Filial> é obrigatório!")
					_lRet := .F.
				EndIf
				If empty(GDFieldGet ("HC_PRODUTO", _nLinha))
					u_help("Campo <Produto> é obrigatório!")
					_lRet := .F.
				EndIf
				If empty(GDFieldGet ("HC_DATA"   , _nLinha))
					u_help("Campo <Data> é obrigatório!")
					_lRet := .F.
				EndIf
				If empty(GDFieldGet ("HC_QUANT"  , _nLinha)) .or. GDFieldGet ("HC_QUANT", _nLinha) == 0
					u_help("Campo <Quantidade> é obrigatório!")
					_lRet := .F.
				EndIf
				If empty(GDFieldGet ("HC_VAEVENT", _nLinha))
					u_help("Campo <Evento> é obrigatório!")
					_lRet := .F.
				EndIf
				
				// verifica se produto existe e esta desbloqueado
				_sProduto := GDFieldGet ("HC_PRODUTO", _nLinha)

				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT "
				_oSQL:_sQuery += " 	COUNT(*) "
				_oSQL:_sQuery += " FROM SB1010 "
				_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
				_oSQL:_sQuery += " AND B1_COD    = '" + _sProduto + "' "
				_oSQL:_sQuery += " AND B1_MSBLQL = '2' "
				_aSB1 := aclone (_oSQL:Qry2Array ())
				For _x:= 1 to Len(_aSB1)
					_nVlr := _aSB1[_x,1]

					If _nVlr == 0
						u_help("Campo <Produto> inválido! Produto:" + _sProduto)
						_lRet := .F.
					EndIf
				Next
			Endif
		Next
	EndIf
Return _lRet
//
// --------------------------------------------------------------------------
// Valida 'Tudo OK'
User Function ValidaZBC()
	Local _lRet 	:= .T.
	Local _aAreaAnt := U_ML_SRArea ()
	
	// Testa código preenchido
	If _lRet .and. empty(M -> ZBC_COD)
		msgalert ("Código deve ser preenchido!")
		_lRet = .F.
	EndIf
	// Testa descrição preenchida
	If _lRet .and. empty(M -> ZBC_DESC)
		msgalert ("Informar a descrição do evento! ")
		_lRet = .F.
	EndIf 
	// testa duplicidade
	If _lRet .and. inclui
		ZBC -> (dbsetorder (1))
		If ZBC -> (dbseek (xfilial ("ZBC") + M -> ZBC_COD, .F.))
			msgalert ("Registro já cadastrado. Verifique! ")
			_lRet = .F.
		EndIf
	EndIf
	
	U_ML_SRArea (_aAreaAnt)
Return _lRet
//
// --------------------------------------------------------------------------
// Excluir registros da ZBC e filhos: SHC - ZBD
User Function ZBCEXC()
	Local _lRet 	:= .T.
	Local _aAreaAnt := U_ML_SRArea ()
	Local _cQuery   := ""
	Local _aItem    := ""
	Local _x        := 0
	
	// busca itens para verificar opcionais anexados
	_cQuery := " SELECT HC_FILIAL, HC_VAEVENT, HC_ANO, HC_PRODUTO  "
	_cQuery += " FROM " + RetSqlName("SHC")
	_cQuery += " WHERE D_E_L_E_T_ = '' "
	_cQuery += " AND HC_FILIAL    = '" + alltrim(ZBC -> ZBC_FILIAL) + "'"
	_cQuery += " AND HC_VAEVENT   = '" + ZBC -> ZBC_COD + "'"
	_cQuery += " AND HC_ANO       = '" + ZBC -> ZBC_ANO + "'"
	_aItem := U_Qry2Array(_cQuery)
	
	// Deleta  registros de opcionais ZBD
	For _x:= 1 to Len(_aItem)		
		dbSelectArea("ZBD")
		ZBD -> (dbsetorder (1))  // ZBD_FILIAL + ZBD_VAEVE + ZBD_ANO + ZBD_PROD + ZBD_DATA
		If dbseek (_aItem[_x, 1] + _aItem[_x, 2] + _aItem[_x, 3] + _aItem[_x, 4], .F.)
			RecLock("ZBD", .F.)
				ZBD -> (dbdelete ())
			MSUnlock()
		EndIf
	Next
	
	// Deleta eventos produtivos
	For _x:= 1 to Len(_aItem)	
		dbSelectArea("SHC")
		SHC -> (dbsetorder (6))  // HC_FILIAL + HC_VAEVENT + HC_ANO
		If dbseek(_aItem[_x, 1] + _aItem[_x, 2] + _aItem[_x, 3], .F.)
			RecLock("SHC", .F.)
				SHC -> (dbdelete ())
			MSUnlock()
		EndIf
	Next

	U_ML_SRArea (_aAreaAnt)
Return _lRet
//
// --------------------------------------------------------------------------
// Visualizacao, Alteracao, Exclusao
User Function PLJA (_nOpcao, _sLinhaOK, _sTudoOK, _lFiltro, _sPreFiltr, _sCodEvento)
	local _lContinua  := .T.
	local _aCampos    := {}
	local _n		  := 1
	local aButtons 	  := {}
	private _sModo    := ""
	private aHeader   := {}
	private aCols     := {}
	private nOpc      := _nOpcao
	private N		  := 1
	
	if empty(_sCodEvento)
		_sCodEvento := ZBC->ZBC_COD
	endif
	u_logIni ()
	DbSelectArea("SHC")
	SHC -> (dbsetorder (5))
	
	If _lContinua	
		CursorWait ()
		_sSeek    := xfilial ("SHC") + _sCodEvento
		_sWhile   := "SHC->HC_VAEVENT == '"+_sCodEvento+"'"
		_aCampos  := U_PLMCpos ()
		
		aHeader := U_GeraHead (""		,; // Arquivo
		                       .F.		,; // Para MSNewGetDados, informar .T.
		                       {}		,; // Campos a nao incluir
		                       _aCampos	,; // Campos a incluir
		                       .T.		 ) // Apenas os campos informados.
		
		aCols := U_GeraCols ("SHC"		,;  // Alias
		                      5			,;  // Indice
		                      _sSeek	,;  // Seek inicial
		                      _sWhile	,;  // While
		                      aHeader	,;  // aHeader
		                      .F.		)  // Nao executa gatilhos

		// Variaveis para o Modelo2
		sTitulo := "Manutenção do planejamento produtivo"
		aC   	:= {}
		aR   	:= {}
		aCGD 	:= {80,   5, oMainWnd:nClientHeight / 2 - 100, oMainWnd:nClientWidth / 2 - 120}
		aCJN 	:= {100, 50, oMainWnd:nClientHeight - 50     , oMainWnd:nClientWidth - 50}

		Aadd( aButtons, {"Opcionais", {|| U_ZBDOpc()}, "Opcionais...", "Opcionais" , {|| .T.}} ) 
		
		_lContinua = Modelo2 (sTitulo	,;  // Titulo
		                 aC				,;  // Cabecalho
		                 aR				,;  // Rodape
		                 aCGD			,;  // Coordenadas da getdados
		                 nOpc			,;  // nOPC
		                 "U_PLMLOK ()"	,;  // Linha OK
		                 "U_PLJITOk()"	,;  // Tudo OK
										,;  // Gets editaveis
										,;  // bloco codigo para tecla F4
										,;  // Campos inicializados
						 999			,;  // Numero maximo de linhas
		                 aCJN			,;  // Coordenadas da janela
		                 .T.			,;  // Linhas podem ser deletadas.
		                 .F.			,;  // Se a tela virá Maximizada
		                 aButtons  		 )  // Array com botoes
		If _lContinua
			If nOpc == 5 
				// caso necessite
			Else		
				// Grava dados do aCols.
				SHC -> (dbsetorder (5))
				_aCposFora := {}
				
				For _n = 1 to len (aCols)
					N := _n
					_sFilial 	:= GDFieldGet ("HC_FILIAL")
					_sDocumento := GDFieldGet ("HC_DOC")
					_sItem      := GDFieldGet ("HC_ITEM")
					_sEvento  	:= GDFieldGet ("HC_VAEVENT")
					_sAnoEve  	:= GDFieldGet ("HC_ANO")
					_sProduto 	:= GDFieldGet ("HC_PRODUTO")
					_sData 		:= GDFieldGet ("HC_DATA")
					_nQuant 	:= GDFieldGet ("HC_QUANT")
					_SRevisao	:= GDFieldGet ("HC_REVISAO")	

					//_sLinEnv := Posicione("SB1",1 ,xFilial("SB1") + _sProduto,"B1_VALINEN")
					//GDFieldPut ("HC_VALINEN", _sLinEnv, N)

					If GDFieldGet ("ZZZ_RECNO") <= 0					
						_sItem := U_BuscaSequencial(_sFilial,_sDocumento,_sAnoEve)
					                                    
						aadd (_aCposFora, {"HC_ITEM", _sItem})			
					EndIf
			
					// Procura esta linha no arquivo por que posso ter situacoes de exclusao ou alteracao.
					If GDFieldGet ("ZZZ_RECNO") > 0
						SHC -> (dbgoto (GDFieldGet ("ZZZ_RECNO")))
						//		
						// Se esta deletado em aCols, preciso excluir do arquivo tambem.
						If GDDeleted ()
							
							_lSeg := _DelZBDGrid(SHC -> HC_FILIAL, SHC -> HC_VAEVENT, SHC -> HC_PRODUTO, SHC -> HC_DATA, SHC -> HC_ANO)
							If _lSeg == .T.
								reclock ("SHC", .F.)
								SHC -> (dbdelete ())
								msunlock ("SHC")	
							EndIf						
						Else							
							reclock ("SHC", .F.)
							U_GrvACols ("SHC", N, _aCposFora)
							msunlock ("SHC")
						EndIf
		
					Else  // A linha ainda nao existe no arquivo
						If GDDeleted ()
							_lSeg := _DelZBDGrid(SHC -> HC_FILIAL, SHC -> HC_VAEVENT, SHC -> HC_PRODUTO, SHC -> HC_DATA, SHC -> HC_ANO)
							loop
						Else	
							reclock ("SHC", .T.)
							U_GrvACols ("SHC", N, _aCposFora)
							msunlock ("SHC")
						EndIf
					EndIf
				Next
			EndIf
		EndIf
	Endif

	SHC -> (dbgotop ())
	u_logFim ()
Return
//
// --------------------------------------------------------------------------
// Adiciona campos no grid
User Function PLMCpos()
	Local _aCampos := {}
	
	aadd (_aCampos, "HC_FILIAL")
	aadd (_aCampos, "HC_DOC")
	aadd (_aCampos, "HC_VAEVENT")
	aadd (_aCampos, "HC_ANO")
	aadd (_aCampos, "HC_ITEM")
	aadd (_aCampos, "HC_PRODUTO")
	aadd (_aCampos, "HC_VADESCR")
	aadd (_aCampos, "HC_DATA")
	aadd (_aCampos, "HC_QUANT")
	aadd (_aCampos, "HC_REVISAO")
	aadd (_aCampos, "HC_REVDESC")
	aadd (_aCampos, "HC_GRPOPC")
	aadd (_aCampos, "HC_OPCITEM")
	aadd (_aCampos, "HC_TPOPRD")
	aadd (_aCampos, "HC_TPPRDE")
	aadd (_aCampos, "HC_VALINEN")
	aadd (_aCampos, "HC_DESCLIN")
	aadd (_aCampos, "ZZZ_RECNO") 	// Adiciona sempre o campo RECNO para posterior uso em gravacoes.

Return _aCampos   
//
// --------------------------------------------------------------------------
// Valida 'Linha OK' da getdados
User Function PLMLOK ()
	local _lRet := .T.

	If _lRet .and. ! GDDeleted ()
		If empty(GDFieldGet("HC_FILIAL"))
			u_help("Campo <Filial> é obrigatório!")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("HC_DOC"))
			u_help("Campo <Documento> é obrigatório!")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("HC_ANO"))
			u_help("Campo <Ano> é obrigatório!")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("HC_PRODUTO"))
			u_help("Campo <Produto> é obrigatório")
			_lRet := .F.
		else
			_lRet := _ValidaProduto(GDFieldGet("HC_PRODUTO"))
		EndIf
		
		If empty(GDFieldGet("HC_QUANT"))
			u_help("Campo <Quantidade> é obrigatório")
			_lRet := .F.
		EndIf
		
		If empty(GDFieldGet("HC_VAEVENT"))
			u_help("Campo <Evento> é obrigatório")
			_lRet := .F.
		EndIf
	EndIf
Return _lRet
//
// --------------------------------------------------------------------------
// Busca a sequencia dos itens. (Usado no campo HC_ITEM)
User Function BuscaSequencial(_sFilial,_sDocumento,_sAnoEve)
	Local _aItem  := {}
	Local _cQuery := ""
	
	_cQuery := " SELECT MAX(HC_ITEM) FROM " + RetSQLName ("SHC") + " SHC "
	_cQuery += " WHERE SHC.HC_FILIAL  = '" + _sFilial + "'"
	_cQuery += " AND SHC.HC_DOC = '" + alltrim(_sDocumento) + "'"
	_cQuery += " AND SHC.HC_ANO = '" + alltrim(_sAnoEve) + "'"
	_aItem := U_Qry2Array(_cQuery)
	
	If len(_aItem) >0
		_sIt := _aItem[1,1]
	Else
		_sIt := '00'
	EndIf
	
	_sItem := SOMA1(_sIt) 
	  
Return _sItem 
//
// --------------------------------------------------------------------------
// Seleciona Opcionais
User Function ZBCSelOpc(_opc)   
	Local _stru		:= {}
	Local aCpoBro 	:= {}
	Local _cQuery 	:= ""
	Local _sRet     := ""
	Local _sProd    := ""
	Local _sRev     := ""
	Local _sFilial	:= ""
	Local _sEvento	:= ""
	Local _sAno		:= ""
	Local _sItem	:= ""
	lOCAL _nQnt		:= 0
	Local _aArqTrb  := {}
	Local _aAreaAnt := U_ML_SRArea ()
	Private lInverte:= .F.
	Private cMark   := GetMark()   
	Private oMark

	If inclui
		_sFilial := M -> HC_FILIAL
		_sEvento := M -> HC_VAEVENT
		_sAno	 := M -> HC_ANO
		_sProd   := M -> HC_PRODUTO
		_sData   := DTOS(M -> HC_DATA)
		_nQnt	 := M -> HC_QUANT
		_sItem 	 := M -> HC_ITEM
		_sRev    := M -> HC_REVISAO
	Else
		_sFilial := GDFieldGet("HC_FILIAL")  
		_sEvento := GDFieldGet("HC_VAEVENT")
		_sAno	 := GDFieldGet("HC_ANO")
		_sProd   := GDFieldGet("HC_PRODUTO") 
		_sData   := DTOS(GDFieldGet("HC_DATA"))
		_nQnt	 := GDFieldGet("HC_QUANT") 
		_sItem 	 := GDFieldGet("HC_ITEM")
		_sRev    := GDFieldGet("HC_REVISAO")
	EndIf

	//Cria um arquivo de Apoio
	AADD(_stru,{"OK"     	,"C"	,2		,0		})
	AADD(_stru,{"GRUPO"   	,"C"	,3		,0		})
	AADD(_stru,{"GRPDESC" 	,"C"	,30		,0		})
	AADD(_stru,{"ITEM"   	,"C"	,4		,0		})
	AADD(_stru,{"ITEDESC" 	,"C"	,30		,0		})
	AADD(_stru,{"COMP" 		,"C"	,15		,0		})

	U_ArqTrb ("Cria", "TTRB", _stru, {}, @_aArqTrb)	

	_cQuery := " SELECT DISTINCT "
	_cQuery += " 	 SGA.GA_GROPC "
	_cQuery += " 	,SGA.GA_DESCGRP"
	_cQuery += " 	,SGA.GA_OPC"
	_cQuery += " 	,SGA.GA_DESCOPC"
	_cQuery += "    ,SG1.G1_COMP"
	_cQuery += " FROM  " + RetSqlName("SG1") + " SG1 "
	_cQuery += " 	," + RetSqlName("SGA") + " SGA "
	_cQuery += " WHERE SG1.D_E_L_E_T_ = ''
	_cQuery += " AND SGA.D_E_L_E_T_ = ''
	_cQuery += " AND SGA.GA_GROPC = G1_GROPC
	_cQuery += " AND SGA.GA_OPC = G1_OPC
	_cQuery += " AND SG1.G1_COD = '" + _sProd + "' "
	_cQuery += " AND SG1.G1_GROPC <> ''
	_cQuery += " AND SG1.G1_INI <= '" +_sData+ "'"
	_cQuery += " AND SG1.G1_FIM >= '" +_sData+ "'"
	If !empty(_sRev)
		_cQuery += " AND G1_REVINI >= '" + _sRev + "' "
		_cQuery += " AND G1_REVFIM <= '" + _sRev + "' "
	EndIf
	_cQuery += " ORDER BY SGA.GA_GROPC, SGA.GA_OPC "
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,_cQuery), "TRA", .F., .T.)
	TRA->(DbGotop())	
	
	DbSelectArea("TTRB")
	DbGotop()

	While  TRA->(!Eof())	
		DbSelectArea("TTRB")	
		RecLock("TTRB",.T.)	
			
		TTRB->GRUPO   :=  TRA->GA_GROPC		
		TTRB->GRPDESC :=  TRA->GA_DESCGRP		
		TTRB->ITEM    :=  TRA->GA_OPC		
		TTRB->ITEDESC :=  TRA->GA_DESCOPC
		TTRB->COMP    :=  TRA->G1_COMP		
		MsunLock()	
		TRA->(DbSkip())
	Enddo
	TRA->(DbCloseArea())
	
	aCpoBro	:= {{ "OK"			,, "Mark"           ,"@!"},;			
				{ "GRUPO"		,, "Grupo"          ,"@!"},;			
				{ "GRPDESC"		,, "Descrição"      ,"@!"},;			
				{ "ITEM"		,, "Opcional"       ,"@!"},;			
				{ "ITEDESC"		,, "Descrição"   	,"@!"},;
				{ "COMP"		,, "Componente"		,"@!"}}			

	DEFINE MSDIALOG oDlg TITLE "Escolha o opcional do grupo" From 9,0 To 315,800 PIXEL
	
	DbSelectArea("TTRB")
	DbGotop()

	oMark := MsSelect():New("TTRB","OK","",aCpoBro,@lInverte,@cMark,{17,1,150,400})
	oMark:bMark := {|| _MarcaOpc()} 
	ACTIVATE MSDIALOG oDlg CENTERED ON INIT EnchoiceBar(oDlg,{|| _sRet := _GrvOpc(_sFilial, _sEvento, _sProd, _sData, _nQnt, _sItem, _sAno)},{|| oDlg:End()})
	
	dbSelectArea("TTRB")
	TTRB->(DbCloseArea())
	
	u_arqtrb ("FechaTodos",,,, @_aArqTrb) 
	
	// Verifica gravação de grupo iguais
	_VerifZBD(_sFilial, _sEvento, _sProd, _sData,_sAno)
	
	U_ML_SRArea (_aAreaAnt)
Return _sRet
//
// --------------------------------------------------------------------------
// Funcao executada ao Marcar/Desmarcar um registro.   
Static Function _MarcaOpc()
	Local _aAreaAnt := U_ML_SRArea ()
	
	RecLock("TTRB",.F.)

	If Marked("OK")	
		TTRB->OK := cMark
	Else	
		TTRB->OK := ""
	Endif   
	          
	MsUnlock()
	oMark:oBrowse:Refresh()
	
	U_ML_SRArea (_aAreaAnt)
Return
//
// --------------------------------------------------------------------------
// Funcao executada ao Marcar/Desmarcar um registro   
Static Function _GrvOpc(_sFilial, _sEvento, _sProd, _sData, _nQnt, _sItem, _sAno)
	Local _aAreaAnt  := U_ML_SRArea ()
	Local _opcionais := ""
	Local _cQuery    := ""

	dbSelectArea("TTRB")
	dbGotop()
     
	// deleta registros já gravados do evento/produto e data selecionado
	_cQuery := " UPDATE " + RetSqlName("ZBD") 
	_cQuery += " SET D_E_L_E_T_ = '*' "
	_cQuery += " WHERE ZBD_FILIAL = '" + _sFilial + "'"
	_cQuery += " AND ZBD_VAEVE    = '" + _sEvento + "'"
	_cQuery += " AND ZBD_PROD     = '" + _sProd   + "'"
	_cQuery += " AND ZBD_DATA     = '" + _sData   + "'"
	_cQuery += " AND ZBD_ANO      = '" + _sAno    + "'"

	If TCSQLExec (_cQuery) < 0
		u_showmemo(_cQuery)
		Return
    Endif   

	While TTRB->(!EoF())      
		If TTRB->OK == cMark
			_sGrp     := alltrim(TTRB -> GRUPO)
			_sGrpOpc  := alltrim(TTRB -> ITEM)
			_sCompOpc := alltrim(TTRB -> COMP)
			
			RecLock("ZBD", .T.)		
				ZBD -> ZBD_FILIAL := _sFilial
				ZBD -> ZBD_VAEVE  := _sEvento
				ZBD -> ZBD_ANO	  := _sAno
				ZBD -> ZBD_PROD   := _sProd
				ZBD -> ZBD_DATA   := STOD(_sData)
				ZBD -> ZBD_QUANT  := _nQnt
				ZBD -> ZBD_ITEM   := _sItem
				ZBD -> ZBD_GRPOPC := _sGrp
				ZBD -> ZBD_OPCITE := _sGrpOpc
				ZBD -> ZBD_CODOPC := _sCompOpc
			MsUnLock() //Confirma e finaliza a operação
			
			_opcionais += _sGrpOpc + ";" 
		EndIf
		
		TTRB->(dbskip())     
	EndDo
		
	oDlg:End()
	U_ML_SRArea (_aAreaAnt)
Return _opcionais
//
// --------------------------------------------------------------------------
// Verifica ZBD
Static Function _VerifZBD(_sFilial, _sEvento, _sProd, _sData,_sAno)
	Local _cQuery  := ""
	Local _cQuery1 := ""
	Local _aQtdIts := {}
	
	_cQuery := " SELECT  DISTINCT
	_cQuery += "	ZBD_OPCITE"
	_cQuery += " FROM " + RetSqlName("ZBD") 
	_cQuery += " WHERE D_E_L_E_T_ = '' "
	_cQuery += " AND ZBD_FILIAL   = '" + _sFilial + "'"
	_cQuery += " AND ZBD_VAEVE    = '" + _sEvento + "'"
	_cQuery += " AND ZBD_PROD     = '" + _sProd   + "'"
	_cQuery += " AND ZBD_DATA     = '" + _sData   + "'"
	_cQuery += " AND ZBD_ANO      = '" + _sAno    + "'"
	_aQtdIts := U_Qry2Array(_cQuery)
	
	If len(_aQtdIts) > 1
		u_help("Os opcionais cadastrados não são de mesmo grupo e serão excluídos. Verifique!")
		//
		// deleta registros já gravados do evento/produto e data selecionado
		_cQuery1 := " UPDATE " + RetSqlName("ZBD") 
		_cQuery1 += " SET D_E_L_E_T_ = '*' "
		_cQuery1 += " WHERE ZBD_FILIAL = '" + _sFilial + "'"
		_cQuery1 += " AND ZBD_VAEVE    = '" + _sEvento + "'"
		_cQuery1 += " AND ZBD_PROD     = '" + _sProd   + "'"
		_cQuery1 += " AND ZBD_DATA     = '" + _sData   + "'"
		_cQuery1 += " AND ZBD_ANO      = '" + _sAno    + "'"
	
		If TCSQLExec (_cQuery1) < 0
			u_showmemo(_cQuery1)
			Return
	    Endif 
	EndIf
Return
//
// --------------------------------------------------------------------------
// Filtro da revisão    
User Function ZBCSG5()
	
	If inclui
		_sProd := M->HC_PRODUTO   
	Else
		_sProd := GDFieldGet("HC_PRODUTO")   
	EndIf            
Return(_sProd)  
//    
// --------------------------------------------------------------------------
// Filtro da grupo opcionais    
User Function ZBCSGA()
	Local _cQuery  := ""
	Local _sFiltro := ""
	Local _aFiltro := {}
	Local _sProd   := ""
	Local _sRev    := ""
	Local x		   := 0
	
	If inclui
		_sProd   := M -> HC_PRODUTO
		_sRev    := M -> HC_REVISAO
		_sData   := DTOS(M -> HC_DATA)
	Else
		_sProd   := GDFieldGet("HC_PRODUTO") 
		_sRev    := GDFieldGet("HC_REVISAO")
		_sData   := DTOS(GDFieldGet("HC_DATA"))
	EndIf

	_cQuery := " SELECT DISTINCT "
	_cQuery += " 	SG1.G1_GROPC "
	_cQuery += " FROM  " + RetSqlName("SG1") + " SG1 "
	_cQuery += " 	," + RetSqlName("SGA") + " SGA "
	_cQuery += " WHERE SG1.D_E_L_E_T_ = ''
	_cQuery += " AND SGA.D_E_L_E_T_ = ''
	_cQuery += " AND SGA.GA_GROPC = G1_GROPC
	_cQuery += " AND SGA.GA_OPC = G1_OPC
	_cQuery += " AND SG1.G1_COD = '" + _sProd + "' "
	_cQuery += " AND SG1.G1_GROPC <> ''
	_cQuery += " AND SG1.G1_INI <= '" +_sData+ "'"
	_cQuery += " AND SG1.G1_FIM >= '" +_sData+ "'"
	If !empty(_sRev)
		_cQuery += " AND G1_REVINI >= '" + _sRev + "' "
		_cQuery += " AND G1_REVFIM <= '" + _sRev + "' "
	EndIf
	_cQuery += " GROUP BY SG1.G1_GROPC "
	
	_aFiltro := U_Qry2Array(_cQuery)
	
	If len(_aFiltro) > 0
		For x=1 to len(_aFiltro)
			_sFiltro += _aFiltro[x,1]
			If x < len(_aFiltro)
				_sFiltro += "/" 
			EndIf
		Next
	EndIf
Return (_sFiltro)
//
// --------------------------------------------------------------------------
// Lista de opcionais  
User Function ZBDOpc()

	AxCadastro("ZBD", "Opcionais", ".T.", "", , , , , , , , , , ) 
Return
//
// -----------------------------------------------------------------------------
// Deleta registros de opcionais no grid
Static Function _DelZBDGrid(_sFilial,_sEvento,_sProd,_sData,_sAno)
	Local lRet := .T.

	// deleta registros já gravados do evento/produto e data selecionado
	_cQuery := " UPDATE " + RetSqlName("ZBD") 
	_cQuery += " SET D_E_L_E_T_ = '*' "
	_cQuery += " WHERE ZBD_FILIAL = '" + _sFilial + "'"
	_cQuery += " AND ZBD_VAEVE    = '" + _sEvento + "'"
	_cQuery += " AND ZBD_PROD     = '" + _sProd   + "'"
	_cQuery += " AND ZBD_DATA     = '" + DTOS(_sData)   + "'"
	_cQuery += " AND ZBD_ANO      = '" + _sAno    + "'"

	If TCSQLExec (_cQuery) < 0
		lRet := .F.
		u_showmemo(_cQuery)
		Return
    Endif 
Return lRet
//
// --------------------------------------------------------------------------
// Relatório de planejamento   
User Function VA_RPLJPRD()
	Private oReport
	Private cPerg   := "VA_RPLJPRD"
	
	_ValidPerg()
	Pergunte(cPerg,.F.)
	
	oReport := ReportDef()
	oReport:PrintDialog()
Return
//
// --------------------------------------------------------------------------
Static Function ReportDef()
	Local oReport  := Nil
	Local oSection1:= Nil
	//Local oFunction

	oReport := TReport():New("VA_RPLJPRD","Planejamento de produção",cPerg,{|oReport| PrintReport(oReport)},"Planejamento de produção")
	
	oReport:SetTotalInLine(.F.)
	oReport:SetLandScape(.T.)
	oReport:ShowHeader()
	
	oSection1 := TRSection():New(oReport,,{}, , , , , ,.T.,.F.,.F.) 
	
	TRCell():New(oSection1,"COLUNA0", 	"" ,"Evento"			,	 ,20,/*lPixel*/,{||  	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA1", 	"" ,"Dia"				,	 , 5,/*lPixel*/,{||  	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA2", 	"" ,"Data"				,    ,10,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA3", 	"" ,"Produto"			,    , 8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA4", 	"" ,"Descrição"			,    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA5", 	"" ,"Quantidade"		,	 ,12,/*lPixel*/,{||		},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUN5A", 	"" ,"Qtd.Litros"		,	 ,12,/*lPixel*/,{||		},"RIGHT",,"RIGHT",,,,,,.F.)
	TRCell():New(oSection1,"COLUN5B", 	"" ,"Embalagem"			,	 ,25,/*lPixel*/,{||		},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA6", 	"" ,"Revisão"			,    , 8,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA7", 	"" ,"Descrição"			,    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA8", 	"" ,"Grupo Opcionais"	,    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA9", 	"" ,"Opcionais"			,    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
	TRCell():New(oSection1,"COLUNA10", 	"" ,"Obs"				,    ,30,/*lPixel*/,{|| 	},"LEFT",,,,,,,,.F.)
Return(oReport)
//
// --------------------------------------------------------------------------
Static Function PrintReport(oReport)
	Local oSection1  := oReport:Section(1)
	Local cQuery     := ""	
	Local cQuery1    := ""
	Local cQuery2    := ""
	Local aZBC       := {}
	Local cTituloRel := ""
	Local x			 := 0
	
		If mv_par09 == 1
			nHandle := FCreate("c:\temp\VA_RPLJPRD.CSV")
			_sLinha := "Evento;Dia;Data;Produto;Descricao;Quantidade;Qtd.Litros;Embalagem;Revisao;Descricao;Grupo Opcionais;Opcionais;Obs;"
			FWrite(nHandle,_sLinha + chr (13) + chr (10))
		EndIf
		
		cQuery := " SELECT "
		cQuery += " 	 ZBC_FILIAL "
		cQuery += " 	,ZBC_COD "
		cQuery += "     ,ZBC_DESC "
		cQuery += "     ,ZBC_ANO "
		cQuery += "     ,ZBC_EMB "
		cQuery += " FROM " + RetSqlName("ZBC")
		cQuery += " WHERE D_E_L_E_T_ = '' "
		cQuery += " AND ZBC_FILIAL BETWEEN '" + mv_par01 + "' AND '" + mv_par02 + "' "
		cQuery += " AND ZBC_COD BETWEEN '" + mv_par03 + "' AND '" + mv_par04 + "' "
		aZBC := U_Qry2Array(cQuery)
		
		If Len(aZBC) > 0
			For x:=1 to Len(aZBC)
				cTituloRel := alltrim(aZBC[x,2]) + " - " + alltrim(aZBC[x,3])+ " / " + alltrim(aZBC[x,4])
				cEmb := alltrim(aZBC[x,5])
				
				cQuery1 := " SELECT "
				cQuery1 += " 	 HC_FILIAL AS FILIAL "
				cQuery1 += " 	,HC_ANO AS ANO "
				cQuery1 += " 	,HC_DATA AS DATA "
				cQuery1 += " 	,HC_VAEVENT AS EVENTO "
				cQuery1 += "    ,HC_PRODUTO AS PRODUTO "
				cQuery1 += "    ,SB1.B1_DESC AS DESCPROD "
				cQuery1 += "    ,HC_QUANT AS QUANT "
				cQuery1 += "    ,HC_REVISAO AS REVISAO "
				cQuery1 += "    ,G5_OBS AS DESCREV "
				cQuery1 += "    ,HC_GRPOPC AS GRP "
				cQuery1 += "    ,HC_OPCITEM AS OPC "
				cQuery1 += "    ,HC_TPOPRD AS PRD "
				cQuery1 += "    ,ZX5_45DESC AS DESCPRD "
				cQuery1 += "    ,HC_OBS AS OBS "
				cQuery1 += " FROM " + RetSQLName ("SHC") + " SHC "
				cQuery1 += " INNER JOIN " + RetSQLName ("SB1") + " SB1 "
				cQuery1 += " 	ON (SB1.D_E_L_E_T_ = '' "
				cQuery1 += " 			AND SB1.B1_COD = SHC.HC_PRODUTO) "
				cQuery1 += " LEFT JOIN " + RetSQLName ("SG5") + " SG5 "
				cQuery1 += " 	ON (SG5.D_E_L_E_T_ = '' "
				cQuery1 += " 			AND SG5.G5_PRODUTO = SHC.HC_PRODUTO "
				cQuery1 += " 			AND SG5.G5_REVISAO = SHC.HC_REVISAO) "
				cQuery1 += " LEFT JOIN " + RetSQLName ("ZX5") + " ZX5 "
				cQuery1 += " 	ON (ZX5.D_E_L_E_T_ = '' "
				cQuery1 += " 			AND ZX5_TABELA = '45' "
				cQuery1 += " 			AND ZX5_45COD = HC_TPOPRD) "
				cQuery1 += " WHERE SHC.D_E_L_E_T_ = '' "
				cQuery1 += " AND SHC.HC_FILIAL = '" + aZBC[x,1] + "' "
				cQuery1 += " AND SHC.HC_VAEVENT = '" + aZBC[x,2] + "' "
				cQuery1 += " AND SHC.HC_ANO = '" + aZBC[x,4] + "' "
				cQuery1 += " AND SHC.HC_DATA BETWEEN '" + DTOS(mv_par07) + "' AND '" + DTOS(mv_par08) + "'"
				cQuery1 += " ORDER BY SHC.HC_DATA"
				
				dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery1), "TRA", .F., .T.)
				TRA->(DbGotop())
				
				oSection1:Init()
				oSection1:SetHeaderSection(.T.)

				While TRA->(!Eof())	
					cDescDt := _BuscaDiaSemana(TRA->DATA)	
					cQtdLitros := _BuscaQTDLitros(TRA->PRODUTO, TRA->REVISAO)			
					
					If !Empty(TRA->PRD) .or. Alltrim(TRA->PRD) != "" // se tem paradas de produção					
						vColuna0  := cTituloRel
						vColuna1  := cDescDt
						vColuna2  := STOD(TRA->DATA)
						vColuna3  := TRA->PRD
						vColuna4  := TRA->DESCPRD
						vColuna5  := 0
						vColun5A  := 0
						vColun5B  := cEmb
						vColuna6  := ""
						vColuna7  := ""
						vColuna8  := ""
						vColuna9  := ""
						vColuna10 := TRA->OBS 				
			
					Else
						If !empty(TRA->GRP)
														 
							cQuery2 := " SELECT"
							cQuery2 += "	ZBD_GRPOPC"
							cQuery2 += "    ,ZBD_OPCITE"
							cQuery2 += "    ,ZBD_CODOPC"
							cQuery2 += "    ,GA_DESCGRP"
							cQuery2 += "    ,GA_DESCOPC"
							cQuery2 += " FROM " + RetSQLName ("ZBD") + " ZBD " 
							cQuery2 += " INNER JOIN " + RetSQLName ("SGA") + " SGA " 
							cQuery2 += " 	ON (SGA.D_E_L_E_T_ = ''"
							cQuery2 += " 			AND SGA.GA_FILIAL = ''"
							cQuery2 += " 			AND SGA.GA_GROPC = ZBD.ZBD_GRPOPC"
							cQuery2 += " 			AND SGA.GA_OPC = ZBD.ZBD_OPCITE)"
							cQuery2 += " WHERE ZBD.D_E_L_E_T_ = ''"
							cQuery2 += " AND ZBD_FILIAL = '" + TRA->FILIAL + "'"
							cQuery2 += " AND ZBD_VAEVE = '" + TRA->EVENTO + "'"
							cQuery2 += " AND ZBD_ANO = '" + TRA->ANO + "'"
							cQuery2 += " AND ZBD_PROD = '" + TRA->PRODUTO + "'"
							cQuery2 += " AND ZBD_DATA = '" + TRA->DATA + "'"
							dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery2), "TRB", .F., .T.)
							TRB->(DbGotop())
							num := 0
							While TRB->(!Eof())	
								num += 1
								
								If num == 1
									vColuna0  := cTituloRel
									vColuna1  := cDescDt
									vColuna2  := STOD(TRA->DATA)
									vColuna3  := TRA->PRODUTO
									vColuna4  := TRA->DESCPROD
									vColuna5  := TRA->QUANT 
									vColun5A  := cQtdLitros * TRA->QUANT 
									vColun5B  := cEmb
									vColuna6  := TRA->REVISAO
									vColuna7  := TRA->DESCREV
									vColuna8  := alltrim(TRB->ZBD_GRPOPC) + "-" + alltrim(TRB->GA_DESCGRP) 
									vColuna9  := alltrim(TRB->ZBD_OPCITE) + "-" + alltrim(TRB->GA_DESCOPC)
									vColuna10 := TRA->OBS 
									If mv_par09 == 1
										_sLinha := vColuna0 +";"+ vColuna1 +";"+ DTOC(vColuna2) +";"+ vColuna3 +";"+ vColuna4 +";"+ str(vColuna5) +";"+  str(vColun5A) +";"+ vColun5B +";"+ vColuna6 +";" + alltrim(vColuna7) +";"+ vColuna8 +";"+ vColuna9 +";"+ vColuna10 +";"
										FWrite(nHandle,_sLinha + chr (13) + chr (10))
									EndIf
								Else
									vColuna0  := ''
									vColuna1  := ''
									vColuna2  := ''
									vColuna3  := ''
									vColuna4  := ''
									vColuna5  := 0
									vColun5A  := 0
									vColun5B  := ''
									vColuna6  := ''
									vColuna7  := ''
									vColuna8  := alltrim(TRB->ZBD_GRPOPC) + "-" + alltrim(TRB->GA_DESCGRP)
									vColuna9  := alltrim(TRB->ZBD_OPCITE) + "-" + alltrim(TRB->GA_DESCOPC)
									vColuna10 := ''	
									If mv_par09 == 1
										_sLinha := vColuna0 +";"+ vColuna1 +";"+ vColuna2 +";"+ vColuna3 +";"+ vColuna4 +";"+ str(vColuna5) +";"+  str(vColun5A) +";"+ vColun5B +";"+ vColuna6 +";" + alltrim(vColuna7) +";"+ vColuna8 +";"+ vColuna9 +";"+ vColuna10 +";"
										FWrite(nHandle,_sLinha + chr (13) + chr (10))
									EndIf	
								EndIf
								
								oSection1:Cell("COLUNA0")	:SetBlock   ({|| vColuna0	})
								oSection1:Cell("COLUNA1")	:SetBlock   ({|| vColuna1	})
								oSection1:Cell("COLUNA2")	:SetBlock   ({|| vColuna2	})
								oSection1:Cell("COLUNA3")	:SetBlock   ({|| vColuna3	})
								oSection1:Cell("COLUNA4")	:SetBlock   ({|| vColuna4 	})
								oSection1:Cell("COLUNA5")	:SetBlock   ({|| vColuna5   })
								oSection1:Cell("COLUN5A")	:SetBlock   ({|| vColun5A   })
								oSection1:Cell("COLUN5B")	:SetBlock   ({|| vColun5B   })
								oSection1:Cell("COLUNA6")	:SetBlock   ({|| vColuna6	})
								oSection1:Cell("COLUNA7")	:SetBlock   ({|| vColuna7 	})
								oSection1:Cell("COLUNA8")	:SetBlock   ({|| vColuna8	})
								oSection1:Cell("COLUNA9")	:SetBlock   ({|| vColuna9 	})
								oSection1:Cell("COLUNA10")	:SetBlock   ({|| vColuna10	})
								
								oSection1:PrintLine()								
								DBSelectArea("TRB")
								dbskip()
							Enddo
							TRB->(DbCloseArea())
						Else
							vColuna0  := cTituloRel
							vColuna1  := cDescDt
							vColuna2  := STOD(TRA->DATA)
							vColuna3  := TRA->PRODUTO
							vColuna4  := TRA->DESCPROD
							vColuna5  := TRA->QUANT 
							vColun5A  := cQtdLitros * TRA->QUANT 
							vColun5B  := cEmb
							vColuna6  := TRA->REVISAO
							vColuna7  := TRA->DESCREV
							vColuna8  := TRA->GRP
							vColuna9  := ""
							vColuna10 := TRA->OBS
						EndIf					
					EndIf

					If empty(TRA->GRP)
						oSection1:Cell("COLUNA0")	:SetBlock   ({|| vColuna0	})
						oSection1:Cell("COLUNA1")	:SetBlock   ({|| vColuna1	})
						oSection1:Cell("COLUNA2")	:SetBlock   ({|| vColuna2	})
						oSection1:Cell("COLUNA3")	:SetBlock   ({|| vColuna3	})
						oSection1:Cell("COLUNA4")	:SetBlock   ({|| vColuna4 	})
						oSection1:Cell("COLUNA5")	:SetBlock   ({|| vColuna5   })
						oSection1:Cell("COLUN5A")	:SetBlock   ({|| vColun5A   })
						oSection1:Cell("COLUN5B")	:SetBlock   ({|| vColun5B   })
						oSection1:Cell("COLUNA6")	:SetBlock   ({|| vColuna6	})
						oSection1:Cell("COLUNA7")	:SetBlock   ({|| vColuna7 	})
						oSection1:Cell("COLUNA8")	:SetBlock   ({|| vColuna8	})
						oSection1:Cell("COLUNA9")	:SetBlock   ({|| vColuna9 	})
						oSection1:Cell("COLUNA10")	:SetBlock   ({|| vColuna10	})
						
						oSection1:PrintLine()
						If mv_par09 == 1
							_sLinha := vColuna0 +";"+ vColuna1 +";"+ DTOC(vColuna2)  +";"+ vColuna3 +";"+ vColuna4 +";"+ str(vColuna5) +";"+  str(vColun5A) +";"+ vColun5B +";"+ vColuna6 +";" + alltrim(vColuna7) +";"+ vColuna8 +";"+ vColuna9 +";"+ vColuna10 +";"
							FWrite(nHandle,_sLinha + chr (13) + chr (10))
						EndIf
					EndIf
							
					DBSelectArea("TRA")
					dbskip()
				Enddo
				oSection1:Finish()
				TRA->(DbCloseArea())
			Next
		Else
			h_help(" Sem registros para os parâmetros selecionados!")
		EndIf	
		If mv_par09 == 1
			u_help(" Planilha gerada em: c:\temp\ Arquivo:VA_RPLJPRD.CSV")
			FClose(nHandle)  
		EndIf  
Return
//
//-------------------------------------------------
// Busca a descrição do dia da semana
Static Function _BuscaDiaSemana(_cDt)
	Local cDescDt := ""
	
	nDt := DOW(STOD(_cDt))
	
	Do Case
		Case nDt == 1
			cDescDt := "Dom"
		Case nDt == 2
			cDescDt := "Seg"
		Case nDt == 3
			cDescDt := "Ter"
		Case nDt == 4
			cDescDt := "Qua"
		Case nDt == 5
			cDescDt := "Qui"
		Case nDt == 6
			cDescDt := "Sex"
		Case nDt == 7
			cDescDt := "Sab"
	EndCase
	
Return cDescDt
//
//-------------------------------------------------
// Busca a qnt. em litros
Static Function _BuscaQTDLitros (_cProd, _cRev)
	Local _qtdLt  := 0
	Local cQuery3 := ""
	
	cQuery3 += " WITH ESTRUT (CODIGO, COD_PAI, COD_COMP, QTD, PERDA, DT_INI, DT_FIM, NIVEL, REVINI, REVFIM, TIPO, DTINI, DTFIM)"
	cQuery3 += " AS"
	cQuery3 += " (SELECT"
	cQuery3 += " 		G1_COD PAI"
	cQuery3 += " 	   ,G1_COD"
	cQuery3 += " 	   ,G1_COMP"
	cQuery3 += " 	   ,G1_QUANT"
	cQuery3 += " 	   ,G1_PERDA"
	cQuery3 += " 	   ,G1_INI"
	cQuery3 += " 	   ,G1_FIM"
	cQuery3 += " 	   ,1 AS NIVEL"
	cQuery3 += "	   ,G1_REVINI"
	cQuery3 += "	   ,G1_REVFIM"
	cQuery3 += "	   ,SB1.B1_TIPO"
	cQuery3 += "	   ,G1_INI"
	cQuery3 += "	   ,G1_FIM"
	cQuery3 += "	FROM " + RetSqlName("SG1") + " SG1 (NOLOCK)"
	cQuery3 += "	INNER JOIN " + RetSqlName("SB1") + " SB1 "
	cQuery3 += "		ON (SB1.D_E_L_E_T_ = ''"
	cQuery3 += "		AND SB1.B1_COD = SG1.G1_COMP)"
	cQuery3 += "	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery3 += "	AND G1_FILIAL = '  '"
	cQuery3 += "	UNION ALL"
	cQuery3 += "	SELECT"
	cQuery3 += "		CODIGO"
	cQuery3 += "	   ,G1_COD"
	cQuery3 += "	   ,G1_COMP"
	cQuery3 += "	   ,QTD * G1_QUANT"
	cQuery3 += "	   ,G1_PERDA"
	cQuery3 += "	   ,G1_INI"
	cQuery3 += "	   ,G1_FIM"
	cQuery3 += "	   ,NIVEL + 1"
	cQuery3 += "	   ,G1_REVINI
	cQuery3 += "	   ,G1_REVFIM"
	cQuery3 += "	   ,SB1.B1_TIPO"
	cQuery3 += "	   ,G1_INI"
	cQuery3 += "	   ,G1_FIM"
	cQuery3 += "	FROM " + RetSqlName("SG1") + " SG1 (NOLOCK)"
	cQuery3 += "	INNER JOIN ESTRUT EST"
	cQuery3 += "		ON G1_COD = COD_COMP"
	cQuery3 += "	INNER JOIN " + RetSqlName("SB1") + " SB1 "
	cQuery3 += "		ON (SB1.D_E_L_E_T_ = ''"
	cQuery3 += "		AND SB1.B1_COD = SG1.G1_COMP)"
	cQuery3 += "	WHERE SG1.D_E_L_E_T_ = ''"
	cQuery3 += "	AND SG1.G1_FILIAL = '  ')"
	cQuery3 += " SELECT"
	cQuery3 += " 	*"
	cQuery3 += " FROM ESTRUT E1"
	cQuery3 += " WHERE E1.CODIGO = '" + _cProd + "'"
	cQuery3 += " AND E1.REVINI <= '" + _cRev + "'"
	cQuery3 += " AND E1.REVFIM >= '" + _cRev + "'"
	cQuery3 += " AND E1.TIPO = 'VD'"
	cQuery3 += " AND E1.COD_PAI = '" + _cProd + "'"
	cQuery3 += " AND E1.DT_INI <= '"+ DTOS(mv_par07) +"'"
	cQuery3 += " AND E1.DT_FIM >= '"+ DTOS(mv_par08) +"'"
	
	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery3), "TRB", .F., .T.)
	TRB->(DbGotop())

	While TRB->(!Eof())	
		_qtdLt += TRB -> QTD
		
		DBSelectArea("TRB")
		dbskip()
	EndDo
	
	TRB->(DbCloseArea())
Return _qtdLt
//
// --------------------------------------------------------------------------
// Exporta arquivo
User Function PLJEXP(_sZBCFilial, _sZBCCod, _sZBCAno)
	Local _oSQL  	:= ClsSQL ():New ()
	Local cLocalDir := ''
	Local cMascara  := '.CSV|*.CSV'
	Local cTitulo   := 'Local do arquivo'
	Local nMascpad  := 0
	Local cDirIni   := '\'
	Local lSalvar   := .F.
	Local nOpcoes   := GETF_LOCALHARD
	Local lArvore   := .F. /*.T. = apresenta o árvore do servidor || .F. = não apresenta*/
	Local _i         := 0
	
	cLocalDir := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcoes, lArvore)

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += " 	   HC_FILIAL "			// 01
	_oSQL:_sQuery += "    ,HC_DOC "				// 02
	_oSQL:_sQuery += "    ,HC_VAEVENT "			// 03
	_oSQL:_sQuery += "    ,HC_ANO "				// 04
	_oSQL:_sQuery += "    ,HC_ITEM "			// 05
	_oSQL:_sQuery += "    ,HC_PRODUTO "			// 06
	_oSQL:_sQuery += "    ,B1_DESC "			// 07
	_oSQL:_sQuery += "    ,HC_DATA "			// 08
	_oSQL:_sQuery += "    ,HC_QUANT "			// 09
	_oSQL:_sQuery += "    ,HC_REVISAO "			// 10
	_oSQL:_sQuery += "    ,G5_OBS AS DESCREV "	// 11
	_oSQL:_sQuery += "    ,HC_GRPOPC "			// 12
	_oSQL:_sQuery += "    ,HC_OPCITEM " 		// 13
	_oSQL:_sQuery += "    ,HC_TPOPRD "			// 14
	_oSQL:_sQuery += "    ,ZX5_45DESC "			// 15
	_oSQL:_sQuery += "    ,B1_LITROS * HC_QUANT"// 16
	_oSQL:_sQuery += "    ,HC_VALINEN "			// 17
	_oSQL:_sQuery += "    ,SH1.H1_DESCRI "		// 18
	_oSQL:_sQuery += " FROM " + RetSQLName("SHC") + " SHC "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName("SB1") + " SB1 "
	_oSQL:_sQuery += " 		ON (SB1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SB1.B1_COD = SHC.HC_PRODUTO) "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SG5") + " SG5 "
	_oSQL:_sQuery += " 		ON (SG5.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " 			AND SG5.G5_PRODUTO = SHC.HC_PRODUTO "
	_oSQL:_sQuery += " 			AND SG5.G5_REVISAO = SHC.HC_REVISAO) "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("ZX5") + " ZX5 "
	_oSQL:_sQuery += "  	ON (ZX5.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "  		AND ZX5_TABELA = '45' "
	_oSQL:_sQuery += "  		AND ZX5_45COD = HC_TPOPRD) "
	_oSQL:_sQuery += " LEFT JOIN " + RetSQLName("SH1") + " SH1 "
	_oSQL:_sQuery += " 		ON (SH1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += "		AND SH1.H1_CODIGO = HC_VALINEN ) "
	_oSQL:_sQuery += " WHERE SHC.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND HC_FILIAL    = '" + _sZBCFilial + "'"
	_oSQL:_sQuery += " AND HC_VAEVENT   = '" + _sZBCCod   + "'"
	_oSQL:_sQuery += " AND HC_ANO       = '" + _sZBCAno    + "'"
	_oSQL:_sQuery += " ORDER BY HC_FILIAL, HC_DATA, HC_DOC, HC_VAEVENT, HC_PRODUTO "
	_aSHC := aclone (_oSQL:Qry2Array ())

	If Len(_aSHC) > 0
		nHandle := FCreate(cLocalDir)
		
		cTexto := "FILIAL|DOCUMENTO|EVENTO|ANO|ITEM|PRODUTO|DESCRICAO|DATA|QUANTIDADE|REVISAO|OBS|GRUPO OPC.|ITEM OPC.|PARADA PROD.|DESCRICAO|LITRAGEM|LINHA ENVASE|DESCRICAO" + CHR(13)+CHR(10) 
		FWrite(nHandle, cTexto)

		For _i:= 1 to Len(_aSHC)
			cTexto := ""
			cTexto += '"' + alltrim(_aSHC[_i, 1]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 2]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 3]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 4]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 5]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 6]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i, 7]) + '"|'
			cTexto += dtoc(_aSHC[_i, 8])          +  '|'
			cTexto += alltrim(str(_aSHC[_i, 9]))  +  '|'
			cTexto += '"' + alltrim(_aSHC[_i,10]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,11]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,12]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,13]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,14]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,15]) + '"|'
			cTexto += alltrim(str(_aSHC[_i, 16])) +  '|'  
			cTexto += '"' + alltrim(_aSHC[_i,17]) + '"|'
			cTexto += '"' + alltrim(_aSHC[_i,18]) + '"' + CHR(13)+CHR(10) 
			
			FWrite(nHandle, cTexto)
		Next

		FClose(nHandle)

		u_help(" Arquivo salvo em:" + cLocalDir)
	Else
		u_help(" Sem dados para gerar o aquivo")
	EndIf	
Return
//
// --------------------------------------------------------------------------
// Importa arquivo
User Function PLJIMP(_sZBCFilial, _sZBCCod, _sZBCAno)
	Local _oSQL  	  := ClsSQL ():New ()
	Local cArq        := ""
	Local cMascara    := ".CSV|*.CSV"
	Local cTitulo     := "Importar arquivo"
	Local nMascpad    := 0
	Local cDirIni     := "\"
	Local lSalvar     := .T.
	Local nOpcoes     := GETF_LOCALHARD
	Local lArvore     := .F. /*.T. = apresenta o árvore do servidor || .F. = não apresenta*/
	Local cLinha  	  := ""
	Local aDados  	  := {}
	Local _x		  := 1
	Local _y          := 1
	local aOpc        := {}
	private _sModo    := ""
	private aHeader   := {}
	private aCols     := {}
	private nOpc      := 4 // alterar
	private N		  := 1
	
	cArq := cGetFile( cMascara, cTitulo, nMascpad, cDirIni, lSalvar, nOpcoes, lArvore)

	If !File(cArq)
		MsgStop("O arquivo '" + cArq + "' não foi encontrado. Importação não realizada!","ATENCAO")
		Return
	EndIf

	FT_FUSE(cArq)
	ProcRegua(FT_FLASTREC())
	FT_FGOTOP()

	While !FT_FEOF()
		cLinha := FT_FREADLN()
		AADD(aDados,Separa(cLinha,"|",.T.))
		FT_FSKIP()		
	EndDo  

	If U_MsgYesNo ("Deseja reimportar os arquivos?")

		// Limpa os registros eventos
		_oSQL:_sQuery += " UPDATE SHC010 SET D_E_L_E_T_='*' "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND HC_FILIAL    = '" + _sZBCFilial + "'"
		_oSQL:_sQuery += " AND HC_VAEVENT   = '" + _sZBCCod    + "'"
		_oSQL:_sQuery += " AND HC_ANO       = '" + _sZBCAno    + "'"
		_oSQL:Exec ()

		// Limpa registros opcionais
		_oSQL:_sQuery += " UPDATE ZBD010 SET D_E_L_E_T_='*' "
		_oSQL:_sQuery += " WHERE D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND ZBD_FILIAL   = '" + _sZBCFilial + "'"
		_oSQL:_sQuery += " AND ZBD_VAEVE    = '" + _sZBCCod    + "'"
		_oSQL:_sQuery += " AND ZBD_ANO      = '" + _sZBCAno    + "'"
		_oSQL:Exec ()
		
		For _x:= 2 to Len(aDados)

			_sFilial 	:= StrTran(aDados[_x, 1], '"', '')
			_sDoc 		:= StrTran(aDados[_x, 2], '"', '')
			_sEvento 	:= StrTran(aDados[_x, 3], '"', '')
			_sAno 		:= StrTran(aDados[_x, 4], '"', '')
			_sItem 		:= StrTran(aDados[_x, 5], '"', '')
			_sProd 		:= StrTran(aDados[_x, 6], '"', '')
			_sRevisao 	:= StrTran(aDados[_x,10], '"', '')
			_sGrpOpc 	:= StrTran(aDados[_x,12], '"', '')
			_sOpcItem 	:= StrTran(aDados[_x,13], '"', '')
			_sTpPrd   	:= StrTran(aDados[_x,14], '"', '')
			_sLinha   	:= StrTran(aDados[_x,17], '"', '')

			RecLock("SHC", .T.)
				SHC -> HC_FILIAL 	:= iif(!empty(_sFilial)		, padl(_sFilial,2,'0')	,"01")
				SHC -> HC_DOC 		:= iif(!empty(_sDoc)		, upper(_sDoc)			, upper(_sZBCCod))
				SHC -> HC_VAEVENT 	:= iif(!empty(_sEvento)		, upper(_sEvento)		, upper(_sZBCCod))
				SHC -> HC_ANO 		:= iif(!empty(_sAno)		, _sAno 				,_sZBCAno)
				SHC -> HC_ITEM 		:= iif(!empty(_sItem)		, padl(_sItem ,2,'0')	," ")
				SHC -> HC_PRODUTO 	:= iif(!empty(_sProd)		, _sProd 				," ")
				SHC -> HC_DATA 		:= iif(!empty(aDados[_x, 8]), ctod(aDados[_x, 8])	,date())   
				SHC -> HC_QUANT 	:= iif(!empty(aDados[_x, 9]), val(aDados[_x, 9])	,0)     
				SHC -> HC_REVISAO 	:= iif(!empty(_sRevisao)	, padl(_sRevisao ,3,'0')," ")
				SHC -> HC_GRPOPC 	:= iif(!empty(_sGrpOpc)		, padl(_sGrpOpc ,3,'0') ," ")
				SHC -> HC_OPCITEM 	:= iif(!empty(_sOpcItem)	, _sOpcItem				," ")
				SHC -> HC_TPOPRD 	:= iif(!empty(_sTpPrd)		, _sTpPrd 				," ")
				SHC -> HC_VALINEN 	:= iif(!empty(_sLinha)		, _sLinha 				," ")
			MsUnlock("SHC")	

			// separa opcionais
			aOpc := {}
			AADD(aOpc,Separa(aDados[_x,13],";",.T.))

			For _y:=1 to Len(aOpc[1])
				_sGrp := iif(!empty(aDados[_x,12]),PADL(aDados[_x,12],3,'0')," ")
				_sOpc := aOpc[1,_y]

				If !empty(_sOpc)
					RecLock("ZBD", .T.)
						ZBD -> ZBD_FILIAL := iif(!empty(aDados[_x, 1]),PADL(aDados[_x, 1],2,'0'),"01")
						ZBD -> ZBD_VAEVE  := iif(!empty(aDados[_x, 3]),upper(aDados[_x, 3]), upper(_sZBCCod))
						ZBD -> ZBD_ANO    := iif(!empty(aDados[_x, 4]),aDados[_x, 4],_sZBCAno)
						ZBD -> ZBD_PROD   := iif(!empty(aDados[_x, 6]),aDados[_x, 6]," ")
						ZBD -> ZBD_DATA   := iif(!empty(aDados[_x, 8]),STOD(aDados[_x, 8]),date())   
						ZBD -> ZBD_QUANT  := iif(!empty(aDados[_x, 8]), val(aDados[_x, 9]),0)   
						ZBD -> ZBD_ITEM   := iif(!empty(aDados[_x, 5]),PADL(aDados[_x, 5],2,'0')," ")
						ZBD -> ZBD_GRPOPC := _sGrp
						ZBD -> ZBD_OPCITE := _sOpc
						ZBD -> ZBD_CODOPC := Posicione("SGA",1,xfilial("SGA") + _sGrp + _sOpc,"GA_VACODOP")  // GA_FILIAL + GA_GROPC + GA_OPC
					MsUnlock("ZBD")	
				Endif			
			Next
		Next  

		U_PLJA(4, 'allwaystrue ()', 'allwaystrue ()', .T., _sPreFiltr, _sZBCCod)
	EndIf
Return
//
// --------------------------------------------------------------------------
// Valida Produto
Static Function _ValidaProduto(_sProduto)
	Local _lRetP  := .T.
	Local _sBloq  := ""
	Local _sTp    := ""

	_sBloq  := Posicione("SB1",1 ,xFilial("SB1") + _sProduto,"B1_MSBLQL")
	_sTp := Posicione("SB1",1 ,xFilial("SB1") + _sProduto,"B1_TIPO")

	If empty(_sTp)
		u_help("Produto não existe!")
		_lRetP := .F.
	EndIf

	If !alltrim(_sTp) $ "PA/PI'"
		u_help("Produto deve ser do tipo PA ou PI")
		_lRetP := .F.
	EndIf

	If _sBloq <> '2'
		u_help("Produto bloqueado para uso!")
		_lRetP := .F.
	EndIf
Return _lRetP
//
// --------------------------------------------------------------------------
// Perguntas
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Filial de       	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {02, "Filial até      	", "C", 2, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {03, "Evento de       	", "C", 3, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {04, "Evento até       	", "C", 3, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {05, "Ano de       	    ", "C", 4, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {06, "Ano até           	", "C", 4, 0,  "",  "   ", {},                         					""}) 
    aadd (_aRegsPerg, {07, "Data de       		", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {08, "Data até       		", "D", 8, 0,  "",  "   ", {},                         					""})
    aadd (_aRegsPerg, {09, "Gerar planilha      ", "N", 1, 0,  "",  "   ", {"Sim", "Não"},                         		""})
     U_ValPerg (cPerg, _aRegsPerg)
Return
