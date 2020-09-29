#include "rwmake.ch"
#include "colors.ch"
#include "sigawin.ch"
#include "set.ch"
#include "ap5mail.ch" 
#include "topconn.ch"
#Include "PROTHEUS.CH"

// Programa:  MT120GOk
// Autor:     Robert Koch
// Data:      30/05/20102
// Descricao: P.E. apos gravacao / exclusao de pedido de compra / autorizacao de entrega.
//            Criado inicialmente para disparar envio de e-mail ao fornecedor.
//
// Historico de alteracoes:
// 06/06/2012 - Robert  - Chamava envio de pedido por e-mail somente na inclusao.
//                      - Atualizacao do SCR passada do P.E. MT120GOk para este.
// 13/07/2012 - Robert  - Exclusao de dados adicionais apos exclusao do pedido/aut.entrega.
// 09/08/2013 - Leandro - Opção para selecionar se quer enviar HTML ou PDF
// 15/05/2015 - Robert  - Removida chamada de envio em formato HTML.
// 02/09/2019 - Andre   - Alterado UPDATE para gravar os novos campos da tabela SCR (CR_TIPOPRO, CR_CC).
// 06/03/2020 - Claudia - Criação de campo com nome de comprador e disponibilizado no browser. GLPI 7596
//
// --------------------------------------------------------------------------
user function MT120GOk ()  
	//local _sAutEnt  := ParamIXB [1]
	local _lInclui  := ParamIXB [2]
	local _lAltera  := ParamIXB [3]
	local _lDeleta  := ParamIXB [4]
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	local _nOpcao   := 0
    //Static oDlg
	//Static oButton1
	//Static oButton2
	//Static oSay1
	
	u_logini()
	
	if (_lInclui .or. _lAltera) //.and. msgyesno ("Deseja enviar este pedido / aut.entrega por e-mail para o fornecedor?")
		_nOpcao = aviso ("Envio do pedido para o fornecedor", ;
		                 "Selecione o formato para envio do pedido para o fornecedor", ;// {"HTML", "PDF", "Nao enviar"}, ;
		                 {"PDF", "Nao enviar"}, ;
		                 3, ;
		                 "Envio do pedido por e-mail")
		//if _nOpcao == 1
		//	u_wfpcomp (_sAutEnt)
		if _nOpcao == 1 //2
			u_pedvend ()
		endif
		
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
		_oSQL:_sQuery +=   " SET C7_COMNOM = '" + UsrFullName(sc7 -> c7_user) +"'"
		_oSQL:_sQuery += " WHERE C7_FILIAL = '" +  cFilAnt + "'"
		_oSQL:_sQuery += " AND C7_NUM = '"+ sc7 -> c7_num +"'" 
		_oSQL:_sQuery += " AND C7_FORNECE = '"+ sc7 -> c7_fornece +"'" 
		_oSQL:_sQuery += " AND C7_EMISSAO = '"+ DTOS(sc7 -> c7_emissao) +"'" 
		_oSQL:Exec ()
		
	endif

	// Grava dados adicionais nos documentos com alcada.
	_AtuSCR ()

	// Exclui dados adicionais, se houver.
	if _lDeleta
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "UPDATE VA_TEXTOS"
		_oSQL:_sQuery +=   " SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE CHAVE = 'SC7" + cEmpAnt + cFilAnt + sc7 -> c7_num + "'"
		_oSQL:Exec ()
	endif

	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
	u_logfim()
return
//
// Grava dados adicionais nos documentos com alcada.
// --------------------------------------------------------------------------
static function _AtuSCR ()
	local _oSQL := NIL
	local _sObs := left (sc7 -> c7_obs, tamsx3 ("CR_OBS")[1])  // Limita ao tamanho do campo, senao o SQL reclama.
	
	// Remove caracteres que podem atrapalhar.
	_sObs = strtran (_sObs, "'", "")
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT COUNT (*) FROM " + RetSQLName ("SCR")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND CR_FILIAL = '" + sc7 -> c7_filial + "'"
	_oSQL:_sQuery +=    " AND CR_TIPO = 'PC'"
	_oSQL:_sQuery +=    " AND SUBSTRING (CR_NUM, 1, 6) = '" + sc7 -> c7_num + "'"
	u_log(_oSQL:RetQry())
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSQLName ("SCR")
	_oSQL:_sQuery +=    " SET CR_OBS = '" + _sObs + "'"   // Limita ao tamanho do campo, senao o SQL reclama.
	_oSQL:_sQuery +=    ", CR_CC = '" + sc7 -> c7_cc + "'"
	_oSQL:_sQuery +=    ", CR_TIPOPRO = '" + fbuscacpo('SB1',1,xfilial('SB1') + SC7 -> C7_PRODUTO,'B1_TIPO') + "'"
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND CR_FILIAL = '" + sc7 -> c7_filial + "'"
	_oSQL:_sQuery +=    " AND CR_TIPO = 'PC'"
	_oSQL:_sQuery +=    " AND SUBSTRING (CR_NUM, 1, 6) = '" + sc7 -> c7_num + "'"
	_oSQL:Exec ()
	u_log(_oSQL:_sQuery)
	u_log(sc7 -> c7_num)
	u_log(sc7 -> c7_cc)
	u_log(sc7 -> C7_PRODUTO)
return
