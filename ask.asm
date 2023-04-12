;-----------------------------Polecenie-------------------------------------------------
;System alarmowy mo�na uzbroi� wprowadzaj�c czterocyfrowy PIN.
;Wprowadzenie tego samego PINu w odwrotnej kolejno�ci powoduje rozbrojenie alarmu.
;Wymy�l rozw�zanie, zademonstruj i obja�nij program.

;-------------------Wykorzystanie urz�dze� peryferyjnych oraz port�w-------------------
;				Klawiatura
;           +----+----+----+
;           |  1 |  2 |  3 |   row3 (P0.3)
;           +----+----+----+
;           |  4 |  5 |  6 |   row2 (P0.2)
;           +----+----|----+
;           |  7 |  8 |  9 |   row1 (P0.1)
;           +----+----+----+
;           |  X |  0 |  X |   row0 (P0.0)
;           +----+----+----+
;           col2 col1 col0
;		  (P0.6)(P0.5)(P0.4)
; 			X - nie u�ywane
;				Matryca LED
;P1.0 - 0 (zapalona) dla uzbrojonego alarmu - 1 (zgaszona) dla rozbrojonego alarmu
;ponadto s�u�y jako flaga
;P1.7 - 0 (zapalona) obs�uga naci�ni�cia przycisku - 1 (zgaszona) brak obs�ugi
;P3.2 - flaga b��dnego PINu
;Wykorzystanie pami�ci:
;R3-R4 - delay
;R0 - wska�nik na kom�rki zawieraj�ce PIN
;R1 - aktualnie sprawdzany klawisz/cyfra
;R2 - por�wnanie cyfr w rozbrajaniu
;A - naci�ni�ty klawisz
;F0 - flaga wskazuj�ca na naci�ni�cie przycisku
;30h-33h - PIN
;---------------------------Start------------------------------------------------------
ORG 0 ;pocz�tek programu w 0 kom�rce pami�ci
MOV R0, #30h ;ustawienie R0 na adres pierwszej kom�rki 
MOV P0,#0FFh ;wyczyszczenie klawiatury
CLR P3.2 ;wyzerowanie flagi - B��dny PIN (rozbrajanie)
;---------------------------P�tla obs�ugi klawiatury---------------------------------------
;								Wiersze
ROWS: ;zmiana wierszy
MOV R1,#0 ;sprawdzanie kolejnych klawiszy zaczynaj�c od zera
CLR P0.0;wyb�r wiersza 0
JB P0.5,NEXTROW ;sprawdzenie naci�ni�cia 0
MOV A,R1		;BUTTON dla 0
SJMP PRESSED		;JB F0,PRESSED dla 0

NEXTROW:
SETB P0.0
INC R1 ;1 - sprawdzanie kolejnych klawiszy zaczynaj�c od 1 (g�rny lewy (3 rz�d 2 kolumna))

CLR P0.3 ;ustawienie wiersza 3
CALL COLUMNS ;wywo�anie funkcji sprawdzaj�cej kolejne kolumny
SETB P0.3 ;wy��czenie sprawdzania wiersza 3
JB F0,PRESSED

CLR P0.2 ;wyb�r wiersza 2
CALL COLUMNS ;podobnie jak dla wiersza 3
SETB P0.2 ;jak wy�ej
JB F0,PRESSED

CLR P0.1
CALL COLUMNS
SETB P0.1

JB F0,PRESSED

SJMP ROWS

;-----------------------------------Klawiatura - Kolumny------------------------------
COLUMNS: ;sprawdzenie kolumn
JNB P0.6,BUTTON ;przejd� do etykiety BUTTON gdy przycisk w kolumnie 2 jest wci�ni�ty
;domy�lnie 1, naci�ni�ty - 0
INC R1 ;kolejna cyfra
JNB P0.5, BUTTON ;kolumna 1
INC R1
JNB P0.4, BUTTON ;kolumna 0
INC R1
RET

BUTTON:
MOV A,R1
SETB F0
RET
;------------------------------Obs�uga naciskanych przycisk�w-------------------------
PRESSED: ;
CLR P1.7 ;zapalenie diody wskazuj�cej na obs�ug� naci�ni�cia klawisza
JB P1.0,UZBROJENIE ;obs�uga uzbrojenia alarmu
SJMP ROZBROJENIE	;obs�uga rozbrojenia alarmu
;------------------------------Obs�uga uzbrojenia alarmu------------------------------
UZBROJENIE:
MOV @R0 ,A ;wpisanie cyfry do kom�rki pami�ci wskazywanej rejestrem R0
INC R0	;zmiana wska�nika na kolejn� kom�rk�
CJNE R0, #34h,KONIECOBS ;skok do KONIECOBS gdy nie wprowadzono 4 cyfr PINu
CLR P1.0	;zapal diod� LED (alarm jest uzbrojony)
MOV R0,#33h	;zmie� na adres ostatniej cyfry PINu (do rozbrojenia)
SJMP KONIECOBS
;-----------------------------Obs�uga rozbrojenia alarmu-----------------------------------
NIEPOPR:
SETB P3.2
SJMP NROZ

ROZBROJENIE:
MOV 2,@R0 ;przenie� cyfr� PINu do R1 (do por�wnania)
DEC R0			;poprzednia cyfra PINu
CJNE A,2,NIEPOPR	;skok gdy cyfra PINu r�na od wprowadzonej - rozbrajanie nieudane
NROZ:
CJNE R0,#2Fh,KONIECROZ ;skok gdy ca�y PIN nie zosta� wprowadzony od ko�ca
JB P3.2,RESETROZ
SETB P1.0		;wy��cz diod� wskazuj�c� na uzbrojony alarm	
MOV R0,#30h		;zmiana rejestru na adres zapisu 1 cyfry PINu
SJMP KONIECROZ

RESETROZ:
CLR P3.2	
MOV R0,#33h	;ustawienie adresu na ostatni� cyfr� PINu
KONIECROZ:
SJMP KONIECOBS

;------------------------------Koniec obs�ugi naciskanych przycisk�w-----------------------
KONIECOBS: ;powr�t do p�tli z obs�ug� klawiatury
CALL DELAY ;op�nienie po wprowadzeniu cyfry
MOV P0,#0FFh ;reset klawiatury
SETB P1.7	;wy��czenie diody obs�ugi naci�ni�cia
CLR F0
SJMP ROWS ;powr�t do oryginalnej p�tli (obs�ugi klawiatury)

;--------------------------------------Delay-----------------------------------------------
DELAY: ;blokowanie klawiszy
MOV R3, #13
DEL: MOV R4, #1bh
DJNZ R4, $
DJNZ R3, DEL
RET

END
