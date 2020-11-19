// Programa:  F3DA0
// Autor:     Robert Koch - TCX021
// Data:      23/07/2008
// Cliente:   Alianca
// Descricao: Browse em cima da tabela DA0, para ser chamado via F3. Foi feito via
//            programa por que tem varias filtragens.
//
// Como cadastrar no SXB: selecionar "consulta especifica" e informar U_F3DA0() no campo "expressao"
// Obs.1: O execblock ja deve deixar a tabela posicionada para retorno.
// Obs.2: O execblock deve retornar .T. para que a consulta seja aceita.
//
// Historico de alteracoes:
// 18/08/2008 - Robert - Incluida pesquisa para o campo A1_TABELA.
// 10/01/2013 - Elaine - Contemplar pesquisa para o VA_LPR
//

#include "rwmake.ch"

// --------------------------------------------------------------------------
User Function F3DA0 ()
	local _aOpcoes   := {}
	local _nOpcao    := 0
	local _aAreaAnt  := U_ML_SRArea ()
	local _aCampos   := {}
	//local _sCliente  := ""
	//local _sLoja     := ""
	//local _sVend     := ""
	local _sQuery    := ""
	local _lContinua := .T.
    local _sCodRep   := ""
    local _xUsuario  := ""
	local _xMat_usu  := ""

	
	if _lContinua
		_sQuery := ""

		// Busca tabelas de preco para cada situacao.
		do case

		// Busca tabelas de preco sem amarracao com cliente nem vendedor.
		case readvar () $ "M->ZY_CODTAB/M->ZP_CODTAB/M->C5_TABELA"
			_sQuery += " select distinct DA0_CODTAB, DA0_DESCRI, ZP_CLIENTE, ZY_VEND, DA0.R_E_C_N_O_"
			_sQuery += "   from " + RetSQLName ("DA0") + " DA0 "
			_sQuery += " left join " + RetSQLName ("SZY") + " SZY  "
			_sQuery +=      " on (SZY.D_E_L_E_T_ =  ''"
			_sQuery +=      " and ZY_FILIAL      =  '" + xfilial ("SZY") + "'"
			_sQuery +=      " and ZY_FILTAB      =  '" + xfilial ("DA0") + "'"
			_sQuery +=      " and ZY_CODTAB      =  DA0.DA0_CODTAB)"
			_sQuery += " left join " + RetSQLName ("SZP") + " SZP  "
			_sQuery +=      " on (SZP.D_E_L_E_T_ =  ''"
			_sQuery +=      " and ZP_FILIAL      =  '" + xfilial ("SZP") + "'"
			_sQuery +=      " and ZP_FILTAB      =  '" + xfilial ("DA0") + "'"
			_sQuery +=      " and ZP_CODTAB      =  DA0.DA0_CODTAB)"
			_sQuery += "  where DA0.D_E_L_E_T_ =  ''"
			_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0") + "'"
			_sQuery += "    and DA0_ATIVO      =  '1'"
			_sQuery += "    and DA0_DATDE      <= '" + dtos (dDataBase) + "'"
			_sQuery += "    and (DA0_DATATE    >= '" + dtos (dDataBase) + "'"
			_sQuery += "     or  DA0_DATATE     = '')"
			_sQuery += " Order by DA0_CODTAB "


		case readvar () $ "MV_PAR01/MV_PAR02" //-- Tratamento, a principio, somente para o VA_LPR
		
        	_xUsuario := upper(alltrim(cUserName))
	        _xMat_usu := ALLTRIM(__CUSERID)
	        dbselectarea ("SA3")
	        DbGoTop()
	        Do WHile !eof()
		       If ALLTRIM(A3_CODUSR) == ALLTRIM(UPPER(_xMat_usu))
			      _sCodRep := A3_COD
			      EXIT
		       ENDIF
		       DbSkip()
	        EndDo

			_sQuery += " select distinct DA0_CODTAB, DA0_DESCRI, '', ZY_VEND, DA0.R_E_C_N_O_"
			_sQuery += "   from " + RetSQLName ("DA0") + " DA0, "
			_sQuery +=              RetSQLName ("SZY") + " SZY  "
			_sQuery += "  where SZY.D_E_L_E_T_ =  ''"
			_sQuery += "    and ZY_FILIAL      =  '" + xfilial ("SZY")  + "'"
			_sQuery += "    and ZY_FILTAB      =  '" + xfilial ("DA0")  + "'"
	        if !empty (_sCodRep)
 			   _sQuery += "    and ZY_VEND        =  '" + _sCodRep + "'"
		   	endif
			_sQuery += "    and ZY_CODTAB      =  DA0.DA0_CODTAB"
			_sQuery += "    and DA0.D_E_L_E_T_ =  ''"
			_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0")  + "'"
			_sQuery += "    and DA0_ATIVO      =  '1'"
			_sQuery += "    and DA0_DATDE      <= '" + dtos (dDataBase) + "'"
			_sQuery += "    and DA0_DATATE     >= '" + dtos (dDataBase) + "'"
			_sQuery += " Order by DA0_CODTAB "

		// Tela de pre-pedidos (acessada pelos representantes): mostra soh
		// as tabelas de precos vinculadas ao cliente ou ao representante.
		case readvar () == "M->CJ_TABELA"

			_sQuery += " select distinct DA0_CODTAB, DA0_DESCRI, ZP_CLIENTE, '', DA0.R_E_C_N_O_"
			_sQuery += "   from " + RetSQLName ("DA0") + " DA0, "
			_sQuery +=              RetSQLName ("SZP") + " SZP  "
			_sQuery += "  where DA0.D_E_L_E_T_ =  ''"
			_sQuery += "    and SZP.D_E_L_E_T_ =  ''"
			_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0") + "'"
			_sQuery += "    and DA0_ATIVO      =  '1'"
			_sQuery += "    and DA0_DATDE      <= '" + dtos (dDataBase) + "'"
			_sQuery += "    and DA0_DATATE     >= '" + dtos (dDataBase) + "'"
			_sQuery += "    and ZP_FILIAL      =  '" + xfilial ("SZP") + "'"
			_sQuery += "    and DA0_CODTAB     =  ZP_CODTAB"
			_sQuery += "    and DA0_FILIAL     =  ZP_FILTAB"
			_sQuery += "    and ZP_CLIENTE     =  '" + m->cj_Cliente + "'"
			_sQuery += "    and ZP_LOJA        =  '" + m->cj_Loja + "'"
			_sQuery += " Union "
			_sQuery += " select distinct DA0_CODTAB, DA0_DESCRI, '', ZY_VEND, DA0.R_E_C_N_O_"
			_sQuery += "   from " + RetSQLName ("DA0") + " DA0, "
			_sQuery +=              RetSQLName ("SZY") + " SZY  "
			_sQuery += "  where DA0.D_E_L_E_T_ =  ''"
			_sQuery += "    and SZY.D_E_L_E_T_ =  ''"
			_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0") + "'"
			_sQuery += "    and DA0_ATIVO      =  '1'"
			_sQuery += "    and DA0_DATDE      <= '" + dtos (dDataBase) + "'"
			_sQuery += "    and DA0_DATATE     >= '" + dtos (dDataBase) + "'"
			_sQuery += "    and ZY_FILIAL      =  '" + xfilial ("SZY") + "'"
			_sQuery += "    and DA0_CODTAB     =  ZY_CODTAB"
			_sQuery += "    and DA0_FILIAL     =  ZY_FILTAB"
			_sQuery += " and ZY_VEND = '" + M->CJ_VEND1 + "'"
			_sQuery += " Order by DA0_CODTAB "
			
		case readvar () $ "M->A1_TABELA"
			_sQuery += " select distinct DA0_CODTAB, DA0_DESCRI, '', ZY_VEND, DA0.R_E_C_N_O_"
			_sQuery += "   from " + RetSQLName ("DA0") + " DA0, "
			_sQuery +=              RetSQLName ("SZY") + " SZY  "
			_sQuery += "  where SZY.D_E_L_E_T_ =  ''"
			_sQuery += "    and ZY_FILIAL      =  '" + xfilial ("SZY")  + "'"
			_sQuery += "    and ZY_FILTAB      =  '" + xfilial ("DA0")  + "'"
			_sQuery += "    and ZY_VEND        =  '" + m->a1_vend       + "'"
			_sQuery += "    and ZY_CODTAB      =  DA0.DA0_CODTAB"
			_sQuery += "    and DA0.D_E_L_E_T_ =  ''"
			_sQuery += "    and DA0_FILIAL     =  '" + xfilial ("DA0")  + "'"
			_sQuery += "    and DA0_ATIVO      =  '1'"
			_sQuery += "    and DA0_DATDE      <= '" + dtos (dDataBase) + "'"
			_sQuery += "    and DA0_DATATE     >= '" + dtos (dDataBase) + "'"
			_sQuery += " Order by DA0_CODTAB "
			//			u_ShowMemo (_squery)

		otherwise
			u_help ("Programa " + procname () + ": Chamada nao prevista. Solicite manutencao.")
			_lContinua = .F.
		endcase
	endif

	if _lContinua
		_aOpcoes = aclone (U_Qry2Array (_sQuery))
	
		if len (_aOpcoes) == 0
			u_help ("Nao foi encontrada nenhuma tabela disponivel.")
			_lContinua = .F.
		endif
	endif

	if _lContinua
		_aCampos = {}
		aadd (_aCampos, {1, "Tabela",     30, ""})
		aadd (_aCampos, {2, "Descricao",  80, ""})
		aadd (_aCampos, {3, "Cliente",    50, ""})
		aadd (_aCampos, {4, "Represent.", 50, ""})
		_nOpcao = u_F3Array (_aOpcoes, "Selecione opcao:", _aCampos, NIL, NIL, "", "", .F.)
	endif

	U_ML_SRArea (_aAreaAnt)
	
	// Deixa o arquivo posicionado no registro selecionado.
	if _lContinua .and. _nOpcao > 0
		da0 -> (dbgoto (_aOpcoes [_nOpcao, 5]))
	endif

return (_lContinua .and. _nOpcao > 0)
