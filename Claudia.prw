// --------------------------------------------------------------------------
user function claudia ()

//	u_help(" nada em execução")
	u_help('descCC')

//	descCC()
	//ImpOBSFin()
return


// // INSERE DESCRICAO CC NO SC7
// Static function descCC()
// 	Local _aDados := {}
// 	Local i       := 0

// 	u_help('começa')

// 	_oSQL := ClsSQL():New ()
// 	_oSQL:_sQuery := ""
// 	_oSQL:_sQuery += " SELECT"
// 	_oSQL:_sQuery += " 	   C7_FILIAL"
// 	_oSQL:_sQuery += "    ,C7_NUM"
// 	_oSQL:_sQuery += "    ,C7_ITEM"
// 	_oSQL:_sQuery += "    ,C7_SEQUEN"
// 	_oSQL:_sQuery += "    ,CTT_DESC01"
// 	_oSQL:_sQuery += " FROM SC7010"
// 	_oSQL:_sQuery += " INNER JOIN CTT010 CTT"
// 	_oSQL:_sQuery += " 	ON (CTT.D_E_L_E_T_ = ''"
// 	_oSQL:_sQuery += " 			AND C7_CC = CTT_CUSTO)"
// 	_oSQL:_sQuery += " WHERE C7_EMISSAO >= '20201201'"
// 	_oSQL:_sQuery += " AND C7_CC <> ''"
// 	_oSQL:_sQuery += " AND C7_VACCDES = ''"
// 	_oSQL:_sQuery += " ORDER BY C7_FILIAL, C7_EMISSAO "
// 	_aDados := _oSQL:Qry2Array ()


// 	For i:=1 to Len(_aDados)
// 			dbSelectArea("SC7")
// 			dbSetOrder(1) // c7_filial, c7_num, c7_item, c7_sequen                                                                                                                                  
// 			dbSeek(_aDados[i,1] + _aDados[i,2]  + _aDados[i,3] + _aDados[i,4] )
			
// 			If Found() // Avalia o retorno da pesquisa realizada
// 				RECLOCK("SC7", .F.)
				
// 				SC7->C7_VACCDES := _aDados[i,5] 
				
// 				MSUNLOCK()     // Destrava o registro
// 			EndIf		
// 	Next
// Return
// // ----------------------------------------------------------------------------
// // Importa CSV obs financeiro

// static Function ImpOBSFin()
// Local _aDados 	:= {}
// Local _i 		:=0
// local _oEvento 	:= NIL

// 	_aDados = U_LeCSV ('C:\Temp\obs.csv', ';')

// 	//u_log (len(_aDados))

// 	for _i := 1 to len (_aDados)

// 		If Len(alltrim(_aDados [_i, 1])) <= 6
// 			_oEvento    := NIL

// 			_oEvento := ClsEvent():new ()
// 			_oEvento:CodEven   = "SA1004"
// 			_oEvento:DtEvento  = date()
// 			_oEvento:Texto	   = _aDados [_i, 3]
// 			_oEvento:Cliente   = PADL(_aDados [_i, 1],6,'0')
// 			_oEvento:LojaCli   = PADL(_aDados [_i, 2],2,'0')
// 			_oEvento:Grava ()

// 			_Cliente := PADL(_aDados [_i, 2],2,'0')
// 		else
// 			u_log ("---AJUSTE:" +alltrim(_Cliente) + alltrim(_aDados [_i, 1]))
// 		EndIf
// 	Next
// return
//
//Static Function _ajusteZA5()
//	local _i := 0
//	
//	cQuery := " SELECT"
//	cQuery += " 	ZA5_FILIAL"
//	cQuery += "    ,ZA5_NUM"
//	cQuery += "    ,ZA5_SEQ"
//	cQuery += "    ,ZA5_DOC"
//	cQuery += "    ,ZA5_PREFIX"
//	cQuery += "    ,ZA5_CLI
//	cQuery += "    ,ZA5_LOJA"
//	cQuery += "    ,ZA5_VENVER"
//	cQuery += "    ,ZA5_VENNF"
//	cQuery += " FROM ZA5010"
//	cQuery += " WHERE D_E_L_E_T_ = ''"
//	cQuery += " AND ZA5_VENVER = ''"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	While TRA->(!Eof())
//		
//		if alltrim( TRA->ZA5_PREFIX) == ''
//			_serie := '10'
//		else
//			_serie := TRA->ZA5_PREFIX
//		EndIf
//		
//		_oSQL:= ClsSQL ():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " SELECT F2_VEND1 FROM SF2010"
//		_oSQL:_sQuery += " WHERE F2_DOC		='"+ TRA->ZA5_DOC +"'"
//		_oSQL:_sQuery += " AND F2_SERIE		='"+ _serie +"'"
//		_oSQL:_sQuery += " AND F2_CLIENTE	='"+ TRA->ZA5_CLI +"'"
//		_oSQL:_sQuery += " AND F2_LOJA		='"+ TRA->ZA5_LOJA +"'"
//		_aVend := _oSQL:Qry2Array ()
//				
//		For _i := 1 to Len(_aVend)
//		
//			dbSelectArea("ZA5")
//			dbSetOrder(1) // ZA5_FILIAL+ZA5_NUM+ZA5_SEQ                                                                                                                                      
//			dbSeek( tra-> ZA5_FILIAL + tra->ZA5_NUM + alltrim(str(tra->ZA5_SEQ)))
//			
//			If Found() // Avalia o retorno da pesquisa realizada
//				RECLOCK("ZA5", .F.)
//				
//				ZA5->ZA5_VENVER := _aVend[_i,1]
//				ZA5->ZA5_VENNF  := _aVend[_i,1]
//				
//				MSUNLOCK()     // Destrava o registro
//			EndIf		
//		Next
//				
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//Return
//	local _oSQL     := NIL
//	
//	u_help ("Atualiza comprador")
//	
//	cQuery := " SELECT C7_FILIAL, C7_USER, C7_NUM, C7_FORNECE, C7_EMISSAO "
//	cQuery += " FROM " + RetSqlName("SC7")"
//	cQuery += " WHERE D_E_L_E_T_=''"
//	cQuery += " AND C7_EMISSAO>='20190101'"
//	dbUseArea(.T., "TOPCONN", TCGenQry(,,cQuery), "TRA", .F., .T.)
//	
//	TRA->(DbGotop())
//	
//	While TRA->(!Eof())	
//		_oSQL := ClsSQL():New ()
//		_oSQL:_sQuery := ""
//		_oSQL:_sQuery += " UPDATE  " + RetSqlName("SC7")
//		_oSQL:_sQuery +=   " SET C7_COMNOM = '" + UsrFullName(tra -> c7_user) +"'"
//		_oSQL:_sQuery += " WHERE C7_FILIAL = '" +  tra->c7_filial + "'"
//		_oSQL:_sQuery += " AND C7_NUM = '"+ tra -> c7_num +"'" 
//		_oSQL:_sQuery += " AND C7_FORNECE = '"+ tra -> c7_fornece +"'" 
//		_oSQL:_sQuery += " AND C7_EMISSAO = '"+ tra -> c7_emissao +"'" 
//		_oSQL:Exec ()
//		
//		DBSelectArea("TRA")
//		dbskip()
//	Enddo
//	
//	TRA->(DbCloseArea())
//	u_help("Compradores atualizados")
//
//	if type ('__cUserId') == 'U' .or. type ('cUserName') == 'U'
//		u_log ('Preparando ambiente')
//		prepare environment empresa '01' filial '01' modulo '05'
//		private cModulo   := 'FAT'
//		private __cUserId := "000210"
//		private cUserName := "claudia.lionco"
//		private __RelDir  := "c:\temp\spool_protheus\"
//		set century on
//	endif
//	//
//	if ! alltrim(upper(cusername)) $ 'ROBERT.KOCH/ADMINISTRADOR/CATIA.CARDOSO/ANDRE.ALVES/CLAUDIA.LIONCO'
//		msgalert ('Nao te conheco, nao gosto de ti e nao vou te deixar continuar. Vai pra casa.', procname ())
//		return
//	endif
//	//
//	private _sArqLog := procname () + "_" + alltrim (cUserName) + cEmpAnt + ".log"
//	delete file (_sArqLog)
//	u_logId ()
//	if U_Semaforo (procname ()) == 0
//		u_help ('Bloqueio de semaforo na funcao ' + procname ())
//	else
//		PtInternal (1, 'U_Claudia')
//		U_UsoRot ('I', procname (), '')
//		
//		processa ({|| _AndaLogo ()})
//		u_logDH ('Processo finalizado')
//		
//		U_UsoRot ('F', procname (), '')
//	endif
//return

// --------------------------------------------------------------------------
//static function _AndaLogo ()
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
//	PRIVATE _oBatch  := ClsBatch():New ()  // Deixar definido para quando testar rotinas em batch.
//	procregua (100)
//	incproc ()
//	
//	//processa ({|| _AtualizaProduto ()})
//	
//	//processa ({|| _AtualizaRepresentante()})
//	
//	//processa ({|| _AtualizaMercanet()})
//	
//	u_help ("Nada definido", procname ())
//return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaMercanet()
//
//	_oSQL := ClsSQL ():New ()
//	_oSQL:_sQuery := ""
//	_oSQL:_sQuery += " SELECT R_E_C_N_O_ "
//	_oSQL:_sQuery += " FROM " + RetSQLName ("SA1")
//	_oSQL:_sQuery += " WHERE D_E_L_E_T_ = ''"
//	_oSQL:_sQuery += " AND A1_FILIAL = '" + xfilial ("SA1") + "'"  // Deixar esta opcao para poder ler os campos memo.
//	_oSQL:_sQuery += " AND A1_VEND = '317'"
//	_oSQL:Log ()
//	_aDados = aclone (_oSQL:Qry2Array ())
//	
//	For _nLinha := 1 To Len(_aDados)
//		sa1 -> (dbgoto (_aDados [_nLinha, 1]))
//		U_LOG (SA1 -> A1_COD)
//		U_AtuMerc ("SA1", sa1 -> (recno ()))
//	next
//	
//Return
//-------------------------------------------------------------------------------------------------
//Static function _AtualizaRepresentante ()
//
//	u_help ("Alterar comissão do vendedor 317")
//	// Ajusta vendedor de 258 para 317
//	sa1 -> (dbsetorder (1))
//	sa1 -> (dbgotop ())
//	//
//	do while ! sa1 -> (eof ())
//		u_log ('Verificando item', sa1 -> a1_vend)
//		if alltrim(sa1 -> a1_vend) == '317'
//			//u_help ('Verificando item '+ sa1 -> a1_vend + '-'+ sa1 -> a1_cod)
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SA1", .F., .F.)
//			sComissao := 5
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SA1", sComissao, sa1 -> (recno ()), '', .F.)
//			_oEvento:Grava()
//			
//			U_AtuMerc ("SA1", sa1 -> (recno ()))
//			
//			reclock ("SA1", .f.)
//				sa1 -> a1_comis = sComissao
//			msunlock ()
//			
//			u_log ('alterado')
//			
//			//exit
//		else
//			u_log ('Nada a alterar')
//		endif
//		//
//		sa1 -> (dbskip ())
//	enddo
//Return


////-------------------------------------------------------------------------------------------------
//Static function _AtualizaProduto ()
//	// Ajusta cadastro produtos em lote (altera codigos de barras itens que NAO TEM codigo EAN)
//	sb1 -> (dbsetorder (1))
//	sb5 -> (dbsetorder (1))
//	sb1 -> (dbgotop ())
//	//
//	do while ! sb1 -> (eof ())
//		u_log ('Verificando item', sb1 -> b1_cod, SB1 -> B1_DESC)
//		if sb1->b1_p_brt != sb1->b1_pesbru
//		
//			// Cria variaveis para uso na gravacao do evento de alteracao
//			regtomemory ("SB1", .F., .F.)
//			m->b1_pesbru := sb1->b1_p_brt
//			
//			// Grava evento de alteracao
//			_oEvento := ClsEvent():new ()
//			_oEvento:AltCadast ("SB1", m->b1_cod, sb1 -> (recno ()), '', .F.)
//	
//			reclock ("SB1", .f.)
//			sb1 -> b1_pesbru = m->b1_pesbru
//			msunlock ()
//			//exit
//		else
//			u_log ('nada a alterar')
//		endif
//		//
//		sb1 -> (dbskip ())
//	enddo
//
//Return

//-----------------------------------------------------------------------------------
