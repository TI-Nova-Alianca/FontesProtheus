// Programa:  OM200Qry
// Autor:     Robert Koch
// Data:      27/05/2014
// Descricao: PE para filtro dos pedidos liberados a gerar carga no OMS
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Ponto_de_entrada #filtro
// #PalavasChave      #montagem_de_cargas
// #TabelasPrincipais #SC5 #SC6 #SC9
// #Modulos           #OMS
//
// Historico de alteracoes:
// 14/07/2020 - Robert  - Permite filtrar por representante (GLPI 8161).
//                      - Inseridas tags para catalogacao de fontes
// 09/03/2023 - Claudia - Incluido filtro de UF destino. GLPI: 13285
// 10/03/2023 - Claudia - Incluido parametro da query para rodar o P.E. apenas uma vez. GLPI: 13300
//
// ---------------------------------------------------------------------------------------------------
#Include "Protheus.ch"
#Include "TopConn.ch"

User Function OM200Qry ()
	local _aAreaAnt := GetArea()
	local _sRet     := paramixb[1]
	local _nTpQuery := paramixb[4]
	local _sRepCarg := ''
	local _aFiltro  := {}
	local _lCont    := .T.
	local _sFiltro := ""

	If _nTpQuery == 1 // segunda execução do P.E.
		
		_OM200Del(RetCodUsr())

		_aFiltro := U_VAOMS200()

		If Len(_aFiltro) > 0
			_sRepCarg := _aFiltro[1, 1]
			_sUFCarg  := _aFiltro[1, 2]

			If !empty(_sRepCarg)
				sa3 -> (dbsetorder (1))
				If !sa3 -> (dbseek (xfilial ("SA3") + _sRepCarg, .F.))
					u_help ("Representante '" + _sRepCarg + "' não cadastrado.",, .t.)
					_lCont := .F.
				EndIf
				If _lCont
					_sRet    += " AND SC5.C5_VEND1 = '" + _sRepCarg + "'"
					_sFiltro += " AND SC5.C5_VEND1 = '" + _sRepCarg + "'"
				EndIf
			EndIf
			
			If !empty(_sUFCarg)
				_sRet    += " AND SC5.C5_VAEST = '" + UPPER(_sUFCarg) + "'"
				_sFiltro += " AND SC5.C5_VAEST = '" + UPPER(_sUFCarg) + "'"
			EndIf
		EndIf
		// Acrescenta filtro a query padrao.
		_sRet    += " AND C9_PEDIDO IN (SELECT C9_PEDIDO FROM VA_VPEDIDOS_PARA_CARGA WHERE C9_FILIAL = '" + xfilial ("SC9") + "')" 
		_sFiltro += " AND C9_PEDIDO IN (SELECT C9_PEDIDO FROM VA_VPEDIDOS_PARA_CARGA WHERE C9_FILIAL = '" + xfilial ("SC9") + "')" 
		
		// Grava Evento
		_oEvento    := NIL
		_oEvento := ClsEvent():new ()
		_oEvento:CodEven   = "OMS200"
		_oEvento:DtEvento  = date()
		_oEvento:Texto	   = _sFiltro
		_oEvento:Usuario   = RetCodUsr()
		_oEvento:Grava()
	EndIf

	If 	_nTpQuery == 2
		_oSQL:= ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT "
		_oSQL:_sQuery += " 		DESCRITIVO "
		_oSQL:_sQuery += " FROM VA_VEVENTOS "
		_oSQL:_sQuery += " WHERE DATA    = '" + dtos(date()) +"' "
		_oSQL:_sQuery += " AND USUARIO   = '" + RetCodUsr()  +"' "
		_oSQL:_sQuery += " AND CODEVENTO = 'OMS200' "
		_aDados := aclone (_oSQL:Qry2Array ())

		If Len(_aDados) > 0
			_sRet += _aDados[1,1]
		EndIf

		_OM200Del(RetCodUsr())

	EndIf

	RestArea(_aAreaAnt)
return _sRet
//
// --------------------------------------------------------------------------
// Abre tela de filtros
User Function VAOMS200()
	local _aAreaAnt  	:= U_ML_SRArea ()
	local _aAmbAnt   	:= U_SalvaAmb ()
	Local oButton1
	Local oButton2
	Local oGet1
	Local _sRep := "   "
	Local oGet2
	Local _sUf  := "  "
	Local oSay1
	Local oSay2
	Local _aRet := {}
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Filtros" FROM 000, 000  TO 120, 260 COLORS 0, 16777215 PIXEL

	@ 012, 010 SAY oSay1 PROMPT "Representante:" SIZE 041, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 026, 010 SAY oSay2 PROMPT "Uf Destino:" SIZE 037, 007 OF oDlg COLORS 0, 16777215 PIXEL
	@ 012, 052 MSGET oGet1 VAR _sRep SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 026, 052 MSGET oGet2 VAR _sUf SIZE 060, 010 OF oDlg COLORS 0, 16777215 PIXEL
	@ 042, 075 BUTTON oButton1 PROMPT "OK" SIZE 037, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL
	@ 042, 035 BUTTON oButton2 PROMPT "Cancelar" SIZE 037, 012 OF oDlg ACTION  (_lRet := .F., oDlg:End ())  PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	if _lRet
		AADD(_aRet, { _sRep ,;
					  _sUf  })
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)

Return _aRet
//
// --------------------------------------------------------------------------
// Deleta registros para filtros
Static Function _OM200Del(_sUsuario)
	Local _oSQL:= ClsSQL ():New ()

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " DELETE "
	_oSQL:_sQuery += " FROM VA_VEVENTOS "
	_oSQL:_sQuery += " WHERE USUARIO   = '" + _sUsuario +"' "
	_oSQL:_sQuery += " AND CODEVENTO = 'OMS200' "
	_oSQL:Exec()

Return
