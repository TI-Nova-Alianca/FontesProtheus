// Programa...: VAHISTNF
// Descricao..: Histórico NF
// Data.......: 2016
// Autor......: Procdata
//
// Historico de alteracoes:
// 08/01/2014 - Leandro - Inclusão de pesquisa de histórico de NFs, conforme solicitação de Jeferson
// 09/03/2020 - Claudia - Ajuste de fonte conforme solicitação de versão 12.1.25 - SX3
// 23/04/2020 - Robert  - Quando chamado via menu, os parametros _xCliente e _xLoja nao tinham tratamento.
//

// ----------------------------------------------------------------------------------------------------
#include "rwmake.ch"

User Function VAHISTNF(_xCliente, _xLoja)
	private cPerg     := "VAHISTNFXX"
	Private cCadastro := "Notas Fiscais do Cliente " + alltrim(_xCliente) + "-" + alltrim(_xLoja)		
	Private cDelFunc  := ".T."
	Private cString   := "SF2"
	Private aRotina   := {	{"Historico"	,"U_VARASTRO(SF2->F2_DOC, SF2->F2_SERIE)"	,0,2}  ,;
							{"Visualizar"	,'MC090Visual("SF2",Recno(),2)'		 		,0,2}  ,;
							{"Pesquisar"	,"AxPesqui"									,0,1}   }

	pergunte (cPerg, .T.)
	_ValidPerg ()

	dbSelectArea("SF2")
	dbSetOrder(1)
	
	cExprFilTop := "F2_FILIAL = '" 	+ xFilial ("SF2") + "'"
	if _xCliente != NIL .and. _xLoja != NIL
		cExprFilTop += "F2_CLIENTE = '" 	+ alltrim(_xCliente) 	+"'"
		cExprFilTop += "AND F2_LOJA >= " 	+ alltrim(_xLoja)  		+" "
	endif
	cExprFilTop += "AND F2_EMISSAO >= " + dtos(MV_PAR01) 		+" "
	cExprFilTop += "AND F2_EMISSAO <= " + dtos(MV_PAR02) 		+" "
	cExprFilTop += "AND (D_E_L_E_T_ = '' OR D_E_L_E_T_ = '*')"
	
	mBrowse(6,1,22,75,"SF2",,,,,,,,,,,,,,cExprFilTop)
Return
// --------------------------------------------------------------------------
// Abre tela com as informações de historico da nota
User Function VARASTRO(_sDoc, _sSerie)
	local _aAreaAnt  	:= U_ML_SRArea ()
	local _aAmbAnt   	:= U_SalvaAmb ()
	local _oDlg      	:= NIL
	Local i             := 0
	//local _oBrw      	:= NIL
	//local _aCpos     	:= {}
	//local _aEstrut   	:= {}
	//local _nCampo    	:= 0
	//local _sQuery   	:= ""
	Local nI
	//Local oDlg
	//Local oGetDados2
	Local nUsado 	 	:= 0
	Local _ret		 	:= .F.
	//local _aLinVazia 	:= {}
	//local _lContinua 	:= .T.
	//local _sOrdEmb   	:= ""
	//local _sMsgInf   	:= ""
	//local _oDlgMemo  	:= NIL
	local _aSize     	:= {}  // Para posicionamento de objetos em tela
	//Local nUsado 	 	:= 0
	local _oEvento 		:= NIL
	local _i			:= 0
	Private lRefresh 	:= .T.
	Private aHeader 	:= {}
	Private aCols 		:= {}
	private aRotina  	:= {{"BlaBlaBla", "allwaystrue ()", 0, 1}, ;
							{"BlaBlaBla", "allwaystrue ()", 0, 2}, ;
							{"BlaBlaBla", "allwaystrue ()", 0, 3}, ;
							{"BlaBlaBla", "allwaystrue ()", 0, 4}  }  // aRotina eh exigido pela MSGetDados!!!

//	DbSelectArea("SX3")
//	DbSetOrder(1)
//	DbSeek("SZN")
//	
//	While !Eof() .and. SX3->X3_ARQUIVO == "SZN"
//		If X3Uso(SX3->X3_USADO)
//			If Alltrim(SX3->X3_CAMPO) $ ("ZN_DATA/ZN_HORA/ZN_USUARIO/ZN_STATUS/ZN_DESCST1/ZN_SUBSTS/ZN_DESCST2/ZN_DTENT/ZN_PEDVEND/ZN_NFS/ZN_SERIES/ZN_TEXTO/ZN_CLIENTE/ZN_LOJACLI/ZN_FLAG")
//				nUsado++
//				Aadd(aHeader,{Trim(X3Titulo()),;
//					SX3->X3_CAMPO,;
//					SX3->X3_PICTURE,;
//					SX3->X3_TAMANHO,;
//					SX3->X3_DECIMAL,;
//					SX3->X3_VALID,;
//					"",;
//					SX3->X3_TIPO,;
//					"",;
//					"" })
//			endif
//		EndIf
//		DbSkip()
//	End

	_aCampos := {}
	_aCpoSX3 := FwSX3Util():GetAllFields('SZN')
	
	For i := 1 To Len(_aCpoSX3)
		If  GetSx3Cache(_aCpoSX3[i], 'X3_ARQUIVO') == "SZN" .and. X3Uso(GetSx3Cache(_aCpoSX3[i], 'X3_USADO'))
			If Alltrim(GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')) $ ("ZN_DATA/ZN_HORA/ZN_USUARIO/ZN_STATUS/ZN_DESCST1/ZN_SUBSTS/ZN_DESCST2/ZN_DTENT/ZN_PEDVEND/ZN_NFS/ZN_SERIES/ZN_TEXTO/ZN_CLIENTE/ZN_LOJACLI/ZN_FLAG")
				nUsado++
				Aadd (aHeader, {GetSx3Cache(_aCpoSX3[i], 'X3_TITULO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_CAMPO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_PICTURE')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TAMANHO')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_DECIMAL')	,;
								GetSx3Cache(_aCpoSX3[i], 'X3_VALID')	,;
								""										,;
								GetSx3Cache(_aCpoSX3[i], 'X3_TIPO')		,;
								""										,;
								""					 					})
			EndIf
		EndIf
	Next i   
	
	_lin := 1

	dbselectarea("SZN")
	dbsetorder(3)
	dbseek(xFilial("SZN") + _sDoc)

	while !EOF() .and. SZN->ZN_NFS == _sDoc .and. SZN->ZN_SERIES == _sSerie

		if SZN->ZN_HISTNF == '1'
			Aadd(aCols,Array(nUsado+1))

			For nI := 1 To nUsado
				aCols[_lin][nI] := CriaVar(aHeader[nI][2])
			Next

			aCols[_lin][1] := SZN->ZN_DATA
			aCols[_lin][2] := SZN->ZN_HORA
			aCols[_lin][3] := SZN->ZN_USUARIO
			aCols[_lin][4] := SZN->ZN_STATUS
			aCols[_lin][5] := IIF(!Empty(SZN->ZN_STATUS),alltrim(Posicione("SX5",1 ,xFilial("SX5")+"ZT"+alltrim(SZN->ZN_STATUS),"X5_DESCRI")),"")
			aCols[_lin][6] := SZN->ZN_SUBSTS
			aCols[_lin][7] := IIF(!Empty(SZN->ZN_SUBSTS),alltrim(Posicione("SX5",1 ,xFilial("SX5")+"ZU"+alltrim(SZN->ZN_SUBSTS),"X5_DESCRI")),"")

			if alltrim(SZN->ZN_STATUS) == '2'
				_dDtEnt := SZN->ZN_DATA
			else
				_dDtEnt := STOD("")
			endif
			_sUF := alltrim(Posicione("SA1",1,xFilial("SA1") + SZN->ZN_CLIENTE + SZN->ZN_LOJACLI,"A1_EST"))
			_sPrazo := val(Posicione("SX5",1 ,xFilial("SX5")+"ZV"+alltrim(_sUF),"X5_DESCRI"))

			if alltrim(SZN->ZN_STATUS) == '2'
				_oDUtil = ClsDUtil():New ()
				_dVencto = _oDUtil:SomaDiaUt(_dDtEnt,_sPrazo)
			else
				_dVencto := " / / "
			endif

			aCols[_lin][8]  := IIF(alltrim(SZN->ZN_STATUS) == '2',DTOC(_dVencto)," / / ")
			aCols[_lin][9]  := SZN->ZN_PEDVEND
			aCols[_lin][10] := SZN->ZN_NFS
			aCols[_lin][11] := SZN->ZN_SERIES
			aCols[_lin][12] := SZN->ZN_TEXTO
			aCols[_lin][13] := SZN->ZN_CLIENTE
			aCols[_lin][14] := SZN->ZN_LOJACLI

			aCols[_lin][15] := SZN->ZN_FLAG
			aCols[_lin][16] := .F.

			_lin += 1
		endif

		dbselectarea("SZN")
		dbskip()
	enddo

// verifica usuários que podem deletar linhas
//	If alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR/JEFERSON.MUNHOZ'
//		_lDeleta := .T.
//	else
		_lDeleta := .F.
//	endif

	N := 1
	_aSize := MsAdvSize()
	define MSDialog _oDlg from 0,0 to _aSize [6], _aSize [5] of oMainWnd pixel title "Consulta de Historico da NF " + alltrim(_sSerie) + "-" + alltrim(_sDoc)

	// Botao OK para fechar o dialogo. Definido antes para que o 'foco' caia nele.
	@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 75  bmpbutton type 1 action (_ret := .T., _oDlg:End ())
	@ _oDlg:nClientHeight / 2 - 40, _oDlg:nClientWidth / 2 - 45  bmpbutton type 2 action (_ret := .F., _oDlg:End ())

	// Getdados para os eventos
	_oMulti := MSGETDADOS ():New (	15									, ;  // Limite superior
								  	15									, ;  // Limite esquerdo
								  	_oDlg:nClientHeight / 2 - 50		, ;  // Limite inferior
								  	_oDlg:nClientWidth / 2 - 15			, ;  // Limite direito
								  	4									, ;  // opcao do mbrowse, caso tivesse (alterar)
								  	"allwaystrue ()"					, ;  // Linha ok
								  	"allwaystrue ()"					, ;  // Tudo ok
								  										, ;  // Campos com incremento automatico
								  	_lDeleta							, ;  // Permite deletar linhas
								  	{"ZN_STATUS","ZN_SUBSTS","ZN_TEXTO"}, ;  // Vetor de campos que podem ser alterados
								  										, ;  // Reservado
								  	.F.									, ;  // Se .T., a primeira coluna nunca pode ficar vazia
								  	999999								, ;  // Maximo de linhas permitido
								  	"allwaystrue ()"					, ;  // Executada na validacao de campos, mesmo os que nao estao na MSGetDados
								  	"AllwaysTrue ()"					, ;  // Funcao executada quando pressionadas as teclas <Ctrl>+<Delete>.
								  										, ;  // Reservado
								  	"allwaystrue ()"					, ;  // Funcao executada para validar a exclusao ou reinclusao de uma linha do aCols.
								  	_oDlg								)    // Objeto no qual a MsGetDados serah criada.

	activate msdialog _oDlg centered

	if _ret
		For _i:= 1 to Len(aCols)
			If !GDDeleted(_i)
				if aCols[_i][15] == .F.

					_oEvento    := NIL
					_texto := alltrim(aCols[_i][12])
					_sUF := alltrim(Posicione("SA1",1,xFilial("SA1") + aCols[_lin][8] + aCols[_lin][9],"A1_EST"))
					_sPrazo := val(Posicione("SX5",1 ,xFilial("SX5")+"ZV"+alltrim(_sUF),"X5_DESCRI"))

					_oEvento := ClsEvent():new ()
					_oEvento:CodEven   = "SZN001"
					_oEvento:Texto	   =  _texto
					_oEvento:NFSaida   =  IIF(empty(aCols[1][10]),_sDoc,aCols[1][10])
					_oEvento:SerieSaid =  IIF(empty(aCols[1][11]),_sSerie,aCols[1][11])
					_oEvento:PedVenda  =  aCols[1][9]
					_oEvento:Cliente   =  aCols[1][13]
					_oEvento:LojaCli   =  aCols[1][14]
					_oEvento:Hist	   =  "1"
					_oEvento:Status	   =  aCols[_i][4]
					_oEvento:Sub	   =  aCols[_i][6]
					_oEvento:Prazo	   =  _sPrazo
					_oEvento:Flag	   =  .T.
					_oEvento:Grava ()

				ENDIF
			else
				dbselectarea("SZN")
				dbsetorder(3)
				if dbseek(xFilial("SZN") + _sDoc)
					While !Eof() .and. alltrim(SZN->ZN_NFS) == alltrim(_sDoc) .and. alltrim(SZN->ZN_SERIES) == alltrim(_sSerie)
						if SZN->ZN_DATA == acols[_i][1] .and. SZN->ZN_HORA == acols[_i][2] .and. SZN->ZN_STATUS == acols[_i][4] .and. SZN->ZN_SUBSTS == acols[_i][6] .and. SZN->ZN_HISTNF == '1'
							reclock ("SZN", .F.)
							szn->(dbdelete ())
							msunlock ()
						endif
						dbselectarea("SZN")
						dbskip()
					enddo
				endif
			EndIf
		Next _i
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)
Return
// --------------------------------------------------------------------------
// cria perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}

	//                     PERGUNT      TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Data de"	, "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Data ate"	, "D", 8,  0,  "",   "   ", {},    ""})
	U_ValPerg (cPerg, _aRegsPerg)
return
