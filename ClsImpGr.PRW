// Programa:  ClsImpGr
// Autor:     Robert Koch
// Data:      06/03/2008
// Descricao: Classe para impressao grafica.
//            Poderia trabalhar como uma include, mas prefiro declarar uma funcao de usuario apenas para poder
//            incluir no projeto e manter na pasta dos fontes.
//
// Historico de alteracoes:
// 12/09/2008 - Robert - Diminuida altura da pagina (formato retrato)
// 30/01/2015 - Catia  - Alterado o campo telefone que estava errado
// 13/08/2018 - Andre  - Removi logo e ajustado formatação do cabeçalho. Chamado 4441.

#include "protheus.ch"

// --------------------------------------------------------------------------
// Funcao declarada apenas para poder compilar este arquivo fonte.
//user function classes ()
//return



// ==========================================================================
// ==========================================================================
// Classe usada para controle de impressao grafica.
CLASS ClsImpGr

	// Declaracao das propriedades da Classe
	data _oPrn
	data _nPagAtual
	data _nMargSup
	data _nMargInf
	data _nMargEsq
	data _nAltPag
	data _nLargPag
	data _nAltLin
	data _nLinAtual
	data _oTimes8
	data _oTimes16
	
	// Declaração dos Métodos da Classe
	METHOD New (_oPrinter, _sPapel) //CONSTRUCTORMETHOD
	method Cabec (_lObrig, _nMinimo, _lZeraPag)
	method IncLinha (_nQuantas)
ENDCLASS


// --------------------------------------------------------------------------
METHOD New(_oPrinter, _sPapel) Class ClsImpGr
	::_oPrn      := _oPrinter
	::_nPagAtual := 1  // Contador de paginas
	::_nLinAtual := 0
	::_nAltLin   := 50  // Altura de cada linha em pontos (para trabalhar de forma semelhante a impressao caracter)
	::_nMargSup  := 40  // Margem superior da pagina
	::_nMargInf  := 50  // Margem inferior da pagina
	::_nMargEsq  := 40   // Margem esquerda da pagina
	if _sPapel == "A4R"  // A4 retrato
		::_nAltPag   := 3100  //3400  // Altura maxima da pagina
		::_nLargPag  := 2350  // Largura maxima da pagina
	elseif _sPapel == "A4P"  // A4 paisagem
		::_nAltPag   := 2350  // Altura maxima da pagina
		::_nLargPag  := 3400  // Largura maxima da pagina
	endif
	::_oTimes8  := TFont():New("Times New Roman",,8,,.T.,,,,,.F.)
	::_oTimes16 := TFont():New("Times New Roman",,16,,.T.,,,,,.F.)
Return Self


// --------------------------------------------------------------------------
method IncLinha(_nQuantas) class ClsImpGr
	_nQuantas := iif (_nQuantas == NIL, 1, _nQuantas)
	::_nLinAtual += ::_nAltLin * _nQuantas
return


// --------------------------------------------------------------------------
method Cabec(_lObrig, _nMinimo, _lZeraPag) class ClsImpGr
	local _sLinhaImp := ""
	_nMinimo := iif (_nMinimo == NIL, 0, _nMinimo)
	_lZeraPag := iif (_lZeraPag == NIL, .F., _lZeraPag)
	if ::_nLinAtual >= ::_nAltPag - (::_nMargInf + _nMinimo) .or. _lObrig
		if ::_nPagAtual > 1
			::_oPrn:EndPage ()    // Encerra pagina
		endif
		::_oPrn:StartPage ()  // Inicia uma nova pagina
		
		if _lZeraPag
			::_nPagAtual = 1
		endif

		// Moldura em torno da pagina
		::_oPrn:Box(10, ;  // Linha sup
	               10, ;  // Coluna esq
	               ::_nAltPag - 10, ; // Linha inf
	               ::_nLargPag - 10)  // Coluna dir

		// Moldura em torno do cabecalho
		::_oPrn:Box(30, ;  // Linha sup
	               30, ;  // Coluna esq
	               200, ; // Linha inf
	               ::_nLargPag - 40)  // Coluna dir

		// Monta cabecalho padrao
		::_nLinAtual = ::_nMargSup
		_sLinhaImp := "Pag. " + cvaltochar (::_nPagAtual)
		::_oPrn:Say (::_nLinAtual, ::_nLargPag - 200, _sLinhaImp, ::_oTimes8, 100)
/*		::_oPrn:SayBitmap(::_nLinAtual, ;  // Linha
		                  ::_nMargEsq, ;  // Coluna
		                  "Logo2.bmp", ;  // Arquivo
		                  400, ;  // Largura
		                  107)  // Altura */
		_sLinhaImp := alltrim (sm0 -> m0_nomecom)
		::_oPrn:Say (::_nLinAtual, 100, _sLinhaImp, ::_oTimes16, 100)
		::_nLinAtual += 60

		_sLinhaImp := alltrim (sm0 -> m0_endcob) + " - "
		_sLinhaImp += "Bairro " + alltrim (sm0 -> m0_BairCob) + " - "
		_sLinhaImp += "CEP " + alltrim (transform (sm0 -> m0_CEPCob, "@R 99.999-999")) + " - "
		_sLinhaImp += alltrim (sm0 -> m0_CidCob) + " - " + sm0 -> m0_EstCob + " - "
		_sLinhaImp += "Fone/fax: " + alltrim( sm0 -> m0_tel)
		::_oPrn:Say (::_nLinAtual, 100, _sLinhaImp, ::_oTimes8, 100)
		::_nLinAtual += 40

		_sLinhaImp := "CNPJ: " + alltrim (sm0 -> m0_cgc) + " - "
		_sLinhaImp += "Inscr.: " + alltrim (sm0 -> m0_Insc) + " - "
		_sLinhaImp := "E-mail: alianca@novaalianca.coop.br  -  http://www.novaalianca.coop.br"
		::_oPrn:Say (::_nLinAtual, 100, _sLinhaImp, ::_oTimes8, 100)
		::_nLinAtual = 200

		::_nPagAtual ++
	endif
return

// ==========================================================================
// ==========================================================================
