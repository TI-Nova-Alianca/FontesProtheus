// Programa...: MTAGrSD4
// Autor......: Leandro Perondi - DWT
// Data.......: 02/07/2014
// Descricao..: P.E. apos gravar SD4.
//              Criado inicialmente para mudar local dos empenhos.
//
// Historico de alteracoes:
// 19/08/2014 - Robert - salva e restaura areas de trabalho.
// 25/10/2014 - Robert - Passa a usar a funcao U_LocEmp.
// 05/10/2016 - Robert - Passa a verificar campo B1_APROPRI antes de alterar o almox. dos empenhos.
// 11/05/2017 - Robert - Funcao de ajuste de almox. dos empenhos passa a ser externa.
// 08/04/2019 - Catia  - include TbiConn.ch 
// ------------------------------------------------------------------------------------
#include "colors.ch"
#Include "Protheus.ch"
#Include "RwMake.ch"
#Include "TbiConn.ch"

User Function mtagrsd4()
	local _aAreaAnt := U_ML_SRArea ()
	local _oSQL     := NIL
	local _sLocEmp  := ""

	// Altera armazem dos empenhos.
	_oSQL := ClsSQL ():New ()
	_oSQL:_sQuery := "SELECT dbo.VA_FLOC_EMP_OP ('" + cFilAnt + "', D4_COD) AS LOCEMP"
	_oSQL:_sQuery +=  " FROM " + RetSqlName ("SD4") + " SD4 "
	_oSQL:_sQuery +=  " WHERE SD4.R_E_C_N_O_ = " + cvaltochar (sd4 -> (recno ()))
	_sLocEmp = _oSQL:RetQry (1, .F.)
	if _sLocEmp != sd4 -> d4_local
		U_AjLocEmp (_sLocEmp)
	endif

	// Altera centro de custo da mao de obra conforme a filial.
	_AltCC ()

	U_ML_SRArea (_aAreaAnt)
return



// ----------------------------------------------------------------------
// Alguns centros de custo existem apenas na matriz.
static function _AltCC ()
	local _sCCNovo  := ""
	local _sMMMNovo := ""
	local _sLocal   := ""

	if cEmpAnt == '01' .and. left (sd4 -> d4_cod, 3) == 'MMM' .and. substr (sd4 -> d4_cod, 4, 2) != cFilAnt
		_sCCNovo = cFilAnt + substr (sd4 -> d4_cod, 6, 7)
		
		// Se o CC nao existir nesta filial ou estiver bloqueado, troca pelo da 01.
		ctt -> (dbsetorder (1))  // CTT_FILIAL+CTT_CUSTO
		if ! ctt -> (dbseek (xfilial ("CTT") + _sCCNovo, .F.)) .or. ctt -> ctt_bloq == '1'
			aVetor := {}
			nOpc   := 5    // excluir
			lMsErroAuto := .F.
			aVetor:={ 	{"D4_COD"  	 , sd4 -> d4_cod,   Nil},;
						{"D4_LOCAL"  , sd4 -> d4_local, Nil},;
						{"D4_OP"     , SD4 -> D4_OP,    Nil},;
						{"D4_DATA"   , sd4 -> d4_data,  Nil},;
						{"D4_QTSEGUM", 0,               Nil}}
			MSExecAuto({|x,y| mata380(x,y)},aVetor,nOpc)
			If lMsErroAuto
				MostraErro()
			endif
		else
			aVetor := {}
			nOpc   := 5    // excluir
			lMsErroAuto := .F.
			aVetor:={ 	{"D4_COD"  	 , sd4 -> d4_cod,   Nil},;
						{"D4_LOCAL"  , sd4 -> d4_local, Nil},;
						{"D4_OP"     , SD4 -> D4_OP,    Nil},;
						{"D4_DATA"   , sd4 -> d4_data,  Nil},;
						{"D4_QTSEGUM", 0,               Nil}}
			MSExecAuto({|x,y| mata380(x,y)},aVetor,nOpc)
			If lMsErroAuto
				MostraErro ()
			else
				_sMMMNovo = left ('MMM' + _sCCNovo + space (15), 15)
				_sLocal = FBuscaCpo ("SB1", 1, xfilial ("SB1") + _sMMMNovo, "B1_LOCPAD")

				// Cria armazem caso ainda não existir.
				DbSelectArea("SB2")
				DbSetOrder(1)
				If !dbSeek(xfilial() + _sMMMNovo + _sLocal)
					CriaSB2 (_sMMMNovo, _sLocal)
				endif
				aVetor := {}
				nOpc   := 3    // incluir
				lMsErroAuto := .F.
				aVetor:={ 	{"D4_COD"  	 , _sMMMNovo, Nil},;
							{"D4_OP"     , SD4->D4_OP,  Nil},;
							{"D4_LOCAL"  , _sLocal ,Nil},;
							{"D4_DATA"   , FBuscaCpo ("SC2", 1, xfilial ("SC2") + sd4 -> d4_op, "C2_DATPRI") ,Nil},;
							{"D4_QTDEORI", SD4->D4_QTDEORI, Nil},;
							{"D4_QUANT"  , SD4->D4_QUANT, Nil}}
				MSExecAuto({|x,y| mata380(x,y)},aVetor,nOpc)  // alteracao
				If lMsErroAuto
					MostraErro()
				Endif
			endif		
		endif
	endif
return
