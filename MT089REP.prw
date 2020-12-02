// Programa:  MT089REP
// Autor:     Cláudia Lionço
// Data:      30/11/2020
// Descricao: Rotina para realizar transferencia de registros de TES inteligente entre filiais
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Rotina para realizar transferencia de registros de TES inteligente entre filiais
// #PalavasChave      #TES_inteligente #manutencao
// #TabelasPrincipais #SFM
// #Modulos           #FIS
//
// Historico de alteracoes:
//
// --------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include 'parmtype.ch'

User Function MT089REP()
	Local _Empresa  := '01'
	Local _FilOri 	:= cFilAnt
	Local _lContinua:= .T.
	cPerg   := "MT089REP"
	
	// // Controle de semaforo.
	// _nLock := U_Semaforo (procname () + cEmpAnt)
	// If _nLock == 0
	// 	msgalert ("Não foi possível obter acesso exclusivo a esta rotina.")
	// 	_lContinua := .F.
	// Endif
	
	If _lContinua
		_lRet = _LibRotina ()
		
		If _lRet == .T.
			_ValidPerg()
			
			If Pergunte (cPerg, .T.)
				If empty(mv_par01)
					u_help("Filial de destino não informada. Verifique!")
				Else
					_UFOri   := fBuscaCpo ("SM0", 1, _FilOri, "M0_ESTCOB") //u_help("Origem:" + _FilOri + "-" + _UFOri)
			
					_FilDest := mv_par01
					_UFDest  := fBuscaCpo ("SM0", 1, _Empresa + _FilDest, "M0_ESTCOB") //u_help("destino:"+_FilDest + "-" + _UFDest)
							
					If _UFOri != _UFDest
						_cMens := ("UF de origem (" + _UFOri + ") é diferente da UF de destino(" + _UFDest + "). Deseja continuar?")
						
						If MsgYesNo(_cMens,"ATENÇÃO","YESNO")
						   Processa({|| _MT089E(_FilOri,_UFOri,_FilDest,_UFDest)})
						Else
							u_help("Processo finalizado!")
						EndIf
					Else
						 Processa({|| _MT089E(_FilOri,_UFOri,_FilDest,_UFDest)})
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf
Return
// --------------------------------------------------------------------------
// Liberação de rotina
static function _LibRotina ()
	local _lRet      := .T.
	
	If ! U_ZZUVL ('123', __cUserId, .F.) 
		u_help ("Usuário sem permissão para utilização da rotina 123!")
		_lRet = .F.
	Endif
return _lRet
//------------------------------------------------------------------------------------------
// Exclui registros e copia novos registros
Static Function _MT089E(_FilOri,_UFOri,_FilDest,_UFDest)
	Local aArea     := GetArea()
    Local aEstru    := {}
    Local aConteu   := {}
    Local nPosFil   := 0
    Local cCampoFil := ""
    Local nAtual    := 0
    Local _Qry 		:= ""
    Local cTabelaAux:= "SFM"
    Local nReg		:= 0
	
	_cMens:= "Registros da filial " + alltrim(_FilDest) + " serão deletados e substituidos pelos registros da filial " + alltrim(_FilOri) + ". Deseja continuar?"
	If MsgYesNo(_cMens,"ATENÇÃO","YESNO")
	
		_lCont := _MT089D(_FilDest) // DELETA OS REGISTROS
		
		If _lCont == .T.
		    DbSelectArea(cTabelaAux) // Realiza a copia     
		    aEstru := (cTabelaAux)->(DbStruct()) //Pega a estrutura da tabela
		     
		    //Encontra o campo filial
		    nPosFil   := aScan(aEstru, {|x| "FILIAL" $ AllTrim(Upper(x[1]))})
		    cCampoFil := aEstru[nPosFil][1]
		    
			_Qry := " SELECT R_E_C_N_O_ AS DADREC"  
			_Qry += " FROM SFM010 " 
			_Qry += " WHERE D_E_L_E_T_ = '' "
			_Qry += " AND FM_FILIAL = '" + _FilOri + "' "
			_Qry += " ORDER BY FM_FILIAL, FM_TIPO"

			dbUseArea(.T., "TOPCONN", TCGenQry(,,_Qry), "TRA", .F., .T.)
			TRA->(DbGotop())
			
			While TRA->(!Eof())	
				aConteu   := {}
		        (cTabelaAux)->(DbGoTo(TRA->DADREC))//Posiciona recno
		         
		        ProcRegua(Len(aEstru)) 
		        For nAtual := 1 To Len(aEstru) //Percorre a estrutura
		            If Alltrim(aEstru[nAtual][1]) == Alltrim(cCampoFil) //Se for campo filial
		                aAdd(aConteu, _FilDest)
		            Else
		                aAdd(aConteu, &(cTabelaAux+"->"+aEstru[nAtual][1]))
		            EndIf
		        Next
		         
		        RecLock(cTabelaAux, .T.) //Faz um RecLock
		        For nAtual := 1 To Len(aEstru) //Percorre a estrutura
		            &(aEstru[nAtual][1]) := aConteu[nAtual] //Grava o novo valor
		        Next
		        (cTabelaAux)->(MsUnlock())
		        
		        nReg += 1
		        IncProc("Criando registros... " + alltrim(str(nReg)))
		        
				DBSelectArea("TRA")
				dbskip()
			Enddo
			TRA->(DbCloseArea())
			RestArea(aArea)	
		
			u_help("Processo finalizado!")
		Else
			u_help("Processo cancelado!")
		EndIf
	Else
		u_help("Processo cancelado!")
	EndIf
Return
//------------------------------------------------------------------------------------------
// Deleta fisicamente os registros da filial de destino - virtualmente gerava erro de duplicate key
Static Function _MT089D(_FilDest)
	Local _Qry1 := ""
	
	If alltrim(_FilDest) == '01'
		u_help(" Filial de destino 01 é inválida! Não será possivel prosseguir com o processo.")
		
		_lRet := .F.
	Else
		_Qry1 := " DELETE SFM010 "
		_Qry1 += " WHERE FM_FILIAL = '" + _FilDest + "'"
		_Qry1 += " AND FM_FILIAL <> '01' "
		TCSQLExec(_Qry1) 
		
		_lRet := .T.
	EndIf

Return _lRet
//------------------------------------------------------------------------------------------
// PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Filial destino	", "C", 2, 0,  "",  "SM0", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
