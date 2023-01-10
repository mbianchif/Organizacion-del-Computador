;                   Protección de información - Cifrado Playfair
;
; La protección de información consiste en convertir un mensaje original en otro de forma tal que 
; éste sólo pueda ser recuperado por un grupo de personas a partir del mensaje codificado.
; El sistema para llevar a cabo la protección deberá basarse en el álgebra lineal, con las siguientes
; pautas: - Alfabeto a utilizar 25 caracteres (A ..Z, omitiendo la J). - Las letras son distribuidas
; en una matriz de 5x5. - El mensaje a codificar deberá ser dividido en bloques de a dos caracteres
; (validando que ninguno de los bloques contenga dos ocurrencias de la misma letra y la 'J').
;
; La conversión se llevará a cabo por bloques, es decir tomando dos caracteres del mensaje por vez.
;
; • Si los caracteres se encuentran en distinta fila y columna de la matriz, considerar un rectángulo 
;   formado con los caracteres como vértices y tomar de la misma fila la esquina opuesta. Si los caracteres
;   se encuentran en la misma fila, de cada caracter el situado a la derecha. Si los caracteres se encuentran
;   en la misma columna, tomar el caracter situado debajo.
;
; • Se pide desarrollar un programa en assembler Intel 80x86 que permita proteger información de la manera antes descripta.
;
; El mismo va a recibir como entrada:
;       • El mensaje a codificar o codificado.
;       • La matriz de 5x5.
; El mismo va a dejar como salida:
;       • El mensaje codificado u original.


; -------------- Llamado_a_rutinas_de_debug --------------:
call imprimirMatriz
; call imprimirModeFrase
; call imprimirPar


global main
extern fopen
extern fclose
extern fread
extern puts
extern gets
extern sscanf
extern printf
extern strncpy
extern fwrite


; -------------- Inicio_del_programa --------------:


section .data
    matriz times 25 db 0,0

    fileName db "matriz.dat",0
    fileMode db "rb",0
    file     dq 0

    MsjInput       db 10,"'_' '_______' [modo(E/D)] [mensaje]",10,10,"> ",0
    caracProhibido db 'j'

    encMode  db 0,0
    encFrase times 100 db 0
    input    times 100 db 0

    itFrase dw 0 ; Iterador de palabra

    par        dw 0,0
    pos1       dw 0,0
    pos2       dw 0,0
    posABuscar db 0

    posRow1 dw 0,0
    posCol1 dw 0,0
    posRow2 dw 0,0
    posCol2 dw 0,0

    buffer times 5 db 0,0

    caracNoEncontrado  db  0
    esPalabraImparUP   db 'N' ; Es palabra impar y se esta iterando el ultimo "par"

    ; Formatos_para_scanf
    FmtInput db "%c %[^\0]\0",0

    ; Formatos_para_printf
    FmtEnter       db 10,0
    FmtPares       db 10,"Par: [%c%c]",0
    FmtPoses       db " -> {%i %i}",10,0
    FmtPedirMatriz db 10,"Ingrese una matriz | Tiene que ser de minimo 25 chars y no contener la letra %c",10,10,"> ",0
    FmtErrCrypt    db 10,"Hubo un error, no se encontro este caracter en la matriz: %c",10,0
    FmtMsjCrypt    db 10,"El mensaje enc/dec es: %s",10,0
    FmtMatriz      db 10,"| %s |",0
    FmtDebugInt    db "%i",10,0

    ; string_para_debug
    hola db "HOLA",0


section .bss
    inputValido        resb 1
    matrizValida       resb 1
    caracEncontrado    resb 1
    primerCharEspacio  resb 1
    segundoCharEspacio resb 1


section .text
main:
    call    abrirArchivo
    cmp     qword[file],0
    jne     archivoExiste
pedirMatriz:
    call    pedirMatrizInput
    cmp     byte[matrizValida],'N'
    je      pedirMatriz
    call    crearMatrizArchivo
    jmp     tengoLaMatriz
archivoExiste:
    call    cargarMatriz
    call    cerrarArchivo
    cmp     byte[matrizValida],'N'
    je      pedirMatriz
tengoLaMatriz:
    call    pedirFrase

call imprimirMatriz

    call    encryptDecrypt
    call    imprimirEncDec
ret


; -------------- Rutinas_internas --------------:


; Matriz_de_archivo:
abrirArchivo:
    mov     rcx,fileName
    mov     rdx,fileMode
    sub     rsp,32
    call    fopen
    add     rsp,32
    mov     [file],rax
ret


cerrarArchivo:
    mov     rcx,[file]
    sub     rsp,32
    call    fclose
    add     rsp,32
ret


pedirMatrizInput:
    mov     byte[matrizValida],'S'

    mov     rcx,FmtPedirMatriz
    mov     rdx,[caracProhibido]
    sub     rsp,32
    call    printf
    add     rsp,32

    mov     rcx,input
    sub     rsp,32
    call    gets
    add     rsp,32

    mov     rcx,matriz
    mov     rdx,input
    mov     r8,25
    sub     rsp,32
    call    strncpy
    add     rsp,32

    call    valMatriz
ret


crearMatrizArchivo:
    mov     byte[fileMode],'w'
    mov     byte[fileMode + 1],0

    call    abrirArchivo

    mov     rcx,matriz
    mov     rdx,25
    mov     r8,1
    mov     r9,[file]
    sub     rsp,32
    call    fwrite
    add     rsp,32

    call    cerrarArchivo
ret


cargarMatriz:
    mov     byte[matrizValida],'S'

    mov     rcx,matriz
    mov     rdx,25
    mov     r8,1
    mov     r9,[file]
    sub     rsp,32
    call    fread
    add     rsp,32
    cmp     rax,0
    jle     matrizInvalida

    call    valMatriz
    jmp     finCargarMatriz
matrizNoValida:
    mov     byte[matrizValida],'N'
finCargarMatriz:
ret


valMatriz:
    mov     rbx,0
proximoCaracter:
    mov     rcx,1
    lea     rsi,[matriz + rbx]
    lea     rdi,[caracProhibido]
    repe    cmpsb
    je      matrizInvalida

    cmp     byte[matriz + rbx],97
    jl      probarSiEsMayusculaMatriz

    cmp     byte[matriz + rbx],122
    jg      matrizInvalida
volverMatriz:
    inc     rbx
    cmp     rbx,25
    jl      proximoCaracter
    jmp     finValMatriz
matrizInvalida:
    mov     byte[matrizValida],'N'
    jmp     finValMatriz
probarSiEsMayusculaMatriz:
    mov     ah,byte[matriz + rbx]
    add     ah,32
    cmp     ah,97
    jl      matrizInvalida
    mov     byte[matriz + rbx],ah
    jmp     volverMatriz
finValMatriz:
ret


; Input_y_verificacion:
pedirFrase:
    mov     byte[inputValido],'S'

    mov     rcx,MsjInput
    sub     rsp,32
    call    printf
    add     rsp,32

    mov     rcx,input
    sub     rsp,32
    call    gets
    add     rsp,32

    mov     rcx,input
    mov     rdx,FmtInput
    mov     r8,encMode
    mov     r9,encFrase
    sub     rsp,32
    call    sscanf
    add     rsp,32
    cmp     rax,2
    jne     pedirFrase

; call imprimirModeFrase

    call    valInput
    cmp     byte[inputValido],'N'
    je      pedirFrase
ret


valInput:
    mov     ah,'d'
    cmp     ah,[encMode]
    je      valWord

    inc     ah
    cmp     ah,[encMode]
    je      valWord

    mov     ah,'D'
    cmp     ah,[encMode]
    je      pasarModeMinuscula

    inc     ah
    cmp     ah,[encMode]
    je      pasarModeMinuscula

    jmp      inputInvalido
pasarModeMinuscula:
    add     ah,32
    mov     [encMode],ah
valWord:
    mov     rbx,0
proximaWord:
    mov     rcx,1
    lea     rsi,[encFrase + rbx]
    lea     rdi,[caracProhibido]
    repe    cmpsb
    je      inputInvalido

    mov     rdx,1
    and     rdx,rbx
    cmp     rdx,1
    je      esPosImpar

    mov     rcx,1
    lea     rsi,[encFrase + rbx]
    lea     rdi,[encFrase + rbx + 1]
    repe    cmpsb
    je      inputInvalido
esPosImpar:
    cmp     byte[encFrase + rbx],32
    je      esUnEspacio

    cmp     byte[encFrase + rbx],97
    jl      probarSiEsMayusculaFrase

    cmp     byte[encFrase + rbx],122
    jg      inputInvalido
esUnEspacio:
volverFrase:
    inc     rbx
    cmp     byte[encFrase + rbx],0
    je      finValInput
    jmp     proximaWord
inputInvalido:
    mov     byte[inputValido],'N'
    jmp     finValInput
probarSiEsMayusculaFrase:
    mov     ah,byte[encFrase + rbx]
    add     ah,32
    cmp     ah,97
    jl      inputInvalido
    mov     byte[encFrase + rbx],ah
    jmp     volverFrase
finValInput:
ret


imprimirEncDec:
    mov     rcx,FmtMsjCrypt
    mov     rdx,encFrase
    sub     rsp,32
    call    printf
    add     rsp,32
ret


; -------------- Encrypt_Decrypt --------------:


encryptDecrypt:
    mov     rbx,encFrase
    add     bx,[itFrase]
    mov     rcx,2
    lea     rsi,[rbx]
    lea     rdi,[par]
    rep     movsb

    cmp     word[par],0
    je      finEncryptDecrypt


    call    calcDesplaz
    cmp     byte[caracEncontrado],'N'
    je      errCaracter

; call imprimirPar

    call    transformarPoses

; call imprimirParTransformado

    cmp     byte[esPalabraImparUP],'S'
    je      pegarPrimerLetra

pegarSegundaLetra:
    mov     rbx,matriz
    add     bx,[pos2]
    mov     rax,encFrase
    add     ax,[itFrase]
    mov     rcx,1
    lea     rsi,[rbx]
    lea     rdi,[rax + 1]
    rep     movsb

    cmp     byte[segundoCharEspacio],'S'
    jne     pegarPrimerLetra
    mov     byte[rax + 1],' '

pegarPrimerLetra:
    mov     rbx,matriz
    add     bx,[pos1]
    mov     rax,encFrase
    add     ax,[itFrase]
    mov     rcx,1
    lea     rsi,[rbx]
    lea     rdi,[rax]
    rep     movsb

    cmp     byte[primerCharEspacio],'S'
    jne     moverIt
    mov     byte[rax],' '
moverIt:
    add     word[itFrase],2
    jmp     encryptDecrypt
errCaracter:
    call    errCrypt
finEncryptDecrypt:
ret


calcDesplaz:
    mov     byte[primerCharEspacio],'N'
    mov     byte[segundoCharEspacio],'N'
    mov     byte[posABuscar],0
deNuevo:
    mov     byte[caracEncontrado],'S'
    mov     rbx,0
    cmp     byte[posABuscar],0
    je      avanzar

    cmp     byte[par + 1],0
    je      segundoCaracterEs0
    cmp     byte[par + 1],32
    je      segundoCaracterEsEspacio
avanzar:
    mov     rcx,1
    cmp     byte[posABuscar],0
    jne     posDos
    
    cmp     byte[par],32
    je      primerCaracterEsEspacio

    lea     rsi,[par]
    jmp     salto
posDos:
    lea     rsi,[par + 1]
salto:
    lea     rdi,[matriz + rbx]
    repe    cmpsb
    je      encontrado

    inc     rbx
    cmp     rbx,25
    je      noEncontrado
    jmp     avanzar
encontrado:
    cmp     byte[posABuscar],0
    jne     segundaPos
    mov     [pos1],rbx
    inc     byte[posABuscar]
    jmp     deNuevo
segundaPos:
    mov     [pos2],rbx
    jmp     finCalcDesplaz
noEncontrado:
    mov     byte[caracEncontrado],'N'
    cmp     byte[posABuscar],0
    jne     dos
    mov     rax,0
    mov     al,[par]
    mov     [caracNoEncontrado],al
    jmp     finCalcDesplaz
dos:
    mov     rax,0
    mov     al,[par + 1]
    mov     [caracNoEncontrado],al
segundoCaracterEs0:
    mov     rcx,1
    lea     rsi,[pos1]
    lea     rdi,[pos2]
    repe    movsb
    jmp     finCalcDesplaz
primerCaracterEsEspacio:
    mov     byte[primerCharEspacio],'S'
    inc     byte[posABuscar]
    mov     word[pos1],-1
    jmp     deNuevo
segundoCaracterEsEspacio:
    mov     byte[segundoCharEspacio],'S'
    mov     word[pos2],-1
finCalcDesplaz:
ret


errCrypt:
    mov     rcx,FmtErrCrypt
    mov     rdx,[caracNoEncontrado]
    sub     rsp,32
    call    printf
    add     rsp,32

    mov     byte[caracNoEncontrado],'E'
ret


transformarPoses:
    mov     rcx,2
    lea     rsi,[pos1]
    lea     rdi,[pos2]
    repe    cmpsb
    je      sonElMismoCaracter

    cmp     byte[primerCharEspacio],'S'
    je      fin
    cmp     byte[segundoCharEspacio],'S'
    je      fin

    mov     word[posRow1],0
    mov     word[posCol1],0
    mov     word[posRow2],0
    mov     word[posCol2],0

    mov     rax,0
    mov     rdx,0

    mov     rax,[pos1]
    mov     rbx,5
    idiv    bl
    mov     [posRow1],al
    mov     [posCol1],ah

    mov     rax,0
    mov     rdx,0

    mov     rax,[pos2]
    idiv    bl
    mov     [posRow2],al
    mov     [posCol2],ah

    mov     rcx,2
    lea     rsi,[posCol1]
    lea     rdi,[posCol2]
    repe    cmpsb
    je      tienenMismaColumna

    mov     rcx,2
    lea     rsi,[posRow1]
    lea     rdi,[posRow2]
    repe    cmpsb
    je      tienenMismaFila
    jmp     tienenDistintaFilaColumna
sonElMismoCaracter:
    jmp     finSonIguales
tienenDistintaFilaColumna:
    call    swapearFilasColumnas
    jmp     finTransformarPoses
tienenMismaFila:
    call    mismaFila
    jmp     finTransformarPoses
tienenMismaColumna:
    call    mismaColumna
    jmp     finTransformarPoses
finTransformarPoses:
    mov     rax,5
    mul     word[posRow1]
    add     rax,[posCol1]
    mov     [pos1],rax

    mov     rax,5
    mul     word[posRow2]
    add     rax,[posCol2]
    mov     [pos2],rax
    jmp     fin
finSonIguales:
    mov     word[pos2],0
    mov     byte[esPalabraImparUP],'S'
fin:
ret


mismaFila:
    cmp     byte[encMode],'d'
    je      mismaFilaDecrypt

    add     word[posCol1],1
    add     word[posCol2],1
volverMismaFilaE:
    cmp     word[posCol1],4
    jg      posCol1Es5

    cmp     word[posCol2],4
    jg      posCol2Es5

    jmp     finMismaFila
posCol1Es5:
    mov     word[posCol1],0
    jmp     volverMismaFilaE
posCol2Es5:
    mov     word[posCol2],0
    jmp     volverMismaFilaE

mismaFilaDecrypt:
    sub     word[posCol1],1
    sub     word[posCol2],1
volverMismaFilaD:
    cmp     word[posCol1],0
    jl      posCol1EsMenos1

    cmp     word[posCol2],0
    jl      posCol2EsMenos1

    jmp     finMismaFila
posCol1EsMenos1:
    mov     word[posCol1],4
    jmp     volverMismaFilaD
posCol2EsMenos1:
    mov     word[posCol2],4
    jmp     volverMismaFilaD
finMismaFila:
ret


mismaColumna:
    cmp     byte[encMode],'d'
    je      mismaColumnaDecrypt

    add     word[posRow1],1
    add     word[posRow2],1
volverMismaColumnaE:
    cmp     word[posRow1],4
    jg      posRow1Es5

    cmp     word[posRow2],4
    jg      posRow2Es5

    jmp     finMismaColumna
posRow1Es5:
    mov     word[posRow1],0
    jmp     volverMismaColumnaE
posRow2Es5:
    mov     word[posRow2],0
    jmp     volverMismaColumnaE

mismaColumnaDecrypt:
    sub     word[posRow1],1
    sub     word[posRow2],1
volverMismaColumnaD:
    cmp     word[posRow1],0
    jl      posRow1EsMenos1

    cmp     word[posRow2],0
    jl      posRow2EsMenos1

    jmp     finMismaColumna
posRow1EsMenos1:
    mov     word[posRow1],4
    jmp     volverMismaColumnaD
posRow2EsMenos1:
    mov     word[posRow2],4
    jmp     volverMismaColumnaD
finMismaColumna:
ret

; Con PosEsEoZ me refiero a, tomando en cuenta el teclado y sus caracteres E y Z
; una matriz en la que E y Z son los caracteres que quiero rotar (centro en S) y
; con PosEsQoC lo mismo
swapearFilasColumnas:
    cmp     byte[encMode],'e'
    je      compararCol
compararCol:
    mov     rcx,1
    lea     rsi,[posCol1]
    lea     rdi,[posCol2]
    repe    cmpsb
    jl      compararFIzq
    jmp     compararFDer
compararFIzq:
    mov     rcx,1
    lea     rsi,[posRow1]
    lea     rdi,[posRow2]
    repe    cmpsb
    jg      PosEsEoZ
    jmp     PosEsQoC
compararFDer:
    mov     rcx,1
    lea     rsi,[posRow1]
    lea     rdi,[posRow2]
    repe    cmpsb
    jl      PosEsEoZ
    jmp     PosEsQoC
PosEsEoZ:
    cmp     byte[encMode],'e'
    je      swapearFilas
    jmp     swapearColumnas
PosEsQoC:
    cmp     byte[encMode],'e'
    je      swapearColumnas
    jmp     swapearFilas
swapearFilas:
    mov     ax,[posRow1]
    mov     rcx,1
    lea     rsi,[posRow2]
    lea     rdi,[posRow1]
    rep     movsb

    mov     [posRow2],ax
    jmp     finSwapearFC
swapearColumnas:
    mov     ax,[posCol1]
    mov     rcx,1
    lea     rsi,[posCol2]
    lea     rdi,[posCol1]
    rep     movsb

    mov     [posCol2],ax
finSwapearFC:
ret


; -------------- Rutinas_de_debug --------------:


imprimirMatriz:
    mov     rbx,0
proximos5:
    lea     rcx,[buffer]
    lea     rdx,[matriz + ebx]
    mov     r8,5
    sub     rsp,32
    call    strncpy
    add     rsp,32

    add     ebx,5

    mov     rcx,FmtMatriz
    mov     rdx,buffer
    sub     rsp,32
    call    printf
    add     rsp,32

    cmp     ebx,25
    je      finImprimirMatriz

    jmp     proximos5
finImprimirMatriz:
    mov     rcx,FmtEnter
    sub     rsp,32
    call    printf
    add     rsp,32
ret


imprimirModeFrase:
    mov     rcx,encMode
    sub     rsp,32
    call    puts
    add     rsp,32

    mov     rcx,encFrase
    sub     rsp,32
    call    puts
    add     rsp,32
ret


imprimirPoses:
    mov     rcx,FmtPoses
    mov     rdx,[pos1]
    mov     r8,[pos2]
    sub     rsp,32
    call    printf
    add     rsp,32
ret


imprimirPar:
    mov     rcx,FmtPares
    mov     rdx,[par]
    mov     r8,[par + 1]
    sub     rsp,32
    call    printf
    add     rsp,32

    call    imprimirPoses
ret


imprimirParTransformado:
    mov     rax,matriz
    add     ax,[pos1]
    mov     rbx,matriz
    add     bx,[pos2]

    lea     rcx,[FmtPares + 1]
    mov     rdx,[rax]
    mov     r8,[rbx]
    sub     rsp,32
    call    printf
    add     rsp,32

    call    imprimirPoses
ret


imprimirHola:
    mov     rcx,hola
    sub     rsp,32
    call    puts
    add     rsp,32
ret