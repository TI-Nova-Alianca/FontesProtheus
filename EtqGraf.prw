// Programa...: EtqGraf
// Autor......: Robert Koch
// Data.......: 28/04/2008
// Cliente....: Alianca
// Descricao..: Impressao de etiquetas em formato grafico.
//              Recebe uma array com os dados a imprimir e faz a formatacao das
//              etiquetas.
//
// Historico de alteracoes:            
//

// --------------------------------------------------------------------------
User Function EtqGraf (_aEtiq, _sFolha, _nQtCol, _nQtLin, _nLayout, _lBox)
   local _nLIniBox   := 0   // Coordenadas para 'box' em torno de cada etiqueta
   local _nCIniBox   := 0   // Coordenadas para 'box' em torno de cada etiqueta
   local _nLFimBox   := 0   // Coordenadas para 'box' em torno de cada etiqueta
   local _nCFimBox   := 0   // Coordenadas para 'box' em torno de cada etiqueta
   local _nMargSup   := 160 // Margem superior da pagina
   local _nMargEsq   := 80  // Margem esquerda da pagina
   local _nLargEtiq  := 0
   local _nAltEtiq   := 0
   local _nEtiq      := 0
   local _nLin       := 0
   local _nCol       := 0
	local _nAltPag    := 0
	local _nLargPag   := 0

	if _sFolha == "A4R"  // A4 retrato
		_nAltPag  = 3400
		_nLargPag = 2350
	elseif _sFolha == "A4P"  // A4 paisagem
		_nAltPag  = 2350
		_nLargPag = 3400
	else
		u_help ("Funcao " + procname () + ": Tamanho de folha nao previsto!")
		return
	endif

	_nLargEtiq = (_nLargPag - _nMargEsq + 70) / _nQtCol
	_nAltEtiq = (_nAltPag - _nMargSup - 70) / _nQtLin

   // Objetos para tamanho e tipo das fontes: usa fonte Courier por que eh monoespacada.
	_oCour18N := TFont():New("Courier New",,18,,.T.,,,,,.F.)
	_oCour16N := TFont():New("Courier New",,16,,.T.,,,,,.F.)
	_oCour12N := TFont():New("Courier New",,12,,.T.,,,,,.F.)
	_oCour10N := TFont():New("Courier New",,10,,.T.,,,,,.F.)
	_oCour8N  := TFont():New("Courier New",,8 ,,.T.,,,,,.F.)

   oPrn:=TAVPrinter():New("Etiquetas")
   oPrn:Setup()           // Tela para usuario selecionar a impressora
   oPrn:SetPortrait()     // ou SetLanscape()

   _nCol = 0
   _nLin = 0
   _nEtiq = 1
   do while _nEtiq <= len (_aEtiq)
      if _nCol > _nQtCol - 1
         _nLin ++
         _nCol = 0
      endif
      if _nLin > _nQtLin - 1
         oPrn:EndPage ()    // Encerra pagina
         oPrn:StartPage ()  // Inicia uma nova pagina
         _nLin = 0
      endif

		// Calcula coordenadas (4 cantos) da etiqueta
		_nLIniBox := _nMargSup + _nLin * _nAltEtiq
		_nCIniBox := _nMargEsq + _nCol * _nLargEtiq
		_nLFimBox := _nMargSup + _nLin * _nAltEtiq + _nAltEtiq - 30
		_nCFimBox := _nMargEsq + _nCol * _nLargEtiq + _nLargEtiq - 50

      // Gera um 'box' em torno da etiqueta
      if _lBox
	      _Box (_nLIniBox, _nCIniBox, _nLFimBox, _nCFimBox)
		endif

      // O programa chamador pode especificar como vai ser a distribuicao
      // dos dados dentro da etiqueta (uma das linhas em destaque, etc.)
      if _nLayout == 1

      	// Quebra linhas de texto recebidas
      	_aLinha1 = aclone (U_QuebraTXT (_aEtiq [_nEtiq, 1], 25))
      	_aLinha2 = aclone (U_QuebraTXT (_aEtiq [_nEtiq, 2], 31))
      	_aLinha3 = aclone (U_QuebraTXT (_aEtiq [_nEtiq, 3], 25))
        	if len (_aLinha1) >= 1
         	oPrn:Say(_nLIniBox + 10,  _nCIniBox + 10, _aLinha1 [1], _oCour12N, 100)
         endif
         if len (_aLinha1) >= 2
	         oPrn:Say(_nLIniBox + 50,  _nCIniBox + 10, _aLinha1 [2], _oCour12N, 100)
         endif
         if len (_aLinha2) >= 1
         	oPrn:Say(_nLIniBox + 120, _nCIniBox + 10, _aLinha2 [1], _oCour10N, 100)
         endif
         if len (_aLinha2) >= 2
      	   oPrn:Say(_nLIniBox + 160, _nCIniBox + 10, _aLinha2 [2], _oCour10N, 100)
         endif
         if len (_aLinha2) >= 3
   	      oPrn:Say(_nLIniBox + 200, _nCIniBox + 10, _aLinha2 [3], _oCour10N, 100)
         endif
         if len (_aLinha2) >= 4
	         oPrn:Say(_nLIniBox + 240, _nCIniBox + 10, _aLinha2 [4], _oCour10N, 100)
         endif
         if len (_aLinha3) >= 1
   	      oPrn:Say(_nLIniBox + 320, _nCIniBox + 10, _aLinha3 [1], _oCour12N, 100)
         endif
         if len (_aLinha3) >= 2
	         oPrn:Say(_nLIniBox + 360, _nCIniBox + 10, _aLinha3 [2], _oCour12N, 100)
         endif
      else
			u_help ("Funcao " + procname () + ": Layout nao previsto!")
			return
      endif

      _nCol ++
      _nEtiq ++
   enddo

   oPrn:EndPage()   // Encerra página
   oPrn:Preview()       // Visualiza antes de imprimir
   oPrn:End()
Return



// --------------------------------------------------------------------------
// Desenha o box em torno da etiqueta
static function _Box (_nLIniBox, _nCIniBox, _nLFimBox, _nCFimBox)
   oPrn:line (_nLIniBox, _nCIniBox, _nLFimBox, _nCIniBox)  // Esquerda
   oPrn:line (_nLIniBox, _nCIniBox, _nLIniBox, _nCFimBox)  // Superior
   oPrn:line (_nLFimBox, _nCIniBox, _nLFimBox, _nCFimBox)  // Inferior
   oPrn:line (_nLIniBox, _nCFimBox, _nLFimBox, _nCFimBox)  // Direita
return
