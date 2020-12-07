// Programa:   PE_MATA030
// Autor:      Andre Alves
// Data:       07/05/2019
// Descricao:  P.E. novo padrão MVC na tela de cadastro de clientes.
//
// Tags para automatizar catalogo de customizacoes:
// #TipoDePrograma    #ponto_de_entrada
// #Descricao         #P.E. novo padrão MVC na tela de cadastro de clientes.
// #PalavasChave      #MVC #clientes #cadastro_de_clientes
// #TabelasPrincipais #SA1 
// #Modulos   		  #TODOS 
//
// Historico de alteracoes:
// 18/08/2008 - Robert - Criada validacao cfe. campo A3_VAEXTAB
// 27/01/2010 - Robert - Passa a usar a funcao u_help para avisos.
// 13/02/2012 - Robert - Nao exige mais %comis se estiver zerado tambem no vendedor.
// 20/02/2012 - Robert - Verifica se o CNPJ jah existe em outro cliente.
// 24/05/2012 - Robert - Impedia alteracao de cliente com CNPJ repetido, mesmo que o outro estivesse bloqueado.
// 29/05/2013 - Elaine - Inclui tratamento para Inscricao Estadual para mercado externo
// 12/03/2015 - Catia  - Desabilitada a validação para inscrição estadual
// 27/11/2020 - Cláudia - Incluido botão de obs.financeira. GLPI: 8923
//
// -----------------------------------------------------------------------------------------------
#include "protheus.ch"
#include "parmtype.ch"

User Function CRMA980()
    Local aParam := PARAMIXB
    Local xRet := .T.
    Local oObj := "" 
    Local cIdPonto := ""
    Local cIdModel := ""
    Local lIsGrid := .F.
    Local nOper := 0
 
    If aParam <> NIL
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)
 
        If cIdPonto == "MODELPOS"
        	nOper := oObj:nOperation
			if nOper == 4


				u_log ('')
				u_log ('')
				u_log ('')
				u_logPCham ()
				u_log ('M:', m->a1_nome)
				u_log ('SA1:', sa1->a1_nome)



        	    _GeraLog ()
        		U_AtuMerc ('SA1', sa1 -> (recno ()))
        	endif
        	xRet := _ma030tok()
        ElseIf cIdPonto == "MODELVLDACTIVE"
            nOper := oObj:nOperation
            //Se for Exclusão, não permite abrir a tela
            If nOper == 5  // Exclusao
				u_help ("Nenhum registro de cliente pode ser excluído em função da integração com o software Mercanet.")
				xRet = .F.
			EndIf
        ElseIf cIdPonto == "FORMPOS"
            xRet := NIL
        ElseIf cIdPonto == "FORMLINEPRE"
        	xRet := .T.
        ElseIf cIdPonto == "FORMLINEPOS"
            xRet := .T.
        ElseIf cIdPonto == "MODELCOMMITTTS"
        	xRet := .T.
        ElseIf cIdPonto == "MODELCOMMITNTTS"
        	nOper := oObj:nOperation
        	//Se for inclusão
            If nOper == 3
                _M030INC()
            EndIf
        ElseIf cIdPonto == "FORMCOMMITTTSPRE"
        	xRet := .T.
        ElseIf cIdPonto == "FORMCOMMITTTSPOS"
        	xRet := .T.
        ElseIf cIdPonto == "MODELCANCEL"
            xRet := .T.
        ElseIf cIdPonto == "BUTTONBAR"
           // xRet := {}
		   	If cFilAnt == '01'
				xRet := {{"Obs.Financeiro", "Obs.Financeiro", {||U_VA_OBSFIN('1')}}}
		   	EndIf
        EndIf
    EndIf

Return xRet

//----------------------------------------------------------------------------------
static function _GeraLog ()
	local _oEvento  := NIL

		_oEvento := ClsEvent():new ()
		_oEvento:Cliente = sa1->a1_cod
		_oEvento:LojaCli = sa1->a1_loja
		_oEvento:AltCadast ("SA1", sa1->a1_cod + sa1->a1_loja, sa1 -> (recno ()))
	
return




static Function _ma030tok()
	Local _aAreaAnt := U_ML_SRArea ()
	Local _xFim     := chr(13)+chr(10)
	Local _lRet     := .T.
	Local _xCOD     := M->A1_COD
	Local _xLOJA    := M->A1_LOJA
	Local _xNOME    := M->A1_NOME
	Local _xEST     := M->A1_EST
	Local _xTIPO    := M->A1_TIPO
	//Local _xINSCR   := M->A1_INSCR
	//Local _xSUFRAMA := M->A1_SUFRAMA
	//Local _xCODMUN  := M->A1_CODMUN
	//Local _xCALCSUF := M->A1_CALCSUF
	Local _xCGC     := M->A1_CGC
	Local _xBCO1    := M->A1_BCO1
	Local _xPRACA   := M->A1_PRACA
	local _oSQL     := NIL
	local _nInd		:= 0
	
	// Consiste Estado com Tipo do Cliente (Critica Exportacao)
	If _lRet
		If ( _xEST == "EX" .And. _xTIPO <> "X" ) .Or. ( _xEST <> "EX" .And. _xTIPO == "X" )
			u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo ESTADO e o Campo TIPO pois existe incoerencia."+_xFim;
			,"Atencao !!!  Incoerencia entre o Campo ESTADO e TIPO.")
			_lRet := .F.
		Endif
	Endif
	
	// Consiste !Exportacao X Preenchimento do CNPJ / CPF
	If _lRet
		If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. Empty(_xCGC)
			u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
			,"Atencao !!!  Obrigatorio CNPJ / CPF.")
			_lRet := .F.
		Endif
		If  ( _xEST <> "EX" .And. _xTIPO <> "X" ) .And. _xCGC == "00000000000000"
			u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
			"Verifique o campo CNPJ / CPF. O mesmo deve estar Preenchido."+_xFim;
			,"Atencao !!!  Nao preencher CNPJ / CPF com zero.")
			_lRet := .F.
		Endif
	Endif
	
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifico se todos os caracteres do Codigo sao numeros                    ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If _lRet
		For _nInd := 1 To Len(_xCOD)
			_cChar := Substr(_xCOD,_nInd,1)
			If IsAlpha(_cChar)
				u_help("O Codigo so permite Campos Numericos."+_xFim;
				,"Atencao !!!  Codigo Invalido.")
				_lRet := .F.
				Exit
			Endif
		Next
	Endif
	
	// Consiste Praca Sicredi
	If _lRet
		// Parametro Flag (Valida Informacoes Sicredi)
		If GetNewPar("ML_VLDC748","S") == "S" .And. _xBCO1 == "748"
			If Empty(_xPRACA) .And. _lRet
				u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
				"A Praca SICREDI precisa OBRIGATORIAMENTE estar preenchida se o Banco for 748 (Sicredi)."+_xFim;
				,"Atencao !!!  Verificar Praca Sicredi (Obrigatorio).")
				_lRet := .F.
			Endif
			
			DbSelectArea("SZ3")
			DbSetOrder(1)
			If DbSeek(xFilial("SZ3")+_xPRACA)
				If SZ3->Z3_SITUACA <> "A" .And. _lRet
					u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
					"Praca: "+_xPRACA+" NAO esta ativa."+_xFim;
					,"Atencao !!!  Verificar Praca Sicredi (Situacao).")
					_lRet := .F.
				Endif
				If SZ3->Z3_TPCOB <> "A" .And. _lRet
					u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
					"Praca: "+_xPRACA+" esta relacionada a Banco Correspondente."+_xFim;
					,"Atencao !!!  Verificar Praca Sicredi (Bco Correspondente).")
					_lRet := .F.
				Endif
				If SZ3->Z3_UF <> SA1->A1_EST .And. _lRet
					u_help("Cliente: "+Trim(_xCOD)+"/"+Trim(_xLOJA)+" - "+_xNOME+_xFim+;
					"Praca: "+_xPRACA+" Estado do Cliente Difere do Estado da Praca."+_xFim;
					,"Atencao !!!  Verificar Praca Sicredi (UF Incorreta).")
					_lRet := .F.
				Endif
			Else
				u_help("Praca: "+_xPRACA+" Nao encontrada.","Atencao")
				_lRet := .F.
			Endif
		Endif
	Endif
	
	// O sistema dah um aviso, mas permite mais de um cadastro com mesmo CNPJ.
	if _lRet
		_oSQL := ClsSQL():New ()
		_oSQL:_sQuery := ""
		_oSQL:_sQuery += " SELECT A1_COD + '/' + A1_LOJA"
		_oSQL:_sQuery +=   " FROM " + RetSQLName ("SA1") + " SA1 "
		_oSQL:_sQuery +=  " WHERE D_E_L_E_T_ = ''"
		_oSQL:_sQuery +=    " AND A1_FILIAL  = '" + xfilial ('SA1') + "'"
		_oSQL:_sQuery +=    " AND A1_CGC     = '" + m->a1_cgc + "'"
		_oSQL:_sQuery +=    " AND A1_CGC    != ''"
		_oSQL:_sQuery +=    " AND A1_MSBLQL != '1'"
		_oSQL:_sQuery +=    " AND A1_COD + A1_LOJA != '" + m->a1_cod + m->a1_loja + "'"
		_oSQL:RetQry ()
		if ! empty (_oSQL:_xRetQry)
			u_help ("CNPJ / CPF ja cadastrado para o cliente/loja '" + _oSQL:_xRetQry + "'. Bloqueie um dos dois!")
			_lRet = .F.
		endif
	endif
	
	U_ML_SRArea (_aAreaAnt)
Return(_lRet)


// --------------------------------------------------------------------------
Static Function _M030INC()

	// Cria registro para o cliente no arquivo de classes de valor.
	// Verifica se jah existe por que o P.E. eh executado mesmo se o usuario cancelar o cadastramento.
	cth -> (dbsetorder (1))  // CTH_FILIAL+CTH_CLVL
	if ! cth -> (dbseek (xfilial ("CTH") + SA1->A1_COD + SA1->A1_LOJA, .F.))
		RecLock('CTH',.t.)
		CTH->CTH_FILIAL := xFilial('CTH')
		CTH->CTH_CLVL   := SA1->A1_COD + SA1->A1_LOJA
		CTH->CTH_DESC01 := SA1->A1_NOME
		CTH->CTH_CLASSE := '2'
		CTH->CTH_BLOQ   := '2'
		CTH->CTH_CLVLLP := '00000000 '
		CTH->CTH_DTEXIS := dDataBase
		MsUnLock()
	endif
	DbSelectArea('SA1')

	U_AtuMerc ('SA1', sa1 -> (recno ()))

Return()

