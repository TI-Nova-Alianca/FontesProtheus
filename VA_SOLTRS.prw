// Programa...: VA_SOLTRS
// Autor......: Claudia Lionço
// Data.......: 28/03/2023
// Descricao..: Solicitação de transferencia em lote
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #processo
// #Descricao         #Solicitação de transferencia em lote
// #PalavasChave      #solicitacao_de_transferencia #TRS
// #TabelasPrincipais #SE1
// #Modulos           #FIN
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------
#XTranslate .OK       => 1
#XTranslate .Filial   => 2
#XTranslate .Numero   => 3
#XTranslate .Prefixo  => 4
#XTranslate .Parcela  => 5
#XTranslate .Tipo     => 6
#XTranslate .Cliente  => 7
#XTranslate .Loja     => 8
#XTranslate .Nome     => 9
#XTranslate .Valor    => 10
#XTranslate .Recno    => 11

#include "rwmake.ch"
#Include "protheus.ch"   
#include "tbiconn.ch"

User Function VA_SOLTRS()
    private cPerg := "VA_SOLTRS"

    _ValidPerg()
	if pergunte (cPerg, .T.)
        processa ({|| _Seleciona()})
    endif
Return
//
// --------------------------------------------------------------------------------
// Seleciona titulos para a trsnferencia
Static Function _Seleciona()
	Local _oSQL   := ClsSQL ():New ()
	Local _aDados := {}
	Local _x      := 0

	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT "
	_oSQL:_sQuery += "     ' ' AS OK "
	_oSQL:_sQuery += " 	  ,E1_FILIAL AS FILIAL "
	_oSQL:_sQuery += "    ,E1_NUM AS NUMERO "
	_oSQL:_sQuery += "    ,E1_PREFIXO AS PREFIXO "
	_oSQL:_sQuery += "    ,E1_PARCELA AS PARCELA "
	_oSQL:_sQuery += "    ,E1_TIPO AS TIPO "
	_oSQL:_sQuery += "    ,E1_CLIENTE AS CLENTE "
	_oSQL:_sQuery += "    ,E1_LOJA AS LOJA " 
	_oSQL:_sQuery += "    ,A1_NOME AS NOME "
	_oSQL:_sQuery += "    ,E1_VALOR AS VALOR "
	_oSQL:_sQuery += "    ,SE1.R_E_C_N_O_ AS RECNO "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SE1") + " SE1 "
	_oSQL:_sQuery += " INNER JOIN " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " 	ON SA1.D_E_L_E_T_   = '' "
	_oSQL:_sQuery += " 		AND SA1.A1_COD  = E1_CLIENTE "
	_oSQL:_sQuery += " 		AND SA1.A1_LOJA = E1_LOJA "
	_oSQL:_sQuery += " WHERE SE1.D_E_L_E_T_ = '' "
	_oSQL:_sQuery += " AND E1_FILIAL  = '01' "
	_oSQL:_sQuery += " AND E1_SALDO   = E1_VALOR "
	_oSQL:_sQuery += " AND E1_SITUACA = '0' "
	_oSQL:_sQuery += " AND E1_BAIXA   = '' "
	_oSQL:_sQuery += " AND E1_NUMSOL  = '' "
	_oSQL:_sQuery += " AND E1_EMISSAO BETWEEN '"+ dtos(mv_par01) +"' AND '"+ dtos(mv_par02)+"' "
	_oSQL:_sQuery += " AND E1_CLIENTE BETWEEN '"+      mv_par04  +"' AND '"+      mv_par05 +"' "
	if !empty(mv_par03)
		_oSQL:_sQuery += " AND E1_TIPO = '" + mv_par03 + "' "
	endif
	_aDados := aclone(_oSQL:Qry2Array())

	If Len(_aDados) > 0
		
		// Inicializa coluna de selecao com .F. ('nao selecionada').
		for _x := 1 to len(_aDados)
			_aDados [_x, .Ok] = .F.
		next

		_aCols = {}
		aadd (_aCols, {.Filial  , 'Filial' , 10, '@!'				})
		aadd (_aCols, {.Numero  , 'Numero' , 20, '@!'				})
		aadd (_aCols, {.Prefixo , 'Prefixo', 10, '@!'				})
		aadd (_aCols, {.Parcela , 'Parcela', 10, '@!'				})
		aadd (_aCols, {.Tipo    , 'Tipo'   , 10, '@!'				})
		aadd (_aCols, {.Cliente , 'Cliente', 10, '@!'				})
		aadd (_aCols, {.Loja    , 'Loja'   , 10, '@!'				})
		aadd (_aCols, {.Nome    , 'Nome'   , 60, '@!'				})
		aadd (_aCols, {.Valor   , 'Valor'  , 30, "@E 999,999,999.99"})
		
		U_MBArray (@_aDados, 'Selecione os titulos para gerar solicitações', _aCols, 1)
		
		_sFiDest := U_VA_SOLTEL() // Busca filial de destino

		for _x = 1 to len (_aDados)				
			if _aDados[_x, .Ok]
				if !empty(_sFiDest)                                                                                                    
					Fa620Auto(_aDados[_x, .Recno], _sFiDest, "INCLUSÃO DE SOLICITAÇÃO AUTOMÁTICA", .F., .F.)
				else
					u_help("Filial de destino não selecionada!")
				endif
			endif			
		next
		u_help("Solicitações de transferência finalizadas!")
	else
		u_help("Sem titulos selecionados!")
	endif
Return
//
// --------------------------------------------------------------------------
// Abre tela para incluir observações
User Function VA_SOLTEL()
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	Local oButton1
	Local oButton2
	Local oGet1
	Local cGet1     := "  "
	Local oSay1
	Local _lRet     := .T.
	Local _sFilial  := ""
	Static oDlg

	DEFINE MSDIALOG oDlg TITLE "Filial de destino" FROM 000, 000  TO 090, 300 COLORS 0, 16777215 PIXEL

		@ 012, 006 SAY oSay1 PROMPT "Informe a filial de destino :" SIZE 067, 007 OF oDlg COLORS 0, 16777215 PIXEL
		@ 010, 082 MSGET oGet1 VAR cGet1 SIZE 046, 010 OF oDlg COLORS 0, 16777215 PIXEL
		@ 027, 090 BUTTON oButton1 PROMPT "OK" SIZE 037, 012 OF oDlg ACTION  (_lRet := .T., oDlg:End ()) PIXEL
		@ 027, 045 BUTTON oButton2 PROMPT "Cancela" SIZE 037, 012 OF oDlg ACTION  (_lRet := .F., oDlg:End ())  PIXEL

	ACTIVATE MSDIALOG oDlg CENTERED

	if _lRet
		_sFilial := cGet1
	endif

	U_SalvaAmb (_aAmbAnt)
	U_ML_SRArea (_aAreaAnt)

Return _sFilial
//
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT        TIPO TAM DEC VALID F3     Opcoes Help
	aadd (_aRegsPerg, {01, "Emissão de  ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {02, "Emissão ate ", "D", 8,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {03, "Tipo        ", "C", 3,  0,  "",   "   ", {},    ""})
	aadd (_aRegsPerg, {04, "Cliente de  ", "C", 6,  0,  "",   "SA1", {},    ""})
	aadd (_aRegsPerg, {05, "Cliente até ", "C", 6,  0,  "",   "SA1", {},    ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
