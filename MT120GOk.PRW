// Programa.: MT120GOk
// Autor....: Robert Koch
// Data.....: 30/05/2012
// Descricao: P.E. apos gravacao / exclusao de pedido de compra / autorizacao de entrega.
//            Criado inicialmente para disparar envio de e-mail ao fornecedor.
//   
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. apos gravacao / exclusao de pedido de compra / autorizacao de entrega
// #PalavasChave      #pedido_de_compra #autorizacao_de_entrega
// #TabelasPrincipais #SC7 
// #Modulos 		  #COM         
//
// Historico de alteracoes:
// 06/06/2012 - Robert  - Chamava envio de pedido por e-mail somente na inclusao.
//                      - Atualizacao do SCR passada do P.E. MT120GOk para este.
// 13/07/2012 - Robert  - Exclusao de dados adicionais apos exclusao do pedido/aut.entrega.
// 09/08/2013 - Leandro - Opção para selecionar se quer enviar HTML ou PDF
// 15/05/2015 - Robert  - Removida chamada de envio em formato HTML.
// 02/09/2019 - Andre   - Alterado UPDATE para gravar os novos campos da tabela SCR (CR_TIPOPRO, CR_CC).
// 06/03/2020 - Claudia - Criação de campo com nome de comprador e disponibilizado no browser. GLPI 7596
// 15/01/2021 - Claudia - Incluido bloco de descrições do programa no cabeçalho.
// 04/05/2021 - Claudia - Incluida a gravação do solicitante no pedido. GLPI: 9814
// 20/02/2023 - Claudia - Retirada a ligação de  item na consulta. GLPI: 11691
// 17/03/2023 - Claudia - Gravação do nome do fornecedor. GLPI: 13308
// 12/03/2024 - Robert - Chamadas de metodos de ClsSQL() nao recebiam parametros.
//

// -------------------------------------------------------------------------------------------------------
#include "rwmake.ch"
#include "colors.ch"
#include "sigawin.ch"
#include "set.ch"
#include "ap5mail.ch" 
#include "topconn.ch"
#Include "PROTHEUS.CH"

user function MT120GOk ()  
	//local _sAutEnt  := ParamIXB [1]
	local _lInclui  := ParamIXB [2]
	local _lAltera  := ParamIXB [3]
	local _lDeleta  := ParamIXB [4]
	local _aAreaAnt := U_ML_SRArea ()
	local _aAmbAnt  := U_SalvaAmb ()
	local _oSQL     := NIL
	local _nOpcao   := 0
	
	if (_lInclui .or. _lAltera) //.and. msgyesno ("Deseja enviar este pedido / aut.entrega por e-mail para o fornecedor?")
		_nOpcao = aviso ("Envio do pedido para o fornecedor", ;
		                 "Selecione o formato para envio do pedido para o fornecedor", ;// {"HTML", "PDF", "Nao enviar"}, ;
		                 {"PDF", "Nao enviar"}, ;
		                 3, ;
		                 "Envio do pedido por e-mail")
						 
		if _nOpcao == 1 //2
			u_pedvend ()
		endif

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""		
		_oSQL:_sQuery += " SELECT DISTINCT "
		_oSQL:_sQuery += " 		SC1.C1_SOLICIT "
		_oSQL:_sQuery += " FROM " + RetSqlName("SC7") + " SC7 "
		_oSQL:_sQuery += " INNER JOIN " + RetSqlName("SC1") + " SC1 "
		_oSQL:_sQuery += " 	 ON SC1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " 		AND SC1.C1_FILIAL = SC7.C7_FILIAL "
		_oSQL:_sQuery += " 		AND SC1.C1_PEDIDO = SC7.C7_NUM "
		_oSQL:_sQuery += " WHERE SC7.D_E_L_E_T_ = '' "
		_oSQL:_sQuery += " AND SC7.C7_FILIAL    = '" + cFilAnt           		+ "'"
		_oSQL:_sQuery += " AND SC7.C7_NUM       = '" + sc7 -> c7_num     		+ "'"
		_oSQL:_sQuery += " AND SC7.C7_FORNECE   = '" + sc7 -> c7_fornece 		+ "'" 
		_oSQL:_sQuery += " AND SC7.C7_EMISSAO   = '" + DTOS(sc7 -> c7_emissao)  + "'" 
		_aSolic := aclone (_oSQL:Qry2Array (.f., .f.))

		if len(_aSolic) > 0
			_sSolicitante := _aSolic[1,1]
		else
			_sSolicitante := "-"
		endif

		// Regrava o nome do fornecedor no campo C7_VAFNOME, devido a cópia do pedido sem ativação de gatilhos
		_sNomeFor := Posicione("SA2",1,xfilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA,"A2_NOME") 

		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
		_oSQL:_sQuery += " 		SET C7_COMNOM  = '" + UsrFullName(sc7 -> c7_user) +"'"
		_oSQL:_sQuery += "         ,C7_SOLICIT = '" + _sSolicitante               +"'"
		_oSQL:_sQuery += "         ,C7_VAFNOME = '" + _sNomeFor                   +"'"
		_oSQL:_sQuery += " WHERE C7_FILIAL = '" +  cFilAnt + "'"
		_oSQL:_sQuery += " AND C7_NUM      = '"+ sc7 -> c7_num +"'" 
		_oSQL:_sQuery += " AND C7_FORNECE  = '"+ sc7 -> c7_fornece +"'" 
		_oSQL:_sQuery += " AND C7_EMISSAO  = '"+ DTOS(sc7 -> c7_emissao) +"'" 
		_oSQL:Exec ()
		
	endif

	// Grava dados adicionais nos documentos com alcada.
	_AtuSCR ()

	// Exclui dados adicionais, se houver.
	if _lDeleta
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " UPDATE VA_TEXTOS"
		_oSQL:_sQuery += " SET D_E_L_E_T_ = '*'"
		_oSQL:_sQuery += " WHERE CHAVE = 'SC7" + cEmpAnt + cFilAnt + sc7 -> c7_num + "'"
		_oSQL:Exec ()
	endif


	U_ML_SRArea (_aAreaAnt)
	U_SalvaAmb (_aAmbAnt)
return
//
// --------------------------------------------------------------------------
// Grava dados adicionais nos documentos com alcada.
static function _AtuSCR ()
	local _oSQL := NIL
	local _sObs := left (sc7 -> c7_obs, tamsx3 ("CR_OBS")[1])  // Limita ao tamanho do campo, senao o SQL reclama.
	
	// Remove caracteres que podem atrapalhar.
	_sObs = strtran (_sObs, "'", "")
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT COUNT (*) "
	_oSQL:_sQuery += "		FROM " + RetSQLName ("SCR")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CR_FILIAL = '" + sc7 -> c7_filial + "'"
	_oSQL:_sQuery += " AND CR_TIPO = 'PC'"
	_oSQL:_sQuery += " AND SUBSTRING (CR_NUM, 1, 6) = '" + sc7 -> c7_num + "'"
	u_log(_oSQL:RetQry (1, .f.))
	
	_oSQL := ClsSQL():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " UPDATE " + RetSQLName ("SCR")
	_oSQL:_sQuery += " SET CR_OBS = '" + _sObs + "'"   // Limita ao tamanho do campo, senao o SQL reclama.
	_oSQL:_sQuery += ", CR_CC = '" + sc7 -> c7_cc + "'"
	_oSQL:_sQuery += ", CR_TIPOPRO = '" + fbuscacpo('SB1',1,xfilial('SB1') + SC7 -> C7_PRODUTO,'B1_TIPO') + "'"
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND CR_FILIAL = '" + sc7 -> c7_filial + "'"
	_oSQL:_sQuery += " AND CR_TIPO = 'PC'"
	_oSQL:_sQuery += " AND SUBSTRING (CR_NUM, 1, 6) = '" + sc7 -> c7_num + "'"
	_oSQL:Exec ()
	u_log(_oSQL:_sQuery)
	u_log(sc7 -> c7_num)
	u_log(sc7 -> c7_cc)
	u_log(sc7 -> C7_PRODUTO)

// to com duvida se o campo eh no SC7 ou SCR. Robert --->	U_Log2 ('debug', '[' + procname () + ']Ped.' + sc7 -> c7_num + '/' + sc7 -> c7_item + ' estah com CR_TIPOPRO = ' + )

return
