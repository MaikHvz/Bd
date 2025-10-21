package com.dolphinconsulting.asignaciones.model;

import lombok.Data;
import javax.persistence.*;

@Data
@Entity
@Table(name = "COMUNA")
public class Comuna {
    @Id
    @Column(name = "ID_COMUNA")
    private Long idComuna;
    
    @Column(name = "NOMBRE_COMUNA")
    private String nombreComuna;
}