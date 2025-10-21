package com.dolphinconsulting.asignaciones.model;

import lombok.Data;
import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "AUDITORIA_SUELDOS")
public class AuditoriaSueldos {
    
    @Id
    @Column(name = "ID_AUDITORIA")
    private Long idAuditoria;
    
    @Column(name = "NUMRUN_PROF")
    private Long numrunProf;
    
    @Column(name = "FECHA_CAMBIO")
    private LocalDate fechaCambio;
    
    @Column(name = "SUELDO_ANTERIOR")
    private BigDecimal sueldoAnterior;
    
    @Column(name = "SUELDO_NUEVO")
    private BigDecimal sueldoNuevo;
    
    @Column(name = "USUARIO")
    private String usuario;
    
    @Column(name = "TERMINAL")
    private String terminal;
    
    @Column(name = "FECHA_REGISTRO")
    private LocalDateTime fechaRegistro;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "NUMRUN_PROF", insertable = false, updatable = false)
    private Profesional profesional;
}