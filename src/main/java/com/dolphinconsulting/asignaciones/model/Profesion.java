package com.dolphinconsulting.asignaciones.model;

import lombok.Data;

import javax.persistence.*;

@Data
@Entity
@Table(name = "PROFESION")
public class Profesion {

    @Id
    @Column(name = "ID_PROFESION")
    private Long idProfesion;
    
    @Column(name = "NOMBRE_PROF")
    private String nombreProf;
}