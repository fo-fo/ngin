NGIN_MAPPER_FME_7 = 1
.include "ngin/mapper/fme-7.inc"

.segment "NGIN_MAPPER_INIT"
.export __ngin_initMapper_FME_7
.proc __ngin_initMapper_FME_7
    ; Write 0 to all FME-7 registers. Order is somewhat significant,
    ; because the IRQ control register (which makes sure IRQ counting
    ; is disabled) comes before the IRQ counter reload value.

    lda #0
    tax
    clear:
        stx ngin_Fme_7::command
        sta ngin_Fme_7::parameter
        inx
        cpx #16
    bne clear

    ; \note This code is inlined, no RTS allowed.
.endproc
