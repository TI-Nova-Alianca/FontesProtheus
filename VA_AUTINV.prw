// Programa...: VA_AUTINV
// Autor......: Cl�udia Lion�o
// Data.......: 04/09/2019
// Descricao..: Gera registros de invent�rio na tabela SB7
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Atualizacao
// #Descricao         #Gera registros de saldo atual na tabela SB7 para posterior comparativo com a contagem fisica.
// #PalavasChave      #inventario
// #TabelasPrincipais #SB7
// #Modulos           #EST
//
// Historico de alteracoes:
// 12/11/2019 - Robert - Valida se o usuario tem acesso a esta rotina.
// 25/03/2020 - Ajuste da rotina, criando a tabela temporaria ao gerar o arquivo .csv 
//				e ao realizar a grava��o dos dados.
// 20/07/2020 - Robert  - Verificacao de acesso passa a validar acesso 106 e nao mais 069.
//                      - Inseridas tags para catalogacao de fontes
// 03/02/2021 - Cl�udia - Ajustada a importa��o de itens. GLPI: 9254
//
// -------------------------------------------------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#include 'parmtype.ch'
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function VA_AUTINV ()
	local _lContinua   := .T.
	local cCadastro    := "Gera registros de invent�rio"
	local aSays        := {}
	local aButtons     := {}
	local nOpca        := 0
	local lPerg        := .F.
	local _nLock       := 0
	Private cPerg      := "VA_AUTINV"
	private _ErroLog   :=""
	private _MErro     := .F.
	_Cnt := .T.

	u_logIni ()
	
	if _lContinua
		if ! u_zzuvl ('106', __cUserId, .T.)
			_lContinua = .F.
		endif
	endif

	If _lContinua // Somente uma estacao por vez
		_nLock := U_Semaforo (procname (), .F.)
		If _nLock == 0
			u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
			return
		EndIf
	EndIf
	
	If _lContinua
		_ValidPerg ()
		Pergunte (cPerg, .F.)
		AADD(aSays,cCadastro)
		AADD(aSays,"")
		AADD(aSays,"")
		
		AADD(aButtons, { 5,.T.,{|| lPerg := Pergunte(cPerg,.T. ) } } )
		AADD(aButtons, { 4,.T.,{|| _IMPSB7()}} )
		AADD(aButtons, { 1,.T.,{|| nOpca := If(( lPerg .Or. Pergunte(cPerg,.T.)) .And. _TudoOk() , 1, 2 ), If( nOpca == 1, FechaBatch(), Nil ) }})
		AADD(aButtons, { 2,.T.,{|| FechaBatch() }} )
		
	 	FormBatch( cCadastro, aSays, aButtons )
	
		If nOpca == 1
			sDocumento := DTOS(mv_par01)
			Processa( {|lEnd| BuscaEstoque()})
		EndIf
	
		// Libera semaforo.
		If _nLock > 0
			U_Semaforo (_nLock)
		EndIf
	EndIf
Return
//	
// --------------------------------------------------------------------------
// valida��o tudo OK
Static Function _TudoOk()
	Local _lRet     := .T.
	
	If empty(mv_par01) 
		u_help ("Data de invent�rio dever� ser preenchida")
		_lRet = .F.
	EndIf
	
Return(_lRet)
//
// --------------------------------------------------------------------------
// Busca estoque
Static Function BuscaEstoque()
	local   _lContinua := .T.
	Private sDoc       := ""

	u_logsx1 ()
	
	_sQuery := ""
	_sQuery += " WITH C AS "
	_sQuery += " ("
	_sQuery += " SELECT"
	_sQuery += " 		SB2.B2_FILIAL AS FILIAL,"
	_sQuery += " 		SB2.B2_LOCAL  AS ALMOX,"
	_sQuery += " 		SB1.B1_TIPO   AS TPROD,"
	_sQuery += " 		SB1.B1_GRUPO  AS GRUPO,"
	_sQuery += " 		SB1.B1_COD    AS PRODUTO,"
	_sQuery += " 		SB1.B1_DESC   AS DESCRICAO,"
	_sQuery += " 		CASE WHEN SB1.B1_LOCALIZ = 'S' "
	_sQuery += " 			THEN BF_LOTECTL "
	_sQuery += " 			ELSE '' END AS LOTECTL,"
	_sQuery += " 		CASE WHEN SB1.B1_LOCALIZ = 'S'"
	_sQuery += " 			THEN BF_LOCALIZ "
	_sQuery += " 			ELSE '' END AS LOCALIZ,"
	_sQuery += " 		ISNULL(SBF.BF_QUANT, ISNULL(SB8.B8_SALDO, SB2.B2_QATU)) AS QTD,   "
	_sQuery += " 		SB1.B1_LOCALIZ AS USALOC, "
	_sQuery += " 		ISNULL(SB8.B8_DTVALID, '') AS VALID, "
	_sQuery += " 		SB1.B1_LOCALIZ AS B1_LOCAL,"
	_sQuery += " 		SB1.B1_RASTRO AS B1_RASTRO "
	_sQuery += " 	FROM " + RetSQLName ("SB1") + " SB1 "
	_sQuery += " 	LEFT JOIN " + RetSQLName ("SB2") + " SB2 "    
	_sQuery += " 		ON (B1_COD = B2_COD"
	_sQuery += " 		AND SB2.D_E_L_E_T_ = '')"
	_sQuery += " 	LEFT JOIN " + RetSQLName ("SBF") + " SBF " 
	_sQuery += " 		ON (RTRIM(B2_COD)      = RTRIM(BF_PRODUTO)"
	_sQuery += " 		AND (RTRIM(SB1.B1_COD) = RTRIM(SBF.BF_PRODUTO)"
	_sQuery += " 		AND RTRIM(B2_LOCAL)    = RTRIM(BF_LOCAL)"
	_sQuery += " 		AND RTRIM(B2_FILIAL)   = RTRIM(BF_FILIAL)"
	_sQuery += " 		AND SBF.D_E_L_E_T_     = ''))"
	_sQuery += " 	LEFT JOIN " + RetSQLName ("SB8") + " SB8 " 
	_sQuery += " 		ON (SB8.D_E_L_E_T_ = ''"
	_sQuery += " 		AND B8_FILIAL  = BF_FILIAL"
	_sQuery += " 		AND B8_PRODUTO = BF_PRODUTO"
	_sQuery += " 		AND B8_LOCAL   = BF_LOCAL"
	_sQuery += " 		AND B8_LOTECTL = BF_LOTECTL)"
	_sQuery += " 	WHERE SB1.D_E_L_E_T_ = ''"
	_sQuery += " 	AND SB2.B2_QATU <> 0"
	_sQuery += "  AND SB1.B1_TIPO NOT IN ('MO')"
	_sQuery += "  AND B2_LOCAL NOT IN ('66')"
	If ! empty(mv_par01) // filial
		_sQuery += "  AND B2_FILIAL = '" + alltrim(cFilAnt) + "'"
	EndIf
	If ! empty(mv_par03) // grupo
		_sQuery += "  AND SB1.B1_GRUPO BETWEEN '" + alltrim(mv_par02) + "' AND '" + alltrim(mv_par03)+ "'"
	EndIf
	If ! empty(mv_par05) // tipo de produto
		_sQuery += "  AND SB1.B1_TIPO BETWEEN '" + alltrim(mv_par04) + "' AND '" + alltrim(mv_par05) + "'"
	EndIf
	If ! empty(mv_par07) // almoxarifado/local
		_sQuery += "  AND B2_LOCAL BETWEEN '" + alltrim(mv_par06) + "' AND '" + alltrim(mv_par07) + "'"
	EndIf
	If ! empty(mv_par09) // produto
		_sQuery += "  AND SB1.B1_COD BETWEEN '" + alltrim(mv_par08) + "' AND '" + alltrim(mv_par09) + "'"
	EndIf	
	_sQuery += " )"
	_sQuery += " SELECT * FROM C"
	_sQuery += " WHERE QTD <> 0"
	_sQuery += " ORDER BY FILIAL, ALMOX, TPROD, GRUPO, PRODUTO"
	// -------------------- Faz valida��es no processo para mostrar em tela
	dbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery), "_trb", .F., .T.)

	procregua (_trb -> (reccount ()))
	_trb -> (dbgotop ())
	
	sMensagem := ""
	Do while ! _trb -> (eof ())
		If _trb -> B1_RASTRO = 'L' .AND. empty(_trb -> LOTECTL)
			sMensagem += " SEM INFORMA��O DE LOTE:" + CRLF
			sMensagem += " -> Filial: " + alltrim(_trb-> FILIAL) +" Produto:"+alltrim(_trb->PRODUTO)+" Almox:"+alltrim(_trb->ALMOX) + CRLF
			sMensagem += " --------------------------------" + CRLF
			_Cnt := .F.
		EndIf
		If _trb -> B1_LOCAL = 'S' .AND. empty(_trb -> LOCALIZ)
			sMensagem += "SEM INFORMA��O DE LOCAL: " + CRLF
			sMensagem += " -> Filial: " + alltrim(_trb-> FILIAL) +" Produto:"+alltrim(_trb->PRODUTO)+" Almox:"+alltrim(_trb->ALMOX) + CRLF
			sMensagem += " --------------------------------" + CRLF
			_Cnt := .F.
		EndIf
		_trb -> (dbskip ())
	EndDo
	
	If _Cnt == .F.
		zMsgLog(sMensagem, "Log de erros na valida��o", 1, .T.)
	EndIf
	_trb -> (dbCloseArea ())

	// -------------------- Executa o processo
	//dbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery), "_trb", .F., .T.)
	// procregua (_trb -> (reccount ()))	
	If _lContinua
		If U_MsgNoYes ("Deseja exportar para uma planilha para conferencia?")
			dbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery), "_trb", .F., .T.)
			procregua (_trb -> (reccount ()))
			_trb -> (dbgotop ())
			U_TRB2XLS ('_trb')
			_trb ->(DbCloseArea())
		EndIf
		
		 // Verifica permiss�o para gera��o de invent�rio
		If U_MsgNoYes ("Confirma a geracao dos registros de invent�rio?")

			If ! U_ZZUVL ('106', __cUserId, .F.)
				u_help ("Usu�rio sem permiss�o para inclus�o/altera��o de registro de invent�rio.")
			Else
				incproc ()
				dbUseArea(.T., "TOPCONN", TCGenQry(,,_sQuery), "_trb", .F., .T.)
				_trb -> (dbgotop ())
				Do while ! _trb -> (eof ())
					IF alltrim(_trb -> USALOC) ='S'
						dDtValid := Posicione("SB8",3,_trb -> FILIAL + _trb -> PRODUTO + _trb -> ALMOX +_trb -> LOTECTL, "B8_DTVALID")
					EndIf
					GravaSB7()
					_trb -> (dbskip ())
				EndDo
				_trb ->(DbCloseArea())
				
				If _MErro == .T.
					zMsgLog(sMensagem, "Log de erros na grava��o", 1, .T.)
				EndIf
	
			Endif
		EndIf
	EndIf
Return
//
// --------------------------------------------------------------------------
// Grava SB7
Static function GravaSB7()
	lMsErroAuto := .F.
	aAuto       := {}	
	
	Aadd(aAuto, {"B7_FILIAL" 	, _trb -> FILIAL		 , NIL})
	Aadd(aAuto, {"B7_COD" 		, _trb -> PRODUTO 		 , NIL})
	Aadd(aAuto, {"B7_LOCAL" 	, alltrim(_trb -> ALMOX) , NIL})
	Aadd(aAuto, {"B7_TIPO" 		, alltrim(_trb -> TPROD) , NIL})
	Aadd(aAuto, {"B7_DOC" 		, alltrim(sDocumento)	 , NIL})
	Aadd(aAuto, {"B7_QUANT" 	, _trb -> QTD	         , NIL})
	Aadd(aAuto, {"B7_DATA" 		, date() 				 , NIL})
	Aadd(aAuto, {"B7_LOTECTL" 	, _trb -> LOTECTL		 , NIL})
	Aadd(aAuto, {"B7_LOCALIZ" 	, _trb -> LOCALIZ  		 , NIL})
	Aadd(aAuto, {"B7_LOCALIZ" 	, _trb -> LOCALIZ  		 , NIL})
	Aadd(aAuto, {"B7_CONTAGE" 	, '1' 					 , NIL})
	Aadd(aAuto, {"B7_ORIGEM" 	, "VA_AUTINV" 			 , NIL})
	Aadd(aAuto, {"B7_STATUS" 	, "1" 					 , NIL})
	IF alltrim(_trb -> USALOC) ='S'
		Aadd(aAuto, {"B7_DTVALID" 	, dDtValid					 , NIL})
	EndIf
            
	MsExecAuto({|a,b,c| MATA270(a,b,c)}, aAuto, .T.,3)

	If lMsErroAuto
		_ErroLog += "-> Filial/Produto/Almox:" +alltrim(_trb -> FILIAL) + "/"+ alltrim(_trb -> PRODUTO) + "/" + alltrim(_trb -> ALMOX) + "-->" + U_LeErro (memoread (NomeAutoLog ())) + chr (13) + chr (10) + chr (13) + chr (10)
		_MErro := .T.
	Else
		// Grava evento para posterior consulta
		_oEvento := ClsEvent():new ()
		_oEvento:Texto = "Produto:" + alltrim(_trb -> PRODUTO) + " Ax.:" + alltrim(_trb -> ALMOX) + " Qnt.:" + alltrim(str(_trb->QTD)) + " "
		_oEvento:LeParam (cPerg)
		_oEvento:CodEven = 'SB7010'
		_oEvento:Grava ()
	Endif

Return 
//
// --------------------------------------------------------------------------
Static Function zMsgLog(cMsg, cTitulo, nTipo, lEdit)
    Local lRetMens := .F.
    Local oDlgMens
    Local oBtnOk, cTxtConf := ""
    Local oFntTxt := TFont():New("Lucida Console",,-015,,.F.,,,,,.F.,.F.)
    Local oMsg  
    Default lEdit   := .F.
     
    //Definindo os textos dos bot�es
    cTxtConf:='&Ok'
 
    //Criando a janela centralizada com os bot�es
    DEFINE MSDIALOG oDlgMens TITLE cTitulo FROM 000, 000  TO 300, 400 COLORS 0, 16777215 PIXEL
        //Get com o Log
        @ 002, 004 GET oMsg VAR cMsg OF oDlgMens MULTILINE SIZE 191, 121 FONT oFntTxt COLORS 0, 16777215 HSCROLL PIXEL
        If !lEdit
            oMsg:lReadOnly := .T.
        EndIf
         
        //Se for Tipo 1, cria somente o bot�o OK

        @ 127, 144 BUTTON oBtnOk  PROMPT cTxtConf   SIZE 051, 019 ACTION (lRetMens:=.T., oDlgMens:End()) OF oDlgMens PIXEL
         
    ACTIVATE MSDIALOG oDlgMens CENTERED
 
Return lRetMens
// --------------------------------------------------------------------------
// Importa registro por .CSV
// Formato de arquivo: .csv
// Nome do arquivo: inventario.csv
// Separador: ; (ponto e virgula)
// Cabe�alho: B7_FILIAL;B7_COD;B7_LOCAL;B7_TIPO;B7_DOC;B7_QUANT;B7_DATA;B7_CONTAGE;B7_STATUS;B7_ORIGEM
// 01;0151;02;PA;20210213;1;20210213;1;1;IMPMANUAL      
//
Static Function _IMPSB7()
	Local _aDados   := {}
	Local i         := 0
	Private cPerg1  := "AUTINV"

	_ValidP1 ()
	Pergunte (cPerg1, .T.)

	_sArq     := alltrim(mv_par01) + alltrim(mv_par02)  + '.csv'
	_sSeparad := ";"
	_aDados := U_LeCSV (_sArq, _sSeparad)
	If Len(_aDados) == 0
		Return
	EndIf

	ProcRegua(Len(_aDados))
	
	For i:=2 to Len(_aDados)
	
		IncProc("Importando dados...")
	
		dbSelectArea("SB7")
		dbSetOrder(3) // B7_FILIAL+B7_DOC+B7_COD+B7_LOCAL                                                                                                                                
		dbGoTop()
		
		
		_sFilial := PADL(_aDados[i,1],2,'0')
		_sProd   := PADR(_aDados[i,2],15,' ')
		_sLocal  := PADL(_aDados[i,3],2,'0')
		_sTipo   := UPPER(_aDados[i,4])
		_sDoc    := PADR(_aDados[i,5], 9,' ')
		
		
		If dbSeek(_sFilial + _sDoc + _sProd + _sLocal)
			u_help(" O produto: " + alltrim(_sProd) + " no local " + _sLocal + " no documento " + alltrim(_sDoc) + " j� est� importado! O processo ser� finalizado." )
		Else
			Reclock("SB7",.T.)
				SB7->B7_FILIAL 	:= _sFilial
				SB7->B7_COD	   	:= _aDados[i,2]
				SB7->B7_LOCAL 	:= _sLocal
				SB7->B7_TIPO 	:= _sTipo
				SB7->B7_DOC 	:= _aDados[i,5]
				SB7->B7_QUANT 	:= val(_aDados[i,6])
				SB7->B7_DATA 	:= STOD(_aDados[i,7])
				SB7->B7_CONTAGE := _aDados[i,8]
				SB7->B7_STATUS 	:= _aDados[i,9]
				SB7->B7_ORIGEM 	:= _aDados[i,10]
			SB7->(MsUnlock())
		EndIf
	Next i
	u_help("Importa��o finalizada!")
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	//                     PERGUNT                 TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Data do invent�rio  ", "D", 10,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {02, "Grupo de         	", "C",  4,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {03, "Grupo at�        	", "C",  4,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {04, "Tipo de          	", "C",  2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {05, "Tipo at�         	", "C",  2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {06, "Almoxarifado de  	", "C",  2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {07, "Almoxarifado at� 	", "C",  2,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {08, "Produto de       	", "C", 15,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {09, "Produto at�      	", "C", 15,  0,  "",   "      ", {},    ""})
	

	U_ValPerg (cPerg, _aRegsPerg)
Return
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidP1 ()
	local _aRegsPerg := {}
	//                     PERGUNT                 TIPO TAM DEC VALID F3        Opcoes Help
	aadd (_aRegsPerg, {01, "Caminho do arquivo  ", "C", 20,  0,  "",   "      ", {},    ""})
	aadd (_aRegsPerg, {02, "Nome do arquivo     ", "C", 20,  0,  "",   "      ", {},    ""})

	U_ValPerg (cPerg1, _aRegsPerg)
Return
