package com.dolphinconsulting.asignaciones.model;

import lombok.Data;
import javax.persistence.*;
import java.math.BigDecimal;

@Data
@Entity
@Table(name = "DETALLE_ASIGNACION_MES")
public class DetalleAsignacionMes {
    
    @Id
    @Column(name = "RUN_PROFESIONAL")
    private String runProfesional;

    @Column(name = "MES_PROCESO")
    private Integer mesProceso;

    @Column(name = "ANNO_PROCESO")
    private Integer annoProceso;

    @Column(name = "NOMBRE_PROFESIONAL")
    private String nombreProfesional;

    @Column(name = "PROFESION")
    private String profesion;

    @Column(name = "NRO_ASESORIAS")
    private Integer nroAsesorias;
    
    @Column(name = "MONTO_HONORARIOS")
    private BigDecimal montoHonorarios;

    @Column(name = "MONTO_ASIG_TIPOCONT")
    private BigDecimal montoAsigTipoCont;

    @Column(name = "MONTO_ASIG_PROFESION")
    private BigDecimal montoAsigProfesion;

    @Column(name = "MONTO_MOVIL_EXTRA")
    private BigDecimal montoMovilExtra;

    @Column(name = "MONTO_TOTAL_ASIGNACIONES")
    private BigDecimal montoTotalAsignaciones;
    
    // Relación con Profesional eliminada: RUN_PROFESIONAL no enlaza con NUMRUN_PROF
}