// Programa...: BatVFat
// Autor......: Cláudia Lionço
// Data.......: 14/02/2020
// Descricao..: Realiza a gravação de dados na tabela VA_FATDADOS através da view VA_VFAT
//				_nTipo: 1 = Bat executado diariamente/ 2 = Processo executado via menu do Protheus
// Historico de alteracoes:
// 29/04/2020 - Cláudia - Incluida mensagem de finalização de processo qndo executado manualmente
// 24/06/2020 - Robert  - Incluida coluna VALOR_NET calculada a partir de colunas ja existentes na view (GLPI 8104).
// 09/07/2020 - Robert  - Formula do VALOR_NET somava rapel em lugar do frete.
//

// -------------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function BatVFat(_nTipo)
	local _oSQL      := NIL
	local _sSQL 	 := ""
//	local _sAliasQ   := ""
//	local _sSQL      := ""
	Private cPerg    := "BatVFat"
	
	If _nTipo != 1
		If ! u_zzuvl ('097', __cUserId, .T.)
			u_help ("Usuário sem permissão para usar estar rotina")
			Return
		Endif
	EndIf

	// Somente uma estacao por vez, pois a rotina eh pesada e certos usuarios derrubam o client na estacao e mandam rodar novamente...
	_nLock := U_Semaforo (procname ())
	If _nLock == 0
		u_help ("Nao foi possivel obter acesso exclusivo a esta rotina.")
		Return
	Endif
	
	If _nTipo == 1
		_QtdDias := 180
		_dDtIni  := DTOS(DaySub( Date() , _QtdDias))
		_dDtFim  := DTOS( Date() )
		
	Else
		_ValidPerg()
		If Pergunte(cPerg,.T.)
			_dDtIni := DTOS(mv_par01)
			_dDtFim := DTOS(mv_par02)
		Else
			Return
		EndIf
	EndIf
	
	
	u_logIni ()
	_sErroAuto := ''  // Para a funcao u_help gravar mensagens
	
	_sSQL := " DELETE FROM BI_ALIANCA.dbo.VA_FATDADOS" 
	_sSQL += " WHERE EMISSAO BETWEEN '"+ _dDtIni +"' AND '"+ _dDtFim +"'"
	u_log (_sSQL)
		
	If TCSQLExec (_sSQL) < 0
		if type ('_oBatch') == 'O'
			_oBatch:Mensagens += 'Erro ao limpar tabela VA_FATDADOS'
			_oBatch:Retorno = 'N'  // "Executou OK?" --> S=Sim;N=Nao;I=Iniciado;C=Cancelado;E=Encerrado automaticamente
		else
			u_help ('Erro ao limpar tabela VA_FATDADOS',, .t.)
		endif
	Else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := " 		INSERT INTO BI_ALIANCA.dbo.VA_FATDADOS(EMPRESA,ORIGEM,FILIAL,TES,CLIENTE,LOJA,GRUPOPROD,PRODUTO,TIPOPROD,TIPONFENTR,TIPONFSAID,"
		_oSQL:_sQuery += " QUANTIDADE,QTLITROS,DOC,SERIE,EMISSAO,VEND1,VEND2,PEDVENDA,ITEMPDVEND,PVCOND,SEGURO,DESPESA,TOTAL,VALIPI,COMIS1,COMIS2,COMIS3,"
		_oSQL:_sQuery += " COMIS4,COMIS5,RAPELPREV,BASERAPEL,VALICM,VALPIS,VALCOFINS,CUSTOMEDIO,QTCAIXAS,F4_DUPLIC,F4_ESTOQUE,F4_MARGEM,EST,PRODPAI,NFORI,"
		_oSQL:_sQuery += " SERIORI,ITEMORI,ITEMNOTA,PESOBRUTO,UMPROD,UMPRODPAI,ICMSRET,MOTDEV,DESCONTO,PRUNIT,CFOP,TRANSP,CUSTOREPOS,DTGERACAO,VALBRUT,"
		_oSQL:_sQuery += " MARGEMCONT,TIPOFRETE,FRETEPREV,VALORFRETE,FRETEREENT,FRETEREDSP,FRETEPALET,DFRAPEL,DFENCART,DFFEIRAS,DFFRETES,DFDESCONT,DFDEVOL,"
		_oSQL:_sQuery += " DFCAMPANH,DFABLOJA,DFCONTRAT,DFOUTROS,ATIVIDADE,PRAZOMEDIO,MARCA,GRPEMB,CODLINHA,DESCRIATIV,CANAL,DESCRICANAL,D2_VALFRE,VALOR_NET)"
		_oSQL:_sQuery += " 		SELECT EMPRESA,ORIGEM,FILIAL,TES,CLIENTE,LOJA,GRUPOPROD,PRODUTO,TIPOPROD,TIPONFENTR,TIPONFSAID,"
		_oSQL:_sQuery += " QUANTIDADE,QTLITROS,DOC,SERIE,EMISSAO,VEND1,VEND2,PEDVENDA,ITEMPDVEND,PVCOND,SEGURO,DESPESA,TOTAL,VALIPI,COMIS1,COMIS2,COMIS3,"
		_oSQL:_sQuery += " COMIS4,COMIS5,RAPELPREV,BASERAPEL,VALICM,VALPIS,VALCOFINS,CUSTOMEDIO,QTCAIXAS,F4_DUPLIC,F4_ESTOQUE,F4_MARGEM,EST,PRODPAI,NFORI,"
		_oSQL:_sQuery += " SERIORI,ITEMORI,ITEMNOTA,PESOBRUTO,UMPROD,UMPRODPAI,ICMSRET,MOTDEV,DESCONTO,PRUNIT,CFOP,TRANSP,CUSTOREPOS,DTGERACAO,VALBRUT,"
		_oSQL:_sQuery += " MARGEMCONT,TIPOFRETE,FRETEPREV,VALORFRETE,FRETEREENT,FRETEREDSP,FRETEPALET,DFRAPEL,DFENCART,DFFEIRAS,DFFRETES,DFDESCONT,DFDEVOL,"
		_oSQL:_sQuery += " DFCAMPANH,DFABLOJA,DFCONTRAT,DFOUTROS,ATIVIDADE,PRAZOMEDIO,MARCA,GRPEMB,CODLINHA,DESCRIATIV,CANAL,DESCRICANAL,D2_VALFRE"
		
		_oSQL:_sQuery += " ,(TOTAL - VALICM"
		_oSQL:_sQuery += " - CASE WHEN DFRAPEL > 0 THEN DFRAPEL ELSE RAPELPREV END"
		_oSQL:_sQuery += " - CASE WHEN VALORFRETE > 0 THEN (VALORFRETE + FRETEREENT + FRETEREDSP + FRETEPALET) ELSE FRETEPREV END"
		_oSQL:_sQuery += " - DFENCART - DFFEIRAS - DFFRETES - DFDESCONT - DFDEVOL - DFCAMPANH - DFABLOJA - DFCONTRAT - DFOUTROS"
		_oSQL:_sQuery += " - (TOTAL * COMIS1 / 100))"

		_oSQL:_sQuery += " 		FROM VA_VFAT WHERE EMISSAO BETWEEN '"+ _dDtIni +"' AND '"+ _dDtFim +"'"
		//
		_oSQL:Log ()
		_oSQL:Exec ()
	EndIf

	If _nTipo != 1
		u_help("Processo finalizado com sucesso")
	EndIf
Return
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	
	//                     PERGUNT         TIPO TAM DEC VALID F3     Opcoes             Help
	aadd (_aRegsPerg, {01, "Data inicial ", "D", 08, 0,  "",   "   ", {},                ""})
	aadd (_aRegsPerg, {02, "Data final   ", "D", 08, 0,  "",   "   ", {},                ""})

	 U_ValPerg (cPerg, _aRegsPerg)
Return
