// Programa.: VA_FISA140
// Autor....: Cláudia Lionço
// Data.....: 16/05/2022
// Descricao: Realiza cópida de registros da matriz para demais filiais.
//            Produto X Código valores declaratorios
// 
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #Cadastro
// #Descricao         #Realiza cópida de registros da matriz para demais filiais
// #PalavasChave      #valores_declaratorios #manutencao
// #TabelasPrincipais #F3K
// #Modulos           #FIS
//
// Historico de alteracoes:
// 04/08/2022 - Robert - Ajuste log, que mostrava nome de outra rotina.
//

// --------------------------------------------------------------------------------------------
#include 'protheus.ch'
#include "totvs.ch"

User Function VA_FISA140
	Local _FilDest := ""
	Local _FilOri  := cFilAnt
	
	cPerg := "VA_FISA140"
	_lRet = _LibRotina ()
	
	If _lRet 
		_ValidPerg()
		
		If Pergunte(cPerg, .T.)
//			u_logIni()
//			u_log("Iniciando BatPessoas em", date (), time ())
			U_Log2 ('info', '[' + procname () + ']')

			If _lRet .and. empty(mv_par01)
				u_help("Filial de destino não informada. Verifique!")
				u_log("Filial de destino não informada. Verifique!")
				_lRet    := .F.
				_FilDest := ""
			EndIf

			If _lRet
				_FilDest := mv_par01
				If _lRet .and. alltrim(_FilOri) <> '01'
					u_help("A filial de origem para execução deve ser a matriz!")
					u_log("A filial de origem para execução deve ser a matriz!")
					_lRet := .F.
				EndIf
				
				If _lRet .and. _FilDest == '01'
					u_help("A filial de destino não pode ser a matriz")
					u_log("A filial de destino não pode ser a matriz")
					_lRet := .F.
				EndIf

				If _lRet
					Processa({|| _GravaRegistros(_FilOri, _FilDest)})
				Else
					u_help("Processo finalizado!")
					u_log("Processo finalizado!")
				EndIf
			EndIf
		EndIf
	EndIf
//	u_logFim()
	U_Log2 ('info', 'Finalizando ' + procname ())
Return
//
// --------------------------------------------------------------------------
// Liberação de rotina
static function _LibRotina ()
	local _lRet      := .T.
	
	If ! U_ZZUVL ('123', __cUserId, .F.) 
		u_help ("Usuário sem permissão para utilização da rotina grupo 123!")
		_lRet = .F.
	Endif
return _lRet
//
//------------------------------------------------------------------------------------------
// Exclui registros e copia novos registros
Static Function _GravaRegistros(_FilOri, _FilDest)
	Local aArea     := GetArea()
    Local aEstru    := {}
    Local aConteu   := {}
    Local nPosFil   := 0
    Local cCampoFil := ""
    Local nAtual    := 0
    Local _Qry 		:= ""
    Local cTabelaAux:= "F3K"
    Local nReg		:= 0
	
	_cMens:= "Registros da filial " + alltrim(_FilDest) + " serão deletados e substituidos pelos registros da filial " + alltrim(_FilOri) + ". Deseja continuar?"
	If MsgYesNo(_cMens,"ATENÇÃO","YESNO")
	
		_lCont := _DeletaReg(_FilDest) // DELETA OS REGISTROS
		
		If _lCont == .T.
		    DbSelectArea(cTabelaAux) // Realiza a copia     
		    aEstru := (cTabelaAux)->(DbStruct()) //Pega a estrutura da tabela
		     
		    //Encontra o campo filial
		    nPosFil   := aScan(aEstru, {|x| "FILIAL" $ AllTrim(Upper(x[1]))})
		    cCampoFil := aEstru[nPosFil][1]
		    
			_Qry := " SELECT R_E_C_N_O_ AS DADREC"  
			_Qry += " FROM F3K010 " 
			_Qry += " WHERE D_E_L_E_T_ = '' "
			_Qry += " AND F3K_FILIAL = '" + _FilOri + "' "
			_Qry += " ORDER BY F3K_FILIAL, F3K_PROD "
			u_log(_Qry)
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
		        
				//u_log(str(TRA->DADREC))
				DBSelectArea("TRA")
				dbskip()
			Enddo
			TRA->(DbCloseArea())
			RestArea(aArea)	
			u_help("Processo finalizado!")
			u_log("Processo finalizado!")
		Else
			u_help("Processo cancelado!")
			u_log("Processo cancelado!")
		EndIf
	Else
		u_help("Processo cancelado!")
		u_log("Processo cancelado!")
	EndIf
Return
//------------------------------------------------------------------------------------------
// Deleta fisicamente os registros da filial de destino 
Static Function _DeletaReg(_FilDest)
	Local _Qry1 := ""
	
	If alltrim(_FilDest) == '01'
		u_help(" Filial de destino 01 é inválida! Não será possivel prosseguir com o processo.")
		u_log(" Filial de destino 01 é inválida! Não será possivel prosseguir com o processo.")
		_lRet := .F.
	Else
		_Qry1 := " DELETE F3K010 "
		_Qry1 += " WHERE F3K_FILIAL = '" + _FilDest + "'"
		_Qry1 += " AND F3K_FILIAL <> '01' "
		TCSQLExec(_Qry1) 
		
		_lRet := .T.
	EndIf
Return _lRet
//
//------------------------------------------------------------------------------------------
// PERGUNTAS
Static Function _ValidPerg ()
    local _aRegsPerg := {}
    //                     PERGUNT                TIPO TAM DEC VALID F3     Opcoes                      				Help
    aadd (_aRegsPerg, {01, "Filial destino	", "C", 2, 0,  "",  "SM0", {},                         					""})
    
     U_ValPerg (cPerg, _aRegsPerg)
Return
