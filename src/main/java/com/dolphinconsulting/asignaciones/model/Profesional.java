package com.dolphinconsulting.asignaciones.model;

import lombok.Data;

import javax.persistence.*;
import java.math.BigDecimal;

@Data
@Entity
@Table(name = "PROFESIONAL")
public class Profesional {

    @Id
    @Column(name = "NUMRUN_PROF")
    private Long numrunProf;
    
    @Column(name = "DVRUN_PROF")
    private String dvrunProf;
    
    @Column(name = "PNOMBRE")
    private String pnombre;
    
    @Column(name = "SNOMBRE")
    private String snombre;
    
    @Column(name = "APPATERNO")
    private String appaterno;
    
    @Column(name = "APMATERNO")
    private String apmaterno;
    
    @Column(name = "SUELDO")
    private BigDecimal sueldo;
    
    @Column(name = "TIPO_CONTRATO")
    private String tipoContrato;
    
    @ManyToOne
    @JoinColumn(name = "ID_PROFESION")
    private Profesion profesion;
    
    @ManyToOne
    @JoinColumn(name = "ID_COMUNA")
    private Comuna comuna;
    
    // Método para obtener nombre completo
    public String getNombreCompleto() {
        return pnombre + " " + (snombre != null ? snombre + " " : "") + appaterno + " " + apmaterno;
    }
}