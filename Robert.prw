// Programa:  U_Robert
// Autor:     Robert Koch
// Descricao: Ajustes e testes diversos

//http://www.universoadvpl.com/2015/03/21-advpl-i-x31updtable-sincronizar-base/

// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Processamento
// #Descricao         #Rotinas diversas de testes, ajustes e automacoes.
// #PalavasChave      #auxiliar #uso_generico
// #TabelasPrincipais 
// #Modulos           #todos_modulos

#include "protheus.ch"
//#include "rwmake.ch"
#include "VA_INCLU.prw"
#include "tbiconn.ch"
//#INCLUDE "XMLXFUN.CH"

// --------------------------------------------------------------------------
user function robert ()
	if type ('__cUserId') == 'U' .or. type ('cUserName') == 'U'
		prepare environment empresa '01' filial '01' modulo '05'
		private cModulo   := 'FAT'
		private __cUserId := "000210"
		private cUserName := "robert.koch"
		private __RelDir  := "c:\temp\spool_protheus\"
		set century on
	endif
	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR'
		msgalert ('Nao te conheco, nao gosto de ti e nao vou te deixar continuar. Vai pra casa.', procname ())
		return
	endif
	private _sArqLog := procname () + "_" + alltrim (cUserName) + cEmpAnt + ".log"
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + '_' + ALLTRIM (upper (GetEnvServer())) + ".log"
	delete file ('\logs\' + _sArqLog)
	//u_logId ()
	if ! empty (GetSrvProfString ("IXBLOG", ""))
		u_help ("Parametro IXBLOG ativo no appserver.ini")
	else
		if U_Semaforo (procname ()) == 0
			u_help ('Bloqueio de semaforo na funcao ' + procname (),, .t.)
		else
			PtInternal (1, 'U_Robert')
			U_UsoRot ('I', procname (), '')
			processa ({|| _AndaLogo ()})
			u_log2 ('info', 'Processo finalizado')
			U_UsoRot ('F', procname (), '')
		endif
	endif
return



// --------------------------------------------------------------------------
static function _AndaLogo ()
//	local _sQuery    := ""
//	local _sAliasQ   := ""
//	local _oEvento   := NIL
//	local _aArqTrb   := {}
//	local _aRetSQL   := {}
//	local _nRetSQL   := 0
//	local _sCRLF     := chr (13) + chr (10)
//	local _oSQL      := NIL
//	local _lContinua := .T.
//	local _aDados    := {}
//	local _nDado     := 0
//	local _nCarga    := 0
//	local _i         := 0
//	local _sError    := ''
//	local _sWarning  := ''
//	local _oCtaCorr  := NIL
//	local _nParc     := 0
//	local _oAssoc    := NIL
//	local _aAssoc := {}
//	local _nAssoc := 0
	PRIVATE _oBatch  := ClsBatch():New ()  // Deixar definido para quando testar rotinas em batch.
	procregua (100)
	incproc ()

//	u_help ('Nada definido.')
//	u_log2 ('info', 'Batch: [retorno:' + _oBatch:Retorno + '] [Mensagens:' + _oBatch:Mensagens + ']')

	//za1 -> (dbsetorder (1))
	//if za1 -> (dbseek ('01'+'2000341473', .f.))
;;coment do branch teste	U_EnvEtFul ('2000345213', .t.)
segunto teste
return

//	_sArqLog := 'U_BatMetaF_' + alltrim (cusername) + '_' + dtos (date ()) + ".log"
//	u_batmetaf ()
//return

//	_sArqLog := 'U_BatMercP_' + alltrim (cusername) + '_' + dtos (date ()) + ".log"
//	u_batmercp ()
//RETURN

/*
	// Compara relatorios associados
	_aAssoc = {}
//	aadd (_aAssoc, '003577')  // bastante movimento
//	aadd (_aAssoc, '005128')  // apenas 1 entrada e 1 compra
	//aadd (_aAssoc, '001369')  // so 14 complementos
	//aadd (_aAssoc, '004826')  // 9+6+0
//	aadd (_aAssoc, '003241')  // 16+15+2 Idalino Pan - tem complemento
	//aadd (_aAssoc, '000643')  // UM ASSOCIADO QUE TEVE REPARCELAMENTO em 2020
	//aadd (_aAssoc, '012791')  // lUIS eSCOSTEGUY (nao associado de Livramento)
//	aadd (_aAssoc, '002380')  // Elmar Busetti
//	aadd (_aAssoc, '002859')  // Celso Chiarani
//	aadd (_aAssoc, '000184')  // Arside Piton - apenas uva isabel; UNIMED em aberto
//	aadd (_aAssoc, '000289')  // Rui Bertuol - UNIMED em aberto.
//	aadd (_aAssoc, '003024')  // Vilson Da Campo - NF de compra devolvida em 2020.
	aadd (_aAssoc, '002660')  // Cledinei Da Campo - NF trocada com Vilson em 2020.
	for _nAssoc = 1 to len (_aAssoc)
		U_GravaSX1 ("ML_FECHASAFRA", '01', '2020')  // safra
		U_GravaSX1 ("ML_FECHASAFRA", '02', _aAssoc [_nAssoc])
		U_GravaSX1 ("ML_FECHASAFRA", '03', '01')  // loja
		U_GravaSX1 ("ML_FECHASAFRA", '04', '  ')  // nucleo
		U_GravaSX1 ("ML_FECHASAFRA", '05', 1)  // lista saldo CC 1=sim;2=nao
		U_GravaSX1 ("ML_FECHASAFRA", '06', 1)  // 1=detalhado;2=resumido
	//	U_ml_fechasafra (.T.)
		//U_GravaSX1 ("SZI_REL2", "01", _aAssoc [_nAssoc])
		//U_GravaSX1 ('SZI_REL2', "02", '')
		//U_GravaSX1 ("SZI_REL2", "03", _aAssoc [_nAssoc])
		//U_GravaSX1 ('SZI_REL2', "04", 'zz')
		//U_GravaSX1 ('SZI_REL2', "05", stod ("19000101"))
		//U_GravaSX1 ('SZI_REL2', "06", stod ("20201231"))
		//U_GravaSX1 ('SZI_REL2', "07", 1)  // tipo normal/capital
		//U_GravaSX1 ('SZI_REL2', "08", 2)  //listar OBS S/N
		//U_szi_rel2 (.t.)
		//U_GravaSX1 ('SZI_REL', "01", _aAssoc [_nAssoc])
		//U_GravaSX1 ('SZI_REL', "02", '')
		//U_GravaSX1 ('SZI_REL', "03", _aAssoc [_nAssoc])
		//U_GravaSX1 ('SZI_REL', "04", 'zz')
		//U_GravaSX1 ('SZI_REL', "05", '')
		//U_GravaSX1 ('SZI_REL', "06", 'zz')
		//U_GravaSX1 ('SZI_REL', "07", stod ("19000101"))
		//U_GravaSX1 ('SZI_REL', "08", stod ("20201231"))
		//U_GravaSX1 ('SZI_REL', "09", 1)
		//U_GravaSX1 ('SZI_REL', "10", '')
		//U_GravaSX1 ('SZI_REL', "11", 2)
		//U_GravaSX1 ('SZI_REL', "12", 1)
		//U_GravaSX1 ('SZI_REL', "13", '')
		//U_GravaSX1 ('SZI_REL', "14", 'zz')
		//U_GravaSX1 ('SZI_REL', "15", 2)
		//U_szi_rel (.t., 1)
		u_gravasx1 ('SZI_LCS', '01', _aAssoc [_nAssoc])  // Associado inicial
		u_gravasx1 ('SZI_LCS', '02', '')  // Loja associado inicial
		u_gravasx1 ('SZI_LCS', '03', _aAssoc [_nAssoc])  // Associado final
		u_gravasx1 ('SZI_LCS', '04', 'z')  // Loja associado final          
		u_gravasx1 ('SZI_LCS', '05', '')  // Tipo de movimento inicial     
		u_gravasx1 ('SZI_LCS', '06', 'z')  // Tipo de movimento final       
		u_gravasx1 ('SZI_LCS', '07', date ())  // Posicao em                    
		u_gravasx1 ('SZI_LCS', '08', '')  // Coop.orig(AL/SV/...) bco=todas
		u_gravasx1 ('SZI_LCS', '09', '')  // Filial inicial                
		u_gravasx1 ('SZI_LCS', '10', 'z')  // Filial final                  
		u_gravasx1 ('SZI_LCS', '11', '')  // Forma pagamento (bco=todas)
		u_gravasx1 ('SZI_LCS', '12', 3)   // Movtos a: debito /credito /Todos
		u_gravasx1 ('SZI_LCS', '13', '')  // T.M. desconsiderar (separ. /)
		u_gravasx1 ('SZI_LCS', '14', '')  // Parcelas (separ. /) bco=todas
		u_gravasx1 ('SZI_LCS', '15', 2)  // Gerar recibos apos o relatorio: Sim/Nao
		u_gravasx1 ('SZI_LCS', '16', '')  // P/recibo: Correspondente a... 
		u_gravasx1 ('SZI_LCS', '17', '')  // P/recibo: Local               
		u_gravasx1 ('SZI_LCS', '18', date ())  // P/recibo: Data                
		u_gravasx1 ('SZI_LCS', '19', '')  // Nucleos(SG/FC/...) bco=todos
		u_szi_lcs (.t., 2)
	next
return
*/
/*
	// Importa TES inteligente (executar apenas 1 vez) - GLPI 8727
	_aDados = U_LeCSV ('\sfm_import.csv', ';')
	u_log (len(_aDados))
	for _nDado = 1 to len (_aDados)
		reclock ("SFM", .T.)
		sfm -> fm_filial  = xfilial ("SFM")
		sfm -> fm_tipo    = _aDados [_nDado, 1]
		sfm -> fm_grprod  = _aDados [_nDado, 2]
		sfm -> fm_est     = _aDados [_nDado, 3]
		sfm -> fm_tipocli = _aDados [_nDado, 4]
		sfm -> fm_ts      = _aDados [_nDado, 5]
		msunlock ()
		u_log (_nDado)
	next
return
*/
/* Este trecho funciona bem
	U_GravaSX1 ('SZI_REL2', '01', '000004')
	pergunte ('SZI_REL2', .T.)
	U_GravaSX1 ('SZI_REL', '01', '000004')
	pergunte ('SZI_REL', .T.)
	U_GravaSX1 ('SZI_RCB', '01', '000004')
	pergunte ('SZI_RCB', .T.)
*/
/*
// --------------------------------------------------------------------------
// Cria Perguntas no SX1
Static Function _ValidPerg ()
	local _aRegsPerg := {}
	local _aDefaults := {}
	
	//                     PERGUNT                           TIPO TAM DEC VALID F3        Opcoes                               Help
	aadd (_aRegsPerg, {01, "TESTE ROBERT", "C", 6,  0,  "",   "SA2_AS", {},                                  ""})

	U_ValPerg (cPerg, _aRegsPerg, {}, _aDefaults)
return
*/
/*
	_sArqLog := 'U_BatRevCH_' + alltrim (cusername) + '_' + dtos (date ()) + ".log"
	U_BatRevCh ("AC", "CTE", 90)
	U_BatRevCh ("AC", "NFE", 90)
	U_BatRevCh ("AL", "CTE", 90)
	U_BatRevCh ("AL", "NFE", 90)
	U_BatRevCh ("AM", "CTE", 90)
	U_BatRevCh ("AM", "NFE", 90)
	U_BatRevCh ("AP", "CTE", 90)
	U_BatRevCh ("AP", "NFE", 90)
	U_BatRevCh ("BA", "CTE", 90)
	U_BatRevCh ("BA", "NFE", 90)
	U_BatRevCh ("CE", "CTE", 90)
	U_BatRevCh ("CE", "NFE", 90)
	U_BatRevCh ("DF", "CTE", 90)
	U_BatRevCh ("DF", "NFE", 90)
	U_BatRevCh ("ES", "CTE", 90)
	U_BatRevCh ("ES", "NFE", 90)
	U_BatRevCh ("GO", "CTE", 90)
	U_BatRevCh ("GO", "NFE", 90)
	U_BatRevCh ("MA", "CTE", 90)
	U_BatRevCh ("MA", "NFE", 90)
	U_BatRevCh ("MG", "CTE", 90)
	U_BatRevCh ("MG", "NFE", 90)
	U_BatRevCh ("MS", "CTE", 90)
	U_BatRevCh ("MS", "NFE", 90)
	U_BatRevCh ("MT", "CTE", 90)
	U_BatRevCh ("MT", "NFE", 90)
	U_BatRevCh ("PA", "CTE", 90)
	U_BatRevCh ("PA", "NFE", 90)
	U_BatRevCh ("PB", "CTE", 90)
	U_BatRevCh ("PB", "NFE", 90)
	U_BatRevCh ("PE", "CTE", 90)
	U_BatRevCh ("PE", "NFE", 90)
	U_BatRevCh ("PI", "CTE", 90)
	U_BatRevCh ("PI", "NFE", 90)
	U_BatRevCh ("PR", "CTE", 90)
	U_BatRevCh ("PR", "NFE", 90)
	U_BatRevCh ("RJ", "CTE", 90)
	U_BatRevCh ("RJ", "NFE", 90)
	U_BatRevCh ("RN", "CTE", 90)
	U_BatRevCh ("RN", "NFE", 90)
	U_BatRevCh ("RO", "CTE", 90)
	U_BatRevCh ("RO", "NFE", 90)
	U_BatRevCh ("RR", "CTE", 90)
	U_BatRevCh ("RR", "NFE", 90)
	U_BatRevCh ("RS", "CTE", 90)
	U_BatRevCh ("RS", "NFE", 90)
	U_BatRevCh ("SC", "CTE", 90)
	U_BatRevCh ("SC", "NFE", 90)
	U_BatRevCh ("SE", "CTE", 90)
	U_BatRevCh ("SE", "NFE", 90)
	U_BatRevCh ("SP", "CTE", 90)
	U_BatRevCh ("SP", "NFE", 90)
	U_BatRevCh ("TO", "CTE", 90)
	U_BatRevCh ("TO", "NFE", 90)
RETURN
*/
/*
	// Gera precos para as pre-notas de compra de safra.
	Private cPerg   := "VAZZ9P"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'Z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // produto ini
	U_GravaSX1 (cPerg, '07', 'z')    // fim
	U_GravaSX1 (cPerg, '08', 2)      // tipos uvas {"Comuns","Finas","Todas"}
	U_GravaSX1 (cPerg, '09', 2)      // regrava com NF ja gerada {"Sim", "Nao"}
	U_GravaSX1 (cPerg, '10', 1)      // regrava com obs {"Regrava","Nao altera"}
	U_GravaSX1 (cPerg, '11', '03')   // Filial inicial
	U_GravaSX1 (cPerg, '12', '03')   // Filial final
	U_GravaSX1 (cPerg, '13', 'Z')    // parcela ini
	U_GravaSX1 (cPerg, '14', 'Z')    // parcela final
	U_GravaSX1 (cPerg, '15', 1)      // regrava se ja tiver preco {"Sim", "Nao"}
	U_VA_ZZ9P (.t.)
return
*/
/*
	// Simulacoes precos para 2021
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '012373')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', '012373')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '03')     // Filial inicial
	U_GravaSX1 (cPerg, '10', '03')   // Filial final
	U_GravaSX1 (cPerg, '11', 'Z')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '') // Apenas estas variedades (bordo, bordo de bordadura/em conversao/organico)
	U_GravaSX1 (cPerg, '15', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'Z')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
RETURN
*/
/*
	U_HELP ('VOU GRAVAR')
	_oEvento := ClsEvent ():New ()
	_oEvento:Texto   = "Teste inclusao evento" + CHR (13) + CHR(10)+"para ver como grava campo memo"
	_oEvento:CodEven = "000001"
	_oEvento:Grava ()
return
*/
/*
	// Ajusta profiles apos migracao dos SX para o banco de dados
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT ID_USR, NOME FROM VA_USR_USUARIOS"
	_oSQL:_sQuery += " WHERE BLOQUEADO = 'N'"
	_oSQL:_sQuery +=   " AND NOME LIKE '%.%'"
	_oSQL:_sQuery +=   " AND NOME NOT LIKE 'RET_%'"
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT * FROM MP_SYSTEM_PROFILE WHERE P_NAME = ID_USR + '_OLD')"
	_oSQL:_sQuery += " ORDER BY ID_USR"
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array ()
	for _nDado = 1 to len (_aDados)
		_sUsr = _aDados [_nDado, 1]
		_sNomeUsr = '01' + upper (left (_aDados [_nDado, 2], 13))
		u_log2 ('info', _sUsr + ' ' + _sNomeUsr)
		begin transaction
		_oSQL:_sQuery := "UPDATE MP_SYSTEM_PROFILE SET P_NAME = '" + _sUsr + "_OLD'
		_oSQL:_sQuery += " WHERE upper (P_NAME)   = '" + _sUsr + "'"
		_oSQL:_sQuery +=   " AND P_EMPANT = ''"
		_oSQL:_sQuery +=   " AND MP_SYSTEM_PROFILE.P_TASK IN ('PERGUNTE')"
		_oSQL:Log ()
		_oSQL:Exec ()
		_oSQL:_sQuery := "UPDATE MP_SYSTEM_PROFILE SET P_NAME = '" + _sUsr + "', P_EMPANT = '01'"
		_oSQL:_sQuery += " WHERE upper (P_NAME) = '" + _sNomeUsr + "'"
		_oSQL:_sQuery +=   " AND MP_SYSTEM_PROFILE.P_TASK IN ('PERGUNTE')"
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT * FROM MP_SYSTEM_PROFILE NOVO"
		_oSQL:_sQuery +=                    " WHERE NOVO.P_NAME = '" + _sUsr + "'"
		_oSQL:_sQuery +=                      " AND NOVO.P_PROG = MP_SYSTEM_PROFILE.P_PROG"
		_oSQL:_sQuery +=                      " AND NOVO.P_TASK = MP_SYSTEM_PROFILE.P_TASK"
		_oSQL:_sQuery +=                      " AND NOVO.P_TYPE = MP_SYSTEM_PROFILE.P_TYPE"
		_oSQL:_sQuery +=                      " AND NOVO.P_EMPANT = '01'"
		_oSQL:_sQuery +=                      " AND NOVO.P_FILANT = MP_SYSTEM_PROFILE.P_FILANT)"
		_oSQL:Log ()
		_oSQL:Exec ()
		end transaction
		//exit
	next
RETURN
*/
/*
// Envia atualizacoes diversas para o Mercanet
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//   	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SB1")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND B1_FILIAL = '" + xfilial ("SB1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND B1_COD IN ('0345', '0215')"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	For _nLinha := 1 To Len(_aDados)
//		sb1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_AtuMerc ("SB1", sb1 -> (recno ()))
//	next
//
//	da0 -> (dbgotop ())
//	do while ! da0 -> (eof ())
//		if alltrim (da0 -> da0_codtab) $ '722'
//			U_AtuMerc ("DA0", da0 -> (recno ()))
//		endif
//		da0 -> (dbskip ())
//	enddo
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SA3")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND A3_FILIAL = '" + xfilial ("SA3") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND A3_COD BETWEEN '291' and '298'"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	For _nLinha := 1 To Len(_aDados)
//		sa3 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_LOG (SA3 -> A3_COD)
//		U_AtuMerc ("SA3", sa3 -> (recno ()))
//	next
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SF1")
//	_oSQL:_sQuery += " WHERE F1_FILIAL = '" + xfilial ("SF1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND F1_EMISSAO >= '20150101'"  // DATA INICIA EXPORT P/ MERCANET
//	_oSQL:_sQuery += " AND (F1_DOC like '%28305%')"
//	_oSQL:_sQuery += " AND F1_SERIE = '1  '"
//	//_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_NOTA_FISCAL WHERE DB_NOTA_NRO = CAST (F2_DOC AS INT))"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	For _nLinha := 1 To Len(_aDados)
//		sf1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_AtuMerc ("SF1", sf1 -> (recno ()))
//	next
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SF2")
//	_oSQL:_sQuery += " WHERE F2_FILIAL = '" + xfilial ("SF2") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND F2_EMISSAO >= '20150101'"  // DATA INICIA EXPORT P/ MERCANET
////	_oSQL:_sQuery += " AND (F2_DOC like '%28305%' or F2_DOC like '%139308%' or F2_DOC like '%139289%')"
//	_oSQL:_sQuery += " AND (F2_DOC like '%139289%')"
//	//_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM LKSRV_MERCANETPRD.MercanetPRD.dbo.DB_NOTA_FISCAL WHERE DB_NOTA_NRO = CAST (F2_DOC AS INT))"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	For _nLinha := 1 To Len(_aDados)
//		sf2 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_AtuMerc ("SF2", sf2 -> (recno ()))
//	next
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND A1_FILIAL = '" + xfilial ("SA1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND EXISTS (SELECT *"
//	_oSQL:_sQuery += "			   FROM " + RetSQLName ("SZN")	
//	_oSQL:_sQuery += "			   WHERE SZN.ZN_CODEVEN = 'ALT001'"
//	_oSQL:_sQuery += "			   AND SZN.ZN_ALIAS = 'SA1'"
//	_oSQL:_sQuery += "			   AND SZN.ZN_DATA >= '20190801'"
//	_oSQL:_sQuery += "			   AND SZN.ZN_USUARIO IN ('ADMINISTRADOR', 'robert.koch')"
//	_oSQL:_sQuery += "			   AND SZN.ZN_PILHA LIKE '%BATLIMCR%'"
//	_oSQL:_sQuery += "			   AND SZN.ZN_CLIENTE = SA1.A1_COD"
//	_oSQL:_sQuery += "			   AND SZN.ZN_LOJACLI = SA1.A1_LOJA)
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	For _nLinha := 1 To Len(_aDados)
//		sa1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_LOG (SA1 -> A1_COD)
//		U_AtuMerc ("SA1", sa1 -> (recno ()))
//	next
//
//	se4 -> (dbgotop ())
//	do while ! se4 -> (eof ())
//		U_AtuMerc ("SE4", se4 -> (recno ()))
//		se4 -> (dbskip ())
//	enddo
return
*/
/*
	// Testes verificacoes genericas.
	// _oVerif := ClsVerif():New (25)
	// _oVerif:SetParam ('01', '2017')
	// _oVerif:SetParam ('02', '')
	// _oVerif:SetParam ('03', 'zz')
	// _oVerif:SetParam ('04', '30 ')
	// _oVerif:SetParam ('05', '028')
	// _oVerif:SetParam ('06', '077')
	// _oVerif:SetParam ('07', '000017')
	// _oVerif := ClsVerif():New (24)
	// _oVerif:SetParam ('01', '09189201001  ')
	// _oVerif:SetParam ('02', '09189201001  ')
	// _oVerif:SetParam ('03', '')
	// _oVerif:SetParam ('04', 'z')
	_oVerif := ClsVerif():New (34)
	if _oVerif:Executa ()
		u_log2 ('debug', 'Pendencias do tipo ' + _oVerif:Descricao)
		u_log2 ('debug', _oVerif:Result)
	else
		u_log2 ('erro', 'Erro na verificacao: ' + _oVerif:UltMsg)
	endif
return
*/
/*
	cPerg := "VA_RTSAF"
	U_GravaSX1 (cPerg, "01", stod ('20200131'))
	U_GravaSX1 (cPerg, "02", 1)
	if cFilAnt == '01' ; U_GravaSX1 (cPerg, "03", 1314513.17) ; endif // provisao compra safra
	if cFilAnt == '03' ; U_GravaSX1 (cPerg, "03",  417707.26) ; endif // provisao compra safra
	if cFilAnt == '07' ; U_GravaSX1 (cPerg, "03", 1260996.28) ; endif // provisao compra safra
	if cFilAnt == '09' ; U_GravaSX1 (cPerg, "03",   45004.61) ; endif // provisao compra safra
	_sArqLog := 'VA_RTSAF_' + alltrim (cusername) + '_' + dtos (date ()) + ".log"
	U_VA_RTSAF (.t.)
RETURN
*/
/* Aguarda atualizacao de build
	// Linguagem TL++: https://tdn.totvs.com/pages/viewpage.action?pageId=334340072
	// local varJson := { "teste" : { "var1" : "oioi", "var2": "oioi2", "var3": "oioi3" }}  https://tdn.totvs.com/display/tec/Json
	_oUtil := ClsDUtil ():New ()
	u_log (_oUtil:SubtrMes ('202009', 2))
	u_log (_oUtil:SubtrMes ('202009', -2))
	//u_log (ClsDUtil ():SubtrMes ('202009', -2))
*/
/*
	cPerg := "ML_NFXCONH"
	U_GravaSX1 (cPerg, "01", stod ('20020128')) // Data Emissao/Recebimento
	U_GravaSX1 (cPerg, "02", stod ('20020225')) // Data Emissao/Recebimento
	U_GravaSX1 (cPerg, "03", '')  // Cliente de
	U_GravaSX1 (cPerg, "04", 'Z') // Cliente ate
	U_GravaSX1 (cPerg, "05", '')  //	Doc de Saida
	U_GravaSX1 (cPerg, "06", 'Z') // Doc de Saida
	U_GravaSX1 (cPerg, "07", '')  // Fornecedor de
	U_GravaSX1 (cPerg, "08", 'z') // Fornecedor até
	U_GravaSX1 (cPerg, "09", '')  // Doc de Entrada
	U_GravaSX1 (cPerg, "10", 'Z') // Doc de Entrada
	U_GravaSX1 (cPerg, "11", '')  // UF
	U_GravaSX1 (cPerg, "12", '000068736') // Conhecimento de
	U_GravaSX1 (cPerg, "13", '000070063') // Conhecimento ate
	U_GravaSX1 (cPerg, "14", 2) // Ordenar por
	U_GravaSX1 (cPerg, "15", 1) // Listar
	U_ML_NFXCONH (.t.)
RETURN
*/

//	_a := ALLGROUPS ()
//	for _n = 1 to len (_a)
//		u_log (_a [_n])
//		u_log (FWGrpParam (_a [_n, 1, 1]))
//	next

/*
	Private cPerg   := "VAXLS53"
	U_GravaSX1 (cPerg, '01', '2020')
	U_GravaSX1 (cPerg, '02', '2020')
	u_va_xls53 (.T.)
return
*/
/*
	// Testes metodos associados.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT ZI_ASSOC, ZI_LOJASSO"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
	_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC between '012351' and '012360'"
	_oSQL:_sQuery +=  " ORDER BY ZI_ASSOC, ZI_LOJASSO"
	_aDados = _oSQL:Qry2Array ()
	_sResult = ''
	for _nDado = 1 to len (_aDados)
		_oAssoc := ClsAssoc():New (_aDados [_nDado, 1], _aDados [_nDado, 2])
		_aSld1 := aclone (_oAssoc:SaldoEmOLD (stod ('20200331')))
		_aSld2 := aclone (_oAssoc:SaldoEm (stod ('20200331')))
		_sLinImp = _aDados [_nDado, 1] + _aDados [_nDado, 2] + ' ' + transform (_aSld1 [1], '@E 999,999,999.99') + ' ' + transform (_aSld2 [1], '@E 999,999,999.99') + ' ' + transform (_aSld1 [2], '@E 999,999,999.99') + ' ' + transform (_aSld2 [2], '@E 999,999,999.99');
		                                                           + transform (_aSld1 [3], '@E 999,999,999.99') + ' ' + transform (_aSld2 [3], '@E 999,999,999.99') + ' ' + transform (_aSld1 [4], '@E 999,999,999.99') + ' ' + transform (_aSld2 [4], '@E 999,999,999.99')
		u_log (_sLinImp)
		_sResult += _sLinImp + chr (13) + chr (10)
	//	if ! _oAssoc:CalcCM ('032020', 1.0, 1.0, 999.99, .T., .F.)
	//		u_help (_oAssoc:Codigo + "/" + _oAssoc:Loja + ' - ' + alltrim (_oAssoc:Nome) + _oAssoc:UltMsg,, .t.)
	//	endif
	next
	u_log (_sResult)
return
*/
/*
	// Cria registros na conta corrente para nota trocada entre associados (GLPI 8175)
	if cFilAnt != '07'
		u_help ("Filial errada",, .t.)
		return
	endif
	_sQuery := ""
	_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO, E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA,"
	_sQuery +=        " ROW_NUMBER () OVER (ORDER BY E2_PARCELA) AS NUM_PARC"
	_sQuery +=   " FROM " + RetSQLName ("SE2")
	_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_sQuery +=    " AND E2_TIPO    = 'NF'"
	_sQuery +=    " AND E2_FORNECE = '002660'"
	_sQuery +=    " AND E2_LOJA    = '01'"
	_sQuery +=    " AND E2_PREFIXO = '30 '"
	_sQuery +=    " AND E2_NUM     = '000015371'"
	_sQuery +=    " AND E2_VACHVEX = ''"
	_sQuery +=    " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
	_sQuery +=  " ORDER BY E2_PARCELA"
	//u_log (_sQuery)
	_sAliasQ = GetNextAlias ()
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
	U_TCSetFld (alias ())
	do while ! (_sAliasQ) -> (eof ())
		//u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)

		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc    = (_sAliasQ) -> e2_fornece
		_oCtaCorr:Loja     = (_sAliasQ) -> e2_loja
		_oCtaCorr:TM       = '13'
		_oCtaCorr:DtMovto  = (_sAliasQ) -> e2_EMISSAO
		_oCtaCorr:Valor    = (_sAliasQ) -> e2_valor
		_oCtaCorr:SaldoAtu = (_sAliasQ) -> e2_saldo
		_oCtaCorr:Usuario  = cUserName
		_oCtaCorr:Histor   = 'COMPRA SAFRA 2020 GRP.C'
		_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
		_oCtaCorr:Doc      = (_sAliasQ) -> e2_num
		_oCtaCorr:Serie    = (_sAliasQ) -> e2_prefixo
		_oCtaCorr:Parcela  = (_sAliasQ) -> e2_parcela
		_oCtaCorr:Origem   = 'GLPI8175'
		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			else
				se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
				if empty (se2 -> e2_vachvex)  // Soh pra garantir...
					reclock ("SE2", .F.)
					se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
					msunlock ()
				endif
			endif
		else
			U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
			_lContinua = .F.
		endif

		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
return
*/
/*
User Function AFTERLOGIN
	Local cId     := ParamIXB[1]
	Local cNome := ParamIXB[2]
	IF OAPP:LMDI
		ALERT("VOCE NÃO TEM AUTORIZAÇÃO PARA FAZER ESTE ACESSO !!!")
		FINAL()
	ENDIF
RETURN
*/
/*
	// Gera lista de campos cuja numeracao automatica precisa ser ajustada manualmente.
	use sxe exclusive new alias sxe
	// parece que corrompe o arquivo --> index on xe_alias + xe_filial to (criatrab ({}, .F.))
	sx3 -> (dbsetorder (2))
	sxe -> (dbgotop ())
	do while ! sxe -> (eof ())
		if left (xe_filial, 2) $ '  /' + cFilAnt
			u_log2 ('debug', sxe -> xe_alias + ': ' + sxe -> xe_numero)
			if ! six -> (dbseek (sxe -> xe_alias + '1', .F.))
				u_help ("Nao encontrei SIX para " + sxe -> xe_alias)
			else
				(sxe -> xe_alias) -> (dbsetorder (1))
				if (sxe -> xe_alias) -> (dbseek (xfilial (sxe -> xe_alias) + left (sxe -> xe_numero, sxe -> xe_tamanho), .T.))
					u_log2 ('info', sxe -> xe_alias + ' = ' + alltrim (fBuscaCpo ("SX2", 1, sxe -> xe_alias, 'X2_NOME')))
					u_logTrb (sxe -> xe_alias)
					(sxe -> xe_alias) -> (dbskip ())
					if ! (sxe -> xe_alias) -> (eof ())
						u_log2 ('info', sxe -> xe_alias + ' tem lacuna')
					endif
				endif
			endif
	//		if ! sx3 -> (dbseek (sxe -> xe_campo, .F.))
	//			u_help ("Nao encontrei o campo no SX3",, .t.)
	//		endif
		endif
		_sxe_ant = sxe -> xe_alias + sxe -> xe_filial
		sxe -> (dbskip ())
		if sxe -> xe_alias + sxe -> xe_filial == _sxe_ant
			u_log2 ('aviso', 'Parece que temos duplicidade: ' + _sxe_ant)
		endif
	enddo
	sxe -> (dbclosearea ())
return
*/
/*
	// Geramos faturas de pagamento de safra indevidamente...
	dDataBase = stod ('20200720')
	if cFilAnt != '01'
		u_help ("Filial errada.",, .t.)
		return
	endif
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT R_E_C_N_O_"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
	_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SZI.ZI_FILIAL = '01'"
	_oSQL:_sQuery +=    " AND SZI.ZI_DATA   = '20200720'"
	_oSQL:_sQuery +=    " AND SZI.ZI_SERIE  = '30'"
	_oSQL:_sQuery +=    " AND SZI.ZI_HISTOR = 'FAT.PAG.SAFRA 2020'"
	_oSQL:_sQuery +=    " AND SZI.ZI_SALDO  = ZI_VALOR"
	_oSQL:_sQuery +=  " ORDER BY ZI_ASSOC, ZI_LOJASSO, ZI_SEQ"
	_oSQL:Log ()
	_aDados = _oSQL:Qry2Array ()
	for _nDado = 1 to len (_aDados)
		szi -> (dbgoto (_aDados [_nDado, 1]))
		u_log2 ('info', '--------------------------------------------------------------------')
		u_log2 ('info', szi -> zi_assoc + '/' + szi -> zi_lojasso + ' doc.' + szi -> zi_doc + ' ' + szi -> zi_histor)
		if ! u_szicf (.T.)
			exit
		endif
		exit  // por enquanto, apenas um...
	next
return
*/

/*
	// Migra tabelas do SX5 para o ZX5
	//_aDePara = {'88', '39'} // Linhas comerciais 
	//_aDePara = {'Z7', '40'} // Marcas comerciais 
	_aDePara = {'79', '54'} // Eventos do sistema
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT X5_CHAVE, X5_DESCRI, X5_DESCSPA"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SX5")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND X5_FILIAL  = '" + xFilial ("SX5") + "'"
	_oSQL:_sQuery +=    " AND X5_TABELA  = '" + _aDePara [1] + "'"
	_oSQL:_sQuery +=  " ORDER BY X5_CHAVE"
	u_log (_oSQL:_sQuery)
	_aDados := _oSQL:Qry2Array ()
	u_log (_aDados)
	if U_RetSQL ("SELECT COUNT (*) FROM " + RetSqlName ("ZX5") + " WHERE D_E_L_E_T_ != '*' AND ZX5_FILIAL = '" + xFilial ("ZX5") + "' AND ZX5_TABELA  = '" + _aDePara [2] + "'") > 0
		u_help ("Jah existe a tabela '" + _aDePara [2] + "' no ZX5")
	else
		begin transaction
		for _nDado = 1 to len (_aDados)
			reclock ("ZX5", .t.)
			zx5 -> zx5_filial = xfilial ("ZX5")
			zx5 -> zx5_tabela = _aDePara [2]
			zx5 -> zx5_chave  = SOMA1 (U_RetSQL ("SELECT MAX (ZX5_CHAVE) FROM " + RetSqlName ("ZX5") + " WHERE D_E_L_E_T_ != '*' AND ZX5_FILIAL = '" + xFilial ("ZX5") + "' AND ZX5_TABELA  = '" + _aDePara [2] + "'"))
			zx5 -> &('zx5_' + _aDePara [2] + 'cod')  = _aDados [_nDado, 1]
			zx5 -> &('zx5_' + _aDePara [2] + 'desc') = _aDados [_nDado, 2]
			u_log ('incluindo ', _aDados [_nDado, 1])
			msunlock ()
		next
		end transaction
	endif
return
*/
/*
	// Recalcula saldos conta corrente associados
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT R_E_C_N_O_"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
	_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SZI.ZI_FILIAL = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC = '002960'"
	_oSQL:_sQuery +=    " AND SZI.ZI_DATA >= '20200301'"
//	_oSQL:_sQuery +=    " AND EXISTS (SELECT *"
//	_oSQL:_sQuery +=                  " FROM " + RetSQLName ("SA2") + " SA2 "
//	_oSQL:_sQuery +=                 " WHERE SA2.D_E_L_E_T_ = ''"
//	_oSQL:_sQuery +=                   " AND SA2.A2_FILIAL  = '" + xfilial ("SA2") + "'"
//	_oSQL:_sQuery +=                   " AND SA2.A2_COD     = SZI.ZI_ASSOC"
//	_oSQL:_sQuery +=                   " AND SA2.A2_LOJA    = SZI.ZI_LOJASSO"
//	_oSQL:_sQuery +=                   " AND SA2.A2_VACBASE = SA2.A2_COD"
//	_oSQL:_sQuery +=                   " AND SA2.A2_VALBASE = SA2.A2_LOJA)"  // Somente codigo/loja base
//	_oSQL:_sQuery +=    " AND NOT EXISTS (SELECT * FROM ZZM010 WHERE D_E_L_E_T_ = '' AND ZZM_ASSOC = ZI_ASSOC AND ZZM_LOJA = ZI_LOJASSO AND ZZM_DATA = '20171231')"
	//_oSQL:_sQuery +=    " AND EXISTS (SELECT * FROM SE5010 SE5 WHERE SE5.D_E_L_E_T_ = '' AND E5_FORNECE = ZI_ASSOC AND E5_DATA > '20180706')"
	_oSQL:_sQuery +=  " ORDER BY ZI_ASSOC, ZI_LOJASSO, ZI_FILIAL, ZI_SEQ"
	_aDados = _oSQL:Qry2Array ()
	for _nDado = 1 to len (_aDados)
		szi -> (dbgoto (_aDados [_nDado, 1]))
		_nSaldoAnt = szi -> zi_saldo
		u_log2 ('info', szi -> zi_assoc + '/' + szi -> zi_lojasso + ' seq.' + szi -> zi_seq + ' ' + szi -> zi_histor)
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		_oCtaCorr:AtuSaldo ()
		if szi -> zi_saldo != _nSaldoAnt
			u_log2 ('aviso', szi -> zi_assoc + '/' + szi -> zi_lojasso + ' seq.' + szi -> zi_seq + ' sld ant:' + transform (_nSaldoAnt, "@E 999,999,999.99") + ' novo:' +  transform (szi -> zi_saldo, "@E 999,999,999.99") + ' ' + _oCtaCorr:UltMsg)
		endif
	next
return
*/
	// teste de uso de memoria
//	_a := FWSFallGrps ()
//	for _i = 1 to 12  // mais que 17 trava o servico
//		u_log2 ('debug', _i)
//		aadd (_a, aclone (_a))
//		sleep (1000)
//	next
/*
	// Gera pre-notas complemento uva Rubea safra 2020
	cPerg = "VAGNF3"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', 'H')    // Parcela
	U_GravaSX1 (cPerg, '07', '')     // DCO inicial
	U_GravaSX1 (cPerg, '08', 'z')    // DCO final
	U_GravaSX1 (cPerg, '09', '') //'9822')     // Prod ini
	U_GravaSX1 (cPerg, '10', 'z') //'9822')    // Prod final
	U_GravaSX1 (cPerg, '11', 0)    // Preco 2016
	U_GravaSX1 (cPerg, '12', '9936/9811/9812')  // Apenas estas variedades (Rubea, no caso)
	U_GravaSX1 (cPerg, '13', '')  // Exceto estas variedades
	U_VA_GNF3 (.T.)
return
*/
/*
	// Gera fatura para reagrupar vencimentos de titulos de compra de uva dos associados.
	// Busca notas cujas parcelas precisa recalcular.
	_sArqLog := 'Reparcelamento_notas_grupo_C_2020.log'
	if cFilAnt != '01'
		u_help ("Filial errada",, .t.)
		return
	endif
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT DISTINCT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_TIPO, E2_EMISSAO"
	_oSQL:_sQuery +=   " FROM SE2010 SE2, SZI010 SZI
	_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SE2.E2_FILIAL = '01'"
	_oSQL:_sQuery += " AND SE2.E2_PREFIXO = '30 '"
	_oSQL:_sQuery += " AND SE2.E2_EMISSAO >= '20200501'"
	_oSQL:_sQuery += " AND SE2.E2_SALDO > 0"
	_oSQL:_sQuery += " AND SE2.E2_TIPO IN ('NF', 'DP')"
	_oSQL:_sQuery += " AND SE2.E2_HIST NOT LIKE 'AJ%'"
	_oSQL:_sQuery += " AND SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZI_FILIAL = SE2.E2_FILIAL"
	_oSQL:_sQuery += " AND ZI_ASSOC = SE2.E2_FORNECE"
	_oSQL:_sQuery += " AND ZI_LOJASSO = SE2.E2_LOJA"
	_oSQL:_sQuery += " AND ZI_DOC = SE2.E2_NUM"
	_oSQL:_sQuery += " AND ZI_SERIE= SE2.E2_PREFIXO"
	_oSQL:_sQuery += " AND ZI_PARCELA = SE2.E2_PARCELA"
	_oSQL:_sQuery += " AND ZI_TM = '13'"
	_oSQL:_sQuery += " AND ZI_HISTOR LIKE '%GRP.C%'"
	
	// quero uns problematicos para testar
	// _oSQL:_sQuery += " AND exists (SELECT * FROM SE2010 PARCD WHERE PARCD.E2_FILIAL = SE2.E2_FILIAL AND PARCD.E2_FORNECE=SE2.E2_FORNECE AND PARCD.E2_NUM=SE2.E2_NUM AND PARCD.E2_PARCELA ='D' AND PARCD.E2_SALDO < PARCD.E2_VALOR)"
	
	_oSQL:_sQuery += " ORDER BY E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_TIPO"
	_oSQL:Log ()
	_sAliasQ := _oSQL:Qry2Trb ()
	do while ! (_sAliasQ) -> (eof ())
		_nTotTit = 0
		_nSldTit = 0
		_aTitOri = {}
		u_log2 ('info', '----------------------------------------------------------------------')
		u_log2 ('info', 'forn.' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' tit:' + (_sAliasQ) -> e2_prefixo + (_sAliasQ) -> e2_num)
		se2 -> (dbsetorder(6))  // E2_FILIAL, E2_FORNECE, E2_LOJA, E2_PREFIXO, E2_NUM, E2_PARCELA, E2_TIPO, R_E_C_N_O_, D_E_L_E_T_
		se2 -> (dbseek ((_sAliasQ) -> e2_filial + (_sAliasQ) -> e2_fornece + (_sAliasQ) -> e2_loja + (_sAliasQ) -> e2_prefixo + (_sAliasQ) -> e2_num, .F.))
		do while ! se2 -> (eof ());
			.and. se2 -> e2_filial == (_sAliasQ) -> e2_filial;
			.and. se2 -> e2_fornece == (_sAliasQ) -> e2_fornece;
			.and. se2 -> e2_loja == (_sAliasQ) -> e2_loja;
			.and. se2 -> e2_prefixo == (_sAliasQ) -> e2_prefixo;
			.and. se2 -> e2_num == (_sAliasQ) -> e2_num
			if se2 -> e2_tipo == (_sAliasQ) -> e2_tipo .and. se2 -> e2_emissao == stod ((_sAliasQ) -> e2_emissao)  // Pode ter sido feita alguma fatura e nao quero misturar
				u_log2 ('debug', 'Tit.orig.: ' + se2 ->e2_tipo + ' parc.' + se2 -> e2_parcela + ' sld:' + cvaltochar (se2 -> e2_saldo) + ' vcto:' + dtoc (se2 -> e2_vencrea))
				_nTotTit += se2 -> e2_valor
				_nSldTit += se2 -> e2_saldo
				if se2 -> e2_saldo > 0
					aadd (_aTitOri, {se2 -> E2_PREFIXO, se2 -> E2_NUM, se2 -> E2_PARCELA, se2 -> E2_TIPO, .F.})
				endif
			endif
			se2 -> (dbskip ())
		enddo
		u_log2 ('debug', 'total titulo: ' + cvaltochar (_nTotTit))
		u_log2 ('debug', 'saldo titulo: ' + cvaltochar (_nSldTit))

		// Agora tenho o valor total da nota. Vou distribuir esse valor original dentro dos percentuais corretos
		// para saber o valor liquido que deve ser pago em cada mes.
		_aNewParc = {}
		aadd (_aNewParc, {0                          , 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.040, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.114, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.114, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.114, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.114, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.142, 2), 0, 0})
		aadd (_aNewParc, {round (_nTotTit * 0.142, 2), 0, 0})
		// Deixa a diferenca para a primeira parcela.
		_nDistr =0
		for _nParc = 2 to len (_aNewParc)
			_nDistr += _aNewParc [_nParc, 1]
		next
		_aNewParc [1, 1] = _nTotTit - _nDistr  // Este seria o total que deveria ter sido pago ateh junho.
//		u_log2 ('debug', 'Parcelas como era para terem ficado:')
//		u_log2 ('debug', _aNewParc)

		// Agora que tenho os valores como devem ficar, distribuo o saldo do titulo de tras para frente
		// limitando ao valor de cada parcela.
		_nDistr = 0
		for _nParc = len (_aNewParc) to 1 step -1
			_aNewParc [_nParc, 2] = min (_aNewParc [_nParc, 1], _nSldTit - _nDistr)
			_nDistr += _aNewParc [_nParc, 2]
		next
//		u_log2 ('debug', 'Saldo distribuido:')
//		u_log2 ('debug', _aNewParc)

		// Se o saldo do titulo for menor que a distribuicao das parcelas restantes, eh por que ja foi
		// mordido para compensar algum adto.
		if _aNewParc [1, 1] <= 0
			u_log2 ('erro', 'Ainda sem tratamento: Parcelas restantes jah foram parcialmente usadas.')
		else

			// Agora que tenho os valores das novas parcelas, calculo o % de representatividade de cada uma.
			_nDistr = 0
			for _nParc = len (_aNewParc) to 2 step -1
				_aNewParc [_nParc, 3] = round (_aNewParc [_nParc, 2] * 100 / _nSldTit, 2)
				_nDistr += _aNewParc [_nParc, 3]
			next
			// Deixa a diferenca (dos percentuais) para a primeira parcela.
			_aNewParc [1, 3] = 100 - _nDistr
			u_log2 ('debug', 'Percentuais das novas parcelas calculados:')
			u_log2 ('debug', _aNewParc)

			// Ajusta os % no cadastro da condicao de pagamento e confere se fechou 100% (agora ja estou meio apavorado)
			SEC -> (DBSETORDER (1))  // EC_FILIAL, EC_CODIGO, EC_ITEM, R_E_C_N_O_, D_E_L_E_T_
			_ndistr = 0
			for _nParc = 1 to len (_aNewParc)
				if ! sec -> (dbseek (xfilial ("SEC") + '801' + strzero (_nParc, 2), .F.))
					u_help ("ERRO", 'Nao encontrei SEC')
					exit
				else
					reclock ("SEC", .F.)
					sec -> ec_rateio = _aNewParc [_nParc, 3]
					msunlock ()
				endif
				_nDistr += _aNewParc [_nParc, 3]
			next
			if _ndistr != 100
				u_log2 ('erro', 'Distribuicao nao fechou em 100%')
			else

				// Dados para a fatura a ser criada.
				_aFatPag = {}
				Aadd(_aFatPag, "31 ")                                //-- Prefixo
				Aadd(_aFatPag, "FAT")                                //-- Tipo
				Aadd(_aFatPag, (_sAliasQ) -> e2_num)                             //-- Numero da Fatura (se o numero estiver em branco obtem pelo FINA290)
				Aadd(_aFatPag, "120201    ")                         //-- Natureza
				Aadd(_aFatPag, stod ((_sAliasQ) -> e2_emissao))                            //-- Data emissao inicial
				Aadd(_aFatPag, stod ((_sAliasQ) -> e2_emissao))                            //-- Data emissao final
				Aadd(_aFatPag, (_sAliasQ) -> e2_fornece)                            //-- Fornecedor
				Aadd(_aFatPag, (_sAliasQ) -> e2_loja)                               //-- Loja
				Aadd(_aFatPag, (_sAliasQ) -> e2_fornece)                            //-- Fornecedor para geracao
				Aadd(_aFatPag, (_sAliasQ) -> e2_loja)                               //-- Loja do fornecedor para geracao
				Aadd(_aFatPag, '801')                            //-- Condicao de pagto
				Aadd(_aFatPag, 01)                                   //-- Moeda
				Aadd(_aFatPag, aclone(_aTitOri) )                    //-- ARRAY com os titulos da fatura (Prefixo,Numero,Parcela,Tipo,Título localizado na geracao de fatura (lógico). Iniciar com falso.)
				Aadd(_aFatPag, 0)                                    //-- Valor de decrescimo
				Aadd(_aFatPag, 0)                                    //-- Valor de acrescimo

				u_log2 ('info', 'Gerando fatura ' + (_sAliasQ) -> e2_num + ' para o fornecedor ' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_Loja + ' agrupando os seguintes titulos:')
				u_log2 ('info', _aTitOri)

				_sMsgErro = ''
				dbselectarea("SE2")
				dbsetorder(1)
				set filter to
		//		dbgotop ()
				lMsErroAuto  := .F.
				_sErroAuto := ''
				MsExecAuto( { |x,y| FINA290(x,y)},3,_aFatPag,)
				If lMsErroAuto
					if ! empty (_sErroAuto)
						_sMsgErro += _sErroAuto + '; '
					endif
					if ! empty (NomeAutoLog ())
						_sMsgErro += U_LeErro (memoread (NomeAutoLog ())) + '; '
					endif
					u_help ('Rotina automatica retornou erro: ' + _sMsgErro,, .t.)
				else
					// Ajusta os saldos da conta corrente para os titulos aglutinados na fatura.
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT R_E_C_N_O_"
					_oSQL:_sQuery +=   " FROM SZI010 SZI"
					_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=    " AND SZI.ZI_FILIAL  = '" + xfilial ("SZI") + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC   = '" + (_sAliasQ) -> e2_fornece + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '" + (_sAliasQ) -> e2_loja + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_SERIE   = '" + (_sAliasQ) -> e2_prefixo + "'"
					_oSQL:_sQuery +=    " AND SZI.ZI_DOC     = '" + (_sAliasQ) -> e2_num + "'"
					//_oSQL:Log ()
					_aDados = _oSQL:Qry2Array ()
					for _nDado = 1 to len (_aDados)
						sZI -> (dbgoto (_aDados [_nDado, 1]))
						_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
						_oCtaCorr:AtuSaldo ()
					next


					// Localiza os titulos gerados pela fatura, atualiza-os e gera conta corrente.
					_oSQL := ClsSQL ():New ()
					_oSQL:_sQuery := ""
					_oSQL:_sQuery += " SELECT R_E_C_N_O_"
					_oSQL:_sQuery +=   " FROM SE2010 SE2"
					_oSQL:_sQuery +=  " WHERE SE2.D_E_L_E_T_ = ''"
					_oSQL:_sQuery +=    " AND SE2.E2_FILIAL  = '" + xfilial ("SE2") + "'"
					_oSQL:_sQuery +=    " AND SE2.E2_EMISSAO = '" + dtos (ddatabase) + "'"
					_oSQL:_sQuery +=    " AND SE2.E2_SALDO   > 0"
					_oSQL:_sQuery +=    " AND SE2.E2_TIPO    = 'FAT'"
					_oSQL:_sQuery +=    " AND SE2.E2_FORNECE = '" + (_sAliasQ) -> e2_fornece + "'"
					_oSQL:_sQuery +=    " AND SE2.E2_LOJA    = '" + (_sAliasQ) -> e2_loja + "'"
					_oSQL:_sQuery +=    " AND SE2.E2_PREFIXO = '31 '"
					_oSQL:_sQuery +=    " AND SE2.E2_NUM     = '" + (_sAliasQ) -> e2_num + "'"
					//_oSQL:Log ()
					_aDados = _oSQL:Qry2Array ()
					for _nDado = 1 to len (_aDados)
						se2 -> (dbgoto (_aDados [_nDado, 1]))
					//	u_log2 ('debug', 'fatura: ' + se2 ->e2_tipo + ' ' + se2 -> e2_parcela + ' sld:' + cvaltochar (se2 -> e2_saldo) + ' ' + dtoc (se2 -> e2_vencrea))

						// altera o historio e deixa posicionado o E2 para criar conta corrente referente a este titulo.
						reclock("SE2", .F.)
						SE2->E2_HIST := 'REPARCELAMENTO COMPRA SAFRA 2020 GRP.C'
						MsUnLock()

						_oCtaCorr := ClsCtaCorr():New ()
						_oCtaCorr:Assoc    = se2 -> e2_fornece
						_oCtaCorr:Loja     = se2 -> e2_loja
						_oCtaCorr:TM       = '13'
						_oCtaCorr:DtMovto  = se2 -> e2_EMISSAO
						_oCtaCorr:Valor    = se2 -> e2_valor
						_oCtaCorr:SaldoAtu = se2 -> e2_saldo
						_oCtaCorr:Usuario  = cUserName
						_oCtaCorr:Histor   = SE2 -> E2_HIST
						_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
						_oCtaCorr:Doc      = se2 -> e2_num
						_oCtaCorr:Serie    = se2 -> e2_prefixo
						_oCtaCorr:Origem   = 'GLPI8138'
						_oCtaCorr:Parcela  = se2 -> e2_parcela
						if _oCtaCorr:PodeIncl ()
							if ! _oCtaCorr:Grava (.F., .F.)
								U_help ("Erro na atualizacao da conta corrente para o associado '" + se2 -> e2_fornece + '/' + se2 -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
							else
								if empty (se2 -> e2_vachvex)
									reclock ("SE2", .F.)
									se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
									msunlock ()
								endif
							endif
						else
							U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + se2 -> e2_fornece + '/' + se2 -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg,, .t.)
						endif
					next
				endif
			endif
		endif
		(_sAliasQ) -> (dbskip ())
		//exit  // teste
	enddo
return
*/
/*
	// Recalcula frete safra 2020 e compara com conteudo jah gravado
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT FILIAL, SAFRA, CARGA "
	_oSQL:_sQuery +=  " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '2020'"
	// AND FILIAL = '" + xfilial ("SZE") + "'"
	_oSQL:_sQuery +=   " and STATUS != 'C'"
	_oSQL:_sQuery +=   " and CONTRANOTA != ''"
	//_oSQL:_sQuery +=   " and ASSOCIADO = '000161'"
	_oSQL:_sQuery += " ORDER BY ASSOCIADO, FILIAL, CARGA"
	_oSQL:Log ()
	_aCargas = _oSQL:Qry2Array ()
	for _nCarga = 1 to len (_aCargas)
		u_log2 ('info', replicate ('-', 80))
		sze -> (dbsetorder (1))
		if sze -> (dbseek (_aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3], .T.))
			U_VA_RUSCF (.f.)
		else
			u_log2 ('erro', 'Carga nao encontrada com a seguinte chave: ' + _aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3])
		endif
	next
return
*/
/*
	// Teste geracao avisos
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'A'
	_oAviso:Destinatar = 'robert'
	_oAviso:Texto      = 'teste robert'
	_oAviso:Origem     = procname ()
	_oAviso:DiasDeVida = 3
	_oAviso:CodAviso   = '010'
	_oAviso:Grava ()
	//
	_oAviso := ClsAviso ():New ()
	_oAviso:Tipo       = 'E'
	_oAviso:Destinatar = 'robert'
	_oAviso:Texto      = 'teste robert'
	_oAviso:Origem     = procname ()
	_oAviso:DiasDeVida = 3
	_oAviso:CodAviso   = '010'
	_oAviso:Grava ()
return
*/
/*
	// Simula integralizacao de cotas sobre a producao do associado
	cPerg := "SZI_ICP"
	U_GravaSX1 (cPerg, "01", '006417')
	U_GravaSX1 (cPerg, "02", '')
	U_GravaSX1 (cPerg, "03", '006418')
	U_GravaSX1 (cPerg, "04", 'zz')
	U_GravaSX1 (cPerg, "05", '2020')
	U_GravaSX1 (cPerg, "06", 2)  // gerar/simular
	U_szi_icp (.t.)
return
*/
/*
	// Simula contabilizacoes
	cPerg := "SIMULCTB"
	U_GravaSX1 (cPerg, '01', stod ('20200514'))
	U_GravaSX1 (cPerg, '02', stod ('20200514'))
	U_SimulCTB
return
*/
/*
	// aKeyValues:= {"USR_CODIGO","USR_NOME","USR_EMAIL","USR_MSBLQL"}
	// Para obter as informações das empresas que o usuário tem acesso, deve-se usar a função FWUsrEmp
	// FWSFallGrps
	// http://sempreju.com.br/principais-funcoes-para-informacoes-de-usuarios/
	// RETORNA O MESMO QUE PSWRET(), MAS PRA TODOS OS USUARIOS --> u_showarray (allusers ())
	u_log2 ('debug', pswret ())
//	u_showarray (pswret ())
	PswOrder(1)
	if PswSeek ('000653', .T.)
		_aPswRet := PswRet ()
		u_log2 ('debug', _apswret)
	else
		u_log2 ('erro', 'Nao localizei usuario')
	endif

	_aSup := FWSFUsrSup('000653')
	For _i := 1 to Len(_aSup)
		u_log2 ('info', 'Superior: ' + _aSup [_i])
	next

	// Retorna regras / politicas
	_aUsers := FWSFAllRules()
	U_LOG2 ('INFO', _aUsers)

	_aRet := FWGetMnuAccess (__cUserID, 97 )
	u_log2 ('info', _aRet)

	// https://tdn.totvs.com/pages/viewpage.action?pageId=42796368
	// https://tdn.totvs.com/display/tec/GetUserFromSID
	//_aSID = GetUserFromSID ()
	//u_log2 ('info', _aSID)

	// http://microsigadvpl.blogspot.com/2010/09/pegando-senhas-dos-usuarios-do-protheus.html
	
	if "TESTE" $ upper (GetEnvServer())
		cKey1 := cKey2 := cKey3 := cPswDet := ''
		nRetUser := 2
		u_log2 ('info', 'chamando getfields')
		SPF_GETFIELDS('sigapss.spf',nRetUser,@cKey1,@cKey2,@cKey3,@cPswDet)
		oXml:=XmlParser(cPswDet,"_",@cErro,@cWarn)
		u_log2 ('debug', XMLSaveStr(oXml))
	endif

return
*/
	/*
	// Puxa ZZ9 da base quente para base teste, para simular geracao de notas.
	if "TESTE" $ upper (GetEnvServer())
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "update ZZ9010 set D_E_L_E_T_ = '*' where ZZ9_SAFRA = '2020'"
		if _oSQL:Exec ()
			_oSQL:_sQuery := " SELECT * from LKSRV_PROTHEUS.protheus.dbo.ZZ9010 WHERE D_E_L_E_T_ = '' AND ZZ9_SAFRA = '2020'"
			_sAliasQ = _oSQL:Qry2Trb ()
			do while ! (_sAliasQ) -> (eof ())
				if (_sAliasQ) -> (recno ()) % 10 == 0
					u_log2 ('info', 'copiando ZZ9 reg. ' + cvaltochar ((_sAliasQ) -> (recno ())) + ' de ' + cvaltochar ((_sAliasQ) -> (reccount ())))
				endif
				reclock ("ZZ9", .T.)
				for _nCampo = 1 to zz9 -> (fcount ())
					_sCampo = alltrim (zz9 -> (fieldname (_nCampo)))
					_xDado = (_sAliasQ) -> &(_sCampo)
					zz9 -> &(_sCampo) = _xDado
				next
				msunlock ()
				(_sAliasQ) -> (dbskip ())
			enddo
		endif
	endif
return
*/
/* Acho que vai dar 1 trabalhao e nao tenho tempo.
	// Gera planilha com tabelas de precos de uvas em formato amigavel.
	local _aTabFinal := {}
	local _nQualTab := 0
	local _aGrpUva := {}
	local _nGrpUva := 0
	_nQualTab = 1

	// Define quais grupos de uvas devem ser lidos
	if _nQualTab == 1  // Uvas comuns
		
		if _sSafra == '2020'
			_aGrpUva = {'101','111','131','141','151','152'}

			// Cria uma linha na tabela final que vai servir como titulos das colunas.
			aadd (_aTabFinal, {'Grau', 'Conv/bordadura', 'Em conversao', 'Organica', 'Conv/bordadura', 'Em conversao', 'Organica', 'Conv/bordadura', 'Em conversao', 'Organica', 'Conv/bordadura', 'Em conversao', 'Organica', 'Conv/bordadura', 'Em conversao', 'Organica', 'Conv/bordadura', 'Em conversao', 'Organica'}
		endif

	elseif _nQualTab == 2  // Viniferas espaldeira
		if _sSafra == '2020'
			_aGrpUva = {'210','211','213','214'}
		endif

	elseif _nQualTab == 3  // Viniferas latadas
		if _sSafra == '2020'
			_aGrpUva = {'301','302','304','305'}
		endif
	endif

	// Cria linhas com as variedades no inicio da tabela final.
	for _nGrpUva = 1 to len (_aGrpUva)

		// Verifica em qual coluna da tabela final esta variedades devem aparecer
		local _nColTbFin := 0
		_nColTbFin = _nGrpUva * (parei aqui) + 1
		// Monta lista com as variedades do grupo
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "SELECT RTRIM (ZX5_14PROD) + '-' + RTRIM (B1_DESC)"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("ZX5") + " ZX5, "
		_oSQL:_sQuery +=             RetSQLName ("ZB1") + " SB1 "
		_oSQL:_sQuery += " WHERE ZX5.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND ZX5_FILIAL     = '" + xfilial ("ZX5") + "'"
		_oSQL:_sQuery +=   " AND ZX5_TABELA     = '14'"
		_oSQL:_sQuery +=   " AND ZX5_14SAFR     = '" + _sSafra + "'"
		_oSQL:_sQuery +=   " AND ZX5.ZX5_14GRUP = '" + _aGrpUva [_nGrpUva] + "'"
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL  = '" + xfilial ("SB1") + "'"
		_oSQL:_sQuery +=   " AND SB1.B1_COD     = ZX5.ZX5_14PROD"
		_oSQL:_sQuery += " ORDER BY B1_DESC"
		_oSQL:Log ()
		local _aVaried := {}
		local _nVaried := 0
		_aVaried := aclone (_oSQL:Qry2Array ())
		for _nVaried = 1 to len (_aVaried)

			// Se nao tem linha disponivel para esta variedade na array final, cria uma linha nova.
			_nLinDest = ascan (_aTabFinal, {|_aVal| empty (_aVal [_nGrpUva + 1])})
		next
return
*/
/*
	// Conferencia geracao precos uvas
	_aPrecos := {}
	for _nGrau = 10 to 22
	// Bordo
		aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9925           ', _nGrau, 'B', 'L', .f.)[2], ;
		                         U_PrcUva20 ('01', '9948           ', _nGrau, 'B', 'L', .f.)[2], ;
		                         U_PrcUva20 ('01', '9959           ', _nGrau, 'B', 'L', .f.)[2]})

	// Niagara
	//	aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9904           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9832           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9831           ', _nGrau, 'B', 'L', .f.)[2]})

	// Isabel
	//	aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9901           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9949           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9960           ', _nGrau, 'B', 'L', .f.)[2]})

	// Tintorias (seibel2)
	//	aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9923           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9801           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9802           ', _nGrau, 'B', 'L', .f.)[2]})

	// Moscato Embrapa
	//	aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9918           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9837           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9836           ', _nGrau, 'B', 'L', .f.)[2]})

	// Cora
	//	aadd (_aPrecos, {_nGrau, U_PrcUva20 ('01', '9958           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9809           ', _nGrau, 'B', 'L', .f.)[2], ;
	//	                         U_PrcUva20 ('01', '9810           ', _nGrau, 'B', 'L', .f.)[2]})
	next
//	U_log2 ('info', 'Preco compra calculado: ' + cvaltochar (_aRetPrc [2]))
//	U_log2 ('info', 'Grau ' + transform (_aRetPrc [4][_nGrau, .PrcUvaColGrau], '@E 99.9') + ' = ' + cvaltochar (_aRetPrc [4][_nGrau, .PrcUvaColPrcCompra]))
	U_log2 ('info', _aPrecos)
return

/*
	Private cPerg   := "VAGNF2"
	U_GravaSX1 (cPerg, '01', '000235')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', '000235')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Parcelas sep.barras (bco=todas)
	U_GravaSX1 (cPerg, '07', 'C')    // Grupos
	U_GravaSX1 (cPerg, '08', 3)      // Geracao por DCO: {"Com DCO", "Sem DCO", "Todos"}
	U_GravaSX1 (cPerg, '09', 1)      // fina/comum: {"Comum", "Fina", "Todas"}
	U_GravaSX1 (cPerg, '10', 1)      // tipo NF: {"Normais", "Compl.preco"}
	U_GravaSX1 (cPerg, '11', '801')     // Cond pagto
	U_GravaSX1 (cPerg, '12', '9901')     // Apenas estas variedades
	U_GravaSX1 (cPerg, '13', '')     // Exceto estas vriedades
	u_va_gnf2 (.t.)
return
*/
/*
	// Estoque com codigo de Sisdevin
	Private cPerg   := "VAXLS15"
	U_GravaSX1 (cPerg, '01', '2445')
	U_GravaSX1 (cPerg, '02', '2445')
	U_GravaSX1 (cPerg, '03', '')
	U_GravaSX1 (cPerg, '04', 'z')
	U_GravaSX1 (cPerg, '05', date ())
	U_GravaSX1 (cPerg, '06', 1)
	u_va_xls15 (.T.)
return
*/
/*
	// Gera precos para as pre-notas de compra de safra.
	Private cPerg   := "VAZZ9P"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // produto ini
	U_GravaSX1 (cPerg, '07', 'z')    // fim
	U_GravaSX1 (cPerg, '08', 3)      // tipos uvas {"Comuns","Finas","Todas"}
	U_GravaSX1 (cPerg, '09', 2)      // regrava com NF ja gerada {"Sim", "Nao"}
	U_GravaSX1 (cPerg, '10', 1)      // regrava com obs {"Regrava","Nao altera"}
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'O')    // parcela ini
	U_GravaSX1 (cPerg, '14', 'O')    // parcela final
	U_GravaSX1 (cPerg, '15', 2)      // regrava se ja tiver preco {"Sim", "Nao"}
	U_VA_ZZ9P (.t.)
return
*/
/*
	cPerg := 'VA_CCR2'
	U_GravaSX1 (cPerg, '01', '0345           ')  // prod pai ini
	U_GravaSX1 (cPerg, '02', '0348           ')  // prod pai fim
	U_GravaSX1 (cPerg, '03', 'PA')  // tipo pai ini
	U_GravaSX1 (cPerg, '04', 'PA')  // tipo pai fim
	U_GravaSX1 (cPerg, '05', 1)  // 1=apenas pais ativos; 2=todos
	U_GravaSX1 (cPerg, '06', '')  // LINHA COML pai ini
	U_GravaSX1 (cPerg, '07', 'Z')  // LINHA COML pai fim
	u_va_ccr2 (.t.)
return
*/
/*	// Gera adiantamento 2a. parcela safra 2020
	Private cPerg   := "VA_ADSAF"
	U_GravaSX1 (cPerg, '01', '') //012000')
	U_GravaSX1 (cPerg, '02', '')
	U_GravaSX1 (cPerg, '03', 'z') //012800')
	U_GravaSX1 (cPerg, '04', 'z')
	U_GravaSX1 (cPerg, '05', '2020')
	U_GravaSX1 (cPerg, '06', 2)  // Simular / Gerar
	U_GravaSX1 (cPerg, '07', stod ('20200430'))  // Data para pagto
	U_GravaSX1 (cPerg, '08', '041')  // Banco
	U_GravaSX1 (cPerg, '09', '0873')  // Agencia
	U_GravaSX1 (cPerg, '10', '0685668204')  // Conta
	U_GravaSX1 (cPerg, '11', 2)  // Qual parcela vai ser adiantada (primeira, segunda, ...)
	U_GravaSX1 (cPerg, '12', 2)  // Qual preco do ZZ9 deve ser usado
	U_GravaSX1 (cPerg, '13', STOD ('20200328'))  // Ignorar debitos CC antes desta data (em que foi gerado o adto. da parcela anterior)
	u_va_adsaf (.T.)
return
*/
/*
	// Gera precos para as pre-notas de compra de safra.
	Private cPerg   := "VAZZ9P"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // produto ini
	U_GravaSX1 (cPerg, '07', 'z')    // fim
	U_GravaSX1 (cPerg, '08', 3)      // tipos uvas {"Comuns","Finas","Todas"}
	U_GravaSX1 (cPerg, '09', 2)      // regrava com NF ja gerada {"Sim", "Nao"}
	U_GravaSX1 (cPerg, '10', 1)      // regrava com obs {"Regrava","Nao altera"}
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '')    // parcela ini
	U_GravaSX1 (cPerg, '14', 'z')    // parcela final
	U_GravaSX1 (cPerg, '15', 1)      // regrava se ja tiver preco {"Sim", "Nao"}
	U_VA_ZZ9P (.t.)
return
*/
/*
	// Geracao pre-notas compra safra 2020
	// grupo A - bordo
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'A')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '9925/9822/9948/9959') // Apenas estas variedades (bordo, bordo de bordadura/em conversao/organico)
	U_GravaSX1 (cPerg, '15', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'A')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
	// 
	// grupo A - organicas
	// exceto bordo, jah gerado anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'B')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'O')    // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'A')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
	// 
	// grupo B - tintorias
	// exceto bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'C')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'B')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
	// 
	// grupo B - viniferas espaldeira
	// exceto tintoreas, bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'D')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 2)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'B')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '2')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
	// 
	// grupo C - viniferas latadas
	// exceto tintoreas, bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'E')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 2)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'C')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '1')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
	//
	// grupo C - demais
	// exceto tintoreas, bordo e organicas, viniferas jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2020') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'F')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 1)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'C')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_GravaSX1 (cPerg, '21', '107')  // TES compra de associados
	U_GravaSX1 (cPerg, '22', '077')  // TES compra de nao associados
	U_VA_GNF1 (.T.)
return
*/
/*
	Private cPerg   := "VA_ADSAF"
	U_GravaSX1 (cPerg, '01', '012000')
	U_GravaSX1 (cPerg, '02', '')
	U_GravaSX1 (cPerg, '03', '012800')
	U_GravaSX1 (cPerg, '04', 'z')
	U_GravaSX1 (cPerg, '05', '2020')
	U_GravaSX1 (cPerg, '06', 1)  // Simular / Gerar
	U_GravaSX1 (cPerg, '07', stod ('20200331'))  // Data para pagto
	U_GravaSX1 (cPerg, '08', '041')  // Banco
	U_GravaSX1 (cPerg, '09', '0873')  // Agencia
	U_GravaSX1 (cPerg, '10', '0685668204')  // Conta
	u_va_adsaf (.T.)
return
*/
/*
	// sIMULA EXECUCAO DO RATEIO de estocagem
	_ddfim := '20190131'
	_ddini := substr(_ddfim,1,6) + '01'
	// Cria array com os produtos do tipo VD e seus saldos em estoque na data final do periodo.
	// Somente aqueles que nao tem mao de obra na estrutra (os demais custeiam pelo "AO-, GF- e AP-")
	if _lContinua
		incproc ('Verificacao saldos estoque')
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := "WITH C AS ("
		_oSQL:_sQuery += "SELECT B2_COD, B2_LOCAL,"
		_oSQL:_sQuery +=       " dbo.VA_SALDOESTQ (SB2.B2_FILIAL, SB2.B2_COD, SB2.B2_LOCAL, '" + _dDFim + "') AS SALDOESTQ"
		_oSQL:_sQuery +=  " FROM " + RetSQLName ("SB2") + " SB2,"
		_oSQL:_sQuery +=             RetSQLName ("SB1") + " SB1"
		_oSQL:_sQuery += " WHERE SB2.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SB2.B2_FILIAL   = '"  + XFilial("SB2") + "' "
		_oSQL:_sQuery +=   " AND SB2.B2_COD      = B1_COD "
		_oSQL:_sQuery +=   " AND SB1.D_E_L_E_T_  = ''"
		_oSQL:_sQuery +=   " AND SB1.B1_FILIAL   = '"  + XFilial("SB1") + "' "
		_oSQL:_sQuery +=   " AND SB1.B1_TIPO     = 'VD' "
		_oSQL:_sQuery +=   " AND SB1.B1_AGREGCU != '1' "
		_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT *"
		_oSQL:_sQuery +=                     " FROM " + RETSQLNAME ("SG1") + " SG1 "
		_oSQL:_sQuery +=                    " WHERE SG1.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=                      " AND SG1.G1_FILIAL   = '" + xfilial ("SG1") + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_COD      = SB1.B1_COD"
		_oSQL:_sQuery +=                      " AND SG1.G1_INI     <= '" + _dDFim + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_FIM     >= '" + _dDFim + "'"
		_oSQL:_sQuery +=                      " AND SG1.G1_COMP    LIKE 'MMM%'"
		_oSQL:_sQuery +=                    ")"
		_oSQL:_sQuery += " )"
		_oSQL:_sQuery += " SELECT C.*, SUM (SALDOESTQ) OVER () AS ESTQ_TOT"
		_oSQL:_sQuery +=  " FROM C"
		//_oSQL:_sQuery += " WHERE SALDOESTQ > 0"
		_oSQL:_sQuery += " WHERE SALDOESTQ > 0.01"  // Evita pegar produtos com saldo muito pequeno
		_oSQL:Log ()
		_aEstq = aclone (_oSQL:Qry2Array ())
		if len (_aEstq) == 0
			u_help ("Nao foi encontrado nenhum produto com estoque em " + dtoc (stod (_dDFim)) + " e que precise rateio.")
			_lContinua = .F.
		else
			_nTotEstq = _aEstq [1, 4]
		endif
		u_log ('Estoques:', _aEstq)
	endif

	_aCC = {}
	aadd (_aCC, {'011101', 99584.36,  '300'})
	aadd (_aCC, {'011102', 175876.08, '301'})
	aadd (_aCC, {'011201', 77640.88,  '302'})
	aadd (_aCC, {'011202', 57885.53,  '303'})
	_aDist := {}
	for _nCC = 1 to len (_aCC)
		_nADistr = _aCC [_nCC, 2]
		//u_log ('Valor a distribuir:', _nADistr)
		for _nEstq = 1 to len (_aEstq)
			_nQtd = _aEstq [_nEstq, 3]
		
			// Gera, para cada produto, uma movimentacao de custo proporcional a seu estoque.
			_nCusMvTot = _nQtd * _nADistr / _nTotEstq

			u_log ("union all SELECT '01' AS FILIAL, '20190131' AS EMISSAO, '" + _aCC [_nCC, 3] + "' AS TM, '" + _aEstq [_nEstq, 1] + "' AS ITEM, '" + _aEstq [_nEstq, 2] + "' as LOCAL, " + CVALTOCHAR (_nCusMvTot) + " aS VALOR")
			aadd (_aDist, {_aCC [_nCC, 1], _aCC [_nCC, 2], _aEstq [_nEstq, 1], _aEstq [_nEstq, 2], _aEstq [_nEstq, 3], _nCusMvTot})
		next
	next
	U_AColsXLS (_aDist)
return
*/
/*
	// Recalcula classificacao uvas para 2020 e compara com conteudo gravado no SZF.
	if "TESTE" $ upper (GetEnvServer())
		_sLinkSrv = "LKSRV_NAWEB_TESTE.naweb_teste.dbo"
	else
		_sLinkSrv = "LKSRV_NAWEB.naweb.dbo"
	endif
	private _aRusInsp := {}
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT FILIAL, SAFRA, CARGA "
	_oSQL:_sQuery +=  " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '2020' AND FILIAL = '" + xfilial ("SZE") + "'"
	_oSQL:_sQuery +=   " and STATUS != 'C'"
	_oSQL:_sQuery +=   " and GRAU != ''"
	//_oSQL:_sQuery +=   " and PRODUTO = '9861'"
	//_oSQL:_sQuery +=   " and VARUVA = 'F'"
	//_oSQL:_sQuery +=   " and VARUVA = 'F'"
	//_oSQL:_sQuery +=   " AND CARGA in ('0065','0096','1051','1207')"
	_oSQL:_sQuery += " ORDER BY CARGA"
	_oSQL:Log ()
	_aCargas = _oSQL:Qry2Array ()
//	u_log (_aCargas)
	for _nCarga = 1 to len (_aCargas)
		u_log (replicate ('-', 80))
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		sze -> (dbsetorder (1))
		if sze -> (dbseek (_aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3], .T.))
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SITUACAO,"
			_oSQL:_sQuery +=        " VAR_NAO_PREV_CAD_VIT as VarNaoPrev,"
			_oSQL:_sQuery +=        " ENTREGOU_CADERNO_CPO as EntrCad,"
			_oSQL:_sQuery +=        " BOTRYTIS_PATIO as BOTRYP, "
			_oSQL:_sQuery +=        " BOTRYTIS_TOMBADOR AS BOTRYT, "
			_oSQL:_sQuery +=        " GLOMERELLA_PATIO as GlomeP, "
			_oSQL:_sQuery +=        " GLOMERELLA_TOMBADOR as GlomeT, "
			_oSQL:_sQuery +=        " ASPERGILLUS_PATIO as AsperP, "
			_oSQL:_sQuery +=        " ASPERGILLUS_TOMBADOR as AsperT, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_PATIO as PodriP, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_TOMBADOR as PodriT, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_PATIO as AcVolP, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_TOMBADOR as AcVolT, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_PATIO as MEstrP, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_TOMBADOR as MEstrT, "
			_oSQL:_sQuery +=        " MISTURA_VARIEDADES as Mistu"
			_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".VA_VINSPECOES_SAFRA_" + _aCargas [_nCarga, 2]
			_oSQL:_sQuery +=  " WHERE SAFRA  = '" + sze -> ze_safra  + "'"
			_oSQL:_sQuery +=    " AND FILIAL = '" + sze -> ze_filial + "'"
			_oSQL:_sQuery +=    " AND CARGA  = '" + sze -> ze_carga  + "'"
			_oSQL:Log ()
			_sAliasInsp = _oSQL:Qry2Trb (.F.)

			// Alimenta array de inspecoes. Deve estar previamente criada como 'private' na rotina chamadora.
			_aRusInsp = aclone (afill (array (.InspecoesSafraQtColunas), ''))

			if (_sAliasInsp) -> (eof ())
				u_log ('Sem retorno na consulta de inspecoes. Vou assumir valores padrao.')
				// Se nao encontou inspecao, assume status vazio e nao conforme para facilitar nos testes posteriores.
				_aRusInsp [.InspecoesSafraSituacao]         = '   '
				_aRusInsp [.InspecoesSafraVarNaoPrevCadVit] = 'N'  // N='Nao teve nenhuma variedade nao prevista no cadastro viticola'
				_aRusInsp [.InspecoesSafraEntrCadCpo]       = 'S'  // S='entregou caderno de campo'
				_sInspBotr = ''
				_sInspGlom = ''
				_sInspAspe = ''
				_sInspPodr = ''
				_sInspAcid = ''
				_sInspMEst = ''
			else
				_aRusInsp [.InspecoesSafraSituacao]          = (_sAliasInsp) -> situacao
				_aRusInsp [.InspecoesSafraVarNaoPrevCadVit]  = (_sAliasInsp) -> VarNaoPrev
				_aRusInsp [.InspecoesSafraEntrCadCpo]        = (_sAliasInsp) -> EntrCad
				_aRusInsp [.InspecoesSafraMisturaNoTombador] = (_sAliasInsp) -> Mistu

				// Se tem resultado na inspecao de tombador, melhor. Senao, pega a de patio.
				_sInspBotr = iif (! empty ((_sAliasInsp) -> BotryT), (_sAliasInsp) -> BotryT, (_sAliasInsp) -> BotryP)
				_sInspGlom = iif (! empty ((_sAliasInsp) -> GlomeT), (_sAliasInsp) -> GlomeT, (_sAliasInsp) -> GlomeP)
				_sInspAspe = iif (! empty ((_sAliasInsp) -> AsperT), (_sAliasInsp) -> AsperT, (_sAliasInsp) -> AsperP)
				_sInspPodr = iif (! empty ((_sAliasInsp) -> PodriT), (_sAliasInsp) -> PodriT, (_sAliasInsp) -> PodriP)
				_sInspAcid = iif (! empty ((_sAliasInsp) -> AcVolT), (_sAliasInsp) -> AcVolT, (_sAliasInsp) -> AcVolP)
				_sInspMEst = iif (! empty ((_sAliasInsp) -> MEstrT), (_sAliasInsp) -> MEstrT, (_sAliasInsp) -> MEstrP)
			endif
			(_sAliasInsp) -> (dbclosearea ())
			dbselectarea ("SZE")
			
			u_log ('Inspecoes:')
			u_log (   'Situacao da carga no APP........: ', _aRusInsp [.InspecoesSafraSituacao])
			u_log (   'Varied.nao prevista no cad.vitic: ', _aRusInsp [.InspecoesSafraVarNaoPrevCadVit])
			u_log (   'Entrega cad.campo...............: ', _aRusInsp [.InspecoesSafraEntrCadCpo])
			u_log (   'Mistura variedades no tombador..: ', _aRusInsp [.InspecoesSafraMisturaNoTombador])
			u_log (   'Chave agenda original...........: ', _aRusInsp [.InspecoesSafraAgendaOri])
			u_log (   'Botrytis......:', _sInspBotr)
			u_log (   'Glomerella....:', _sInspGlom)
			u_log (   'Aspergyllus...:', _sInspAspe)
			u_log (   'Podridoes.....:', _sInspPodr)
			u_log (   'Acidez volatil:', _sInspAcid)
			u_log (   'Mat.estranho..:', _sInspMEst)

			sb1 -> (dbsetorder (1))
			szf -> (dbsetorder (1))  // filial + safra + carga + item
			szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
			do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
				if ! sb1 -> (dbseek (xfilial ("SB1") + szf -> zf_produto, .F.))
					u_log ('Produto nao cadastrado:', szf -> zf_produto)
				else
					u_log ('Filial:', sze -> ze_filial, 'Safra:', sze -> ze_safra, 'Carga:', sze -> ze_carga, 'Item:', szf -> zf_item, 'Grau:', szf -> zf_grau)
					_aClasUva = aclone (U_ClUva20 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst))
					u_log (_aClasUva)
					reclock ("SZF", .F.)
					if szf -> zf_conduc == 'L'
						szf -> zf_clabd_2 = _aClasUva [1]
						if alltrim (_aClasUva [1]) != alltrim (szf -> zf_clasABD)
							u_log ('no ZF_CLASABD consta ', szf -> zf_clasABD, 'zf_obs:', szf -> zf_obs)
						endif
					else
						szf -> zf_prm99_2 = _aClasUva [5]
						if alltrim (_aClasUva [5]) != alltrim (szf -> zf_prm99)
							u_log ('no ZF_CLASSE consta ', szf -> zf_prm99, 'zf_obs:', szf -> zf_obs)
						endif
					endif
					msunlock ()
				endif
				szf -> (dbskip ())
			enddo
		endif
	next
return
*/
/*
	// Ajusta cadastro fornecedores em lote
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SA2.R_E_C_N_O_"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA2") + " SA2 "
	_oSQL:_sQuery +=  " WHERE SA2.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA2.A2_FILIAL = '" + xfilial ("SA2") + "'"
	_oSQL:_sQuery +=    " AND SA2.A2_COND != '801'"
//	_oSQL:_sQuery +=    " AND (SA2.A2_MSBLQL != '2' or SA2.A2_ATIVO != 'S')"
	_oSQL:_sQuery +=    " AND EXISTS (SELECT * FROM SZI010 SZI WHERE SZI.D_E_L_E_T_ = '' and SZI.ZI_ASSOC = SA2.A2_COD AND SZI.ZI_LOJASSO = SA2.A2_LOJA)"
	_oSQL:_sQuery +=  " ORDER BY A2_COD"
	_oSQL:Log ()
	_aDados = _oSQL:Qry2Array ()
	//u_log (_aDados)
	for _i = 1 to len (_aDados)
		sa2 -> (dbgoto (_aDados [_i, 1]))
		u_log ('Verificando forn', sa2 -> a2_cod, Sa2 -> a2_nome)
		// Cria variaveis para uso na gravacao do evento de alteracao
		regtomemory ("SA2", .F., .F.)
		m->a2_cond = '801'

		// Grava evento de alteracao
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA2", m->a2_cod + m->a2_loja, sa2 -> (recno ()), '', .F.)

		reclock ("SA2", .f.)
		sa2 -> a2_cond = m->a2_cond
		msunlock ()
	//	exit
	next
*/
/*
	Private cPerg   := "VAXLS50"
	U_GravaSX1 (cPerg, '01', '2006')
	U_GravaSX1 (cPerg, '02', '2020')
	U_GravaSX1 (cPerg, '03', '')
	U_GravaSX1 (cPerg, '04', 'z')
	u_va_xls50 (.T.)
return
*/

/*	_a := {}
	aadd (_a, {'0345', '0082', nil   , nil   , '9901'})
	aadd (_a, {''    , '0328', '0150', '8010', nil})
	aadd (_a, {'0005', nil   , '0151', '8011', 0})
	aadd (_a, {'0348', nil   , ''    , '8012', nil})
	_oLstPrd := ClsAUtil ():New (_a)
	_oLstPrd:ReduzLin ()
	u_log (_oLstPrd:_aArray)
return
*/
/*
	Private cPerg   := "VAXLS35"
	U_GravaSX1 (cPerg, '01', '')  // assoc 
	U_GravaSX1 (cPerg, '02', '')  // loja
	U_GravaSX1 (cPerg, '03', 'z')  // assoc 
	U_GravaSX1 (cPerg, '04', 'z')  // loja
	U_GravaSX1 (cPerg, '05', '2020')  // safra
	U_GravaSX1 (cPerg, '06', '09')  // filial
	U_GravaSX1 (cPerg, '07', '09')  // filial
	U_GravaSX1 (cPerg, '08', '')  // carga
	U_GravaSX1 (cPerg, '09', 'z')  // carga
	U_GravaSX1 (cPerg, '10', 3)  // comum/fina/ambas
	U_GravaSX1 (cPerg, '11', '')  // nf produtor ini
	U_GravaSX1 (cPerg, '12', 'z')  // nf produtor fim
	U_GravaSX1 (cPerg, '13', 1)  // ignorar cargas canceladas / redirecionadas
	u_va_xls35 (.T.)
return
*/
/*
	Private cPerg   := "VAXLS41"
	U_GravaSX1 (cPerg, '01', '')  // assoc 
	U_GravaSX1 (cPerg, '02', '')  // loja
	U_GravaSX1 (cPerg, '03', 'z')  // assoc 
	U_GravaSX1 (cPerg, '04', 'z')  // loja
	U_GravaSX1 (cPerg, '05', '2020')  // safra
	U_GravaSX1 (cPerg, '06', '')  // grp fam
	U_GravaSX1 (cPerg, '07', 'z')  // grp fam
	U_GravaSX1 (cPerg, '08', '01')  // filial
	U_GravaSX1 (cPerg, '09', '01')  // filial
	U_GravaSX1 (cPerg, '10', '1520')  // carga
	U_GravaSX1 (cPerg, '11', '1520')  // carga
	U_GravaSX1 (cPerg, '12', stod (''))  // data
	U_GravaSX1 (cPerg, '13', stod ('20201231'))  // data
	u_va_xls41 (.T.)
return
*/
/*
	// Testes geracao XML
	paramixb := array (3, 7)
	_aNotas = {}
	//              Tipo  Serie    NF        CliFor    Loja
	// aadd (_aNotas, {'2', '10 ',   '000059408', '012732', '01', '', ''})  // F01 - Saida tipo I
	// aadd (_aNotas, {'2', '10 ',   '000059248', '014381', '01', '', ''})  // F01 - Exportacao
	//aadd (_aNotas, {'1', '10 ',   '000092506', '008478', '01', '', ''})  // F01 - Saida com ST para UF=MG
	//aadd (_aNotas, {'1', '10 ',   '000094484', '009830', '01', '', ''})  // F01 - Saida com ST para UF=PR
	//aadd (_aNotas, {'1', '10 ',   '000093720', '013301', '01', '', ''})  // F01 - Saida com ST para UF=PR
	//aadd (_aNotas, {'1', '10 ',   '000093920', '007492', '01', '', ''})  // F01 - Saida com ST para UF=RJ
	//aadd (_aNotas, {'1', '10 ',   '000087045', '005780', '01', '', ''})  // F01 - Saida com ST para UF=RS
	//aadd (_aNotas, {'1', '10 ',   '000094403', '015085', '01', '', ''})  // F01 - Saida com ST para UF=RS
	//aadd (_aNotas, {'1', '10 ',   '000094408', '002086', '01', '', ''})  // F01 - Saida com ST para UF=SC
	//aadd (_aNotas, {'1', '10 ',   '000093852', '010810', '01', '', ''})  // F01 - Saida com ST para UF=SC
	//aadd (_aNotas, {'1', '10 ',   '000087040', '014978', '01', '', ''})  // F01 - Saida com ST para UF=SP
	// aadd (_aNotas, {'1', '10 ',   '000094379', '016674', '01', '', ''})  // F01 - Saida com ST para UF=SP
	//aadd (_aNotas, {'2', '10 ',   '000004108', '015225', '01', '', ''})  // F03 - Entrada consignacao com ST
	aadd (_aNotas, {'2', '10 ',   '000097924', '003882', '01', '', ''})  // F01 - Importacao
	//aadd (_aNotas, {'1', '10 ',   '000009508', '017469', '01', '', ''})  // F10 - Saida com impostos.
	aadd (_aNotas, {'1', '10 ',   '000102422', '004478', '01', '', ''})  // F01 - Saida tipo B.
	aadd (_aNotas, {'1', '10 ',   '000106732', '002942', '01', '', ''})  // F01 - Saida com fundo erradicacao pobreza.
	aadd (_aNotas, {'1', '10 ',   '000105551', '014639', '01', '', ''})  // F01 - Saida com fundo erradicacao pobreza.
	aadd (_aNotas, {'1', '10 ',   '000125643', '009189', '01', '', ''})  // F01 - Saida com transp. redespacho
	aadd (_aNotas, {'1', '10 ',   '000125646', '009189', '01', '', ''})  // F01 - Saida com transp. redespacho
	aadd (_aNotas, {'1', '10 ',   '000159196', '005410', '01', '', ''})  // F01 - Saida com dados adicionais do contribuinte e do fisco.
	aadd (_aNotas, {'1', '10 ',   '000160432', '024238', '01', '', ''})  // F01 - Saida com dados adicionais do contribuinte e do fisco + redespacho.
	aadd (_aNotas, {'1', '10 ',   '000160414', '023635', '01', '', ''})  // F01 - Entrada
	aadd (_aNotas, {'1', '10 ',   '000160473', '005116', '01', '', ''})  // F01 - Saida com AMPARA
	for _nDado = 1 to len (_aNotas)
		u_logIni (_aNotas [_nDado, 3])
		PARAMIXB[1,1] = _anotas [_nDado, 1]
		PARAMIXB[1,3] = _anotas [_nDado, 2]
		PARAMIXB[1,4] = _anotas [_nDado, 3]
		PARAMIXB[1,5] = _anotas [_nDado, 4]
		PARAMIXB[1,6] = _anotas [_nDado, 5]
		PARAMIXB[1,7] = ''
		PARAMIXB[2] = "3.10"
		PARAMIXB[3] = '1'  // 1=producao, 2=homologacao
		U_XmlNfeSEF (_aNotas [_nDado, 1], _aNotas [_nDado, 2], _aNotas [_nDado, 3], _aNotas [_nDado, 4], _aNotas [_nDado, 5], _aNotas [_nDado, 6], _aNotas [_nDado, 7])
		u_logFim (_aNotas [_nDado, 3])
	next
return
*/
/*
	Private cPerg   := "VAXLS40"
	U_GravaSX1 (cPerg, '01', '2020')  // safra
	U_GravaSX1 (cPerg, '02', 3)  // 'Comuns', 'Finas espaldeira', 'Finas latadas', 'Finas SC'
	U_GravaSX1 (cPerg, '03', 3)  // Entrada/Compra/MOC
	U_GravaSX1 (cPerg, '04', 1)  // Todos(decimais) / Apenas inteiros
	u_va_xls40 (.T.)
return
*/
/*
	// Testes inclusao de carga safra via web service
	private _sErros := ''
	_oAssoc := ClsAssoc():New ('000161', '01')
	_aItensCar = {}
	aadd (_aItensCar, {'13386', U_TamFixo ('9901', 15), 'G'})
	aadd (_aItensCar, {'13386', U_TamFixo ('9904', 15), 'G'})
	u_log ('retorno do U_GeraZZE:', U_GeraSZE (_oAssoc,'2020','LB', '123', '123453789', 'chave_nfe', 'abc1x34', '1', 'teste robert',_aItensCar, .T., '789000'))
	u_log ('Msg de problemas:', _sErros)
return
*/

/*
	// Gera alguns XML para testar criacao de novas cargas
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT top 100 FILIAL, SAFRA, CARGA "
	_oSQL:_sQuery +=  " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '2019' AND FILIAL = '" + xfilial ("SZE") + "'"
	_oSQL:_sQuery +=   " and STATUS != 'C' And CONTRANOTA != ''"
	_oSQL:_sQuery +=   " and NOT EXISTS (SELECT * FROM SZE010 WHERE ZE_FILIAL = FILIAL AND ZE_SAFRA = '2020' AND ZE_ASSOC = ASSOCIADO AND ZE_NFPROD = NF_PRODUTOR)"
	_oSQL:_sQuery += " ORDER BY CARGA"
	_oSQL:Log ()
	_aCargas = _oSQL:Qry2Array ()
//	u_log (_aCargas)
	for _nCarga = 1 to len (_aCargas)
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		sze -> (dbsetorder (1))
		if sze -> (dbseek (_aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3], .T.))
			sb1 -> (dbsetorder (1))
			szf -> (dbsetorder (1))  // filial + safra + carga + item
			szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
			_sXML := "#$XML += '<Acao>IncluiCargaSafra</Acao><Safra>2020</Safra><Balanca>LB</Balanca><Associado>" + sze -> ze_assoc + '</Associado><Loja>' + sze -> ze_lojasso + '</Loja><SerieNfProdutor>' + sze -> ze_snfprod + '</SerieNfProdutor><NumeroNfProdutor>' + sze -> ze_nfprod + '</NumeroNfProdutor><ChaveNFPe></ChaveNFPe><PlacaVeiculo>' + sze -> ze_placa + '</PlacaVeiculo><Tombador>1</Tombador><Obs>Teste WS para inclusao de carga de uva durante a safra</Obs><coletarAmostra>N</coletarAmostra>'
			_sItem = '1'
			do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
				_sXML += "<cadastroViticola" + _sItem + ">" + szf -> zf_cadviti + "</cadastroViticola" + _sItem + "><Variedade" + _sItem + ">" + szf -> zf_produto + "</Variedade" + _sItem + "><Embalagem" + _sItem + ">G</Embalagem" + _sItem + ">"
				_sItem = soma1 (_sItem)
				szf -> (dbskip ())
			enddo
			u_log (_sXML + "'")
		endif
	next
return
*/
/*
	// teste leitura inspecoes safra
	if "TESTE" $ upper (GetEnvServer())
		_sLinkSrv = "LKSRV_NAWEB_TESTE.naweb_teste.dbo"
	else
		_sLinkSrv = "LKSRV_NAWEB.naweb.dbo"
	endif
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT top 50 FILIAL, SAFRA, CARGA "
	_oSQL:_sQuery +=  " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '2020' AND FILIAL = '01'"
	_oSQL:_sQuery +=   " and STATUS != 'C'"
	_oSQL:Log ()
	_aCargas = _oSQL:Qry2Array ()
	for _nCarga = 1 to len (_aCargas)
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		sze -> (dbsetorder (1))
		if sze -> (dbseek (_aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3], .T.))
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SITUACAO,"
			_oSQL:_sQuery +=        " VAR_NAO_PREV_CAD_VIT as VarNaoPrev,"
			_oSQL:_sQuery +=        " ENTREGOU_CADERNO_CPO as EntrCad,"
			_oSQL:_sQuery +=        " BOTRYTIS_PATIO as BOTRYP, "
			_oSQL:_sQuery +=        " BOTRYTIS_TOMBADOR AS BOTRYT, "
			_oSQL:_sQuery +=        " GLOMERELLA_PATIO as GlomeP, "
			_oSQL:_sQuery +=        " GLOMERELLA_TOMBADOR as GlomeT, "
			_oSQL:_sQuery +=        " ASPERGILLUS_PATIO as AsperP, "
			_oSQL:_sQuery +=        " ASPERGILLUS_TOMBADOR as AsperT, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_PATIO as PodriP, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_TOMBADOR as PodriT, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_PATIO as AcVolP, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_TOMBADOR as AcVolT, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_PATIO as MEstrP, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_TOMBADOR as MEstrT, "
			_oSQL:_sQuery +=        " DESUNIFORMIDADE_MATURACAO_PATIO as DesunP, "
			_oSQL:_sQuery +=        " DESUNIFORMIDADE_MATURACAO_TOMBADOR as DesunT, "
			_oSQL:_sQuery +=        " MISTURA_VARIEDADES as Mistu"
			_oSQL:_sQuery +=   " FROM " + _sLinkSrv + ".VA_VINSPECOES_SAFRA"
			_oSQL:_sQuery +=  " WHERE SAFRA  = '" + sze -> ze_safra  + "'"
			_oSQL:_sQuery +=    " AND FILIAL = '" + sze -> ze_filial + "'"
			_oSQL:_sQuery +=    " AND CARGA  = '" + sze -> ze_carga  + "'"
			_oSQL:Log ()
			u_log (_oSQL:Qry2Array ())
		endif
	next
return
*/
/*
	cPerg := "VAXLS46"
	U_GravaSX1 (cPerg, '01', stod ('20190901'))
	U_GravaSX1 (cPerg, '02', date ())
	U_GravaSX1 (cPerg, '03', '')
	U_GravaSX1 (cPerg, '04', 'z')
	U_VA_XLS46 (.T.)
return
*/
/*
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SA1.R_E_C_N_O_ "
	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery += " WHERE SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SA1.A1_FILIAL = '" + xfilial ("SA1") + "'"  // Deixar esta opcao para poder ler os campos memo.
	_oSQL:_sQuery += " AND EXISTS (SELECT *"
	_oSQL:_sQuery += "			   FROM " + RetSQLName ("SZN") + " SZN "	
	_oSQL:_sQuery += "			   WHERE SZN.ZN_CODEVEN = 'ALT001'"
	_oSQL:_sQuery += "			   AND SZN.ZN_ALIAS = 'SA1'"
	_oSQL:_sQuery += "			   AND SZN.ZN_DATA >= '20190801'"
	_oSQL:_sQuery += "			   AND SZN.ZN_USUARIO IN ('ADMINISTRADOR', 'robert.koch')"
	_oSQL:_sQuery += "			   AND SZN.ZN_PILHA LIKE '%BATLIMCR%'"
	_oSQL:_sQuery += "			   AND SZN.ZN_CLIENTE = SA1.A1_COD"
	_oSQL:_sQuery += "			   AND SZN.ZN_LOJACLI = SA1.A1_LOJA)
	_oSQL:Log ()
	_aDados = aclone (_oSQL:Qry2Array ())
	For _nLinha := 1 To Len(_aDados)
		sa1 -> (dbgoto (_aDados [_nLinha, 1]))
		U_LOG (SA1 -> A1_COD)
		U_AtuMerc ("SA1", sa1 -> (recno ()))
	next
return
*/
/*
	cPerg := "VASESCO"
	U_GravaSX1 (cPerg, '01', '2019')
	U_GravaSX1 (cPerg, '02', '08')
	U_GravaSX1 (cPerg, '03', 'c:\temp\sescoop_08.txt')
	U_GravaSX1 (cPerg, '04', 257)  // qt func
	U_GravaSX1 (cPerg, '05', 3)  // admitidos
	U_GravaSX1 (cPerg, '06', 4)  // demitidos
	U_GravaSX1 (cPerg, '07', 1)  // 1=gerar planilha;2=gerar arquivo
	U_GravaSX1 (cPerg, '08', '517/518/519')  // Visoes gerenciais a usar
	U_VA_SESCO (.T.)
return
*/
/*
	// limpa SIX duplicado
	use \robert\six_dupl VIA 'DBFCDXADS' exclusive new alias _dup
	pack
	//u_logtrb ('_dup', .t.)
	//index on indice to &(criatrab ({}, .F.))
	_i = 1
	_nTotReg = _dup -> (reccount ())
	do while _i <= _nTotReg
		u_log (_i) //, _i, 'de', _nTotReg)
		_dup -> (dbgoto (_i))
		_aRegOri = {_dup -> indice, _dup -> ordem, _dup -> chave}
		_j = _i + 1
		do while _j <= _nTotReg
			//u_log ('_j', _j)
			_dup -> (dbgoto (_j))
			if _dup -> indice == _aRegOri [1] .and. _dup -> ordem == _aRegOri [2] .and. _dup -> chave == _aRegOri [3]
				//u_log (_j, 'duplicado')
				_dup -> (dbdelete ())
			endif
			_j ++
		enddo
		_i ++
	enddo
return
*/
/*
	cPerg := "VA_GSE2"
	U_GravaSX1 (cPerg, '01', 'c:\temp\km_cedulas.csv')
	U_GravaSX1 (cPerg, '02', stod ('20191008'))
	U_VA_GSE2 (.t.)
return
*/
/*
	// Ajusta cadastro produtos em lote
	sb1 -> (dbsetorder (1))
	sb5 -> (dbsetorder (1))
	sb1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		if sb1 -> b1_tipo = 'MR' .and. sb1 -> b1_te = '104' .and. sb1 -> b1_clasfis != '60'
			if ! sb5 -> (dbseek (xfilial ("SB5") + sb1 -> b1_cod, .F.))
				u_log ('ERRO: Nao encontrei SB5 para o produto ' + sb1 -> b1_cod)
			else
				u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
				
				// Cria variaveis para uso na gravacao do evento de alteracao
				regtomemory ("SB1", .F., .F.)
				regtomemory ("SB5", .F., .F.)
				m->b1_clasfis = '60'
				m->b5_alttrib = '1'
				
				// Grava evento de alteracao
				_oEvento := ClsEvent():new ()
				_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)

				reclock ("SB1", .f.)
				sb1 -> b1_clasfis = m->b1_clasfis
				msunlock ()
				reclock ("SB5", .f.)
				sb5 -> b5_alttrib = m->b5_alttrib
				msunlock ()
				//exit
			endif
		endif
		sb1 -> (dbskip ())
	enddo
*/
/*
	// Testes classe extrato CC
	_oExtr := ClsExtrCC ():New ()
	//_oExtr:Cod_assoc = '002378'  // compensacao com outro associado
	//_oExtr:Cod_assoc = '001071'  // Silvana Crocoli - tem compensacao com Luis Crocoli em 2012
	//_oExtr:Cod_assoc = '001104'  // Mateus Tansini - hist.compens.incompleto para titulo ADT/300316
	//_oExtr:Cod_assoc = '001287'  // Ricardo Frassini - tem compens.tit.de Ricardo Fabian em 2012 e de Maria Frassini em 2018
	_oExtr:Cod_assoc = '000322'  // nao busca refatura compra safra 2018
	_oExtr:Loja_assoc = '01'
	_oExtr:DataIni = stod ('20190301')
	_oExtr:DataFim = stod ('20190430')
	_oExtr:TMIni = ''
	_oExtr:TMFim = 'zz'
	_oExtr:LerObs = .F.
	_oExtr:LerComp3os = .t.
	_oExtr:TipoExtrato = 'N'
	//_oExtr:FormaResult = 'N'
	//_oExtr:Gera ()
	//u_log ('Extrato retornado:', _oExtr:Resultado)
	u_log (_oExtr:UltMsg)
	_oExtr:FormaResult = 'X'
	_oExtr:Gera ()
	u_log (_oExtr:Resultado)
return
*/
/*
	// Atualiza tabelas de verbas (ZA4 e ZA5) para casos em que o desconto na baixa do contas a receber nao estava gravando (GLPI 6573)
	//se5 -> (dbgoto (1638881)) ; _wNumVerba = '008797'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639278)) ; _wNumVerba = '008799'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639280)) ; _wNumVerba = '008791'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639801)) ; _wNumVerba = '008803'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639925)) ; _wNumVerba = '008804'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639951)) ; _wNumVerba = '008806'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639953)) ; _wNumVerba = '008805'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1640285)) ; _wNumVerba = '008700'; _wValor = se5 -> e5_vadcmpv
	//se5 -> (dbgoto (1639929)) ; _wNumVerba = '008807'; _wValor = se5 -> e5_vadarei
	//se5 -> (dbgoto (1640551)) ; _wNumVerba = '008603'; _wValor = se5 -> e5_vaencar
	//se5 -> (dbgoto (1640277)) ; _wNumVerba = '008295'; _wValor = se5 -> e5_vadarei
	u_logtrb ("SE5")
	se1 -> (dbsetorder (2))  // E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	if ! se1 -> (dbseek (se5 -> e5_filial + se5 -> e5_cliente + se5 -> e5_loja + se5 -> e5_prefixo + se5 -> e5_numero + se5 -> e5_parcela + se5 -> e5_tipo, .F.))
		u_help ('Nao encontrei SE1')
	else
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT MAX(ZA5.ZA5_SEQ)"
		_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA5") + " AS ZA5 "
		_oSQL:_sQuery += "   WHERE D_E_L_E_T_   = ''"
		_oSQL:_sQuery += "     AND ZA5.ZA5_NUM  = '" + @(_wnumverba) + "'"
		_oSQL:Log ()
		_aDados := _oSQL:Qry2Array ()
		_wseq := 0
		if len(_aDados) > 0
			_wseq = _aDados[1,1]
		endif
		if _wseq > 0
			u_log ('Parece que jah tem ZA5')
		else
			if _wValor == 0
				u_log ('Nao achei o valor')
			else
				u_log ('gravando')
				// grava tabela ZA5
				RecLock ("ZA5",.T.)
				za5 -> za5_num     = @(_wnumverba)
				za5 -> za5_seq     = _wseq+1
				za5 -> za5_vlr     = @(_wvalor)
				za5 -> za5_prefix  = se1 -> e1_prefixo
				za5 -> za5_doc     = se1 -> e1_num
				za5 -> za5_parc    = se1 -> e1_parcela
				za5 -> za5_tipo    = se1 -> e1_tipo
				za5 -> za5_cli	   = se1 -> e1_cliente
				za5 -> za5_loja    = se1 -> e1_loja
				za5 -> za5_tlib    = fBuscaCpo ('ZA4', 1, xfilial('ZA4') + @(_wnumverba), "ZA4_TLIB")
				za5 -> za5_usu     = alltrim (cUserName)
				za5 -> za5_dta     = ddatabase
				za5 -> za5_filial  = xFilial("ZA5") 
				MsUnLock()
				_wstatus = '2'
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT SUM(ZA4.ZA4_VLR) - ISNULL( ( SELECT ROUND(SUM(ZA5_VLR),2)"
				_oSQL:_sQuery += "         			      		       FROM " + RetSQLName ("ZA5")
				_oSQL:_sQuery += "       				  		          WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery += "         						        AND ZA5_NUM    = ZA4.ZA4_NUM) ,0) AS VLR_SLD"
				_oSQL:_sQuery += "   FROM " + RetSQLName ("ZA4") + " AS ZA4 "
				_oSQL:_sQuery += "  WHERE D_E_L_E_T_   = ''"
				_oSQL:_sQuery += "    AND ZA4.ZA4_NUM  = '" + @(_wnumverba) + "'"
				_oSQL:_sQuery += "  GROUP BY ZA4.ZA4_NUM "
				_oSQL:Log ()
				_aDados := _oSQL:Qry2Array () //U_Qry2Array(_sQuery)
				_wsaldo := 0
				if len(_aDados) > 0
					_wsaldo = _aDados[1,1]
					if _wsaldo > 0
						_wstatus = '1'
					endif
				endif
				// grava status de utilizacao
				DbSelectArea("ZA4")
				DbSetOrder(1)
				DbSeek(xFilial("ZA4") + @(_wnumverba),.F.)
				RecLock ("ZA4",.F.)
				za4 -> za4_sutl = _wstatus
				MsUnLock()
			endif
		endif
	endif
return
*/
/*
	// Atualiza campo memo migrado de virtual para real
	sa1 -> (dbgotop ())
	do while ! sa1 -> (eof ())
		if empty (sa1 -> a1_vamudou) .and. ! empty (SA1 -> A1_VACMUDO)
			_sContAnt := alltrim (MSMM (SA1 -> A1_VACMUDO))
			if ! empty (_sContAnt)
				u_log (sa1 -> a1_cod, sa1 -> a1_loja, ' memo real:' + alltrim (sa1 -> a1_vamudou) + ' memo antigo: ' + alltrim (_sContAnt))
				reclock ("SA1", .F.)
				sa1 -> a1_vamudou = _sContAnt
				msunlock ()
			endif
		endif
		sa1 -> (dbskip ())
	enddo
return
*/
/*
	// Ajusta cadastro clientes em lote - GLPI ??? - Caiu a ST dos vinhso para RS em 01/08/2019
	sa1 -> (dbsetorder (1))
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT SA1.R_E_C_N_O_, A1_COD"
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA1") + " SA1 "
	_oSQL:_sQuery +=  " WHERE SA1.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND SA1.A1_FILIAL = '" + xfilial ("SA1") + "'"
	_oSQL:_sQuery +=    " AND A1_TIPO = 'S' AND A1_EST = 'RS' and A1_VAREGE != '2'"
	_oSQL:_sQuery +=  " ORDER BY A1_COD"
	_oSQL:Log ()
	_aDados = _oSQL:Qry2Array ()
	u_log (_aDados)
	for _i = 1 to len (_aDados)
		sa1 -> (dbgoto (_aDados [_i, 1]))
		u_log ('Verificando cli.', sa1 -> a1_cod, _i / len (_aDados) * 100, '%')

		// Cria variaveis para uso na gravacao do evento de alteracao
		regtomemory ("SA1", .F., .F.)
		m->a1_varege = '2'
		
		// Grava evento de alteracao
		_oEvento := ClsEvent():new ()
		_oEvento:AltCadast ("SA1", m->a1_cod, sa1 -> (recno ()), '', .F.)

		reclock ("SA1", .f.)
		sa1 -> a1_varege = m->a1_varege
		msunlock ()
		//exit
	next
return
*/
/*
	// Ajusta cadastro produtos em lote (itens das lojas)
	sb1 -> (dbsetorder (1))
	sb5 -> (dbsetorder (1))
	sb1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		if sb1 -> b1_tipo = 'PA' .and. ! empty (sb1 -> b1_codpai)
			if ! sb5 -> (dbseek (xfilial ("SB5") + sb1 -> b1_cod, .F.))
				u_log ('ERRO: Nao encontrei SB5 para o produto ' + sb1 -> b1_cod)
			else
				u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
				if sb1 -> B1_CODBAR != sb1 -> B1_VAEANUN ;
					.and. substr (sb1 -> b1_codbar, 1, 8) != '78961005' ;
					.and. substr (sb1 -> b1_vaeanun, 1, 8) = '78961005' ;
					.and. ! "EXP" $ sb1 -> b1_desc  // Itens de exportacao jah estao corretos
				
					// Cria variaveis para uso na gravacao do evento de alteracao
					regtomemory ("SB1", .F., .F.)
					regtomemory ("SB5", .F., .F.)
					m->b1_codgtin = ''
					m->b1_codbar  = sb1 -> b1_vaeanun
					m->b5_2codbar = ''
					m->b5_convdip = 0
					m->b5_umdipi  = ''
					
					// Grava evento de alteracao
					_oEvento := ClsEvent():new ()
					_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
					
					reclock ("SB1", .f.)
					sb1 -> b1_codgtin = m->b1_codgtin
					sb1 -> b1_codbar = m->b1_codbar
					msunlock ()
					reclock ("SB5", .f.)
					sb5 -> b5_2codbar = m->b5_2codbar
					sb5 -> b5_convdip = m->b5_convdip
					sb5 -> b5_umdipi  = m->b5_umdipi
					msunlock ()
				else
					u_log ('nada a alterar')
				endif
			endif
		endif
		sb1 -> (dbskip ())
	enddo

	// Ajusta cadastro produtos em lote (PAs vendidos em caixas)
	sb1 -> (dbsetorder (1))
	sb5 -> (dbsetorder (1))
	sb1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		if sb1 -> b1_tipo = 'PA' .and. empty (sb1 -> b1_codpai)
			if ! sb5 -> (dbseek (xfilial ("SB5") + sb1 -> b1_cod, .F.))
				u_log ('ERRO: Nao encontrei SB5 para o produto ' + sb1 -> b1_cod)
			else
				u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
				if ! '789' $ sb1 -> b1_codbar .and. ! "EXP" $ sb1 -> b1_desc  // exportacao jah estao corretos
					if sb1->b1_codbar != sb1 -> b1_vaDunCx .or. sb5->b5_2codbar != sb1 -> b1_vaEanUn .or. sb5->b5_convdip != sb1 -> b1_conv .or. sb5->b5_umdipi != sb1 -> b1_segum
				
						// Cria variaveis para uso na gravacao do evento de alteracao
						regtomemory ("SB1", .F., .F.)
						regtomemory ("SB5", .F., .F.)
						m->b1_codgtin = ''
						if left (sb1 -> b1_vaduncx, 3) != '000' 
							m->b1_codbar  = sb1 -> b1_vaDunCx
						endif
						if substr (sb1 -> b1_vaeanun, 1, 3) = '789'
							m->b5_2codbar = sb1 -> b1_vaEanUn
						endif
						m->b5_convdip = sb1 -> b1_convml
						m->b5_umdipi  = sb1 -> b1_segum
						
						// Grava evento de alteracao
						_oEvento := ClsEvent():new ()
						_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
						
						reclock ("SB1", .f.)
						sb1 -> b1_codgtin = m->b1_codgtin
						sb1 -> b1_codbar = m->b1_codbar
						msunlock ()
						reclock ("SB5", .f.)
						sb5 -> b5_2codbar = m->b5_2codbar
						sb5 -> b5_convdip = m->b5_convdip
						sb5 -> b5_umdipi  = m->b5_umdipi
						msunlock ()
						//exit
					else
						u_log ('nada a alterar')
					endif
				endif
			endif
		endif
		sb1 -> (dbskip ())
	enddo
return
*/
/*	// Ajusta cadastro de produtos em lote (altera unidades conforme cadastro da caixa)
	sb1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		if sb1 -> b1_tipo == 'PA' .and. ! empty (sb1 -> b1_codpai)
			_aArea := sb1 -> (getarea ())
			_sLinPai = posicione ("SB1", 1, xfilial ("SB1") + sb1 -> b1_codpai, "B1_VALINEN")
			_sDescPai = sb1 -> b1_desc
			sb1 -> (restarea (_aArea))
			if ! empty (_sLinPai) .and. alltrim (_sLinPai) != '999' .and. _sLinPai != sb1 -> b1_vaLinEn
				u_log (sb1 -> b1_cod, sb1 -> b1_desc, sb1 -> b1_valinen, '->', _sLinPai, '(', sb1 -> b1_codpai, _sDescPai)
				_sCodAnt = sb1 -> b1_valinen
				reclock ("SB1", .f.)
				sb1 -> b1_valinen = _sLinPai
				msunlock ()
				_oEvento := ClsEvent ():New ()
				_oEvento:Produto  = sb1 -> b1_cod
				_oEvento:Texto   += "Produto " + alltrim (sb1 -> b1_cod) + "-" + alltrim (sb1 -> b1_desc) 
				_oEvento:Texto   += chr (13) + chr (10)
				_oEvento:Texto   += "Campo B1_VALINEN (" + alltrim (RetTitle ("B1_VALINEN")) + "):"
				_oEvento:Texto   += " alterado de '" + alltrim (_sCodAnt) + "' para '" + alltrim (sb1 -> b1_valinen) + "' cfe. cadastro do codigo pai."
				_oEvento:Alias    = 'SB1'
				_oEvento:CodEven  = "ALT001"
				_oEvento:CodAlias = sb1 -> b1_cod
				_oEvento:Recno    = sb1 -> (recno ())
				//u_log (_oEvento:Texto)
				_oEvento:Grava ()
				//exit
			endif
		endif
		sb1 -> (dbskip ())
	enddo
	u_log ('finalizado')
return
*/
/* PE apos gravacao da aprovacao da solicitacao de compras
user function MT110CFM ()
	u_logIni ()
	u_log (paramixb [1])  // numero da SC
	u_log (paramixb [2])  // 1-aprovada;2-rejeitada;3-bloqueada
	U_LOGTRB ("sc1")  // encontra-se posicionado na SC. quando mv_par02==2 (por SC) chama apenas 1 vez e vem posicionada no item 0001
	if mv_par02 == 1  // por item
		reclock ("SC1", .F.)
		// campo ainda nao criado ---> sc1 -> vaDtLib = date ()
		msunlock ()
	else  // por SC
		// fazer um update por SQL em todos os itens da SC
	endif
	// gravar evento de liber/bloueio/rejeicao da SC
	u_logFim ()
return
*/
/*
	_sDocZAG := '0000000040'
	zag -> (dbsetorder (1))  // ZAG_FILIAL+ ZAG_DOC
	if ! zag -> (dbseek (xfilial ("ZAG") + _sDocZAG, .F.))
		u_help ("Documento '" + _sDocZAG + "' nao localizado na tabela ZAG")
	else
		_oTrEstq := ClsTrEstq ():New (zag -> (recno ()))
		_oTrEstq:Executa () //Libera ()
	endif
return
*/
/*
	// Testes classe transf.estq.
	private _sErroAuto := ''
	_oTrEstq := ClsTrEstq ():New ()
	_oTrEstq:FilOrig = cFilAnt
	_oTrEstq:FilDest = cFilAnt
	_oTrEstq:DtEmis  = date ()
	//_oTrEstq:OP = '1234561212312'
	_oTrEstq:Motivo = 'teste robert (ZAG)' 
	_oTrEstq:ProdOrig = '4072           '
	_oTrEstq:ProdDest = '4072           '
	_oTrEstq:AlmOrig = '02'
	_oTrEstq:AlmDest = '08'
	//_oTrEstq:EndOrig = 'a'
	//_oTrEstq:EndDest = 'b'
	//_oTrEstq:LoteOrig = '1'
	//_oTrEstq:LoteDest = '2'
	_oTrEstq:QtdSolic = 1 
	_oTrEstq:UsrIncl  = 'robert.koch'
	if _oTrEstq:Grava ()
		u_log ('gravou!', _oTrEstq:UltMsg)
		//u_logObj (_oTrEstq)
		if _oTrEstq:Libera ()
			u_log ('Liberou!', _oTrEstq:UltMsg)
		else
			u_help (_oTrEstq:UltMsg)
		endif
		if _oTrEstq:Exclui ()
			u_log ('Excluiu!', _oTrEstq:UltMsg)
		else
			u_help (_oTrEstq:UltMsg)
		endif
	endif
return
*/
/*
	// Migra memo virtual para real no SZN.
	_NgRAVADO := 0
	_nVazio := 0
	szn -> (dbgotop ())
	do while ! szn -> (eof ())
		if ! empty (szn -> zn_codmemo) .AND. Empty (szn -> zn_txt)
			_sTexto = msmm (szn -> zn_codmemo,,,,3)
			if ! empty (_sTexto)
				reclock ("SZN", .F.)
				szn -> zn_txt = _sTexto
				msunlock ()
				_nGravado ++
			else
				_nVazio ++
			endif
		endif
		szn -> (dbskip ())
		if szn -> (recno ()) % 1000 == 0
			u_log (szn -> (recno ()))
		endif
	enddo
	u_log ('Gravados:', _nGravado)
	u_log ('vazios:', _nVazio)
	u_log ('finalizado')
return
*/
/*
	// Limpa registros duplicados
	sx7 -> (dbsetorder (1))
	sx7 -> (dbgotop ())
	do while ! sx7 -> (eof ())
		_sCampo = sx7 -> x7_campo
		_sSeq = sx7 -> x7_sequenc
		_sCDomin = sx7 -> x7_cdomin
		_sRegra = sx7 -> x7_regra
		_sTipo = sx7 -> x7_tipo
		_sSeek = sx7 -> x7_seek
		_sAlias = sx7 -> x7_alias
		_nOrdem = sx7 -> x7_ordem
		_sChave = sx7 -> x7_chave
		_sCondic = sx7 -> x7_condic
		
		sx7 -> (dbskip ())
		
		if sx7 -> x7_campo == _sCampo .and. sx7 -> x7_sequenc == _sSeq .and. sx7 -> x7_cdomin == _sCDomin .and. sx7 -> x7_regra == _sRegra .and. _sTipo = sx7 -> x7_tipo .and. sx7 -> x7_seek == _sSeek .and. sx7 -> x7_alias == _sAlias ;
			.and. sx7 -> x7_ordem == _nOrdem .and. sx7 -> x7_chave == _sChave .and. sx7 -> x7_condic == _sCondic
			u_log ('encontrei duplicidade para', _sCampo, _sSeq, _sCDomin, _sRegra)
			reclock ("SX7", .f.)
			sx7 -> (dbdelete ())
			msunlock ()
		//else
			//sx7 -> (dbskip ())
		endif
	enddo
	u_log ('finalizado')
return
*/
/*
	// Gera precos para as pre-notas de compra de safra.
	Private cPerg   := "VAZZ9P"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // produto ini
	U_GravaSX1 (cPerg, '07', 'z')    // fim
	U_GravaSX1 (cPerg, '08', 3)      // tipos uvas {"Comuns","Finas","Todas"}
	U_GravaSX1 (cPerg, '09', 2)      // regrava com NF ja gerada {"Sim", "Nao"}
	U_GravaSX1 (cPerg, '10', 1)      // regrava com obs {"Regrava","Nao altera"}
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'O')    // parcela ini
	U_GravaSX1 (cPerg, '14', 'O')    // parcela final
	U_GravaSX1 (cPerg, '15', 2)      // regrava se ja tiver preco {"Sim", "Nao"}
	U_VA_ZZ9P (.t.)
return
*/
/*
	// Recalcula saldos associados (ZZM)
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ZZM_ASSOC, ZZM_LOJA"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("ZZM") + " ZZM "
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = '*'"
	_oSQL:_sQuery +=    " AND ZZM_ERRSAL = 'S'"
	_oSQL:_sQuery +=    " AND ZZM_ASSOC  = '002498'"
	_oSQL:_sQuery +=  " ORDER BY ZZM_ASSOC, ZZM_LOJA"
	_aAssoc = _oSQL:Qry2Array ()
	for _i = 1 to len (_aAssoc)
		_oAssoc := ClsAssoc():New (_aAssoc [_i, 1], _aAssoc [_i, 2])
		u_logIni (_oAssoc:Codigo + "/" + _oAssoc:Loja)
		_oSQL := ClsSQL ():New ()
		//_oSQL:_sQuery := "update ZZM010 SET D_E_L_E_T_ = '*', R_E_C_D_E_L_ = R_E_C_N_O_ WHERE ZZM_ASSOC = '" + _oAssoc:Codigo + "' and ZZM_LOJA = '" + _oAssoc:Loja + "'"
		//_oSQL:Exec ()
		_oAssoc:AtuSaldo (DATE ())
		u_logFim (_oAssoc:Codigo + "/" + _oAssoc:Loja)
	next
return
*/
/*
	_oSQL := ClsSQL ():New ()
	use \robert\sld_ZZM VIA 'DBFCDXADS' shared new alias _sld
	//u_logtrb ("_sld", .t.)
	_sld -> (dbgotop ())
	do while ! _sld -> (eof ())
		_oSQL:_sQuery := "UPDATE ZZM010 SET ZZM_ERRSAL = 'S'"
		_oSQL:_sQuery += " WHERE ZZM_ASSOC = '" + strzero (val (_sld -> assoc), 6) + "'"
		_oSQL:_sQuery +=   " AND ZZM_DATA  = '" + strzero (_sld -> ano, 4) + "1231'"
		_oSQL:Log ()
		_oSQL:Exec ()
		_sld -> (dbskip ())
	enddo
return
*/
/*
	// Geracao pre-notas compra safra 2019
	// grupo A - bordo
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'G')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '9925/9822/9948/9959') // Apenas estas variedades (bordo, bordo de bordadura/em conversao/organico)
	U_GravaSX1 (cPerg, '15', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'A')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
	// 
	// grupo A - organicas
	// exceto bordo, jah gerado anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'H')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'O')    // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'A')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
	// 
	// grupo B - tintoreas
	// exceto bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'I')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'B')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
	// 
	// grupo B - viniferas espaldeira
	// exceto tintoreas, bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'J')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 2)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'B')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '2')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
	// 
	// grupo C - viniferas latadas
	// exceto tintoreas, bordo e organicas, jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'K')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 2)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'C')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '1')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
	//
	// grupo C - demais
	// exceto tintoreas, bordo e organicas, viniferas jah geradas anteriormente
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'z')    // Filial final
	U_GravaSX1 (cPerg, '11', 'L')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 1)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_GravaSX1 (cPerg, '19', 'C')    // Grupo para pagamento
	U_GravaSX1 (cPerg, '20', '3')    // 1=Latadas; 2=Espaldeira; 3=Todas
	U_VA_GNF1 (.T.)
return
*/

/*
	Private cPerg   := "VA_EID"
	U_GravaSX1 (cPerg, '01', '')  // NF entr - forn
	U_GravaSX1 (cPerg, '02', '')  // NF entr - loja
	U_GravaSX1 (cPerg, '03', '')  // NF entr - numeros separados por barras
	U_GravaSX1 (cPerg, '04', '')  // NF entr - serie
	U_GravaSX1 (cPerg, '05', '000009885')  // NF saida - numeros separados por barras
	U_GravaSX1 (cPerg, '06', '10 ')  // NF saida - serie
	U_GravaSX1 (cPerg, '07', 2)  // Exportar registros deletados S/N
	U_VA_EID (.t.)
return
*/

//	u_batBL01 ('01', '2019', '0698')
//	u_batBL01 ('01', '2019', '1373')
//	u_batBL01 ('01', '2019', '1386')
//	u_batBL01 ()
//return

// nao deu resultado
//user function MT242CPO ()
//	u_help (procname ())
//return {"D3_VAMOTIV","D3_VAETIQ"}
/*
	// Reavalia classificacao das uvas viniferas safra 2019
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT FILIAL, SAFRA, CARGA "
	_oSQL:_sQuery +=  " FROM VA_VCARGAS_SAFRA"
	_oSQL:_sQuery += " WHERE SAFRA = '2019' AND FILIAL = '" + xfilial ("SZE") + "'"
	_oSQL:_sQuery +=   " AND VARUVA = 'F' and STATUS != 'C'"
	_oSQL:_sQuery +=   " AND ASSOCIADO = '004927' AND PRODUTO = '9979' and STATUS != 'C'"
	_oSQL:_sQuery += " ORDER BY CARGA"
	_oSQL:Log ()
	_aCargas = _oSQL:Qry2Array ()
//	u_log (_aCargas)
	for _nCarga = 1 to len (_aCargas)
		szf -> (dbsetorder (1))  // filial + safra + carga + item
		sze -> (dbsetorder (1))
		if sze -> (dbseek (_aCargas [_nCarga, 1] + _aCargas [_nCarga, 2] + _aCargas [_nCarga, 3], .T.))
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT SITUACAO,"
			_oSQL:_sQuery +=        " VAR_NAO_PREV_CAD_VIT as VarNaoPrev,"
			_oSQL:_sQuery +=        " ENTREGOU_CADERNO_CPO as EntrCad,"
			_oSQL:_sQuery +=        " BOTRYTIS_PATIO as BOTRYP, "
			_oSQL:_sQuery +=        " BOTRYTIS_TOMBADOR AS BOTRYT, "
			_oSQL:_sQuery +=        " GLOMERELLA_PATIO as GlomeP, "
			_oSQL:_sQuery +=        " GLOMERELLA_TOMBADOR as GlomeT, "
			_oSQL:_sQuery +=        " ASPERGILLUS_PATIO as AsperP, "
			_oSQL:_sQuery +=        " ASPERGILLUS_TOMBADOR as AsperT, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_PATIO as PodriP, "
			_oSQL:_sQuery +=        " PODRIDAO_ACIDA_TOMBADOR as PodriT, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_PATIO as AcVolP, "
			_oSQL:_sQuery +=        " ACIDEZ_VOLATIL_TOMBADOR as AcVolT, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_PATIO as MEstrP, "
			_oSQL:_sQuery +=        " MATERIAIS_ESTRANHOS_TOMBADOR as MEstrT, "
			_oSQL:_sQuery +=        " DESUNIFORMIDADE_MATURACAO_PATIO as DesunP, "
			_oSQL:_sQuery +=        " DESUNIFORMIDADE_MATURACAO_TOMBADOR as DesunT, "
			_oSQL:_sQuery +=        " MISTURA_VARIEDADES as Mistu"
			_oSQL:_sQuery +=   " FROM VA_VINSPECOES_SAFRA"
			_oSQL:_sQuery +=  " WHERE SAFRA  = '" + sze -> ze_safra  + "'"
			_oSQL:_sQuery +=    " AND FILIAL = '" + sze -> ze_filial + "'"
			_oSQL:_sQuery +=    " AND CARGA  = '" + sze -> ze_carga  + "'"
			//_oSQL:Log ()
			_sAliasInsp = _oSQL:Qry2Trb (.F.)

			// Alimenta array de inspecoes. Deve estar previamente criada como 'private' na rotina chamadora.
			_aRusInsp = aclone (afill (array (.InspecoesSafraQtColunas), ''))

			if (_sAliasInsp) -> (eof ())
				// Se nao encontou inspecao, assume status vazio e nao conforme para facilitar nos testes posteriores.
				_aRusInsp [.InspecoesSafraSituacao]         = '   '
				_aRusInsp [.InspecoesSafraVarNaoPrevCadVit] = 'N'  // N='Nao teve nenhuma variedade nao prevista no cadastro viticola'
				_aRusInsp [.InspecoesSafraEntrCadCpo]       = 'S'  // S='entregou caderno de campo'
				_sInspBotr = ''
				_sInspGlom = ''
				_sInspAspe = ''
				_sInspPodr = ''
				_sInspAcid = ''
				_sInspMEst = ''
				_sInspDesu = ''
			else
				_aRusInsp [.InspecoesSafraSituacao]          = (_sAliasInsp) -> situacao
				_aRusInsp [.InspecoesSafraVarNaoPrevCadVit]  = (_sAliasInsp) -> VarNaoPrev
				_aRusInsp [.InspecoesSafraEntrCadCpo]        = (_sAliasInsp) -> EntrCad
				_aRusInsp [.InspecoesSafraMisturaNoTombador] = (_sAliasInsp) -> Mistu

				// Se tem resultado na inspecao de tombador, melhor. Senao, pega a de patio.
				_sInspBotr = iif (! empty ((_sAliasInsp) -> BotryT), (_sAliasInsp) -> BotryT, (_sAliasInsp) -> BotryP)
				_sInspGlom = iif (! empty ((_sAliasInsp) -> GlomeT), (_sAliasInsp) -> GlomeT, (_sAliasInsp) -> GlomeP)
				_sInspAspe = iif (! empty ((_sAliasInsp) -> AsperT), (_sAliasInsp) -> AsperT, (_sAliasInsp) -> AsperP)
				_sInspPodr = iif (! empty ((_sAliasInsp) -> PodriT), (_sAliasInsp) -> PodriT, (_sAliasInsp) -> PodriP)
				_sInspAcid = iif (! empty ((_sAliasInsp) -> AcVolT), (_sAliasInsp) -> AcVolT, (_sAliasInsp) -> AcVolP)
				_sInspMEst = iif (! empty ((_sAliasInsp) -> MEstrT), (_sAliasInsp) -> MEstrT, (_sAliasInsp) -> MEstrP)
				_sInspDesu = iif (! empty ((_sAliasInsp) -> DesunT), (_sAliasInsp) -> DesunT, (_sAliasInsp) -> DesunP)
			endif
			(_sAliasInsp) -> (dbclosearea ())
			dbselectarea ("SZE")
			
			//u_log ('inspecoes:', _aRusInsp)

			sb1 -> (dbsetorder (1))
			szf -> (dbsetorder (1))  // filial + safra + carga + item
			szf -> (dbseek (xfilial ("SZF") + sze -> ze_safra + sze -> ze_carga, .T.))
			do while ! szf -> (eof ()) .and. szf -> zf_filial == xfilial ("SZF") .and. szf -> zf_safra == sze -> ze_safra .and. szf -> zf_carga == sze -> ze_carga
				if ! sb1 -> (dbseek (xfilial ("SB1") + szf -> zf_produto, .F.))
					u_log ('Produto nao cadastrado:', szf -> zf_produto)
				else
					if sb1 -> b1_varuva == 'F' .and. sb1 -> b1_vafcuva == 'F'
						_aClasFina = aclone (U_ClUva19 (szf -> zf_produto, val (szf -> zf_grau), szf -> zf_conduc, val (_sInspBotr), val (_sInspGlom), val (_sInspAspe), val (_sInspPodr), val (_sInspAcid), _sInspMEst, val (_sInspDesu)))

						// Assume as classificoes calculadas somente se encontrou dados de inspecao no NaWeb. Senao, assume valores medios.
						if empty (_sInspBotr) .or. empty (_sInspGlom) .or. empty (_sInspAspe) .or. empty (_sInspPodr) .or. empty (_sInspAcid) .or. empty (_sInspMEst) .or. empty (_sInspDesu)
							u_log ('Nao tenho os dados de inspecoes. Assumindo valores medios.')
							if szf -> zf_prm03 != 'B' .or. szf -> zf_prm04 != 'B' .or. szf -> zf_prm05 != 'B'
								u_log ('Classificacoes deveriam estar padrao B por falta de dados no naweb')
							endif
						endif
						
						// Verifica se ficou diferente do calculado.
						if szf -> zf_prm02 != _aClasFina [1] ;
							.or. szf -> zf_prm03 != _aClasFina [2] ;
							.or. szf -> zf_prm04 != _aClasFina [3] ;
							.or. szf -> zf_prm05 != _aClasFina [4] ;
							.or. (szf -> zf_conduc == 'L' .and. szf -> zf_clasABD != _aClasFina [5]) ;
							.or. (szf -> zf_conduc == 'E' .and. szf -> zf_prm99 != _aClasFina [5])
							_sMsg := '  acucar:[' + szf -> zf_prm02 + ' deveria ser ' + _aClasFina [1] + ']'
							_sMsg += '  sanid.:[' + szf -> zf_prm03 + ' deveria ser ' + _aClasFina [2] + ']'
							_sMsg += '  matur.:[' + szf -> zf_prm04 + ' deveria ser ' + _aClasFina [3] + ']'
							_sMsg += '  mt.estr[' + szf -> zf_prm05 + ' deveria ser ' + _aClasFina [4] + ']'
							_sMsg += '  final: [abd:' + szf -> zf_clasABD + '  prm99:' + szf -> zf_prm99 + ' deveria ser ' + _aClasFina [5] + ']'
							_sMsg += ' ' + DTOC (sze -> ze_data)
							_sMsg += ' ' + alltrim (posicione ("SB1", 1, xfilial ("SB1") + SZF -> zf_produto, "B1_DESC")) 
							_sMsg += ' grau ' + szf -> zf_grau
							_sMsg += ' de ' + alltrim (posicione ("SA2", 1, xfilial ("SA2") + sze -> ze_assoc + sze -> ze_lojasso, "A2_NOME"))
							u_log ('carga', szf -> zf_carga, _sMsg)
						endif
					endif
				endif
				szf -> (dbskip ())
			enddo
		endif
	next
	u_log ('finalizado.')
return
*/
/*
	Private cPerg   := "VAXLS42"
	U_GravaSX1 (cPerg, '01', '2019')  // safra
	U_GravaSX1 (cPerg, '02', stod ('20190101'))  // data ini
	U_GravaSX1 (cPerg, '03', stod ('20191231'))  // data fim
	u_va_xls42 (.T.)
return
*/
/*	// LISTA CAMPOS OBRIGATORIOS
	sx3 -> (dbsetorder (1))
	sx3 -> (dbseek ('SD1', .t.))
	do while ! sd3 -> (eof ()) .and. sx3 -> x3_arquivo == 'SD1'
		if (x3uso(SX3->X3_USADO) .and. ((SubStr(BIN2STR(SX3->X3_OBRIGAT),1,1) == "x") .or. VerByte(SX3->x3_reserv,7)))
			u_log (sx3 -> x3_campo)
		endif
		sx3 -> (dbskip ())
	enddo
return
*/
/*
	Private cPerg   := "VAGNF2"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2019') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Parcelas sep.barras (bco=todas)
	U_GravaSX1 (cPerg, '07', 'C')    // Grupos
	U_GravaSX1 (cPerg, '08', 3)      // Geracao por DCO: {"Com DCO", "Sem DCO", "Todos"}
	U_GravaSX1 (cPerg, '09', 2)      // fina/comum: {"Comum", "Fina", "Todas"}
	U_GravaSX1 (cPerg, '10', 1)      // tipo NF: {"Normais", "Compl.preco"}
	U_GravaSX1 (cPerg, '11', '801')     // Cond pagto
	u_va_gnf2 (.t.)
return
*/
/*
	Private cPerg   := "VAXLS19"
	U_GravaSX1 (cPerg, '01', '')  // assoc ini
	U_GravaSX1 (cPerg, '02', '')  // loja ini
	U_GravaSX1 (cPerg, '03', '000200')  // assoc fim
	U_GravaSX1 (cPerg, '04', 'z')  // loja fim
	U_GravaSX1 (cPerg, '05', 1)  // ativos/inat/todos
	U_GravaSX1 (cPerg, '06', 2)  // listar capital social
	U_GravaSX1 (cPerg, '07', 1)  // listar endereco
	U_GravaSX1 (cPerg, '08', 2)  // listar DAP
	U_GravaSX1 (cPerg, '09', 1)  // lista grupo familiar
	U_GravaSX1 (cPerg, '10', 2)  // lista ultima safra
	U_GravaSX1 (cPerg, '11', stod ('20190311'))
	U_VA_XLS19 (.t.)
RETURN
*/
/*
	// importa planilha com cadastro de DAPs dos associados
	use \robert\dap VIA 'DBFCDXADS' shared new alias _dap
	//u_logtrb ('_dap', .T.)
	_dap -> (dbgotop ())
	do while ! _dap -> (eof ())
		_sCPF = substring (_dap -> cpf, 2, 3) + substring (_dap -> cpf, 6, 3) + substring (_dap -> cpf, 10, 3) + substring (_dap -> cpf, 14, 2)
		u_log (_sCPF)
		sa2 -> (dbsetorder (3))  // A2_FILIAL+A2_CGC
		if sa2 -> (dbseek (xfilial ("SA2") + _sCPF, .F.))
			_oAssoc := ClsAssoc ():New (sa2 -> a2_cod, sa2 -> a2_loja, .F.)
			sa2 -> (dbsetorder (1))
			if sa2 -> (dbseek (xfilial ("SA2") + _oAssoc:CodBase + _oAssoc:LojaBase, .F.))
				if alltrim(sa2 -> A2_VANRDAP) != alltrim (_dap -> dap) .or. sa2 -> A2_VAVLDAP != stod (_dap -> valid) .or. sa2 -> A2_VAENDAP != _dap -> enq
					u_log ('Vou atualizar no CPF', sa2 -> a2_cgc)
					_aAutoSA2 := {}
					aadd (_aAutoSA2, {"A2_COD",     sa2 -> a2_cod, NIL})
					aadd (_aAutoSA2, {"A2_LOJA",    sa2 -> a2_loja, NIL})
					aadd (_aAutoSA2, {"A2_VANRDAP", alltrim (_dap -> dap), NIL})
					aadd (_aAutoSA2, {"A2_VAVLDAP", stod (_dap -> valid), NIL})
					aadd (_aAutoSA2, {"A2_VAENDAP", _dap -> enq, NIL})
					_aAutoSA2 := aclone (U_OrdAuto (_aAutoSA2))
					//u_log (_aAutoSA2)
					lMSErroAuto := .F.
					lMSHelpAuto := .F.
					private _sErroAuto  := ""
					MSExecAuto ({|_x, _y| MATA020 (_x, _y)}, _aAutoSA2, 4)
					if lMSErroAuto
						_sErro := memoread (NomeAutoLog ())
						u_log ('Erro:', _sErro)
					endif
					if ! empty (_sErroAuto)
						u_log (_sErroAuto)
					endif
				else
					u_log ('Jah estava correto')
				endif
			else
				u_help ("Loja base do associado nao encontrada")
			endif
		else
			u_help ('CPF nao encontrado:', _sCPF)
		endif
		_dap -> (dbskip ())
	enddo
	_dap -> (dbclosearea ())
	u_log ('Finalizado')
return
*/
/*
	Private cPerg   := "VA_ECM"
	U_GravaSX1 (cPerg, '01', '02/2018')
	U_GravaSX1 (cPerg, '02', '01/2019')
	U_GravaSX1 (cPerg, '03', '')
	U_GravaSX1 (cPerg, '04', 'z')
	U_GravaSX1 (cPerg, '05', '')
	U_GravaSX1 (cPerg, '06', '1183')
	U_GravaSX1 (cPerg, '07', '')
	U_GravaSX1 (cPerg, '08', 'z')
	U_GravaSX1 (cPerg, '09', 1)
	U_GravaSX1 (cPerg, '10', '')
	U_GravaSX1 (cPerg, '11', 'z')
	U_GravaSX1 (cPerg, '12', '')
	U_GravaSX1 (cPerg, '13', 'z')
	U_GravaSX1 (cPerg, '14', 1)
	U_GravaSX1 (cPerg, '15', 1)
	U_GravaSX1 (cPerg, '16', 1)
	U_VA_ECM (.t.)
return
*/
/*
	Private cPerg   := "VA_COP"
	U_GravaSX1 (cPerg, '01', stod ('20150101'))
	U_GravaSX1 (cPerg, '02', stod ('20150131'))
	U_GravaSX1 (cPerg, '03', 1)
	U_GravaSX1 (cPerg, '04', '2444')
	U_GravaSX1 (cPerg, '05', '2445')
	U_GravaSX1 (cPerg, '06', '')
	U_GravaSX1 (cPerg, '07', '')
	U_GravaSX1 (cPerg, '08', 'z')
	U_GravaSX1 (cPerg, '09', '')
	U_GravaSX1 (cPerg, '10', 'z')
	U_GravaSX1 (cPerg, '11', '')
	U_GravaSX1 (cPerg, '12', 'z')
	U_GravaSX1 (cPerg, '13', '')
	U_VA_COP ()
return
*/
/*
	// Exclui distribuicao de sobras gerada com erro (GLPI 5254)
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT R_E_C_N_O_"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SZI") + " SZI"
	_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND SZI.ZI_FILIAL = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery += " AND SZI.ZI_TM = '19'"
	_oSQL:_sQuery += " AND SZI.ZI_SALDO = SZI.ZI_VALOR"
	_oSQL:_sQuery += " AND SZI.ZI_DATA = '20160331'"
	_oSQL:_sQuery += " AND SZI.ZI_PARCELA = '1'"
	_oSQL:_sQuery += " AND SZI.ZI_ASSOC NOT IN ('004348', '003154')"  // isolda longo e neusa ceccato
	_oSQL:_sQuery += " and not exists (SELECT *"
	_oSQL:_sQuery +=                   " FROM " + RetSQLName ("SZI") + " S"
	_oSQL:_sQuery +=                  " WHERE S.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND S.ZI_FILIAL = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery +=                    " AND S.ZI_TM = '09'"
	_oSQL:_sQuery +=                    " AND S.ZI_DATA >= '20180101'"
	_oSQL:_sQuery +=                    " AND S.ZI_ASSOC = SZI.ZI_ASSOC"
	_oSQL:_sQuery +=                    " AND S.ZI_LOJASSO = SZI.ZI_LOJASSO)"
	_oSQL:_sQuery += " and not exists (SELECT *"
	_oSQL:_sQuery +=                   " FROM " + RetSQLName ("SZI") + " S"
	_oSQL:_sQuery +=                  " WHERE S.D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                    " AND S.ZI_FILIAL = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery +=                    " AND S.ZI_TM IN ('11','27')"
	_oSQL:_sQuery +=                    " AND S.ZI_ASSOC = SZI.ZI_ASSOC"
	_oSQL:_sQuery +=                    " AND S.ZI_LOJASSO = SZI.ZI_LOJASSO)"
	_oSQL:_sQuery += " ORDER BY ZI_DATA, ZI_ASSOC"
	_oSQL:Log ()
	_aDados = aclone (_oSQL:Qry2Array ())
	for _nLinha := 1 to len (_aDados)
		SZI -> (dbgoto (_aDados [_nLinha, 1]))
		u_log (szi -> zi_assoc, szi -> zi_lojasso, szi -> zi_nomasso, szi -> zi_histor)
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		// desabilitei este linha pra evitar compilar por engano... _oCtaCorr:Exclui ()
		u_log (_oCtaCorr:UltMsg)
	next
	u_log ('Processo finalizado')
return
*/

/*	// Gera SE2 para lcto especifico do SZI
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT R_E_C_N_O_"
	_oSQL:_sQuery +=   " FROM " + RetSqlName ("SZI") + " SZI "
	_oSQL:_sQuery +=  " WHERE SZI.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=    " AND SZI.ZI_TM = '19'"
	_oSQL:_sQuery +=    " AND SZI.ZI_ASSOC = '003603'"
	_oSQL:_sQuery +=    " AND SZI.ZI_LOJASSO = '02'"
	_oSQL:_sQuery +=    " AND SZI.ZI_SEQ = '000005'"
	_aDados = _oSQL:Qry2Array ()
	for _i = 1 to len (_aDados)
		szi -> (dbgoto (_aDados [_i, 1]))
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		u_logobj (_oCtaCorr)
		dDataBase = stod ('20160331')
		u_log (_oCtaCorr:GeraSE2 (_oCtaCorr:OQueGera (), _oCtaCorr:DtMovto, .F.))
		u_log (_oCtaCorr:UltMsg)
	next
return
*/
//	U_ClUva19 ('9908           ', 15.0, 'L', 0, 0, 0, 0, 0, 'mdio', 0)
//	U_ClUva19 ('9963           ', 14.0, 'E', 0, 0, 0, 0, 0, 'mdio', 0)  // cab.sauv.p/esp
//	U_ClUva19 ('9908           ', 24.0, 'E', 0, 0, 0, 0, 0, 'ausente', 0)

//	u_log (U_PrcUva19 ('03', '9902', 15, 'B', 'E', .T.))  // chardonnay
//	u_log (U_PrcUva19 ('03', '9950', 15, 'B', 'E', .T.))  // chardonnay p/esp
//	u_log (U_PrcUva19 ('03', '9859', 15, 'B', 'L', .T.))  // violeta organica
//RETURN	

/*
	// Simula calculos de precos de uva 2019
	_aVaried = {}
	aadd (_aVaried, {'01', '9925           ', 13, '', ''}) // bordo
	aadd (_aVaried, {'01', '9948           ', 13, '', ''}) // bordo em conversao
	aadd (_aVaried, {'01', '9959           ', 13, '', ''}) // bordo organico
//	aadd (_aVaried, {'01', '9904           ', 13, '', ''}) // niagara branca
//	aadd (_aVaried, {'01', '9901           ', 13, '', ''}) // isabel
//	aadd (_aVaried, {'01', '9923           ', 13, '', ''}) // seibel 2
//	aadd (_aVaried, {'01', '9847           ', 13, '', ''}) // MAGNA
//	aadd (_aVaried, {'01', '9933           ', 13, '', ''}) // lorena
//	aadd (_aVaried, {'01', '9908           ', 13, 'B', 'E'}) // cabernet
//	aadd (_aVaried, {'07', '9908           ', 13, 'B', 'E'}) // cabernet
	aadd (_aVaried, {'09', '9908           ', 13, 'B', 'E'}) // cabernet
	aadd (_aVaried, {'03', '9963           ', 13, 'B', 'E'}) // cabernet
	aadd (_aVaried, {'03', '9902           ', 11.6,'B', 'E'}) // chardonnay
	aadd (_aVaried, {'03', '9954           ', 11.6,'B', 'E'}) // gew.p/espum.
	sb1 -> (dbsetorder (1))
	_aPrecos = {}
	for _nVaried = 1 to len (_aVaried)
		if sb1 -> (dbseek (xfilial ("SB1") + _aVaried [_nVaried, 2], .F.))
			_sFil  = _aVaried [_nVaried, 1]
			_nGrau = _aVaried [_nVaried, 3]
			_sClas = _aVaried [_nVaried, 4]
			_sCond = _aVaried [_nVaried, 5]
			_aRet = U_PrcUva19 (_sFil, sb1 -> b1_cod, _nGrau, _sClas, _sCond)[4]
			for _nRet = 1 to len (_aRet)
				aadd (_aPrecos, {sb1 -> b1_cod, alltrim (sb1 -> b1_desc), 'F' + _sFil, _sClas, _sCond, _aRet [_nRet, 1], _aRet [_nRet, 2], _aRet [_nRet, 3]})
			next
		endif
	next
	u_log (_aPrecos)
//	u_acolsxls (_aPrecos)
return
*/
/*
	// Testes visualizacao rastreabilidade
	_aRast := {}
	// aadd (_aRast, {'01','1193', '09033601'  
	//aadd (_aRast, {'01','2203', '09071401'})  // pequeno (3 OP + 2 tr.lote)  
	// aadd (_aRast, {'01','2203', '09071501  '})  // grande, com transf. para filial 09 + laudo  
	// aadd (_aRast, {'01','1193', '09163601'  // gigante, com recursividade
	// aadd (_aRast, {'01','1193', '09166101'  // muito grande
	// aadd (_aRast, {'01','2444', 'N000012947'  // Pequeno, um nivel abaixo + transf. da filial 09
	// aadd (_aRast, {'01','2445', '09120801  '  // Pequeno, teve venda e transf para filial 13  
	// aadd (_aRast, {'01','1180', '000001A   '  
	// aadd (_aRast, {'01','2445', '000001    '
	// aadd (_aRast, {'01','0345', '09166101'  // Gigante
	// aadd (_aRast, {'01', '2763', '09245501'})  // NECTAR MACA           
	//aadd (_aRast, {'01', '1370', '09272501'})  // VINHO TTO BORDO
	//aadd (_aRast, {'01', '2385', '09248401'})  // NECTAR LARANJA
	//aadd (_aRast, {'01', '0247', '09264801'})  // Vinho pinot
	//aadd (_aRast, {'01', '0431', '09269601'})  // gigante - suco bag tto
	//aadd (_aRast, {'01', '0328', '09260601'})  // filtrado bco
	//aadd (_aRast, {'01', '2448', '09249201'})  // mosto bco
	//aadd (_aRast, {'01', '4225', '09214501'})  // monstro - suco tto tetra 200
	//aadd (_aRast, {'01', '9901', '01166401'})  // CARGA DE UVA 2018
	//aadd (_aRast, {'01', '9925', '01001201'})  // CARGA DE UVA 2018
	//aadd (_aRast, {'01', '9909', '01012901'})  // CARGA DE UVA 2018

	// Rastreia cargas de uva
	private _sCargaUva := ""
	private _aTodasCar := {}
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT D1_FILIAL, D1_COD, D1_LOTECTL, CARGA"
	_oSQL:_sQuery += " FROM SD1010 SD1, VA_VCARGAS_SAFRA V"
	_oSQL:_sQuery += " WHERE SD1.D_E_L_E_T_ = '' AND D1_FILIAL = V.FILIAL AND  D1_FORNECE = V.ASSOCIADO AND D1_LOJA = V.LOJA_ASSOC AND D1_DOC = V.CONTRANOTA AND D1_SERIE = V.SERIE_CONTRANOTA"
	_oSQL:_sQuery += " AND V.SAFRA  = '2018'" 
	_oSQL:_sQuery += " AND V.FILIAL = '" + cFilAnt + "'" 
	_oSQL:_sQuery += " AND V.FILIAL + V.CARGA in ('010204','010250','010283','010330','010333','010356','010360','010379','010381','010456','010645','010679','010759','010835','010852','010943','010978','011098','011423','011461','011464','011496','011559','011587','011591','011637','011651','011704','011767','011770','011791','011801','011837','011852','011884','011943',"
	_oSQL:_sQuery +=                             "'011978','011994','012003','012073','012155','012177','012346','012426','012542','012600','012638','012691','012772','012797','012803','012906','012997','013010','013058','013151','013181','013219','013261','013342','013355','013378','013456','013531','013533','013548','013646','013659','013670','013770','013817','013870',"
	_oSQL:_sQuery +=                             "'013881','013940','013965','014012','014016','014073','014120','014166','014191','014204','070002','070012','070044','070068','071000','070112','070129','070139','070259','070270','070314','070373','070413','070527','070692','070877','070895','070918','070984','071018','071020','071036','071053','071058','071068','071121',"
	_oSQL:_sQuery +=                             "'071129','071145','071149','071152','071186','071189','071196','071211','071213','071226','071229','071255','071266','071268','071271','071289','071302','071320','071347','071355','071377','071379','071380','071391','071407','071413','071445','071447','071468','071469','071493','071517','071520','071527','071530','071549',"
	_oSQL:_sQuery +=                             "'071552','071561','071591','071601','071627','071646','071679','071692','071711','071736','071743','071788','071798','071819','071843','071875','071884','071943','071958','071982','071990','071996','072011','072050','072070','072077','072080','072136','072145','072167','072185','072206','072379','072442','072445','072451',"
	_oSQL:_sQuery +=                             "'072517','072559','072579','072671','072710','072764','072811','072855','072885','072914','072956','090050','090067','090124','090125','090143','090146','090161','090165','090197','090242','090283','090377','090405','090425','090431','012151','013085')" 
	_oSQL:_sQuery += " AND V.PESO_LIQ >= 7000" 
	_oSQL:_sQuery += " AND D1_LOTECTL != ''" 
//	_oSQL:_sQuery += " AND ((V.FILIAL = '01' AND V.CARGA IN ('1664','0075','0146','0194','0266','0310','0339','0358','0592','0595','0597','0700','1012','1197','1353','1623','1972','1999','2326','0056','0452','0472','0697','1036','1157','2752','3323','1587','1496','1637','0679','0852','0456','0645','0204','0250','0283','0330','0333','0356','0360','0379','0381','0759','0835'"
	_oSQL:_sQuery +=                                       ",'0943','0978','1098','1423','1461','1464','1559','1591','1651','1704','1767','1770','1791','1801','1837','1852','1884','1943','1978','1994','2003','2073','2155','2177','2346','2426','2542','2600','2638','2691','2772','2797','2803','2906','2997','3010','3058','3151','3181','3219','3261','3342','3355','3378','3456'"
	_oSQL:_sQuery +=                                       ",'3531','3533','3548','3646','3659','3670','3770','3817','3870','3881','3940','3965','4012','4016','4073','4120','4166','4191','4204','2151','3085','0070','0512','0868','1245','1333','1447','1565','1685','1690','1692','1696','1697','1699','1708','1752','1776','1827','1831','1840','1920','1934','1944','1950','1985'"
	_oSQL:_sQuery +=                                       ",'2025','2147','2150','2163','2185','2288','2415','2467','2469','2470','2480','2481','2558','2571','2579','2583','2587','2669','2732','2749','2773','2884','2991','3011','3030','3036','3236','3250','3255','3292','3300','3400','3417','3457','3461','3466','3540','3559','3726','3787','4011','4049','4078','4180','4189'"
	_oSQL:_sQuery +=                                       ",'0358','1491','0975','1157','0692','0413','1020','1068','1129','1211','1255','1320','1355','1391','1469','1530','1601','1646','1711','1788','1743','1990','1058','1268','1377','1413','1517','1996','0259','0314','0373','0895','0984','0002','1552','2451','0012','0044','0068','0100','0112','0129','0139','0270','0527'"
	_oSQL:_sQuery +=                                       ",'0877','0918','1018','1036','1053','1121','1145','1149','1152','1186','1189','1196','1213','1226','1229','1266','1271','1289','1302','1347','1379','1380','1407','1445','1447','1468','1493','1520','1527','1549','1561','1591','1627','1679','1692','1736','1798','1819','1843','1875','1884','1943','1958','1982','2011'"
	_oSQL:_sQuery +=                                       ",'2050','2070','2077','2080','2136','2145','2167','2185','2206','2379','2442','2445','2517','2559','2579','2671','2710','2764','2811','2855','2885','2914','2956')"
//	_oSQL:_sQuery += " ) OR (V.FILIAL = '09' AND V.CARGA IN ('0013','0067','0143','0161','0165','0197','0124','0125','0146','0050','0242','0283','0377','0405','0425','0431','0003','0063','0076','0136','0145','0147','0154','0155','0159','0160','0175','0215','0218','0222','0277','0307','0482')"
//	_oSQL:_sQuery += " ))"
	_oSQL:_sQuery += " ORDER BY FILIAL, CARGA, D1_COD"
	_aRast := aclone (_oSQL:Qry2Array ())

	for _nRast = 1 to len (_aRast)
		u_log ('#####################')
		//_sCargaUva = _aRast [_nRast, 4]
		_sMapa := U_RastLT (_aRast [_nRast, 1], U_TamFixo (_aRast [_nRast, 2], 15, ' '), _aRast [_nRast, 3], 0, NIL)
		//_sArq := 'c:\temp\rastLT_' + alltrim (_aRast [_nRast, 2]) + '_' + alltrim (_aRast [_nRast, 3]) + '.mm'
		_sArq := 'c:\temp\rast_carga_' + _aRast [_nRast, 4] + '.mm'
		delete file (_sArq)
		if file (_sArq)
			_nHdl = fopen(_sArq, 1)
		else
			_nHdl = fcreate(_sArq, 0)
		endif
		fwrite (_nHdl, _sMapa)
		fclose (_nHdl)
		ShellExecute ("Open", _sArq, "", "", 1)
	next
	u_log (_aTodasCar)
	_aRet = {}
	for _nCarga = 1 to len (_aTodasCar)
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery = "select BF_LOCALIZ, BF_QUANT FROM SBF010 WHERE D_E_L_E_T_ = '' AND BF_FILIAL = '" + _aTodasCar [_nCarga, 2] + "' AND BF_PRODUTO = '" + _aTodasCar [_nCarga, 3] + "' AND BF_LOTECTL = '" + _aTodasCar [_nCarga, 4] + "' AND BF_QUANT > 0"
		_aSBF = aclone (_oSQL:Qry2Array ())
		for _nSBF = 1 to len (_aSBF)
			aadd (_aRet, {cFilAnt, _aTodasCar [_nCarga, 1], _aTodasCar [_nCarga, 2], _aTodasCar [_nCarga, 3], _aTodasCar [_nCarga, 4], _aSBF [_nSBF, 1], _aSBF [_nSBF, 2]})
		next
	next
	u_log (_aTodasCar)
	u_acolsxls (_aRet)
return
*/
/*
	// GLPI5163 - Leitura da parcela H do ZZ9 e geracao de lctos na conta corrente de associados como adto.sobras (especifico para o ano de 2018)
	if cFilAnt != '01'
		u_help ('Filial errada')
		return
	endif
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT ZZ9_FORNEC, ZZ9_LOJA,SUM (ZZ9_VUNIT) AS VALOR"
	_oSQL:_sQuery +=  " from " + RETSQLNAME ("ZZ9") + " ZZ9 "
	_oSQL:_sQuery += " where ZZ9.D_E_L_E_T_ != '*'"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_SAFRA  = '2018'"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_PARCEL = 'H'"
	_oSQL:_sQuery +=   " and ZZ9.ZZ9_NFCOMP = ''"
	_oSQL:_sQuery += " GROUP BY ZZ9_FORNEC, ZZ9_LOJA"
	_oSQL:_sQuery += " ORDER BY ZZ9_FORNEC, ZZ9_LOJA"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	procregua ((_sAliasQ) -> (reccount ()))
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		u_log ((_sAliasQ) -> zz9_fornec)
		// Busca uma parcela que ainda nao exista para o associado.
		_sDoc = '201812'
		_sSerie = 'DS'
		_sParcela = '1'
		_oSQL := ClsSQL ():New ()
		_oSQL:_sQuery := ""                                                                                            
		_oSQL:_sQuery += " select IsNull (max (E2_PARCELA), '1'),"
		_oSQL:_sQuery +=        " SUM (CASE E2_PARCELA WHEN '" + _sParcela + "' THEN 1 ELSE 0 END)"  // Contagem de ocorrencias da parcela desejada.
		_oSQL:_sQuery +=   " from " + RetSQLName ("SE2") + " SE2 "
		_oSQL:_sQuery +=  " where SE2.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=    " and SE2.E2_FILIAL   = '" + xfilial ("SE2")   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_FORNECE  = '" + (_sAliasQ) -> zz9_fornec + "'"
		_oSQL:_sQuery +=    " and SE2.E2_LOJA     = '" + (_sAliasQ) -> zz9_Loja  + "'"
		_oSQL:_sQuery +=    " and SE2.E2_NUM      = '" + _sDoc   + "'"
		_oSQL:_sQuery +=    " and SE2.E2_PREFIXO  = '" + _sSerie + "'"
		_aRetParc = aclone (_oSQL:Qry2Array ())
		if _aRetParc [1, 2] == 0  // Nao encontrou nenhuma ocorrencia da parcela desejada
			_sParcela = _sParcela
		else
			_sParcela = soma1 (_aRetParc [1, 1])
		endif
		
		_oCtaCorr := ClsCtaCorr():New ()
		_oCtaCorr:Assoc    = (_sAliasQ) -> zz9_fornec
		_oCtaCorr:Loja     = (_sAliasQ) -> zz9_loja
		_oCtaCorr:TM       = '30'
		_oCtaCorr:DtMovto  = date ()
		_oCtaCorr:Valor    = (_sAliasQ) -> valor
		_oCtaCorr:SaldoAtu = (_sAliasQ) -> valor
		_oCtaCorr:Usuario  = cUserName
		_oCtaCorr:Histor   = 'ANTECIPACAO DE SOBRAS EXERC 2018'
		_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
		_oCtaCorr:Doc      = _sDoc
		_oCtaCorr:Serie    = _sSerie
		_oCtaCorr:Origem   = 'GLPI5163'
		_oCtaCorr:Parcela  = _sParcela
		if _oCtaCorr:PodeIncl ()
			if ! _oCtaCorr:Grava (.F., .F.)
				U_help ("Erro na atualizacao da conta corrente. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
			else
				_oSQL := ClsSQL ():New ()
				_oSQL:_sQuery += " UPDATE " + RETSQLNAME ("ZZ9")
				_oSQL:_sQuery +=   " SET ZZ9_NFCOMP = '" + _sDoc + "', ZZ9_SERCOM = '" + _sSerie + "'"
				_oSQL:_sQuery += " where D_E_L_E_T_ != '*'"
				_oSQL:_sQuery +=   " and ZZ9_SAFRA  = '2018'"
				_oSQL:_sQuery +=   " and ZZ9_PARCEL = 'H'"
				_oSQL:_sQuery +=   " and ZZ9_FORNEC = '" + (_sAliasQ) -> zz9_fornec + "'"
				_oSQL:_sQuery +=   " and ZZ9_LOJA   = '" + (_sAliasQ) -> zz9_loja + "'"
				_oSQL:Log ()
				_oSQL:Exec ()
			endif
		else
			U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
	(_sAliasQ) -> (dbclosearea ())
    dbselectarea ("ZZ9")
    U_HELP ("Processo finalizado")
return
*/
*/
/*	// Compara classificacao viniferas 2018 com criterios de 2019
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT TOP 100 PRODUTO, GRAU, FILIAL, CLAS_FINAL, CLAS_ABD, ACUCAR, SANIDADE, MATURACAO, MAT_ESTRANHO FROM VA_VNOTAS_SAFRA WHERE SAFRA = '2018' AND CLAS_FINAL != '' AND TIPO_NF = 'E'"
	_oSQL:_sQuery += "ORDER BY ASSOCIADO, LOJA_ASSOC, FILIAL, DOC, SERIE, PRODUTO, GRAU"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	do while ! (_sAliasQ) -> (eof ())
		U_ClUva19 ((_sAliasQ) -> produto, val ((_sAliasQ) -> grau), iif ((_sAliasQ) -> filial == '03', 'E', 'L'), 0, 0, 0, 0, 0, 'ausente', 0)
		u_log ('clas. original:', (_sAliasQ) -> clas_final, 'abd:', (_sAliasQ) -> clas_abd, '     ', (_sAliasQ) -> ACUCAR, (_sAliasQ) -> SANIDADE, (_sAliasQ) -> MATURACAO, (_sAliasQ) -> MAT_ESTRANHO)
		u_log ('')
		u_log ('')
		u_log ('')
		u_log ('')
		(_sAliasQ) -> (dbskip ())
	enddo
return
*/
/*
	// Gera arq. Sisdeclara.
	cPerg := "ML_DEC"
	U_GravaSX1 (cPerg, "01", stod ("20181101"))
	U_GravaSX1 (cPerg, "02", stod ("20181105"))
	U_GravaSX1 (cPerg, "03", 1)  // 1=mov.mensal;2=entradas uvas
	U_GravaSX1 (cPerg, "04", 'ALCEU DALLEMOLLE')
	U_GravaSX1 (cPerg, "05", '????????')  // '05404198' = Hugo    '05403148' = Flavio
	U_GravaSX1 (cPerg, "06", 'c:\temp\sisdeclara' + cFilAnt + '.txt')
	U_GravaSX1 (cPerg, "07", 'robert.koch@novaalianca.coop.br')
	U_GravaSX1 (cPerg, "08", 1)  // Gera arq conferencia (s/n)
	U_GravaSX1 (cPerg, "09", 2)  // Exporta guias? (s/n)
	U_ML_DEC (.t.)
return
*/
/*
	// Gera d2_numseq para cupons recurperados
	use \robert\sd2_rk VIA 'DBFCDXADS' shared new
	_sSeq := 'x09A1H'  // PRIMEIRA SEQ DO DIA 23/11
	_oSQL := ClsSQL ():New ()
	do while ! sd2_rk -> (eof ())
		// Encontra sequencial livre na base quente. Vai demorar... mas se demorar demais,  por que nao achou...
		do while .T.
			_oSQL:_sQuery := " SELECT (SELECT COUNT (*) FROM LKSRV_PROTHEUS.protheus.dbo.SD1010 WHERE D_E_L_E_T_ = '' AND D1_NUMSEQ = '" + _sSeq + "')"
			_oSQL:_sQuery +=      " + (SELECT COUNT (*) FROM LKSRV_PROTHEUS.protheus.dbo.SD2010 WHERE D_E_L_E_T_ = '' AND D2_NUMSEQ = '" + _sSeq + "')"
			_oSQL:_sQuery +=      " + (SELECT COUNT (*) FROM LKSRV_PROTHEUS.protheus.dbo.SD3010 WHERE D_E_L_E_T_ = '' AND D3_NUMSEQ = '" + _sSeq + "')"
			_oSQL:Log ()
			if _oSQL:RetQry () == 0
				exit
			else
				_sSeq := soma1 (_sSeq)
			endif
		enddo
		reclock ('sd2_rk', .F.)
		sd2_rk -> d2_numseq = _sSeq
		msunlock ()
		_sSeq := soma1 (_sSeq)
		sd2_rk -> (dbskip ())
	enddo
	u_log ('feito')
return
*/
/*
	cPerg = "VAGNF3"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', 'H')    // Parcela
	U_GravaSX1 (cPerg, '07', '')     // DCO inicial
	U_GravaSX1 (cPerg, '08', 'z')    // DCO final
	U_GravaSX1 (cPerg, '09', '')     // Prod ini
	U_GravaSX1 (cPerg, '10', 'z')    // Prod final
	U_GravaSX1 (cPerg, '11', 0)    // Preco 2016
	U_VA_GNF3 (.T.)
return
*/
/* Compara SX6 com outra base de dados
	use \robert\sx6010 shared new alias sx6_medio
	index on x6_var to &(criatrab ({}, .F.))
	sx6_medio -> (dbgotop ())
	do while ! sx6_medio -> (eof ())
		if ! sx6 -> (dbseek (cFilAnt + sx6_medio -> x6_var, .F.))
			sx6 -> (dbseek ('  ' + sx6_medio -> x6_var, .F.))
		endif
		if sx6 -> (found ())
			if sx6_medio -> x6_conteud != sx6 -> x6_conteud
				u_log (sx6_medio -> x6_fil, sx6_medio -> x6_var, alltrim (sx6_medio -> x6_conteud), '------', alltrim (sx6 -> x6_conteud), '------', alltrim (sx6 -> x6_descric) + alltrim (sx6 -> x6_desc1) + alltrim (sx6 -> x6_desc2))
			endif
		else
			u_log (sx6_medio -> x6_var, 'nao encontrado')
		endif
		sx6_medio -> (dbskip ())
	enddo
	sx6_medio -> (dbclosearea ())
*/	
/*
	_aDados := {}
	sx3 -> (dbgotop ())
	do while ! sx3 -> (eof ())
		if sx3 -> x3_context != 'V' .and. sx3 -> x3_arquivo $ 'SA2'
			aadd (_aDados, {sx3 -> x3_campo, sx3 -> x3_tipo, sx3 -> x3_tamanho, sx3 -> x3_decimal, alltrim (sx3 -> x3_titulo), alltrim (sx3 -> x3_descric), sx3 -> x3_picture, strtran (sx3 -> x3_cbox, ';', '/')})
		endif
		sx3 -> (dbskip ())
	enddo
	u_log (_adados)
	u_acolsxls (_aDados)
return
*/
/*
	_sAlmox = '02'
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT *"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SGQ")
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND GQ_FILIAL = '" + xfilial ("SGQ") + "
	_oSQL:_sQuery += " AND GQ_LOCAL  = '" + _sAlmox + "'"

	SGQ -> (dbSetOrder(1))	//FILIAL + TIPOPER + LOCAL + USER
	if SGQ -> (dbSeek (xFilial ("SGQ") + "1" + _sAlmox + _sUser))  // Tipo '1' = 'por usuario'
		u_log ('Tem acesso direto pelo usuario')
		_lRet = .T.
	else
		_aGrpUsr = UsrRetGRP(__cUserID)  // Grupos aos quais o usuario pertence.
		u_log ('grupos do usuario:', _aGrpUsr)
		if len (_aGrpUsr) > 0
			SGQ -> (dbSeek (xFilial ("SGQ") + "1" + _sAlmox, .T.))
			do while ! sgq -> (eof ()) .and. sgq -> gq_filial == xfilial ("SGQ") .and. sgq -> gq_TipoRer == '1' .and. sgq -> gq_local == _sAlmox
				u_log ('Testando gq_grpuser =', sgq -> gq_grpuser)
				if ascan (_aGrpUsr, {|_aVal| alltrim (_aVal [1]) == alltrim (SGQ -> GQ_GRPUSER)}) > 0
					u_log ('Grupo ok')
					_lRet = .T.
					exit
				endif
				SGQ -> (dbSkip ())
			enddo
		endif
	endif
*/
/*
	_aLaudos := {}
	aadd (_aLaudos, {'000002424', 50})
	aadd (_aLaudos, {'000002420', 100})
	//aadd (_aLaudos, {'000002418', 100})
	//aadd (_aLaudos, {'000002419', 100})
	U_ZAFM (_aLaudos, '2203           ', 'op', 'novolote', '03')
return
*/
/*
	// Gera entrada na conta corrente do associado, com base nos titulos gerados no financeiro para as notas de compra de safra.
	_sSafra = '2018'
	private _sOrigSZI  := "VA_GNF2"
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT DISTINCT ASSOCIADO, LOJA_ASSOC, DOC, SERIE" 
	_oSQL:_sQuery +=  " FROM VA_VNOTAS_SAFRA V "
	_oSQL:_sQuery += " WHERE FILIAL = '" + cFilAnt + "'"
	_oSQL:_sQuery +=   " AND SAFRA  = '" + _sSafra + "'"
	_oSQL:_sQuery +=   " AND ASSOCIADO = '003008' AND DATA = '20180622'"
	_oSQL:_sQuery +=   " AND TIPO_NF = 'C'"
	_oSQL:_sQuery +=   " AND NOT EXISTS (SELECT * FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery +=                           " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=                             " AND ZI_FILIAL  = V.FILIAL"
	_oSQL:_sQuery +=                             " AND ZI_ASSOC   = V.ASSOCIADO"
	_oSQL:_sQuery +=                             " AND ZI_LOJASSO = V.LOJA_ASSOC"
	_oSQL:_sQuery +=                             " AND ZI_DOC     = V.DOC"
	_oSQL:_sQuery +=                             " AND ZI_SERIE   = V.SERIE"
	_oSQL:_sQuery +=                             " AND ZI_TM      = '13')"
	_oSQL:_sQuery += " order by ASSOCIADO, DOC"
	_oSQL:Log ()
	_aDados := _oSQL:Qry2Array ()
	u_log (_aDados)
	for _nDado = 1 to len (_aDados)
		_sQuery := ""
		_sQuery += " SELECT E2_FILIAL, E2_FORNECE, E2_LOJA, E2_NOMFOR, E2_EMISSAO, E2_VENCREA, E2_NUM, E2_PREFIXO, E2_TIPO, E2_VALOR, E2_SALDO, E2_HIST, R_E_C_N_O_, E2_LA, E2_PARCELA,"
		_sQuery +=        " ROW_NUMBER () OVER (ORDER BY E2_PARCELA) AS NUM_PARC"
		_sQuery +=   " FROM " + RetSQLName ("SE2")
		_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_sQuery +=    " AND E2_TIPO    = 'NF'"
		_sQuery +=    " AND E2_FORNECE = '" + _aDados [_nDado, 1] + "'"
		_sQuery +=    " AND E2_LOJA    = '" + _aDados [_nDado, 2] + "'"
		_sQuery +=    " AND E2_NUM     = '" + _aDados [_nDado, 3] + "'"
		_sQuery +=    " AND E2_PREFIXO = '" + _aDados [_nDado, 4] + "'"
		_sQuery +=    " AND E2_VACHVEX = ''"
		_sQuery +=    " AND E2_FILIAL  = '" + xfilial ("SE2") + "'"
		_sQuery +=  " ORDER BY E2_PARCELA"
		u_log (_sQuery)
		_sAliasQ = GetNextAlias ()
		DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
		U_TCSetFld (alias ())
		do while ! (_sAliasQ) -> (eof ())
	  		u_log ('Filial:' + (_sAliasQ) -> e2_filial, 'Forn:' + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + ' ' + (_sAliasQ) -> e2_nomfor, 'Emis:', (_sAliasQ) -> e2_emissao, 'Vcto:', (_sAliasQ) -> e2_vencrea, 'Doc:', (_sAliasQ) -> e2_num+'/'+(_sAliasQ) -> e2_prefixo, 'Tipo:', (_sAliasQ) -> e2_tipo, 'Valor: ' + transform ((_sAliasQ) -> e2_valor, "@E 999,999,999.99"), 'Saldo: ' + transform ((_sAliasQ) -> e2_saldo, "@E 999,999,999.99"), (_sAliasQ) -> e2_hist)
			_oCtaCorr := ClsCtaCorr():New ()
			_oCtaCorr:Assoc    = (_sAliasQ) -> e2_fornece
			_oCtaCorr:Loja     = (_sAliasQ) -> e2_loja
			_oCtaCorr:TM       = '13'
			_oCtaCorr:DtMovto  = (_sAliasQ) -> e2_EMISSAO
			_oCtaCorr:Valor    = (_sAliasQ) -> e2_valor
			_oCtaCorr:SaldoAtu = (_sAliasQ) -> e2_saldo
			_oCtaCorr:Usuario  = cUserName
			_oCtaCorr:Histor   = 'COMPRA SAFRA ' + _sSafra + "(" + cvaltochar ((_sAliasQ) -> Num_Parc) + ")"
			_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
			_oCtaCorr:Doc      = (_sAliasQ) -> e2_num
			_oCtaCorr:Serie    = (_sAliasQ) -> e2_prefixo
			_oCtaCorr:Origem   = _sOrigSZI
			_oCtaCorr:Parcela  = (_sAliasQ) -> e2_parcela
			if _oCtaCorr:PodeIncl ()
				if ! _oCtaCorr:Grava (.F., .F.)
					U_help ("Erro na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
					_lContinua = .F.
				else
					se2 -> (dbgoto ((_sAliasQ) -> r_e_c_n_o_))
					if empty (se2 -> e2_vachvex)  // Soh pra garantir...
						reclock ("SE2", .F.)
						se2 -> e2_vachvex = _oCtaCorr:ChaveExt ()
						msunlock ()
					endif
				endif
			else
				U_help ("Gravacao do SZI nao permitida na atualizacao da conta corrente para o associado '" + (_sAliasQ) -> e2_fornece + '/' + (_sAliasQ) -> e2_loja + "'. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				_lContinua = .F.
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
	next
return
*/
/*
	// Gera entrada na conta corrente do associado, ref. notas de devolucao de compra de safra.
	local _aNfDevol := {}
	local _nNfDevol := 0
	aadd (_aNfDevol, {'2018', '01', '000003702', '30 ', '004831', '01', '20160530', ' - ERRO INSCR.EST.', '000002427', '30 '})
	for _nNfDevol = 1 to len (_aNfDevol)
		if _aNfDevol [_nNfDevol, 2] != cFilAnt
			u_log ('Filial errada')
		else
			_sQuery := ""
			_sQuery += " SELECT FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE, SUM (VALOR_TOTAL) AS TOTAL"
			_sQuery +=   " FROM VA_VNOTAS_SAFRA"
			_sQuery +=  " WHERE TIPO_NF    = 'C'"
			_sQuery +=    " AND SAFRA      = '" + _aNfDevol [_nNfDevol, 1] + "'"
			_sQuery +=    " AND FILIAL     = '" + _aNfDevol [_nNfDevol, 2] + "'"
			_sQuery +=    " AND ASSOCIADO  = '" + _aNfDevol [_nNfDevol, 5] + "'"
			_sQuery +=    " AND LOJA_ASSOC = '" + _aNfDevol [_nNfDevol, 6] + "'"
			_sQuery +=    " AND DOC        = '" + _aNfDevol [_nNfDevol, 9] + "'"
			_sQuery +=    " AND SERIE      = '" + _aNfDevol [_nNfDevol, 10] + "'"
			_sQuery += " GROUP BY FILIAL, ASSOCIADO, LOJA_ASSOC, DOC, SERIE"
			u_log (_sQuery)
			_sAliasQ = GetNextAlias ()
			DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), _sAliasQ, .f., .t.)
			U_TCSetFld (alias ())
			do while ! (_sAliasQ) -> (eof ())
		  		_oCtaCorr := ClsCtaCorr():New ()
				_oCtaCorr:Assoc    = (_sAliasQ) -> ASSOCIADO
				_oCtaCorr:Loja     = (_sAliasQ) -> LOJA_ASSOC
				_oCtaCorr:TM       = '22'
				_oCtaCorr:DtMovto  = stod (_aNfDevol [_nNfDevol, 7])
				_oCtaCorr:Valor    = (_sAliasQ) -> TOTAL
				_oCtaCorr:SaldoAtu = (_sAliasQ) -> TOTAL
				_oCtaCorr:Usuario  = cUserName
				_oCtaCorr:Histor   = 'DEVOL.COMPRA SAFRA ' + _aNFDevol [_nNFDevol, 1] + _aNFDevol [_nNFDevol, 8]
				_oCtaCorr:MesRef   = strzero(month(_oCtaCorr:DtMovto),2)+strzero(year(_oCtaCorr:DtMovto),4)
				_oCtaCorr:Doc      = _aNfDevol [_nNfDevol, 3]
				_oCtaCorr:Serie    = _aNfDevol [_nNfDevol, 4]
				_oCtaCorr:Origem   = 'DEVOL'
				if _oCtaCorr:PodeIncl ()
					if ! _oCtaCorr:Grava (.F., .F.)
						U_log ("Erro na atualizacao da conta corrente. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
					else
						u_log ('SZI gerado.')
					endif
				else
					U_help ("Gravacao do SZI nao permitida. Ultima mensagem do objeto:" + _oCtaCorr:UltMsg)
				endif
				(_sAliasQ) -> (dbskip ())
			enddo
			(_sAliasQ) -> (dbclosearea ())
		endif
	next
return
*/


/*
	// Cobrei multa por mistura de variedades de um pessoal que estava entregando em caixas.
	if cFilAnt != '07'
		u_help ('filial errada')
		return
	endif
	_sPreNF := "000000"
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT * FROM VA_VNOTAS_SAFRA V WHERE SAFRA = '2018' AND V.TIPO_NF = 'C' AND V.FILIAL = '07' AND exists (select * from ZZ9010 ZZ9 where ZZ9.D_E_L_E_T_ = '' AND V.SAFRA = ZZ9.ZZ9_SAFRA AND V.FILIAL = ZZ9_FILIAL"
	_oSQL:_sQuery += " AND V.ASSOCIADO NOT IN ('000248','002083','002387','002486','002513','002514','002517','002522','002633','002639','003019','003559','004367','004399','005331')"
	_oSQL:_sQuery += " AND V.ASSOCIADO = ZZ9_FORNEC AND V.LOJA_ASSOC = ZZ9_LOJA AND V.DOC = ZZ9_NFCOMP AND V.SERIE = ZZ9_SERCOM AND V.PRODUTO = ZZ9_PRODUT AND V.GRAU = ZZ9_GRAU AND V.CLAS_FINAL = ZZ9_CLASSE AND (ZZ9_MISTU1 != ''"
	_oSQL:_sQuery += " OR ZZ9_MISTU2 != '' OR ZZ9_MISTU3 != '') AND ZZ9_MSGNF LIKE '%Usando prc%' AND EXISTS (SELECT * FROM SD1010 SD1 WHERE SD1.D_E_L_E_T_ = '' AND SD1.D1_FILIAL = ZZ9_FILIAL AND SD1.D1_FORNECE = ZZ9_FORNEC AND SD1.D1_LOJA = ZZ9_LOJA AND SD1.D1_DOC = ZZ9_NFENTR AND SD1.D1_SERIE = '30 ' AND SD1.D1_EMISSAO < '20180120'))"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	u_logtrb (_sAliasQ, .T.)
	(_sAliasQ) -> (dbgotop ())
	do while ! (_sAliasQ) -> (eof ())
		do while ! (_sAliasQ) -> (eof ())
			_nPreco = U_PrecoUva ((_sAliasQ) -> associado, (_sAliasQ) -> loja_assoc, (_sAliasQ) -> Produto, (_sAliasQ) -> grau, (_sAliasQ) -> Safra, (_sAliasQ) -> clas_final, (_sAliasQ) -> clas_abd, 'C', (_sAliasQ) -> filial)
			if _nPreco > (_sAliasQ) -> valor_unit
				reclock ("ZZ9", .T.)
				zz9 -> zz9_filial = xfilial ("ZZ9")
				zz9 -> zz9_pre_nf = _sPreNF
				zz9 -> zz9_safra  = '2018'
				zz9 -> zz9_parcel = 'F'
				zz9 -> zz9_fornec = (_sAliasQ) -> associado
				zz9 -> zz9_loja   = (_sAliasQ) -> loja_assoc
				zz9 -> zz9_TipoNF = "C"
				zz9 -> zz9_produt = (_sAliasQ) -> produto
				zz9 -> zz9_grau   = (_sAliasQ) -> grau
				zz9 -> zz9_classe = (_sAliasQ) -> clas_final
				zz9 -> zz9_clabd  = (_sAliasQ) -> clas_abd
				zz9 -> zz9_quant  = 0
				zz9 -> zz9_vunit  = (_sAliasQ) -> peso_liq * _nPreco - (_sAliasQ) -> valor_total
				zz9 -> zz9_obs    = 'Uva em caixa, nao havia mistura'
				zz9 -> zz9_msgNF  = 'Vl.orig.considerado como mistura'
				zz9 -> zz9_nfori  = (_sAliasQ) -> doc
				zz9 -> zz9_serior = (_sAliasQ) -> serie
				zz9 -> zz9_itemor = (_sAliasQ) -> item_nota
				msunlock ()
				_sPreNF = soma1 (soma1 (soma1 (soma1 (soma1 (_sPreNF)))))
			endif
			(_sAliasQ) -> (dbskip ())
		enddo
	enddo
return
*/


/*
// Testes P.E. exclusao faturas -> atualizar SZI
user function F290CAN ()
	local _aAreaAnt := U_ML_SRArea ()
	U_LOGiD ()
	u_logini ()
	u_logtrb ("SE2")
	
	_AtuSZI ()

	U_ML_SRArea (_aAreaAnt)
	u_logfim ()
return

static function _AtuSZI ()
	local _nRegSZI  := 0
	local _oCtaCorr := NIL
	local _oSQL     := NIL
	local _nValFat  := 0

	// Estou posicionado num dos titulos que fazem parte da fatura: verifica se existe lcto correspondente na conta corrente de associados.
	if se2 -> e2_tipo != 'FAT'  // Soh quero rodar para os titulos que participaram da fatura.
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SZI.R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = '" + xfilial ("SZI") + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + se2 -> e2_fornece + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + se2 -> e2_loja + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_DOC      = '" + se2 -> e2_num + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_SERIE    = '" + se2 -> e2_prefixo + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_PARCELA  = '" + se2 -> e2_parcela + "'"
		_oSQL:Log ()
		_nRegSZI = _oSQL:RetQry (1, .F.)
		if _nRegSZI != 0
			szi -> (dbgoto (_nRegSZI))
			
			// Verifica se existe movimento de geracao de fatura
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT TOP 1 E5_VALOR"  // Soh deve ter um, mas por via das duvidas, buscarei o mais recente.
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SE5") + " SE5 "
			_oSQL:_sQuery += " WHERE SE5.D_E_L_E_T_ != ''"  // SE5 jah vai estar deletado.
			_oSQL:_sQuery +=   " AND SE5.E5_FILIAL   = '" + xfilial ("SE5") + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_CLIFOR   = '" + szi -> zi_assoc + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_LOJA     = '" + szi -> zi_lojasso + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_NUMERO   = '" + szi -> zi_doc + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_PREFIXO  = '" + szi -> zi_serie + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_PARCELA  = '" + szi -> zi_parcela + "'"
			_oSQL:_sQuery +=   " AND SE5.E5_MOTBX    = 'FAT'"
			_oSQL:_sQuery +=   " AND dbo.VA_SE5_ESTORNO (SE5.R_E_C_N_O_) = 0"
			_oSQL:_sQuery += " ORDER BY R_E_C_N_O_ DESC"
			_oSQL:Log ()
			_nValFat = _oSQL:RetQry (1, .F.)
			U_LOG ('_NvALfAT = ', _nValFat)
			if _nValFat > 0
				u_log ('Aumentando saldo SZI de ', szi -> zi_saldo, ' para', szi -> zi_saldo + _nValFat)
				reclock ("SZI", .F.)
				szi -> zi_saldo += _nValFat
				msunlock ()
			endif
		endif
	else
		if se2 -> e2_tipo == 'FAT' .and. se2 -> (deleted ())  // Excluiu a fatura
			_oSQL := ClsSQL():New ()
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += "SELECT SZI.R_E_C_N_O_"
			_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
			_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
			_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = '" + xfilial ("SZI") + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + se2 -> e2_fornece + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + se2 -> e2_loja + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_DOC      = '" + se2 -> e2_num + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_SERIE    = '" + se2 -> e2_prefixo + "'"
			_oSQL:_sQuery +=   " AND SZI.ZI_PARCELA  = '" + se2 -> e2_parcela + "'"
			_oSQL:Log ()
			_nRegSZI = _oSQL:RetQry (1, .F.)
			if _nRegSZI != 0
				szi -> (dbgoto (_nRegSZI))
				u_log ('Excluindo fatura ' + szi -> zi_doc + ' do SZI')
				reclock ("SZI", .F.)
				szi -> (dbdelete ())
				msunlock ()
			endif
		endif
	endif
return
*/

/*
	// Recalcula na conta corrente os saldos das faturas de pagamento da safra 2018
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT SZI.R_E_C_N_O_"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SZI") + " SZI "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND ZI_FILIAL  = '" + xfilial ("SZI") + "'"
	_oSQL:_sQuery += " AND ZI_TM      = '13'"
	_oSQL:_sQuery += " AND ZI_DATA   >= '20180320'"
	_oSQL:_sQuery += " AND ZI_DOC     like '2018%'"
	_oSQL:_sQuery += " AND ZI_SALDO   > 0"
	_oSQL:Log ()
	_aDados = aclone (_oSQL:Qry2Array ())
	For _nLinha := 1 To Len(_aDados)
		szi -> (dbgoto (_aDados [_nLinha, 1]))
		_oCtaCorr := ClsCtaCorr ():New (szi -> (recno ()))
		_oCtaCorr:AtuSaldo ()
		u_log (_oCtaCorr:UltMsg)
	next
return
*/
/*
	// Geracao pre-notas compra safra 2018 - parcela A - bordo
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'A')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '9925/9822/9948/9959') // Apenas estas variedades (bordo, bordo de bordadura/em conversao/organico)
	U_GravaSX1 (cPerg, '15', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
	// Geracao pre-notas compra safra 2018 - parcela A - organicas (exceto bordo, jah gerado anteriormente)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'A')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'O')    // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
	// Geracao pre-notas compra safra 2018 - parcela B - tintoreas (exceto bordo e organicas, jah geradas anteriormente)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '')     // Filial inicial
	U_GravaSX1 (cPerg, '10', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '11', 'B')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
	// Geracao pre-notas compra safra 2018 - parcela B - viniferas Livr. (exceto tintoreas, bordo e organicas, jah geradas anteriormente)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '03')   // Filial inicial
	U_GravaSX1 (cPerg, '10', '03')   // Filial final
	U_GravaSX1 (cPerg, '11', 'B')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 2)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
	// Geracao pre-notas compra safra 2018 - parcela C F.01 - demais (exceto viniferas Livr, tintoreas, bordo e organicas, jah geradas anteriormente)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '01')   // Filial inicial
	U_GravaSX1 (cPerg, '10', '01')   // Filial final
	U_GravaSX1 (cPerg, '11', 'C')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
	// Geracao pre-notas compra safra 2018 - parcela C F.07 e 09 - demais (exceto viniferas Livr, tintoreas, bordo e organicas, jah geradas anteriormente)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2018') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', '07')   // Filial inicial
	U_GravaSX1 (cPerg, '10', '09')   // Filial final
	U_GravaSX1 (cPerg, '11', 'C')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '12', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '13', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '14', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '15', '9925/9822/9948/9959') // Exceto estas variedades.
	U_GravaSX1 (cPerg, '16', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '17', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '18', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
return
*/

/*
	// Varre grupos familiares (atual cadastro viticola) e cria um talhao para cada variedade encontrada.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT DISTINCT CAD_VITICOLA, PRODUTO, DESCRICAO, SIST_CONDUCAO"
	_oSQL:_sQuery += " FROM VA_VASSOC_CAD_VITIC V"
	_oSQL:_sQuery += " WHERE SAFRA >= '2016'"
	_oSQL:_sQuery += " and EXISTS (SELECT *"
	_oSQL:_sQuery +=    " FROM ZA8010"
	_oSQL:_sQuery +=    " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND ZA8_COD = V.CAD_VITICOLA)"
	_oSQL:_sQuery += " and NOT EXISTS (SELECT *"
	_oSQL:_sQuery +=    " FROM SZ9010"
	_oSQL:_sQuery +=    " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND Z9_IDZA8 = V.CAD_VITICOLA"
	_oSQL:_sQuery +=    " AND Z9_IDSB1 = V.PRODUTO)"
	_oSQL:_sQuery += " ORDER BY CAD_VITICOLA, PRODUTO"
	_oSQL:Log ()
	_sAliasQ = _oSQL:Qry2Trb ()
	do while ! (_sAliasQ) -> (eof ())
		_sSeq = '001'
		_sCadVit = (_sAliasQ) -> cad_viticola
		do while ! (_sAliasQ) -> (eof ()) .and. (_sAliasQ) -> cad_viticola == _sCadVit
			reclock ('SZ9', .T.)
			sz9 -> z9_filial  = xfilial ("SZ9")
			sz9 -> z9_idZA8   = _sCadVit
			sz9 -> z9_seq     = _sSeq
			sz9 -> z9_idSB1   = (_sAliasQ) -> produto
			sz9 -> z9_descri  = (_sAliasQ) -> descricao
			sz9 -> z9_cultura = '0000000001'  // Uva
			sz9 -> z9_sustent = (_sAliasQ) -> sist_conducao
			sz9 -> z9_status  = 'A'  // Ativo
			msunlock ()
			_sSeq = soma1 (_sSeq)
			(_sAliasQ) -> (dbskip ())
		enddo
	enddo
RETURN
*/
/*
	// Gera tabelas de grupos familiares e propriedades de associados com base no atual cadastro de patriarcas.
	_oSQL := ClsSQL ():New ()
	// Jah teve manutencao manual --> _oSQL:_sQuery := "DELETE ZAN010"  // NUCLEOS FAMILIARES ASSOCIADOS
	// Jah teve manutencao manual --> _oSQL:Exec ()
	_oSQL:_sQuery := "DELETE ZA8010"  // PROPRIEDADES RURAIS ASSOCIADOS
	_oSQL:Exec ()
	_oSQL:_sQuery := "DELETE SZ9010"  // Talhoes das propriedades rurais
	_oSQL:Exec ()
	// Jah teve manutencao manual --> _oSQL:_sQuery := "DELETE ZAK010"  // ASSOCIADO X NUCLEO FAMILIAR
	// Jah teve manutencao manual --> _oSQL:Exec ()
	_oSQL:_sQuery := "DELETE ZAL010"  // NUCLEO FAMILIAR X PROPRIEDADES RURAIS
	_oSQL:Exec ()
	
	// Cria uma propriedade para cada cadastro viticola movimentado nas duas ultimas safras.
	_oSQL:_sQuery := " SELECT DISTINCT Z2_CADVITI, Z2_CODMUN"
	_oSQL:_sQuery += " FROM SZ2010 SZ2, VA_VNOTAS_SAFRA"
	_oSQL:_sQuery += " WHERE SZ2.D_E_L_E_T_ = '' and Z2_FILIAL = '  ' AND Z2_CADVITI = CAD_VITIC AND SAFRA >= '2016' AND TIPO_NF = 'E'"
	_oSQL:Log ()
	_aCadVit := aclone (_oSQL:Qry2Array ())
	u_log ('gerando SZ8')
	for _nCadVit = 1 to len (_aCadVit)
	
		// Cria propriedade
		reclock ('ZA8', .T.)
		za8 -> za8_filial = xfilial ("ZA8")
		za8 -> za8_cod    = _aCadVit [_nCadVit, 1]    // cada cad.vit. eh uma propriedade rural.    // soma1 (U_RetSQL ("SELECT MAX (ZA8_COD) FROM ZA8010 WHERE D_E_L_E_T_ = ''"))
		za8 -> za8_codmun = _aCadVit [_nCadVit, 2]
		za8 -> za8_descri = 'PROPRIEDADE ' + _aCadVit [_nCadVit, 1]
		za8 -> za8_status = 'A'  // Ativa
		msunlock ()
		//u_log ('za8 criado:', za8 -> za8_cod)

		// Cria um talhao inicial para a propriedade (o mapeamento nao vai ficar pronto para esta safra)
		reclock ('SZ9', .T.)
		sz9 -> z9_filial  = xfilial ("SZ9")
		sz9 -> z9_idZA8   = za8 -> za8_cod
		sz9 -> z9_seq     = '001'
		sz9 -> z9_descri  = 'TALHAO UNICO'
		sz9 -> z9_cultura = '0000000001'  // Uva
		sz9 -> z9_sustent = 'L'  // a grande maioria eh latada.
		sz9 -> z9_status  = 'A'  // Ativo
		msunlock ()
	next

	// Varre propriedades (cad.vitic) e busca patriarcas ligados a esse cad.vitic. A partir deles, busca a distancia ate as filiais.
	u_log ('ajustando KM do SZ8')
	za8 -> (dbgotop ())
	do while ! za8 -> (eof ())
		_oSQL:_sQuery := " SELECT distinct Z8_KMF01, Z8_KMF03, Z8_KMF07"
		_oSQL:_sQuery += " FROM SZ8010 SZ8, ZZB010 ZZB
		_oSQL:_sQuery += " WHERE SZ8.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND ZZB.D_E_L_E_T_ = ''"
		_oSQL:_sQuery += " AND Z8_FILIAL  = '" + xfilial ("SZ8") + "'"
		_oSQL:_sQuery += " AND Z8_SAFRA   = '2018'"
		_oSQL:_sQuery += " AND Z8_CODPAT  = ZZB_CODPAT"
		_oSQL:_sQuery += " AND Z8_LOJAPAT = ZZB_LOJPAT"
		_oSQL:_sQuery += " AND ZZB_CADVIT = '" + za8 -> za8_cod + "'"
		_oSQL:_sQuery += " AND (Z8_KMF01 > 0 OR Z8_KMF03 > 0 OR Z8_KMF07 > 0)"
		//_oSQL:Log ()
		_aDist := aclone (_oSQL:Qry2Array ())
//		u_log (_aDist)
		if len (_aDist) == 1  // Se encontrar mais de um, deixa em branco
			reclock ('ZA8', .F.)
			za8 -> za8_kmf01  = _aDist [1, 1]
			za8 -> za8_kmf03  = _aDist [1, 2]
			za8 -> za8_kmf07  = _aDist [1, 3]
			msunlock ()
			//u_log ('za8 com km atualizado:', za8 -> za8_cod)
		endif
		za8 -> (dbskip ())
	enddo

	// Cria grupos familiares a partir do cadastro de patriarcas
	u_log ('gerando ZAN')
	_oSQL:_sQuery := " SELECT *" //distinct Z8_CODPAT, Z8_LOJAPAT"
	_oSQL:_sQuery += " FROM " + RetSQLName ("SZ8") + " SZ8 "
	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery += " AND Z8_FILIAL  = '" + xfilial ("SZ8") + "'"
	_oSQL:_sQuery += " AND Z8_SAFRA   = '2018'"
//	_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM SZ8010 OUTRO WHERE OUTRO.D_E_L_E_T_ = '' AND OUTRO.Z8_SAFRA = SZ8.Z8_SAFRA AND OUTRO.Z8_CODREL = SZ8.Z8_CODREL AND OUTRO.Z8_LOJAREL = SZ8.Z8_LOJAREL AND OUTRO.Z8_CODPAT + OUTRO.Z8_LOJAPAT != SZ8.Z8_CODPAT + SZ8.Z8_LOJAPAT)"
	_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM SZ8010 OUTROPAT WHERE OUTROPAT.D_E_L_E_T_ = '' AND OUTROPAT.Z8_SAFRA = SZ8.Z8_SAFRA AND OUTROPAT.Z8_CODPAT = SZ8.Z8_CODPAT AND OUTROPAT.Z8_LOJAPAT > SZ8.Z8_LOJAPAT)"
//	_oSQL:_sQuery += " AND NOT EXISTS (SELECT * FROM SZ8010 OUTRO WHERE OUTRO.D_E_L_E_T_ = '' AND OUTRO.Z8_SAFRA = SZ8.Z8_SAFRA AND OUTRO.Z8_CODREL = SZ8.Z8_CODREL AND OUTRO.Z8_LOJAREL = SZ8.Z8_LOJAREL AND OUTRO.Z8_CODPAT != SZ8.Z8_CODPAT)"
	_oSQL:_sQuery += " ORDER BY Z8_CODPAT, Z8_LOJAPAT, Z8_CODREL, Z8_LOJAREL"
	_oSQL:Log ()
	_sz8 = _oSQL:Qry2Trb ()
	(_sz8) -> (dbgotop ())
	do while ! (_sz8) -> (eof ())
		_sPatr = (_sz8) -> z8_codpat + (_sz8) -> z8_lojapat
		u_log (_sPatr)

		// Cria grupo familiar
		sa2 -> (dbsetorder (1))
		if ! sa2 -> (dbseek (xfilial ("SA2") + (_sz8) -> z8_codpat + (_sz8) -> z8_lojapat, .F.))
			u_log ('cadastro patriarca nao encontrado')
		else
//			_sCodZAN = (_sz8) -> z8_codpat  // patriarca aqui pra ter a origem.  --> soma1 (U_RetSQL ("SELECT MAX (ZAN_COD) FROM ZAN010 WHERE D_E_L_E_T_ = ''"))
//			reclock ('ZAN', .T.)
//			zan -> zan_filial = xfilial ("ZAN")
//			zan -> zan_cod    = _sCodZAN
//			zan -> zan_descri = 'GRUPO DE ' + alltrim ((_sz8) -> z8_nomepat)
//			zan -> zan_ativo  = 'S'
//			zan -> zan_avisad = sa2 -> a2_vacavis
//			zan -> zan_ljavis = sa2 -> a2_valavis
//			zan -> zan_nucleo = sa2 -> a2_vanucl
//			zan -> zan_subnuc = sa2 -> a2_vasubnu
//			msunlock ()
//	
//			// Relaciona associados com o grupo familiar
//			do while ! (_sz8) -> (eof ()) .and. (_sz8) -> z8_codpat + (_sz8) -> z8_lojapat == _sPatr
//				if (_sz8) -> z8_codrel + (_sz8) -> z8_lojarel == (_sz8) -> z8_codpat + (_sz8) -> z8_lojapat .OR. U_EhAssoc ((_sz8) -> z8_codrel, (_sz8) -> z8_lojarel, date ())
//					reclock ('ZAK', .T.)
//					zak -> zak_filial = xfilial ("ZAK")
//					zak -> zak_assoc  = (_sz8) -> z8_codrel
//					zak -> zak_loja   = (_sz8) -> z8_lojarel
//					// nao tem mais o mesmo conteudo --> zak -> zak_tipore = (_sz8) -> z8_tiporel
//					zak -> zak_idzan  = _sCodZAN
//					msunlock ()
//				endif
//				(_sz8) -> (dbskip ())
//			enddo
	
			// Associa o grupo familiar com as propriedades rurais que ele explora.
			_oSQL:_sQuery := " SELECT DISTINCT ZZB.ZZB_CADVIT"
			_oSQL:_sQuery += " FROM ZZB010 ZZB"
			_oSQL:_sQuery += " WHERE ZZB.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZZB.D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=   " AND ZZB_CODPAT     = '" + _sCodZAN + "'"
			//NAO TEM LOJA _oSQL:_sQuery +=   " AND ZZB_LOJPAT     = '" + (_sz8) -> z8_lojapat + "'"
//			_oSQL:Log ()
			_aCadVit := aclone (_oSQL:Qry2Array ())
			if len (_aCadVit) == 0
				u_log ('sem cad vit para', _sCodZAN)
			endif
			za8 -> (dbsetorder (1))  // ZA8_FILIAL+ZA8_COD
			zal -> (dbsetorder (1))  // ZAL_FILIAL+ZAL_IDZAN+ZAL_IDZA8
			for _nCadVit = 1 to len (_aCadVit)
				if ! zal -> (dbseek (xfilial ("ZAL") + _sCodZAN + _aCadVit [_nCadVit, 1], .F.))
					if za8 -> (dbseek (xfilial ("ZA8") + _aCadVit [_nCadVit, 1], .F.))
						reclock ('ZAL', .T.)
						zal -> zal_filial = xfilial ("ZAL")
						zal -> zal_IdZAN  = _sCodZAN
						zal -> zal_IdZA8  = _aCadVit [_nCadVit, 1]
						msunlock ()
					endif
				endif
			next
		endif

	enddo
	(_sz8) -> (dbclosearea ())
	U_LOG ('PRONTO')
return
*/
/*
user function FINA290 ()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	U_LOGiNI ()
	u_help (procname ())
	u_logtrb ("SE2")

	// Deleta lcto correspondente na conta corrente de associados.
	if se2 -> (deleted ())  // Excluiu a fatura
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += "SELECT SZI.R_E_C_N_O_"
		_oSQL:_sQuery +=  " FROM " + RETSQLNAME ("SZI") + " SZI "
		_oSQL:_sQuery += " WHERE SZI.D_E_L_E_T_ != '*'"
		_oSQL:_sQuery +=   " AND SZI.ZI_FILIAL   = '" + xfilial ("SZI") + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_ASSOC    = '" + se2 -> e2_fornece + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_LOJASSO  = '" + se2 -> e2_loja + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_DOC      = '" + se2 -> e2_num + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_SERIE    = '" + se2 -> e2_prefixo + "'"
		_oSQL:_sQuery +=   " AND SZI.ZI_PARCELA  = '" + se2 -> e2_parcela + "'"
		_oSQL:Log ()
		_nRegSZI = _oSQL:RetQry (1, .F.)
		if _nRegSZI != 0
			szi -> (dbgoto (_nRegSZI))
			reclock ("SZI", .F.)
			szi -> (dbdelete ())
			msunlock ()
		endif
	endif

	U_ML_SRArea (_aAreaAnt)
	u_logFim ()
return
*/


/*
	// Envia atualizacoes para o Mercanet
	//_oSQL := ClsSQL ():New ()
	//_oSQL:_sQuery := ""
   	//_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
	//_oSQL:_sQuery += " FROM " + RetSQLName ("SB1")
	//_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
	//_oSQL:_sQuery += " AND B1_FILIAL = '" + xfilial ("SB1") + "'"  // Deixar esta opcao para poder ler os campos memo.
	//_oSQL:_sQuery += " AND B1_COD IN ('0345', '0150')"
	//_oSQL:Log ()
	//_aDados = aclone (_oSQL:Qry2Array ())
	//For _nLinha := 1 To Len(_aDados)
	//	sb1 -> (dbgoto (_aDados [_nLinha, 1]))
	//	U_AtuMerc ("SB1", sb1 -> (recno ()))
	//next
	//da0 -> (dbgotop ())
	//do while ! da0 -> (eof ())
	//	U_AtuMerc ("DA0", da0 -> (recno ()))
	//	da0 -> (dbskip ())
	//enddo
	//sf2 -> (dbsetorder (18)) // F2_FILIAL+DTOS(F2_EMISSAO)
	//sf2 -> (dbseek (xfilial ("SF2") + "20170712", .T.))
	//do while ! sf2 -> (eof ()) .and. sf2 -> f2_filial == xfilial ("SF2") .and. dtos (sf2 -> f2_emissao) <= "20170712"
	//	u_log (sf2 -> f2_doc, sf2 -> f2_emissao)
	//	U_AtuMerc ("SF2", sf2 -> (recno ()))
	//	sf2 -> (dbskip ())
	//enddo
return
*/

/*
// --------------------------------------------------------------------------
// Cria novo registro no alias destino e copia dados do registro atual do alias origem.
static function _CopiaReg (_sOrig, _sDest)
	local _sCampo := ""
	local _nCampo := 0
	local _xDado  := NIL
	local _aAreaAnt := U_ML_SRArea ()

	//u_log ((_sDest) -> (fcount ()))
 	reclock (_sDest, .T.)
	for _nCampo = 1 to (_sDest) -> (fcount ())
		_sCampo = alltrim ((_sDest) -> (fieldname (_nCampo)))
		//u_log (_sCampo)
		if (_sOrig) -> (fieldpos (_sCampo)) > 0 .and. valtype ((_sOrig) -> &(_sCampo)) == valtype ((_sDest) -> &(_sCampo))
			_xDado = (_sOrig) -> &(_sCampo)
			//u_log (_sCampo, _xDado)
			(_sDest) -> &(_sCampo) = _xDado
		endif
	next
	msunlock ()
	U_ML_SRArea (_aAreaAnt)
return
*/
/*
	// importa cadastro de tanques
	sbe -> (dbsetorder (1)) // BE_FILIAL+BE_LOCAL+BE_LOCALIZ
	sn1 -> (dbsetorder (2)) // N1_FILIAL+N1_CHAPA
	use \robert\tanques2 shared new alias tanques
    Index on strzero (val (tanques -> filial), 2) + strzero (tanques -> tanque, 6) to &(criatrab ({}, .F.))
	u_logtrb ('tanques', .F.)
	tanques -> (dbgotop ())
	u_log (TamSX3 ("BE_LOCALIZ"))
	do while ! tanques -> (eof ())
		if strzero (val (tanques -> filial), 2) == cFilAnt
			if tanques -> tanque == 0 .or. tanques -> filial != cFilAnt
				tanques -> (dbskip ())
				loop
			endif
			//u_logtrb ('tanques', .F.)

			_sEndereco = U_TamFixo ("T" + cFilAnt + strzero (tanques -> tanque, 4), TamSX3 ("BE_LOCALIZ")[1], ' ')
			//u_log ('>>' + _sEndereco + '<<')

			// 1=Carbono;2=Concreto;3=Fibra vidro;4=Inox 304;5=Inox 316;6=Madeira alta densid;7=Madeira baixa densid
			_sMaterial = ''
			_sDescMat = ''
			if 'CARBONO' $ upper (tanques -> material)
				_sMaterial = '1'
				_sDescMat = 'CARBONO'
			elseif 'CONCRETO' $ upper (tanques -> material)
				_sMaterial = '2'
				_sDescMat = 'CONCRETO'
			elseif 'FIBRA' $ upper (tanques -> material)
				_sMaterial = '3'
				_sDescMat = 'FIBRA'
			elseif 'INOX' $ upper (tanques -> material) .and. '304' $ upper (tanques -> complmat)
				_sMaterial = '4'
				_sDescMat = 'INOX'
			elseif 'INOX' $ upper (tanques -> material) .and. '316' $ upper (tanques -> complmat)
				_sMaterial = '5'
				_sDescMat = 'INOX'
			elseif 'MADEIRA' $ upper (tanques -> material) .and. 'ALTA' $ upper (tanques -> complmat)
				_sMaterial = '6'
				_sDescMat = 'MADEIRA'
			elseif 'MADEIRA' $ upper (tanques -> material) .and. 'BAIXA' $ upper (tanques -> complmat)
				_sMaterial = '7'
				_sDescMat = 'MADEIRA'
			endif

			if sn1 -> (dbseek (xfilial ("SN1") + strzero (tanques -> patrim, 6), .F.)) 
				_sBem = sn1 -> n1_chapa
			else
				_sBem = ''
			endif
			
			_sRefrig = ''  // 1=Nao tem;2=Nao isolado;3=Isolado;4=Cintas ext.isolado;5=Cintas ext.nao isolado;6=Placas internas
			if 'CINTAS EXTERNAS - NO ISOLADO' $ upper (tanques -> refrig)
				_sRefrig = '5'
			elseif 'CINTAS EXTERNAS - ISOLADO' $ upper (tanques -> refrig)
				_sRefrig = '4'
			elseif 'PLACAS INTERNAS' $ upper (tanques -> refrig)
				_sRefrig = '6'
			elseif 'NO TEM' $ upper (tanques -> refrig)
				_sRefrig = '1'
			elseif 'NAO ISOLADO' $ upper (tanques -> refrig)
				_sRefrig = '2'
			elseif 'ISOLADO' $ upper (tanques -> refrig)
				_sRefrig = '3'
			endif

			_sRevInt = ''
			if 'NO TEM' $ upper (tanques -> revint) .or. 'SEM REVESTIMENTO' $ upper (tanques -> revint) .or. empty (tanques -> revint)
				_sRevInt = '1'
			elseif 'EPOXI' $ upper (tanques -> revint)
				_sRevInt = '2'
			elseif 'FIBRA' $ upper (tanques -> revint)
				_sRevInt = '3'
			endif

			_sApoio = ''
			if 'PS' $ upper (tanques -> apoio)
				_sApoio = '1'
			elseif 'MURETAS' $ upper (tanques -> apoio)
				_sApoio = '2'
			elseif 'BASE TOTAL' $ upper (tanques -> apoio)
				_sApoio = '3'
			endif
			
			_sUso = ''
			_sLocal = '03'
			if "UTILIDADES" $ upper (tanques -> uso)
				_sUso = '4'
			elseif "PROCESSAMENTO" $ upper (tanques -> uso)
				_sUso = '3'
			elseif "ESTOCAGEM" $ upper (tanques -> uso)
				_sUso = '1'
			elseif "FORMUL" $ upper (tanques -> uso)
				_sUso = '2'
				if cFilAnt == '01'
					_sLocal = '07'
				endif
			endif
			
			_sSituacao = ''
			if "EM INSTAL" $ upper (tanques -> uso)
				_sSituacao = '2'
			elseif "DESATIVADO" $ upper (tanques -> uso)
				_sSituacao = '3'
			elseif "INVESTIM" $ upper (tanques -> uso)
				_sSituacao = '4'
			ELSEif "INSTALADO" $ upper (tanques -> uso)
				_sSituacao = '1'
			endif

			if ! sbe -> (dbseek (xfilial ("SBE") + _sLocal + _sEndereco, .F.))
				_aAutoSBE := {}
				aadd (_aAutoSBE, {"BE_LOCAL",   _sLocal, NIL})
				aadd (_aAutoSBE, {"BE_LOCALIZ", _sEndereco, NIL})
				aadd (_aAutoSBE, {"BE_DESCRIC", 'TANQUE ' + strzero (tanques -> tanque, 4) + ' (' + _sDescMat + ' ' + alltrim (transform (tanques -> volnom, '@E 9999999')) + ' L)', NIL})
				aadd (_aAutoSBE, {"BE_VATANQ",  'S', NIL})
				aadd (_aAutoSBE, {"BE_VAMATL",  _sMaterial, NIL})
				aadd (_aAutoSBE, {"BE_VAREFRI", _sRefrig, NIL})
				aadd (_aAutoSBE, {"BE_VABEM",   _sBem, NIL})
				aadd (_aAutoSBE, {"BE_VAOBS",   NoAcento (alltrim (tanques -> obs)), NIL})
				aadd (_aAutoSBE, {"BE_VADIAM",  tanques -> diam, NIL})
				aadd (_aAutoSBE, {"BE_ALTURLC", tanques -> altura, NIL})
				aadd (_aAutoSBE, {"BE_CAPACID", tanques -> volnom, NIL})
				aadd (_aAutoSBE, {"BE_VAMATL",  _sMaterial, NIL})
				aadd (_aAutoSBE, {"BE_VAREFRI", _sRefrig, NIL})
				aadd (_aAutoSBE, {"BE_VAAPOIO", _sApoio,  NIL})
				aadd (_aAutoSBE, {"BE_VAREVIN", _sRevInt, NIL})
				aadd (_aAutoSBE, {"BE_VAUSO",   _sUso, NIL})
				aadd (_aAutoSBE, {"BE_VAVFINO", left (tanques -> vinfino, 1), NIL})
				aadd (_aAutoSBE, {"BE_VAVCOMU", left (tanques -> vincomum, 1), NIL})
				aadd (_aAutoSBE, {"BE_VAGASEI", left (tanques -> gaseif, 1), NIL})
				aadd (_aAutoSBE, {"BE_VAMOSTO", left (tanques -> mostosulf, 1), NIL})
				aadd (_aAutoSBE, {"BE_VASUCOI", left (tanques -> sucoint, 1), NIL})
				aadd (_aAutoSBE, {"BE_VASUCOA", left (tanques -> sucoassep, 1), NIL})
				aadd (_aAutoSBE, {"BE_VANECTA", left (tanques -> nectar, 1), NIL})
				aadd (_aAutoSBE, {"BE_VASITUA", _sSituacao, NIL})
				_aAutoSBE := aclone (U_OrdAuto (_aAutoSBE))
				u_log (_aAutoSBE)
				lMSErroAuto := .F.
				lMSHelpAuto := .F.
				private _sErroAuto  := ""
				MSExecAuto ({|_x, _y| MATA015 (_x, _y)}, _aAutoSBE, 3)
				if lMSErroAuto
					_sErro := memoread (NomeAutoLog ())
					u_log ('Erro:', _sErro)
				endif
				if ! empty (_sErroAuto)
					u_log (_sErroAuto)
				endif
			else
				u_log ('Endereco ' + _sEndereco + ' jah cadastrado')
			endif
		endif
		tanques -> (dbskip ())
	enddo
return
*/
/*
	// Testes com XML.
	local _sXML      := ""
	local _oXml      := NIL
	local _sError    := ''
	local _sWarning  := ''
	
	_sXML := '<?xml version="1.0" encoding="UTF-8"?>'
	_sXML += '<Param>'
	_sXML += '<Produto>0005           </Produto>'
	_sXML += '<Quant>10.5</Quant>'
	_sXML += '<Produto>0150           </Produto>'
	_sXML += '<Quant>7</Quant>'
	_sXML += '</Param>'
	
	// Cria o Objeto XML.
   	_oXML := XmlParser (_sXML, "_", @_sError, @_sWarning)
	If !Empty (_sError) .or. !Empty (_sWarning)
		u_help (_sError + ' ' + _sWarning)
	else
		u_log (_oXML)
	endif

	// oXml := XmlParserFile( cFile, "_", @cError, @cWarning )
return
*/

/*
	sb1 -> (dbsetorder (1))
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := " SELECT DISTINCT D2_COD FROM SD2010 WHERE D2_EMISSAO >= '20160701'"
	_oSQL:_sQuery += " AND EXISTS (SELECT * FROM SB5010 WHERE D_E_L_E_T_ = '' AND B5_COD = D2_COD AND B5_VASISDE = 'S')"
	_oSQL:_sQuery += " UNION ALL"
	_oSQL:_sQuery += " SELECT DISTINCT D1_COD FROM SD1010 WHERE D1_DTDIGIT >= '20160701'"
	_oSQL:_sQuery += " AND EXISTS (SELECT * FROM SB5010 WHERE D_E_L_E_T_ = '' AND B5_COD = D1_COD AND B5_VASISDE = 'S')"
	_aRetSQL := aclone (_oSQL:Qry2Array ())
	for _nRetSQL = 1 to len (_aRetSQL)
		if sb1 -> (dbseek (xfilial ("SB1") + _aRetSQL [_nRetSQL, 1], .F.))
			_oSisDec := ClsSisd ():New (sb1 -> b1_cod, 'SB5', cFilAnt)
			_oSisDec:ValProd ()
			for _nErro = 1 to len (_oSisDec:Erros)
				u_log ("ERRO  '" + sb1 -> b1_cod + '-' + sb1 -> b1_desc + "': " + _oSisDec:Erros [_nErro])
			next
		endif
	next
return
*/

/*
	// Recupera cupons que constam na impressora fiscal e nao no sistema.
	_aCupons := {}
	// Nao apagar estas linhas, pois jah me ajudaram a identificar cupons reincluidos...
	//               Fil   Orc.loja  NF/doc       Serie  Emissao            Produt              Qt   VlUni  AliqICM  ItemSD2 ItemSL2 Portador
//	aadd (_aCupons, {'13', '021199', '022472   ', '003', stod ('20160721'), '8155           ',  2,  39.00,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '020852', '022106   ', '003', stod ('20160711'), '8239           ',  6,  49.50,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '021019', '022282   ', '003', stod ('20160716'), '8231           ',  2,   2.50,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '021019', '022282   ', '003', stod ('20160716'), '8095           ',  1,  14.80,    18,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'10', '012516', '014119   ', 'CL4', stod ('20160701'), '8247           ',  2,   4.60,    18,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'10', '012822', '014449   ', 'CL4', stod ('20160721'), '8164           ',  1,  19.50,    18,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'10', '012822', '014449   ', 'CL4', stod ('20160721'), '8000           ',  1,   2.00,    18,    '02',   '02',   'CX3'})

//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8148           ',  1,  14.50,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8028           ',  1,  17.50,    18,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8212           ',  2,  14.00,    18,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8124           ',  1,  14.05,    18,    '04',   '04',   'CY3'})
//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8247           ',  2,   8.50,    18,    '05',   '05',   'CY3'})
//	aadd (_aCupons, {'13', '019733', '020930   ', '003', stod ('20160616'), '8192           ',  4,  22.55,    18,    '06',   '06',   'CY3'})
//	aadd (_aCupons, {'13', '019804', '021004   ', '003', stod ('20160617'), '8168           ',  1,  17.90,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '019874', '021077   ', '003', stod ('20160618'), '8104           ',  2,  24.70,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '019874', '021077   ', '003', stod ('20160618'), '8104           ',  2,  24.70,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '020102', '021317   ', '003', stod ('20160623'), '8163           ',  4,  15.15,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '020102', '021317   ', '003', stod ('20160623'), '8093           ',  2,  15.15,    18,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '017157', '018218   ', '003', stod ('20160408'), '8155           ',  1,  17.70,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '017536', '018611   ', '003', stod ('20160422'), '8146           ',  2,   7.50,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'10', '011305', '012809   ', 'CL4', stod ('20160317'), '8192           ',  1,  14.90,    18,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'13', '015908', '016866   ', '003', stod ('20160222'), '8179           ', 15,   4.50,    18,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '015908', '016866   ', '003', stod ('20160222'), '8077           ',  1,   5.00,    18,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'10', '010503', '011934   ', 'CL4', stod ('20151222'), '8066           ',  6,  16.75,    17,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'10', '010503', '011934   ', 'CL4', stod ('20151222'), '8147           ', 12,   3.95,    17,    '02',   '02',   'CX3'})
//	aadd (_aCupons, {'13', '013674', '014455   ', '003', stod ('20151211'), '8092           ',  1,  14.70,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '013674', '014455   ', '003', stod ('20151211'), '8154           ',  1,  12.50,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '012582', '013286   ', '003', stod ('20151105'), '8063           ',  1,  21.40,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011685', '012313   ', '003', stod ('20151002'), '8092           ',  1,  14.70,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '012122', '012783   ', '003', stod ('20151017'), '8222           ',  2,  22.70,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '012122', '012783   ', '003', stod ('20151017'), '8175           ',  6,  10.45,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8125           ',  1,  11.80,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8127           ',  1,  11.80,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8126           ',  1,  11.80,    17,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8123           ',  1,  11.80,    17,    '04',   '04',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8154           ',  6,  11.80,    17,    '05',   '05',   'CY3'})
//	aadd (_aCupons, {'13', '011589', '012210   ', '003', stod ('20150929'), '8148           ',  3,  11.80,    17,    '06',   '06',   'CY3'})
//	aadd (_aCupons, {'13', '011590', '012211   ', '003', stod ('20150929'), '8222           ',  1,  23.00,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011590', '012211   ', '003', stod ('20150929'), '8192           ',  1,  20.30,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011590', '012211   ', '003', stod ('20150929'), '8235           ', 24,   1.1875,  17,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8233           ',  3,   3.00,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8231           ',  2,   3.00,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8232           ',  2,   3.00,    17,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8134           ',  2,   6.90,    17,    '04',   '04',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8135           ',  1,   6.90,    17,    '05',   '05',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8163           ',  1,  14.70,    17,    '06',   '06',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8096           ',  1,  12.75,    17,    '07',   '07',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8178           ',  3,   4.70,    17,    '08',   '08',   'CY3'})
//	aadd (_aCupons, {'13', '011591', '012212   ', '003', stod ('20150929'), '8179           ',  3,   4.70,    17,    '09',   '09',   'CY3'})
//	aadd (_aCupons, {'13', '011592', '012213   ', '003', stod ('20150929'), '8092           ',  3,  10.70,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011592', '012213   ', '003', stod ('20150929'), '8093           ',  1,  10.70,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011593', '012214   ', '003', stod ('20150929'), '8123           ', 10,   6.95,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011593', '012214   ', '003', stod ('20150929'), '8127           ',  2,   6.95,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011593', '012214   ', '003', stod ('20150929'), '8148           ',  1,  12.50,    17,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '011593', '012214   ', '003', stod ('20150929'), '8154           ',  1,  12.50,    17,    '04',   '04',   'CY3'})
//	aadd (_aCupons, {'13', '011593', '012214   ', '003', stod ('20150929'), '8122           ',  1,   4.70,    17,    '05',   '05',   'CY3'})
//	aadd (_aCupons, {'13', '011594', '012215   ', '003', stod ('20150929'), '8194           ',  1,    8.5,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011594', '012215   ', '003', stod ('20150929'), '8167           ',  1,   15.0,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '011595', '012216   ', '003', stod ('20150929'), '8102           ',  1,   25.9,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011596', '012217   ', '003', stod ('20150929'), '8106           ',  2,   13.4,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '011596', '012217   ', '003', stod ('20150929'), '8233           ',  2,    2.5,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'10', '009481', '010850   ', 'CL4', stod ('20150929'), '8178           ',  1,    2.4,    17,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'10', '009481', '010850   ', 'CL4', stod ('20150929'), '8244           ',  1,   1.25,    17,    '02',   '02',   'CX3'})
//	aadd (_aCupons, {'10', '009481', '010850   ', 'CL4', stod ('20150929'), '8000           ',  1,  19.85,    17,    '03',   '03',   'CX3'})
//	aadd (_aCupons, {'10', '009481', '010850   ', 'CL4', stod ('20150929'), '8000           ',  1,    6.5,    17,    '04',   '04',   'CX3'})
//	aadd (_aCupons, {'10', '009482', '010851   ', 'CL4', stod ('20150929'), '8157           ',  2,   30.0,    17,    '01',   '01',   'CX3'})
//	aadd (_aCupons, {'13', '008839', '009271   ', '003', stod ('20150702'), '8092           ',  2,   12.7,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '008839', '009271   ', '003', stod ('20150702'), '8163           ',  1,   12.7,    17,    '02',   '02',   'CY3'})
//	aadd (_aCupons, {'13', '008839', '009271   ', '003', stod ('20150702'), '8145           ',  1,   10.4,    17,    '03',   '03',   'CY3'})
//	aadd (_aCupons, {'13', '008839', '009271   ', '003', stod ('20150702'), '8092           ',  1,    9.5,    17,    '04',   '04',   'CY3'})
//	aadd (_aCupons, {'13', '006908', '007243   ', '003', stod ('20150505'), '8104           ',  1,   14.2,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '006595', '006912   ', '003', stod ('20150428'), '8157           ',  1,   15.5,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'13', '004592', '004775   ', 'CL3', stod ('20150213'), '8066           ',  3,   19.0,    17,    '01',   '01',   'CY3'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8213           ',  1,   12.0,    17,    '01',   '01'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '2144           ',  2,   16.0,    17,    '02',   '02'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8155           ',  1,   30.9,    17,    '03',   '03'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8093           ',  1,   13.7,    17,    '04',   '04'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8222           ',  1,   27.5,    17,    '05',   '05'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8066           ',  1,   11.7,    17,    '06',   '06'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8000           ',  1,    2.0,    17,    '07',   '07'})
//	aadd (_aCupons, {'10', '007808', '008997   ', 'CL4', stod ('20150219'), '8192           ',  1,   19.0,    17,    '08',   '08'})

//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8192           '           	,3	, 19.5,	20,	'01',	'01',	'C03'})
//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8156           '           	,1	, 19.5,	20,	'02',	'02',	'C03'})
//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8145           '           	,1	, 13.2,	20,	'03',	'03',	'C03'})
//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8168           '           	,5	, 11.5,	20,	'04',	'04',	'C03'})
//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8170           '           	,3	, 11.5,	20,	'05',	'05',	'C03'})
//aadd (_aCupons, {'08', '000256', '000249   ', '001', stod ('20160816'),	'8169           '           	,1	, 11.5,	20,	'06',	'06',	'C03'})

//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8066           '           	,12	, 18.4,	20,	'01',	'01',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8156           '           	,1	, 19.5,	20,	'02',	'02',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8143           '           	,1	, 13.2,	20,	'03',	'03',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8249           '           	,1	, 5.3,	20,	'04',	'04',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8250           '           	,1	, 5.3,	20,	'05',	'05',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8253           '           	,3	, 1.4,	20,	'06',	'06',	'C03'})
//aadd (_aCupons, {'08', '000257', '000250   ', '001', stod ('20160816'),	'8252           '           	,2	, 1.4,	20,	'07',	'07',	'C03'})

//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8156           '           	,2 	, 19.5,	17,	'01',	'01',	'C03'})
//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8250           '           	,2 	,  5.3,	17,	'02',	'02',	'C03'})
//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8251           '           	,1 	,  5.3,	17,	'03',	'03',	'C03'})
//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8249           '           	,1 	,  5.3,	17,	'04',	'04',	'C03'})
//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8243           '           	,1 	,  5.3,	17,	'05',	'05',	'C03'})
//aadd (_aCupons, {'08', '000250', '000243   ', '001', stod ('20160810'),	'8231           '           	,4 	,  2.7,	17,	'06',	'06',	'C03'})

//aadd (_aCupons, {'08', '000252', '000245   ', '001', stod ('20160810'),	'8066           '           	,2 	, 18.4,	17,	'01',	'01',	'C03'})
//aadd (_aCupons, {'08', '000252', '000245   ', '001', stod ('20160810'),	'8251           '           	,1 	,  5.3,	17,	'02',	'02',	'C03'})
//aadd (_aCupons, {'08', '000252', '000245   ', '001', stod ('20160810'),	'8249           '           	,1 	,  5.3,	17,	'03',	'03',	'C03'})
//aadd (_aCupons, {'08', '000252', '000245   ', '001', stod ('20160810'),	'8231           '           	,12	,  2.7,	17,	'04',	'04',	'C03'})

//	_CriaCupom (_aCupons)
return
*/

//Get-ChildItem *.pr* | Select-String -pattern "wait" | Select-String -NotMatch "CursorWait"

/*
//	U_LOG (PutSX1Help ("teste1", {"Teste de pergunta"}, {'teste2'}, {'teste3'}, .T.))
	PutSX1 ('ROBERT', '01', 'teste', 'teste', 'teste', 'mv_ch1', 'C', 6, 0, 0, 'G', '', 'SA1', '', '', 'mv_par01',; 
	'', '', '', '000001',; 
	'', '', '',; 
	'', '', '',; 
	'', '', '',; 
	'', '', '',; 
	{'linha1', 'linha2'}, {}, {}, '')
*/
/* testes para criar help de pergunta cfe chamado da Totvs
Local aHelpP := {}
Local aHelpE := {}
Local aHelpS := {}
Local aAreaSX1 := SX1->(GetArea())

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := "tstputsx1 "

if dbSeek(cPerg + '01')
Reclock("SX1", .F.)
SX1->(dbDelete())
MsUnlock()
endif

// mv_par01 - Data de?
Aadd( aHelpP, "Teste 01 " )
Aadd( aHelpP, "processamento. " )
Aadd( aHelpP, " " )
Aadd( aHelpE, "Teste 01 " )
Aadd( aHelpE, "processamento. " )
Aadd( aHelpE, " " )
Aadd( aHelpS, "Teste 01 " )
Aadd( aHelpS, "processamento. " )
Aadd( aHelpS, " " )
PutSX1(cPerg,"01","Data de?","Data de?","Data de?","MV_CH1","D",8,0,0,"G"," "," "," "," ","mv_par01"," "," "," "," "," "," "," "," "," "," "," "," "," "," "," "," ",aHelpP,aHelpE,aHelpS)

Return	
*/

//	U_BatXML("\\192.168.1.2\Siga\Protheus11\protheus_data\xml_NFe\", 200, .F.)
//	U_BatXML("\\192.168.1.2\Siga\Protheus11\protheus_data\xml_NFe\CT-e\", 100, .F.)
//return

/*
	// Simulacao: Violeta + bordo + assoc. da JC que entregaram na 01 + organicas.
	// Bordo e violeta: paga 100%
	// 9822 BORDO DE BORDADURA                                          
	// 9925 BORDO (IVES)                                                
	// 9959 BORDO ORGANICO                                              
	// 9948 BORDO EM CONVERSAO P/ ORGANICA
	// 9976 BRS VIOLETA                                                                               
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'A')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '9822/9925/9948/9976')  // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '18', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'CEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Associados da L. Jacinto que entregaram na matriz: paga 100%
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '01')   // Filial inicial
	U_GravaSX1 (cPerg, '12', '01')   // Filial final
	U_GravaSX1 (cPerg, '13', 'B')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas organicas parte 1 (assoc. da Jacinto exceto os que entregaram na F.01)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '02')   // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'C')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'O')    // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas organicas parte 2 (exceto assoc. da Jacinto, pois j entraram no lote anterior)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'D')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'AL/PO/SA/SP/SV')  // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'O')    // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas tintoreas parte 1 (assoc. da Jacinto exceto os que entregaram na F.01)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '02')   // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'E')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas tintoreas parte 2 (exceto assoc. da Jacinto, pois j entraram no lote anterior)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'F')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'AL/PO/SA/SP/SV')  // Coop. origem.
	U_GravaSX1 (cPerg, '19', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// O que sobrou vai ateh chegar a 50% do valor total da safra: parte 1 - o resto do pessoal da Jacinto.
	// Por enquanto vou apenas separar numa parcela para conferir quantidades.
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '02')   // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'G')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// O que sobrou vai ateh chegar a 50% do valor total da safra: parte 2 - exceto o pessoal da Jacinto, pois j entraram no lote anterior
	// Por enquanto vou apenas separar numa parcela para conferir quantidades.
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', 'H')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'AL/PO/SA/SP/SV')  // Coop. origem.
	U_GravaSX1 (cPerg, '19', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'CEB')  // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
return
*/

/*
	// Ajusta OPs safra 2016
	_aOP := {}
	aadd (_aOP, {'08724501002', 142790})
	aadd (_aOP, {'08724601001', 64100})
	aadd (_aOP, {'08731801001', 66150})
	aadd (_aOP, {'08733601001', 41200})
	aadd (_aOP, {'08734601003', 30100})
	aadd (_aOP, {'08737901001', 29400})
	aadd (_aOP, {'08738201001', 22000})
	aadd (_aOP, {'08742201001', 2200})
	aadd (_aOP, {'08742301001', 44100})
	aadd (_aOP, {'08742401001', 44100})
	aadd (_aOP, {'08747001001', 33150})
	aadd (_aOP, {'08747301001', 55250})
	aadd (_aOP, {'08747501001', 24300})
	aadd (_aOP, {'08753101001', 44200})
	aadd (_aOP, {'08753501001', 13250})
	aadd (_aOP, {'08753701001', 46550})
	aadd (_aOP, {'08754001001', 33360})
	aadd (_aOP, {'08756701001', 55250})
	aadd (_aOP, {'08757601001', 66300})
	aadd (_aOP, {'08761401001', 66300})
	aadd (_aOP, {'08763401001', 32300})
	aadd (_aOP, {'08763501001', 33150})
	aadd (_aOP, {'08763801001', 33600})
	aadd (_aOP, {'08766901001', 86600})
	aadd (_aOP, {'08768201001', 25600})
	aadd (_aOP, {'08770601001', 142800})
	aadd (_aOP, {'08770901001', 32700})
	aadd (_aOP, {'08774601001', 14900})
                              
	aadd (_aOP, {'08725001001', 71000})
	aadd (_aOP, {'08753801001', 9390})
	aadd (_aOP, {'08754101001', 5790})
	aadd (_aOP, {'08771001001', 28594})
	aadd (_aOP, {'08770801001', 28616})
                              
	aadd (_aOP, {'08720201001', 176800})
	aadd (_aOP, {'08722101001', 37200})
	aadd (_aOP, {'08722801001', 37200})
	aadd (_aOP, {'08724701001', 69800})
	aadd (_aOP, {'08727601001', 65100})
	aadd (_aOP, {'08729001001', 49700})
	aadd (_aOP, {'08730401001', 59800})
	aadd (_aOP, {'08730601001', 30250})
	aadd (_aOP, {'08733401001', 32600})
	aadd (_aOP, {'08736001001', 66300})
	aadd (_aOP, {'08736901001', 74400})
	aadd (_aOP, {'08736901001', 74400})
	aadd (_aOP, {'08738301001', 37200})
	aadd (_aOP, {'08739001001', 35400})
	aadd (_aOP, {'08739401001', 20950})
	aadd (_aOP, {'08739501001', 69600})
	aadd (_aOP, {'08739601001', 71800})
	aadd (_aOP, {'08740601001', 23300})
	aadd (_aOP, {'08741101001', 81800})
	aadd (_aOP, {'08741201001', 37200})
	aadd (_aOP, {'08741301001', 81800})
	aadd (_aOP, {'08743001001', 66850})
	aadd (_aOP, {'08743701001', 939100})
	aadd (_aOP, {'08743801001', 34900})
	aadd (_aOP, {'08744601001', 53000})
	aadd (_aOP, {'08745001001', 34900})
	aadd (_aOP, {'08745101001', 35400})
	aadd (_aOP, {'08746101001', 46500})
	aadd (_aOP, {'08747101001', 35400})
	aadd (_aOP, {'08747601001', 60500})
	aadd (_aOP, {'08747701001', 36900})
	aadd (_aOP, {'08747701001', 36900})
	aadd (_aOP, {'08748701001', 66300})
	aadd (_aOP, {'08748801001', 82900})
	aadd (_aOP, {'08750001001', 39500})
	aadd (_aOP, {'08750201001', 49700})
	aadd (_aOP, {'08750301001', 16300})
	aadd (_aOP, {'08750701001', 54100})
	aadd (_aOP, {'08752101001', 77300})
	aadd (_aOP, {'08752201001', 82500})
	aadd (_aOP, {'08762001001', 66300})
	aadd (_aOP, {'08762101001', 66300})
	aadd (_aOP, {'08762201001', 38700})
	aadd (_aOP, {'08762301001', 65200})
	aadd (_aOP, {'08762401001', 165200})
	aadd (_aOP, {'08762501001', 457200})

	for _nOP = 1 to len (_aOP)
		u_logIni (_aOP [_nOP, 1])
		sc2 -> (dbsetorder (1))
		if ! sc2 -> (dbseek ('01' + _aOP [_nOP, 1], .F.))
			u_log ('OP nao cadastrada')
		else
			_sWhere := " where D_E_L_E_T_ = ''"
			_sWhere +=   " and D3_FILIAL  = '" + sc2 -> c2_filial + "'"
			_sWhere +=   " and D3_OP      = '" + _aOP [_nOP, 1] + "'"
			_sWhere +=   " and D3_CF      = 'PR0'"
			_sWhere +=   " and D3_QUANT   = " + cvaltochar (sc2 -> c2_quje)
			_oSQL := ClsSQL ():New ()
			_oSQL:_sQuery = "select count (*) FROM SD3010 " + _sWhere
			if _oSQL:RetQry () != 1
				u_log ('Nao encontrei apontamento (ou encontrei mais de 1)')
			else
				_oSQL:_sQuery := "update SD3010 set D3_QUANT = " + cvaltochar (_aOP [_nOP, 2]) + _sWhere
				_oSQL:Log ()
				if _oSQL:Exec ()
					//u_log (sc2 -> c2_quje * 100 / _aOP [_nOP, 2])
					reclock ("SC2", .F.)
					sc2 -> c2_quje = _aOP [_nOP, 2]
					msunlock ()
				endif
			endif
		endif
		u_logFim (_aOP [_nOP, 1])
	next
return
*/


////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
	// Gera pre-notas de pagamento de safra 2016, pois teremos umas politicas bem divertidas...
	//
	// Bordo e violeta: paga 100%
	// 9822 BORDO DE BORDADURA                                          
	// 9925 BORDO (IVES)                                                
	// 9959 BORDO ORGANICO                                              
	// 9948 BORDO EM CONVERSAO P/ ORGANICA
	// 9976 BRS VIOLETA                                                                               
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '1')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '9822/9925/9959/9948/9976')  // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '')     // Exceto estas variedades.
	U_GravaSX1 (cPerg, '18', '')     // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Associados da L. Jacinto que entregaram na matriz: paga 100%
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '01')   // Filial inicial
	U_GravaSX1 (cPerg, '12', '01')   // Filial final
	U_GravaSX1 (cPerg, '13', '2')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9959/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 3)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas tintoreas: paga 50% + 50%: parte 1 (assoc. da Jacinto exceto os que entregaram na F.01)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '02')   // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '3')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9959/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// Demais uvas tintoreas: paga 50% + 50%: parte 2 (exceto assoc. da Jacinto, pois j entraram no lote 3)
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '4')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9959/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'AL/PO/SA/SP/SV')  // Coop. origem.
	U_GravaSX1 (cPerg, '19', 1)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// O que sobrou vai ateh chegar a 50% do valor total da safra: parte 1 - o resto do pessoal da Jacinto.
	// Por enquanto vou apenas separar numa parcela para conferir quantidades.
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '02')   // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '5')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9959/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'JC')   // Coop. origem.
	U_GravaSX1 (cPerg, '19', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)

	// O que sobrou vai ateh chegar a 50% do valor total da safra: parte 2 - exceto o pessoal da Jacinto, pois j entraram no lote 5
	// Por enquanto vou apenas separar numa parcela para conferir quantidades.
	cPerg = "VAGNF1"
	U_GravaSX1 (cPerg, '01', '')     // Produtor inicial
	U_GravaSX1 (cPerg, '02', '')     // Loja produtor inicial
	U_GravaSX1 (cPerg, '03', 'z')    // Produtor final
	U_GravaSX1 (cPerg, '04', 'z')    // Loja produtor final
	U_GravaSX1 (cPerg, '05', '2016') // Safra referencia
	U_GravaSX1 (cPerg, '06', '')     // Contranota entrada uva inicial
	U_GravaSX1 (cPerg, '07', 'z')    // Contranota entrada uva final
	U_GravaSX1 (cPerg, '08', '30 ')  // Serie das NF de entrada de uva
	U_GravaSX1 (cPerg, '09', 6)      // Maximo itens por NF produtor
	U_GravaSX1 (cPerg, '10', 2)      // Geracao p/ DCO (so safra 2009) [S/N]
	U_GravaSX1 (cPerg, '11', '')     // Filial inicial
	U_GravaSX1 (cPerg, '12', 'zz')   // Filial final
	U_GravaSX1 (cPerg, '13', '6')    // Gerar com qual parcela
	U_GravaSX1 (cPerg, '14', 3)      // Variedade de uva [Comum/Fina/Todas]
	U_GravaSX1 (cPerg, '15', 3)      // Cor da uva [Tinta/Bca+rose/Todas]
	U_GravaSX1 (cPerg, '16', '')     // Apenas estas variedades.
	U_GravaSX1 (cPerg, '17', '9822/9925/9959/9948/9976')    // Exceto estas variedades (bordo e violeta - ja pagas na primeira parcela)
	U_GravaSX1 (cPerg, '18', 'AL/PO/SA/SP/SV')  // Coop. origem.
	U_GravaSX1 (cPerg, '19', 2)      // Tintoreas [So tintoreas/Exceto tintoreas/Todas]
	U_GravaSX1 (cPerg, '20', 'OCEB') // [O]rganicas / [C]onvencionais / [E]m coversao / [B]ordadura.
	U_VA_GNF1 (.T.)
return
*/	
/*
Beleza Robert, 
tentei tambm com a SoftLock, mas me parece que ele bloqueava o registro tambm.
Consegui fazer com a funo RLOCK( RECNO ).. essa ele retorna falso se no conseguir bloquear.
Valeu!
Att.
Germano Possamai Neto
*/

/*
// --------------------------------------------------------------------------
static function _CriaCupom (_aCupons)
	LOCAL _nCupom := 0
	local _sCliente := ""
	local _sLoja := ""
	local _nValBrut := 0
	local _aImpCD2 := {}
	local _nImpCD2 := 0

	u_logIni ()
	u_log (_aCupons)
	
	begin transaction
	for _nCupom = 1 to len (_aCupons)
		if ascan (_aCupons, {|_aVal| _aVal [9] != _aCupons [_nCupom, 9]}) > 0
			u_help ("Mais de uma aliquota de ICMS. Sem tratamento.")
			return  // Cai fora sem usar loop para evitar o 'end transaction'.
		endif
	next
	for _nCupom = 1 to len (_aCupons)
		if ascan (_aCupons, {|_aVal| _aVal [3] != _aCupons [_nCupom, 3]}) > 0
			u_help ("Mais de um cupom. Sem tratamento.")
			return  // Cai fora sem usar loop para evitar o 'end transaction'.
		endif
	next
	_sCliente := '000000'
	_sLoja := '01'
	_nValBrut = 0
	for _nCupom = 1 to len (_aCupons)
		_nValBrut += _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
	next
	u_log ('ValBrut:', _nValBrut)

	for _nCupom = 1 to len (_aCupons)
		if cFilAnt != _aCupons [_nCupom, 1]
			u_help ("Filial errada")
			return  // Cai fora sem usar loop para evitar o 'end transaction'.
		endif
		u_logIni (_aCupons [_nCupom, 3] + ' ' + _aCupons [_nCupom, 6])
		sl1 -> (dbsetorder (1))  // L1_FILIAL+L1_NUM
		if ! sl1 -> (dbseek (xfilial ("SL1") + _aCupons [_nCupom, 2], .F.))
			u_help ("falta criar sl1")
			return  // Cai fora sem usar loop para evitar o 'end transaction'.
		else
			U_LOG ('Alterando SL1')
			reclock ("SL1", .F.)
			sl1 -> (dbrecall ())
			sl1 -> l1_doc     = _aCupons [_nCupom, 3]
			sl1 -> l1_serie   = _aCupons [_nCupom, 4]
			sl1 -> l1_emisnf  = _aCupons [_nCupom, 5]
			sl1 -> l1_dinheir = sl1 -> l1_valmerc
			sl1 -> l1_entrada = sl1 -> l1_valmerc
			sl1 -> l1_valicm  = sl1 -> l1_valbrut * _aCupons [_nCupom, 9] / 100
			sl1 -> l1_numcfis = _aCupons [_nCupom, 3]
			sl1 -> l1_pdv     = '001'
			sl1 -> l1_tipo    = 'V'
			sl1 -> l1_operado = _aCupons [_nCupom, 12]
			sl1 -> l1_situa   = 'OK'
			sl1 -> l1_storc   = ''
			msunlock ()
			
			sl2 -> (dbsetorder (1))  // L2_FILIAL+L2_NUM+L2_ITEM+L2_PRODUTO
			if ! sl2 -> (dbseek (xfilial ("SL2") + _aCupons [_nCupom, 2] + _aCupons [_nCupom, 11] + _aCupons [_nCupom, 6], .F.))
				u_help ("falta criar sl2 item '" + _aCupons [_nCupom, 11] + "'")
				return  // Cai fora sem usar loop para evitar o 'end transaction'.
			else
				U_LOG ('Alterando SL2')
				if sl2 -> l2_quant != _aCupons [_nCupom, 7]
					u_help ("quant.divergente SL2")
					return  // Cai fora sem usar loop para evitar o 'end transaction'.
				endif
				reclock ("SL2", .F.)
				sl2 -> (dbrecall ())
				sl2 -> l2_vendido = 'S'
				sl2 -> l2_doc     = _aCupons [_nCupom, 3]
				sl2 -> l2_serie   = _aCupons [_nCupom, 4]
				sl2 -> l2_valicm  = sl2 -> l2_baseicm * _aCupons [_nCupom, 9] / 100
				//sl2 -> l2_sittrib = 'T' + _nAliquota_ICMS_verificar_aqui
				sl2 -> l2_pdv     = '001'
				msunlock ()
			endif
			
			sf2 -> (dbsetorder (1))  // F2_FILIAL+F2_DOC+F2_SERIE+F2_CLIENTE+F2_LOJA+F2_FORMUL+F2_TIPO
			if ! sf2 -> (dbseek (xfilial ("SF2") + _aCupons [_nCupom, 3] + _aCupons [_nCupom, 4] + _sCliente + _sLoja, .F.))
				u_log ("Criando SF2")
				reclock ("SF2", .T.)
			else
				u_log ('Alterando SF2')
				reclock ("SF2", .F.)
			endif
			sf2 -> f2_filial  = xfilial ("SF2")
			sf2 -> f2_doc     = _aCupons [_nCupom, 3]
			sf2 -> f2_serie   = _aCupons [_nCupom, 4]
			sf2 -> f2_cliente = _sCliente
			sf2 -> f2_loja    = _sLoja
			sf2 -> f2_cond    = '097'
			sf2 -> f2_dupl    = _aCupons [_nCupom, 3]
			sf2 -> f2_emissao = _aCupons [_nCupom, 5]
			sf2 -> f2_est     = GetMv ("MV_ESTADO")
			sf2 -> f2_tipocli = 'F'
			sf2 -> f2_valbrut = _nValBrut
			sf2 -> f2_baseicm = _nValBrut
			sf2 -> f2_valicm  = _nValBrut * _aCupons [1, 9] / 100
			sf2 -> f2_valmerc = _nValBrut
			sf2 -> f2_tipo    = 'N'
			sf2 -> f2_vend1   = '060'
			sf2 -> f2_dtlanc  = ctod ('')  // Para poder 
			sf2 -> f2_valfat  = _nValBrut
			sf2 -> f2_especie = 'NFCE'
			sf2 -> f2_pdv     = '001'
			sf2 -> f2_ecf     = 'S'
			sf2 -> f2_prefixo = _aCupons [_nCupom, 4]
			sf2 -> f2_basimp5 = _nValBrut
			sf2 -> f2_basimp6 = _nValBrut
			sf2 -> f2_valimp5 = _nValBrut * 7.6 / 100
			sf2 -> f2_valimp6 = _nValBrut * 1.65 / 100
			sf2 -> f2_reciss  = '2'
			msunlock ()
			
			sd2 -> (dbsetorder (3))  // D2_FILIAL+D2_DOC+D2_SERIE+D2_CLIENTE+D2_LOJA+D2_COD+D2_ITEM
			if ! sd2 -> (dbseek (xfilial ("SD2") + _aCupons [_nCupom, 3] + _aCupons [_nCupom, 4] + _sCliente + _sLoja + _aCupons [_nCupom, 6] + _aCupons [_nCupom, 10], .F.))
				u_log ("Criando SD2")
				reclock ("SD2", .T.)
			else
				u_log ('Alterando SD2')
				reclock ("SD2", .F.)
			endif
			sb1 -> (dbsetorder (1))
			if ! sb1 -> (dbseek (xfilial ("SB1") + _aCupons [_nCupom, 6], .F.))
				u_help ("SB1 nao encontrado.")
				return  // Cai fora sem usar loop para evitar o 'end transaction'.
			endif
			sd2 -> d2_filial  = xfilial ("SD2")
			sd2 -> d2_cod     = _aCupons [_nCupom, 6]
			sd2 -> d2_quant   = _aCupons [_nCupom, 7]
			sd2 -> d2_prcven  = _aCupons [_nCupom, 8]
			sd2 -> d2_total   = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
			sd2 -> d2_valicm  = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8] * _aCupons [_nCupom, 9] / 100
			sd2 -> d2_tes     = '526'
			sd2 -> d2_um      = sb1 -> b1_um
			sd2 -> d2_cf      = '5101'
			sd2 -> d2_picm    = _aCupons [_nCupom, 9]
			sd2 -> d2_peso    = _aCupons [_nCupom, 7] * sb1 -> b1_peso
			sd2 -> d2_conta   = '101030101011        '
			sd2 -> d2_cliente = _sCliente
			sd2 -> d2_loja    = _sLoja
			sd2 -> d2_itempv  = strzero (_nCupom, tamsx3 ("D2_ITEMPV")[1])
			sd2 -> d2_doc     = _aCupons [_nCupom, 3]
			sd2 -> d2_emissao = _aCupons [_nCupom, 5]
			sd2 -> d2_local   = sb1 -> b1_locpad
			sd2 -> d2_tp      = sb1 -> b1_tipo
			sd2 -> d2_grupo   = sb1 -> b1_grupo
			sd2 -> d2_serie   = _aCupons [_nCupom, 4]
			sd2 -> d2_est     = GetMv ("MV_ESTADO")
			sd2 -> d2_prunit  = _aCupons [_nCupom, 8]
			sd2 -> d2_tipo    = 'N'
			sd2 -> d2_origlan = 'LO'
			sd2 -> d2_baseicm = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
			sd2 -> d2_item    = _aCupons [_nCupom, 10]  //strzero (_nCupom, tamsx3 ("D2_ITEM")[1])
			sd2 -> d2_comis1  = 1.3
			sd2 -> d2_pdv     = '0001'
			sd2 -> d2_clasfis = '000'
			sd2 -> d2_basimp5 = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
			sd2 -> d2_basimp6 = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
			sd2 -> d2_valimp5 = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8] * 7.6 / 100
			sd2 -> d2_valimp6 = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8] * 1.65 / 100
			sd2 -> d2_alqimp5 = 7.6
			sd2 -> d2_alqimp6 = 1.65
			sd2 -> d2_valbrut = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
			sd2 -> d2_sittrib = 'T' + strzero (_aCupons [1, 9] * 100, 2)  //'T1700'
			msunlock ()

			_aImpCD2 := {}
			aadd (_aImpCD2, {'CF2   ', '01', '',   7.60})
			aadd (_aImpCD2, {'ICM   ', '00', '3', _aCupons [1, 9]})
			aadd (_aImpCD2, {'PS2   ', '01', '',   1.65})
			cd2 -> (dbsetorder (1))  // CD2_FILIAL+CD2_TPMOV+CD2_SERIE+CD2_DOC+CD2_CODCLI+CD2_LOJCLI+CD2_ITEM+CD2_CODPRO+CD2_IMP
			for _nImpCD2 = 1 to len (_aImpCD2)
				if ! cd2 -> (dbseek (xfilial ("CD2") + 'S' + _aCupons [_nCupom, 4] + _aCupons [_nCupom, 3] + _sCliente + _sLoja + _aCupons [_nCupom, 10] + '  ' + _aCupons [_nCupom, 6] + _aImpCD2 [_nImpCD2, 1], .F.))
					u_log ("Criando CD2 para ", _aImpCD2 [_nImpCD2, 1])
					reclock ("CD2", .T.)
				else
					u_log ("Alterando CD2 para ", _aImpCD2 [_nImpCD2, 1])
					reclock ("CD2", .F.)
				endif
				sb1 -> (dbsetorder (1))
				if ! sb1 -> (dbseek (xfilial ("SB1") + _aCupons [_nCupom, 6], .F.))
					u_help ("SB1 nao encontrado.")
					return  // Cai fora sem usar loop para evitar o 'end transaction'.
				endif
				cd2 -> cd2_filial  = xfilial ("CD2")
				cd2 -> cd2_tpmov   = 'S'
				cd2 -> cd2_doc     = _aCupons [_nCupom, 3]
				cd2 -> cd2_serie   = _aCupons [_nCupom, 4]
				cd2 -> cd2_codcli  = _sCliente
				cd2 -> cd2_lojcli  = _sLoja
				cd2 -> cd2_item    = _aCupons [_nCupom, 10] //strzero (_nCupom, tamsx3 ("CD2_ITEM")[1])
				cd2 -> cd2_codpro  = _aCupons [_nCupom, 6]
				cd2 -> cd2_imp     = _aImpCD2 [_nImpCD2, 1]
				cd2 -> cd2_origem  = '0'
				cd2 -> cd2_cst     = _aImpCD2 [_nImpCD2, 2]
				cd2 -> cd2_modbc   = _aImpCD2 [_nImpCD2, 3]
				cd2 -> cd2_bc      = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8]
				cd2 -> cd2_aliq    = _aImpCD2 [_nImpCD2, 4]
				cd2 -> cd2_vltrib  = _aCupons [_nCupom, 7] * _aCupons [_nCupom, 8] * _aImpCD2 [_nImpCD2, 4]
				cd2 -> cd2_qtrib   = _aCupons [_nCupom, 7]
				msunlock ()
			next

			_sParcela := space (tamsx3 ("E1_PARCELA")[1])
			_sTipo := 'R$ '
			se1 -> (dbsetorder (1))  // E1_FILIAL+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
			if ! se1 -> (dbseek (xfilial ("SE1") + _aCupons [_nCupom, 4] + _aCupons [_nCupom, 3], .T.))
				u_log ("Criando SE1")
				reclock ("SE1", .T.)
			else
				u_log ("Alterando SE1")
				reclock ("SE1", .F.)
			endif
			se1 -> e1_filial  = xfilial ("SE1")
			se1 -> e1_prefixo = _aCupons [_nCupom, 4]
			se1 -> e1_num     = _aCupons [_nCupom, 3]
			se1 -> e1_parcela = _sParcela
			se1 -> e1_tipo    = _sTipo
			se1 -> e1_cliente = _sCliente
			se1 -> e1_naturez = 'DINHEIRO'
			se1 -> e1_portado = _aCupons [_nCupom, 12]
			se1 -> e1_agedep  = '.'
			se1 -> e1_conta   = '.'
			se1 -> e1_loja    = _sLoja
			se1 -> e1_nomcli  = 'CONSUMIDOR FINAL'
			se1 -> e1_emissao = _aCupons [_nCupom, 5]
			se1 -> e1_vencto  = _aCupons [_nCupom, 5]
			se1 -> e1_vencrea = _aCupons [_nCupom, 5]
			se1 -> e1_valor   = _nValBrut
			se1 -> e1_vlcruz  = _nValBrut
			se1 -> e1_baixa   = _aCupons [_nCupom, 5]
			se1 -> e1_emis1   = _aCupons [_nCupom, 5]
			se1 -> e1_hist    = 'VENDA EM DINHEIRO'
			se1 -> e1_movimen = _aCupons [_nCupom, 5]
			se1 -> e1_situaca = '0'
			se1 -> e1_vend1   = '060'
			se1 -> e1_comis1  = 1.3
			se1 -> e1_valliq  = _nValBrut
			se1 -> e1_vencori = _aCupons [_nCupom, 5]
			se1 -> e1_moeda   = 1
			se1 -> e1_bascom1 = _nValBrut
			se1 -> e1_valcom1 = _nValBrut * 1.3 / 100
			se1 -> e1_numnota = _aCupons [_nCupom, 3]
			se1 -> e1_serie   = _aCupons [_nCupom, 4]
			se1 -> e1_status  = 'B'
			se1 -> e1_origem  = 'LOJA701'
			se1 -> e1_fluxo   = 'S'
			se1 -> e1_filorig = xfilial ("SE1")
			se1 -> e1_multnat = '2'
			se1 -> e1_nummov  = '01'
			se1 -> e1_relato  = '2'
			msunlock ()

			_sSeqSE5 := strzero (1, tamsx3 ("E5_SEQ")[1])  // space (tamsx3 ("E5_SEQ")[1])
			se5 -> (dbsetorder (7))  // E5_FILIAL+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+E5_CLIFOR+E5_LOJA+E5_SEQ
			if ! se5 -> (dbseek (xfilial ("SE5") + _aCupons [_nCupom, 4] + _aCupons [_nCupom, 3] + _sParcela + _sTipo + _sCliente + _sLoja + _sSeqSE5, .F.))
				u_log ('Criando SE5')
				reclock ("SE5", .T.)
			else
				u_log ('Alterando SE5')
				reclock ("SE5", .F.)
			endif
			se5 -> e5_filial  = xfilial ("SE5")
			se5 -> e5_data    = _aCupons [_nCupom, 5]
			se5 -> e5_tipo    = _sTipo
			se5 -> e5_valor   = _nValBrut
			se5 -> e5_naturez = 'DINHEIRO'
			se5 -> e5_banco   = _aCupons [_nCupom, 12]
			se5 -> e5_agencia = '.'
			se5 -> e5_conta   = '.'
			se5 -> e5_recpag  = 'R'
			se5 -> e5_histor  = 'BAIXA REF VENDA EM DINHEIRO'
			se5 -> e5_tipodoc = 'LJ'
			se5 -> e5_prefixo = _aCupons [_nCupom, 4]
			se5 -> e5_numero  = _aCupons [_nCupom, 3]
			se5 -> e5_parcela = _sParcela
			se5 -> e5_clifor  = _sCliente
			se5 -> e5_loja    = _sLoja
			se5 -> e5_dtdigit = _aCupons [_nCupom, 5]
			se5 -> e5_motbx   = 'NOR'
			se5 -> e5_dtdispo = _aCupons [_nCupom, 5]
			se5 -> e5_filorig = xfilial ("SE5")
			se5 -> e5_cliente = _sCliente
			se5 -> e5_nummov  = '01'
			se5 -> e5_seq     = _sSeqSE5
			msunlock ()
		endif
		u_logFim (_aCupons [_nCupom, 3] + ' ' + _aCupons [_nCupom, 6])
	next
	end transaction
	
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery = "SELECT SUM (F2_VALBRUT) OVER () AS VL_ACUM, * FROM " + RetSQLName ("SF2") + " WHERE D_E_L_E_T_ = '' and F2_FILIAL  = '" + _aCupons [1, 1] + "' AND F2_DOC    = '" + _aCupons [1, 3] + "' AND F2_SERIE   = '" + _aCupons [1, 4] + "'"
	u_log (_oSQL:Qry2Array (.T., .T.)) 
	_oSQL:_sQuery = "SELECT SUM (E1_VALOR)   OVER () AS VL_ACUM, * FROM " + RetSQLName ("SE1") + " WHERE D_E_L_E_T_ = '' and E1_FILIAL  = '" + _aCupons [1, 1] + "' AND E1_NUM    = '" + _aCupons [1, 3] + "' AND E1_PREFIXO = '" + _aCupons [1, 4] + "'"
	u_log (_oSQL:Qry2Array (.T., .T.)) 
	_oSQL:_sQuery = "SELECT SUM (E5_VALOR)   OVER () AS VL_ACUM, * FROM " + RetSQLName ("SE5") + " WHERE D_E_L_E_T_ = '' and E5_FILIAL  = '" + _aCupons [1, 1] + "' AND E5_NUMERO = '" + _aCupons [1, 3] + "' AND E5_PREFIXO = '" + _aCupons [1, 4] + "'"
	u_log (_oSQL:Qry2Array (.T., .T.)) 
	_oSQL:_sQuery = "SELECT SUM (D2_VALBRUT) OVER () AS VL_ACUM, * FROM " + RetSQLName ("SD2") + " WHERE D_E_L_E_T_ = '' and D2_FILIAL  = '" + _aCupons [1, 1] + "' AND D2_DOC    = '" + _aCupons [1, 3] + "' AND D2_SERIE   = '" + _aCupons [1, 4] + "'"
	u_log (_oSQL:Qry2Array (.T., .T.)) 
	_oSQL:_sQuery = "SELECT SUM (CD2_BC)     OVER () AS VL_ACUM, * FROM " + RetSQLName ("CD2") + " WHERE D_E_L_E_T_ = '' and CD2_FILIAL = '" + _aCupons [1, 1] + "' AND CD2_DOC   = '" + _aCupons [1, 3] + "' AND CD2_SERIE  = '" + _aCupons [1, 4] + "' AND CD2_IMP = 'ICM'"
	u_log (_oSQL:Qry2Array (.T., .T.))
	U_LOGfIM () 
return
*/
/*
	// Comparacao do SX3 com SXG
	procregua (9999999)
	sx3 -> (dbsetorder (1))
	sx3 -> (dbgotop ())
	do while ! sx3 -> (eof ())
		if ! empty (sx3 -> x3_grpsxg)
			incproc (sx3 -> x3_grpsxg)
			if ! sxg -> (dbseek (sx3 -> x3_grpsxg, .F.))
				u_log ('nao encontrei', sx3 -> x3_grpsxg, 'no SXG')
			else
				if sx3 -> x3_tamanho != sxg -> xg_size
					if ! sx2 -> (dbseek (sx3 -> x3_arquivo, .F.))
						u_log (sx3 -> x3_arquivo, 'nao existe no sx2.')
					else
						if U_RetSQL ("select count (*) from sysobjects where name = '" + RetSQLName (sx3 -> x3_arquivo) + "' and type = 'U'") == 0
							u_log (RetSQLName (sx3 -> x3_arquivo), 'nao existe. Vou alterar SX3.')
							reclock ("SX3", .F.)
							sx3 -> x3_tamanho = sxg -> xg_size
							msunlock ()
						else
							if U_RetSQL ("select count (*) from " + RetSQLName (sx3 -> x3_arquivo)) == 0
								u_log (RetSQLName (sx3 -> x3_arquivo), 'vazio. Vou dar drop.')
								_oSQL := ClsSQL():New()
								_oSQL:_sQuery = 'drop table ' + RetSQLName (sx3 -> x3_arquivo)
								if msgyesno (_oSQL:_sQuery)
									_oSQL:Exec ()
									reclock ("SX3", .F.)
									sx3 -> x3_tamanho = sxg -> xg_size
									msunlock ()
								endif
							else
								u_log ('alterar tamanho do', sx3 -> x3_campo, 'de', sx3 -> x3_tamanho, 'para', sxg -> xg_size, 'grupo xsg:', sx3 -> x3_grpsxg)
							endif
						endif
					endif
				endif
			endif
		endif
		sx3 -> (dbskip ())
	enddo

	// Comparacao da estrutura do arquivo com SX3
	_aComandos = {}
	sx2 -> (dbsetorder (1))
	sx3 -> (dbsetorder (2))
	sx2 -> (dbgotop ())
	//sx2 -> (dbseek ('S', .T.))
	do while ! sx2 -> (eof ())
		u_log ('Verificando ' + sx2 -> x2_arquivo)
		if U_RetSQL ("select count (*) from sysobjects where name = '" + sx2 -> x2_arquivo + "' and type = 'U'") > 0
			_aEstrut := aclone ((sx2 -> x2_chave) -> (dbstruct ()))
//			u_log (_aEstrut)
			for _nCampo = 1 to len (_aEstrut)
//				u_log (_nCampo, '>>' + left (_aEstrut [_nCampo, 1] + '          ', 10) + "<<")
				if ! sx3 -> (dbseek (left (_aEstrut [_nCampo, 1] + '          ', 10), .F.))
					u_log ('Campo', _aEstrut [_nCampo, 1], 'nao encontrado no SX3.')
				else
					//u_log ('_nCampo antes de testar campo memo:', _nCampo)
					if sx3 -> x3_tipo != 'M' .and. _aEstrut [_nCampo, 2] != 'M'  // Campos memo sao complicados...
						//u_log ('_nCampo antes de testar tipo, tamanho e decimais:', _nCampo)
						if sx3 -> x3_tipo != _aEstrut [_nCampo, 2] .or. sx3 -> x3_tamanho != _aEstrut [_nCampo, 3] .or. sx3 -> x3_decimal != _aEstrut [_nCampo, 4]
							//u_log ('_nCampo antes da contagem do SX2:', _nCampo)
							if U_RetSQL ("select count (*) from " + sx2 -> x2_arquivo) == 0
								u_log (sx2 -> x2_arquivo, 'vazio. Vou dar drop.')
								aadd (_aComandos, {'drop table ' + sx2 -> x2_arquivo, sx2 -> x2_nome})
								exit // Nao preciso mais verificar este arquivo.
							else
								//u_log ('_nCampo antes da msg:', _nCampo)
								u_log ('Campo', _aEstrut [_nCampo, 1], ': sx3:', sx3 -> x3_tipo, sx3 -> x3_tamanho, sx3 -> x3_decimal, '  no arquivo:', _aEstrut [_nCampo, 2], _aEstrut [_nCampo, 3], _aEstrut [_nCampo, 4], 'x2_arquivo:', sx2 -> x2_arquivo)
								//u_log ('_nCampo depois da msg:', _nCampo)
							endif
						endif
					endif
				endif
			next
		endif
		sx2 -> (dbskip ())
	enddo
	// Grava em log os comandos a executar no SQL
	u_log (_aComandos)
return
*/

/*
	sx3 -> (dbsetorder (1))
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT * FROM TOP_FIELD"
	_oSQL:_sQuery += " WHERE FIELD_TABLE LIKE 'dbo.%'"
	_oSQL:_sQuery += " AND FIELD_TABLE LIKE '%010'"
	_sAliasQ := _oSQL:Qry2Trb ()
	do while ! (_sAliasQ) -> (eof ())
		//U_Log ((_sAliasQ) -> field_name)
		if ! sx3 -> (dbseek ((_sAliasQ) -> field_name, .f.))
			u_log ('Campo ', (_sAliasQ) -> field_name, 'nao existe no SX3')
		else
			if sx3 -> x3_tipo == 'D' .and. (_sAliasQ) -> field_type != 'D'
				u_log ('Campo ', (_sAliasQ) -> field_name, 'field_type:', (_sAliasQ) -> field_type, '   x3_tipo:', sx3 -> x3_tipo)
			endif
			if sx3 -> x3_tipo == 'N' .and. (_sAliasQ) -> field_type != 'P'
				u_log ('Campo ', (_sAliasQ) -> field_name, 'field_type:', (_sAliasQ) -> field_type, '   x3_tipo:', sx3 -> x3_tipo)
			endif
			if sx3 -> x3_tipo == 'M' .and. (_sAliasQ) -> field_type != 'M'
				u_log ('Campo ', (_sAliasQ) -> field_name, 'field_type:', (_sAliasQ) -> field_type, '   x3_tipo:', sx3 -> x3_tipo)
			endif
			if sx3 -> x3_tipo == 'L' .and. (_sAliasQ) -> field_type != 'L'
				u_log ('Campo ', (_sAliasQ) -> field_name, 'field_type:', (_sAliasQ) -> field_type, '   x3_tipo:', sx3 -> x3_tipo)
			endif
			if sx3 -> x3_tAMANHO != val((_sAliasQ) -> field_prec)
				u_log ('Campo ', (_sAliasQ) -> field_name, 'field_prec:', (_sAliasQ) -> field_prec, '   x3_tamanho:', sx3 -> x3_tamanho)
			endif
			
		endif
		(_sAliasQ) -> (dbskip ())
	enddo
return
*/



/*
	// Ajusta transferencias internas que ficaram com D3_NUMSEQ repetido.
	_dDataIni := stod ('20150112')
	_dDataFim := stod ('20151231')
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := ""
	_oSQL:_sQuery += " SELECT D3_NUMSEQ "
	_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
	_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
	_oSQL:_sQuery +=    " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
	_oSQL:_sQuery +=    " AND D3_EMISSAO BETWEEN '" + dtos (_dDataIni) + "' AND '" + dtos (_dDataFim) + "'"
	_oSQL:_sQuery +=    " AND D3_EMISSAO > '" + DTOS (getmv ("MV_ULMES")) + "'"  // Soh pra nao mexer em mes fechado...
	_oSQL:_sQuery +=    " AND D3_CF IN ('RE4', 'DE4')"
	_oSQL:_sQuery +=  " GROUP BY D3_NUMSEQ"
	_oSQL:_sQuery += " HAVING COUNT (*) > 2"
	_oSQL:_sQuery +=  " ORDER BY D3_NUMSEQ"
	u_log (_oSQL:_sQuery)
	_aRetSQL := aclone (_oSQL:Qry2Array ())
	u_log (_aRetSQL)
	for _nRetSQL = 1 to len (_aRetSQL)
		u_log (_nRetSQL, 'de', len (_aRetSQL))
		do while .t.
			_nRegRE = 0
			_nRegDE = 0
			_oSQL:_sQuery := ""
			_oSQL:_sQuery += " SELECT top 1 R_E_C_N_O_, D3_COD, D3_EMISSAO, D3_QUANT "
			_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
			_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
			_oSQL:_sQuery +=    " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
			_oSQL:_sQuery +=    " AND D3_NUMSEQ  = '" + _aRetSQL [_nRetSQL, 1] + "'"
			_oSQL:_sQuery +=    " AND D3_CF      = 'RE4'"
			u_log (_oSQL:_sQuery)
			//_nRegRE = _oSQL:RetQry ()
			_aRE = _oSQL:Qry2Array ()
			if len (_aRE) == 1
				_nRegRE = _aRE [1, 1]
				_oSQL:_sQuery := ""
				_oSQL:_sQuery += " SELECT top 1 R_E_C_N_O_ "
				_oSQL:_sQuery +=   " FROM " + RetSQLName ("SD3")
				_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
				_oSQL:_sQuery +=    " AND D3_FILIAL = '" + xfilial ("SD3") + "'"
				_oSQL:_sQuery +=    " AND D3_NUMSEQ  = '" + _aRetSQL [_nRetSQL, 1] + "'"
				_oSQL:_sQuery +=    " AND D3_COD     = '" + _aRE [1, 2] + "'"
				_oSQL:_sQuery +=    " AND D3_EMISSAO = '" + dtos (_aRE [1, 3]) + "'"
				_oSQL:_sQuery +=    " AND D3_QUANT   = '" + cvaltochar (_aRE [1, 4]) + "'"
				_oSQL:_sQuery +=    " AND D3_CF      = 'DE4'"
				u_log (_oSQL:_sQuery)
				_nRegDE = _oSQL:RetQry ()
			endif
			if _nRegDE == 0 .or. _nRegRe == 0  // Se nao achou mais nenhum par, cai fora.
				exit
			endif
			_sNumSeq = ProxNum ()
			u_log ('vou gravar:', _sNumSeq)
			sd3 -> (dbgoto (_nRegDE))
			u_logtrb ('SD3')
			reclock ("SD3", .F.)
			sd3 -> d3_numseq = _sNumSeq
			msunlock ()
			sd3 -> (dbgoto (_nRegRE))
			u_logtrb ('SD3')
			reclock ("SD3", .F.)
			sd3 -> d3_numseq = _sNumSeq
			msunlock ()
		enddo
	next
return
*/
/*
	// Gera codigo EAN para os produtos que estao em branco.
	sb1 -> (dbsetorder (2))  // B1_FILIAL+B1_TIPO+B1_COD
	sb1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		IF left (sb1 -> b1_vaeanun, 7) != '0000000' ;
			.and. SUBSTR (sb1 -> b1_vaeanun, 9, 4) != left (sb1 -> b1_cod, 4) ;
			.and. left (sb1 -> b1_vaeanun, 3) != '789' ;
			.and. ! empty (left (sb1 -> b1_cod, 1)) ;
			.and. ! isalpha (left (sb1 -> b1_cod, 1)) ;
			.and. ! sb1 -> b1_tipo $ 'PA/MO/BN/GF/MC/'

			U_LOG (sb1 -> b1_tipo, sb1 -> B1_COD, sb1 -> B1_vaeanun, sb1 -> b1_desc)
			reclock ("SB1", .F.)
			if ISALPHA (right (alltrim (sb1 -> b1_cod), 1))
				sb1 -> b1_vaeanun = U_ML_DVEAN ('00000009' + left (sb1->B1_cod, 4), .T.)
			else
				sb1 -> b1_vaeanun = U_ML_DVEAN ('00000000' + alltrim (sb1->B1_cod), .T.)
			endif
			msunlock ()
		endif
		sb1 -> (dbskip ())
	enddo
return
*/
/*
	local cURL       := PadR(GetNewPar("MV_SPEDURL","http://localhost:8080/sped"),250)
	local _sEntidade := "000001"
	local _sXML      := ""
	local _sRet      := ""
	local cError     := ""
	local cWarning   := ""
	oWS:= WSNFeSBRA():New()
	oWS:cUSERTOKEN        := "TOTVS"
	oWS:cID_ENT           := _sEntidade
	oWS:oWSNFEID          := NFESBRA_NFES2():New()
	oWS:oWSNFEID:oWSNotas := NFESBRA_ARRAYOFNFESID2():New()
	aadd(oWS:oWSNFEID:oWSNotas:oWSNFESID2,NFESBRA_NFESID2():New())
	Atail(oWS:oWSNFEID:oWSNotas:oWSNFESID2):cID := "10 " + "000056066"
	oWS:nDIASPARAEXCLUSAO := 0
	oWS:_URL := AllTrim(cURL)+"/NFeSBRA.apw"
	If oWS:RETORNANOTAS()
		u_log ('retornanotas')
		// Precisa ler toda a array por que o mesmo numero de nota pode retornar
		// em producao/homologacao, ou em modo normal/contingencia
		For nX := 1 To Len(oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3)
			u_log (nX)
			if valtype (oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE) == "O"
				u_log ('protoc.:', oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CPROTOCOLO)
				_sXml = oWs:oWsRetornaNotasResult:OWSNOTAS:OWSNFES3[nX]:oWSNFE:CXML
				u_log (_sXML)
				if at ("<tpAmb>1</tpAmb>", _sXml) > 0  // Ambiente: 1=producao, 2=homologacao
					
					// Cria objeto XML com dados da NF-e
					oXml := XmlParser(_sXML, "_", @cError, @cWarning )
					u_log (substr (oXml:_NFE:_INFNFE:_ID:TEXT, 4, 44))
				endif
			endif
		next
	endif
return
*/
/*
	// Gera campo B1_VAGRWWC
	SB1 -> (dbgotop ())
	do while ! sb1 -> (eof ())
		u_log (sb1 -> b1_cod)
		reclock ("SB1", .f.)
		sb1 -> b1_vagrwwc  = '000'
		if sb1 -> b1_grpemb != '18'  // Envasados
			do case
				case sb1 -> b1_codlin $ '01'  // reserva/premium
					sb1 -> b1_vagrwwc  = '100'
				case sb1 -> b1_codlin $ '02'  // varietal
					sb1 -> b1_vagrwwc  = '101'
				case sb1 -> b1_codlin $ '03'  // assemblage
					sb1 -> b1_vagrwwc  = '102'
				case sb1 -> b1_codlin $ '07'  // mesa
					sb1 -> b1_vagrwwc  = '111'
				case sb1 -> b1_codlin $ '05'  // cooler
					sb1 -> b1_vagrwwc  = '112'
				case sb1 -> b1_codlin $ '09'  // filtrado
					sb1 -> b1_vagrwwc  = '113'
				case sb1 -> b1_codlin $ '13'  // especificos
					sb1 -> b1_vagrwwc  = '114'
				case sb1 -> b1_codlin $ '11'  // suco valor agregado
					sb1 -> b1_vagrwwc  = '121'
				case sb1 -> b1_codlin $ '06'  // suco tradicional
					sb1 -> b1_vagrwwc  = '122'
				case sb1 -> b1_codlin $ '12'  // suco institucional
					sb1 -> b1_vagrwwc  = '123'
				case sb1 -> b1_codlin $ '04'  // espumantes
					do case
						case sb1 -> b1_claspr $ '02/03'  // extra-brut/brut
							sb1 -> b1_vagrwwc  = '131'
						case sb1 -> b1_claspr $ '05'  // demi-sec
							sb1 -> b1_vagrwwc  = '132'
						case sb1 -> b1_claspr $ '06/07/10'  // suave/doce/adocado
							sb1 -> b1_vagrwwc  = '133'
					endcase
			endcase
		else  // Granel
			do case
				case sb1 -> b1_prod $ '43'  // fino
					do case
						case sb1 -> b1_vacor $ 'B/R'  // branco/rosado
							sb1 -> b1_vagrwwc  = '201'
						case sb1 -> b1_vacor $ 'T'  // tinto
							sb1 -> b1_vagrwwc  = '202'
					endcase
				case sb1 -> b1_prod $ '01/04/05/06/17/18/20/42/44'  // mesa
					do case
						case sb1 -> b1_vacor $ 'B/R'  // branco/rosado
							sb1 -> b1_vagrwwc  = '211'
						case sb1 -> b1_vacor $ 'T'  // tinto
							sb1 -> b1_vagrwwc  = '212'
					endcase
				case sb1 -> b1_prod $ '08/09/12/13'  // suco/mosto
					do case
						case sb1 -> b1_vacor $ 'B/R'  // branco/rosado
							sb1 -> b1_vagrwwc  = '221'
						case sb1 -> b1_vacor $ 'T'  // tinto
							sb1 -> b1_vagrwwc  = '222'
					endcase
			endcase
		endif
		msunlock ()
		sb1 -> (dbskip ())
	enddo
RETURN
*/
