;-----------------------------Polecenie-------------------------------------------------
;System alarmowy mo¿na uzbroiæ wprowadzaj¹c czterocyfrowy PIN.
;Wprowadzenie tego samego PINu w odwrotnej kolejnoœci powoduje rozbrojenie alarmu.
;Wymyœl rozw¹zanie, zademonstruj i objaœnij program.

;-------------------Wykorzystanie urz¹dzeñ peryferyjnych oraz portów-------------------
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
; 			X - nie u¿ywane
;				Matryca LED
;P1.0 - 0 (zapalona) dla uzbrojonego alarmu - 1 (zgaszona) dla rozbrojonego alarmu
;ponadto s³u¿y jako flaga
;P1.7 - 0 (zapalona) obs³uga naciœniêcia przycisku - 1 (zgaszona) brak obs³ugi
;P3.2 - flaga b³êdnego PINu
;Wykorzystanie pamiêci:
;R3-R4 - delay
;R0 - wskaŸnik na komórki zawieraj¹ce PIN
;R1 - aktualnie sprawdzany klawisz/cyfra
;R2 - porównanie cyfr w rozbrajaniu
;A - naciœniêty klawisz
;F0 - flaga wskazuj¹ca na naciœniêcie przycisku
;30h-33h - PIN
;---------------------------Start------------------------------------------------------
ORG 0 ;pocz¹tek programu w 0 komórce pamiêci
MOV R0, #30h ;ustawienie R0 na adres pierwszej komórki 
MOV P0,#0FFh ;wyczyszczenie klawiatury
CLR P3.2 ;wyzerowanie flagi - B³êdny PIN (rozbrajanie)
;---------------------------Pêtla obs³ugi klawiatury---------------------------------------
;								Wiersze
ROWS: ;zmiana wierszy
MOV R1,#0 ;sprawdzanie kolejnych klawiszy zaczynaj¹c od zera
CLR P0.0;wybór wiersza 0
JB P0.5,NEXTROW ;sprawdzenie naciœniêcia 0
MOV A,R1		;BUTTON dla 0
SJMP PRESSED		;JB F0,PRESSED dla 0

NEXTROW:
SETB P0.0
INC R1 ;1 - sprawdzanie kolejnych klawiszy zaczynaj¹c od 1 (górny lewy (3 rz¹d 2 kolumna))

CLR P0.3 ;ustawienie wiersza 3
CALL COLUMNS ;wywo³anie funkcji sprawdzaj¹cej kolejne kolumny
SETB P0.3 ;wy³¹czenie sprawdzania wiersza 3
JB F0,PRESSED

CLR P0.2 ;wybór wiersza 2
CALL COLUMNS ;podobnie jak dla wiersza 3
SETB P0.2 ;jak wy¿ej
JB F0,PRESSED

CLR P0.1
CALL COLUMNS
SETB P0.1

JB F0,PRESSED

SJMP ROWS

;-----------------------------------Klawiatura - Kolumny------------------------------
COLUMNS: ;sprawdzenie kolumn
JNB P0.6,BUTTON ;przejdŸ do etykiety BUTTON gdy przycisk w kolumnie 2 jest wciœniêty
;domyœlnie 1, naciœniêty - 0
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
;------------------------------Obs³uga naciskanych przycisków-------------------------
PRESSED: ;
CLR P1.7 ;zapalenie diody wskazuj¹cej na obs³ugê naciœniêcia klawisza
JB P1.0,UZBROJENIE ;obs³uga uzbrojenia alarmu
SJMP ROZBROJENIE	;obs³uga rozbrojenia alarmu
;------------------------------Obs³uga uzbrojenia alarmu------------------------------
UZBROJENIE:
MOV @R0 ,A ;wpisanie cyfry do komórki pamiêci wskazywanej rejestrem R0
INC R0	;zmiana wskaŸnika na kolejn¹ komórkê
CJNE R0, #34h,KONIECOBS ;skok do KONIECOBS gdy nie wprowadzono 4 cyfr PINu
CLR P1.0	;zapal diodê LED (alarm jest uzbrojony)
MOV R0,#33h	;zmieñ na adres ostatniej cyfry PINu (do rozbrojenia)
SJMP KONIECOBS
;-----------------------------Obs³uga rozbrojenia alarmu-----------------------------------
NIEPOPR:
SETB P3.2
SJMP NROZ

ROZBROJENIE:
MOV 2,@R0 ;przenieœ cyfrê PINu do R1 (do porównania)
DEC R0			;poprzednia cyfra PINu
CJNE A,2,NIEPOPR	;skok gdy cyfra PINu ró¿na od wprowadzonej - rozbrajanie nieudane
NROZ:
CJNE R0,#2Fh,KONIECROZ ;skok gdy ca³y PIN nie zosta³ wprowadzony od koñca
JB P3.2,RESETROZ
SETB P1.0		;wy³¹cz diodê wskazuj¹c¹ na uzbrojony alarm	
MOV R0,#30h		;zmiana rejestru na adres zapisu 1 cyfry PINu
SJMP KONIECROZ

RESETROZ:
CLR P3.2	
MOV R0,#33h	;ustawienie adresu na ostatni¹ cyfrê PINu
KONIECROZ:
SJMP KONIECOBS

;------------------------------Koniec obs³ugi naciskanych przycisków-----------------------
KONIECOBS: ;powrót do pêtli z obs³ug¹ klawiatury
CALL DELAY ;opóŸnienie po wprowadzeniu cyfry
MOV P0,#0FFh ;reset klawiatury
SETB P1.7	;wy³¹czenie diody obs³ugi naciœniêcia
CLR F0
SJMP ROWS ;powrót do oryginalnej pêtli (obs³ugi klawiatury)

;--------------------------------------Delay-----------------------------------------------
DELAY: ;blokowanie klawiszy
MOV R3, #13
DEL: MOV R4, #1bh
DJNZ R4, $
DJNZ R3, DEL
RET

END
